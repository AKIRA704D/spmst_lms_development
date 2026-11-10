using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.LandingPage
{
    public class LandingData : IHttpHandler
    {
        public bool IsReusable { get { return false; } }

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);

            string action = (context.Request.QueryString["action"] ?? "").Trim().ToLowerInvariant();

            try
            {
                object result;

                switch (action)
                {
                    case "stats":
                        result = GetQuickStats();
                        break;
                    case "topborrowers":
                        result = GetTopBorrowers(GetIntParam(context, "count", 20, 1, 50));
                        break;
                    case "topinstitutes":
                        result = GetTopInstitutes(
                            GetStringParam(context, "role", "All"),
                            GetIntParam(context, "count", 20, 1, 50));
                        break;
                    case "topresources":
                        result = GetTopResources(GetIntParam(context, "count", 20, 1, 50));
                        break;
                    case "topsections":
                        result = GetTopSections(GetIntParam(context, "count", 20, 1, 50));
                        break;
                    case "catalogfilters":
                        result = GetCatalogFilters();
                        break;
                    case "catalog":
                        result = GetCatalog(
                            GetStringParam(context, "q", ""),
                            GetStringParam(context, "type", "All"),
                            GetStringParam(context, "section", "All"),
                            GetIntParam(context, "page", 1, 1, int.MaxValue),
                            GetIntParam(context, "pageSize", 12, 1, 60));
                        break;
                    case "contactinfo":
                        result = GetContactInfo();
                        break;
                    case "aboutus":
                        result = GetAboutUs();
                        break;
                    case "services":
                        result = GetPublicServices();
                        break;
                    case "termsactive":
                        result = GetActiveTerms();
                        break;
                    case "logos":
                        result = GetOrganizationLogos(GetStringParam(context, "entityType", null));
                        break;
                    default:
                        WriteJson(context, new { success = false, message = "Unknown action." });
                        return;
                }

                WriteJson(context, new { success = true, data = result });
            }
            catch (Exception ex)
            {
                WriteJson(context, new { success = false, message = "Server error: " + ex.Message });
            }
        }

        // ==========================================================================
        // ACTIONS
        // ==========================================================================

        private object GetQuickStats()
        {
            using (var conn = OpenConnection())
            {
                const string sql = @"
                    SELECT
                        (SELECT COUNT(*) FROM library_resources) AS total_titles,
                        (SELECT COUNT(*) FROM item_copies) AS total_copies,
                        (SELECT COUNT(*) FROM item_copies WHERE is_available = 1 AND status_condition = 'Good') AS available_copies,
                        (SELECT COUNT(DISTINCT user_id) FROM transactions) AS total_borrowers,
                        (SELECT COUNT(*) FROM transactions WHERE status IN ('Borrowed','Overdue')) AS active_loans,
                        (SELECT COUNT(DISTINCT section) FROM library_resources WHERE section IS NOT NULL AND section <> '') AS total_sections,
                        (SELECT COUNT(DISTINCT institute) FROM (
                            SELECT institute FROM students WHERE institute IS NOT NULL AND institute <> ''
                            UNION
                            SELECT institute FROM faculty WHERE institute IS NOT NULL AND institute <> ''
                        ) x) AS total_institutes";

                using (var cmd = new MySqlCommand(sql, conn))
                using (var reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        return new
                        {
                            totalTitles = ReadInt(reader, "total_titles"),
                            totalCopies = ReadInt(reader, "total_copies"),
                            availableCopies = ReadInt(reader, "available_copies"),
                            totalBorrowers = ReadInt(reader, "total_borrowers"),
                            activeLoans = ReadInt(reader, "active_loans"),
                            totalSections = ReadInt(reader, "total_sections"),
                            totalInstitutes = ReadInt(reader, "total_institutes")
                        };
                    }
                }
            }

            return new { totalTitles = 0, totalCopies = 0, availableCopies = 0, totalBorrowers = 0, activeLoans = 0, totalSections = 0, totalInstitutes = 0 };
        }

        private object GetTopBorrowers(int count)
        {
            const string sql = @"
                SELECT b.user_id, b.first_name, b.middle_name, b.last_name, b.profile_path, b.role, COUNT(*) AS borrow_count
                FROM transactions t
                JOIN (
                    SELECT student_id AS user_id, first_name, middle_name, last_name, profile_path, 'Student' AS role FROM students
                    UNION ALL
                    SELECT faculty_id AS user_id, first_name, middle_name, last_name, profile_path, 'Faculty' AS role FROM faculty
                    UNION ALL
                    SELECT staff_id AS user_id, first_name, middle_name, last_name, profile_path, 'Staff' AS role FROM staff
                ) b ON b.user_id = t.user_id
                GROUP BY b.user_id
                ORDER BY borrow_count DESC
                LIMIT @count";

            var list = new List<object>();
            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@count", count);
                using (var reader = cmd.ExecuteReader())
                {
                    int rank = 1;
                    while (reader.Read())
                    {
                        list.Add(new
                        {
                            rank = rank++,
                            userId = ReadString(reader, "user_id"),
                            fullName = BuildFullName(ReadString(reader, "first_name"), ReadString(reader, "middle_name"), ReadString(reader, "last_name")),
                            role = ReadString(reader, "role"),
                            profilePath = NormalizeAssetPath(ReadString(reader, "profile_path"), true),
                            borrowCount = ReadInt(reader, "borrow_count")
                        });
                    }
                }
            }

            return list;
        }

        private object GetTopInstitutes(string role, int count)
        {
            role = role == "Student" || role == "Faculty" ? role : "All";
            string orderCol = role == "Faculty" ? "faculty_count" : role == "Student" ? "student_count" : "total_count";

            string sql = string.Format(@"
                SELECT institute,
                    SUM(CASE WHEN role = 'Student' THEN 1 ELSE 0 END) AS student_count,
                    SUM(CASE WHEN role = 'Faculty' THEN 1 ELSE 0 END) AS faculty_count,
                    COUNT(*) AS total_count
                FROM (
                    SELECT t.transaction_id, s.institute AS institute, 'Student' AS role
                    FROM transactions t JOIN students s ON s.student_id = t.user_id
                    WHERE s.institute IS NOT NULL AND s.institute <> ''
                    UNION ALL
                    SELECT t.transaction_id, f.institute AS institute, 'Faculty' AS role
                    FROM transactions t JOIN faculty f ON f.faculty_id = t.user_id
                    WHERE f.institute IS NOT NULL AND f.institute <> ''
                ) x
                GROUP BY institute
                ORDER BY {0} DESC
                LIMIT @count", orderCol);

            var list = new List<object>();
            int maxValue = 0;
            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@count", count);
                using (var reader = cmd.ExecuteReader())
                {
                    int rank = 1;
                    while (reader.Read())
                    {
                        int studentCount = ReadInt(reader, "student_count");
                        int facultyCount = ReadInt(reader, "faculty_count");
                        int totalCount = ReadInt(reader, "total_count");
                        int shown = role == "Faculty" ? facultyCount : role == "Student" ? studentCount : totalCount;
                        if (shown > maxValue) maxValue = shown;

                        list.Add(new
                        {
                            rank = rank++,
                            institute = ReadString(reader, "institute"),
                            studentCount = studentCount,
                            facultyCount = facultyCount,
                            totalCount = totalCount,
                            shownCount = shown
                        });
                    }
                }
            }

            return new { role = role, maxValue = maxValue, items = list };
        }

        private object GetTopResources(int count)
        {
            const string countsSql = @"
                SELECT resource_id,
                    COUNT(*) AS total_copies,
                    SUM(CASE WHEN is_available = 1 AND status_condition = 'Good' THEN 1 ELSE 0 END) AS available_copies
                FROM item_copies
                GROUP BY resource_id";

            var copyCounts = new Dictionary<int, Tuple<int, int>>();
            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(countsSql, conn))
            using (var reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    copyCounts[ReadInt(reader, "resource_id")] = Tuple.Create(ReadInt(reader, "total_copies"), ReadInt(reader, "available_copies"));
                }
            }

            const string sql = @"
                SELECT r.resource_id, r.title, r.author, r.item_type, r.section, r.cover_path, COUNT(*) AS borrow_count
                FROM transactions t
                JOIN item_copies ic ON ic.accession_number = t.accession_number
                JOIN library_resources r ON r.resource_id = ic.resource_id
                GROUP BY r.resource_id
                ORDER BY borrow_count DESC
                LIMIT @count";

            var list = new List<object>();
            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@count", count);
                using (var reader = cmd.ExecuteReader())
                {
                    int rank = 1;
                    while (reader.Read())
                    {
                        int resId = ReadInt(reader, "resource_id");
                        var copies = copyCounts.ContainsKey(resId) ? copyCounts[resId] : Tuple.Create(0, 0);

                        list.Add(new
                        {
                            rank = rank++,
                            resourceId = resId,
                            title = ReadString(reader, "title"),
                            author = ReadString(reader, "author"),
                            itemType = ReadString(reader, "item_type"),
                            section = ReadString(reader, "section"),
                            coverPath = NormalizeAssetPath(ReadString(reader, "cover_path"), false),
                            borrowCount = ReadInt(reader, "borrow_count"),
                            totalCopies = copies.Item1,
                            availableCopies = copies.Item2
                        });
                    }
                }
            }

            return list;
        }

        private object GetTopSections(int count)
        {
            const string sql = @"
                SELECT r.section, COUNT(*) AS borrow_count, COUNT(DISTINCT r.resource_id) AS resource_count
                FROM transactions t
                JOIN item_copies ic ON ic.accession_number = t.accession_number
                JOIN library_resources r ON r.resource_id = ic.resource_id
                WHERE r.section IS NOT NULL AND r.section <> ''
                GROUP BY r.section
                ORDER BY borrow_count DESC
                LIMIT @count";

            var list = new List<object>();
            int maxValue = 0;
            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@count", count);
                using (var reader = cmd.ExecuteReader())
                {
                    int rank = 1;
                    while (reader.Read())
                    {
                        int borrowCount = ReadInt(reader, "borrow_count");
                        if (borrowCount > maxValue) maxValue = borrowCount;

                        list.Add(new
                        {
                            rank = rank++,
                            section = ReadString(reader, "section"),
                            borrowCount = borrowCount,
                            resourceCount = ReadInt(reader, "resource_count")
                        });
                    }
                }
            }

            return new { maxValue = maxValue, items = list };
        }

        private object GetCatalogFilters()
        {
            var types = new List<string>();
            var sections = new List<string>();

            using (var conn = OpenConnection())
            {
                using (var cmd = new MySqlCommand("SELECT DISTINCT item_type FROM library_resources WHERE item_type IS NOT NULL AND item_type <> '' ORDER BY item_type", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read()) types.Add(ReadString(reader, "item_type"));
                }

                using (var cmd = new MySqlCommand("SELECT DISTINCT section FROM library_resources WHERE section IS NOT NULL AND section <> '' ORDER BY section", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read()) sections.Add(ReadString(reader, "section"));
                }
            }

            return new { types = types, sections = sections };
        }

        private object GetCatalog(string q, string type, string section, int page, int pageSize)
        {
            q = (q ?? "").Trim();
            type = string.IsNullOrWhiteSpace(type) ? "All" : type;
            section = string.IsNullOrWhiteSpace(section) ? "All" : section;
            int offset = (page - 1) * pageSize;

            const string whereClause = @"
                WHERE (@q = '' OR title LIKE @qLike OR author LIKE @qLike OR publisher LIKE @qLike)
                  AND (@type = 'All' OR item_type = @type)
                  AND (@section = 'All' OR section = @section)";

            int total;
            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand("SELECT COUNT(*) FROM library_resources " + whereClause, conn))
            {
                cmd.Parameters.AddWithValue("@q", q);
                cmd.Parameters.AddWithValue("@qLike", "%" + q + "%");
                cmd.Parameters.AddWithValue("@type", type);
                cmd.Parameters.AddWithValue("@section", section);
                total = Convert.ToInt32(cmd.ExecuteScalar());
            }

            var resourceIds = new List<int>();
            var items = new List<Dictionary<string, object>>();

            string sql = @"
                SELECT resource_id, title, author, item_type, section, cover_path, pub_year, publisher
                FROM library_resources " + whereClause + @"
                ORDER BY title ASC
                LIMIT @pageSize OFFSET @offset";

            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@q", q);
                cmd.Parameters.AddWithValue("@qLike", "%" + q + "%");
                cmd.Parameters.AddWithValue("@type", type);
                cmd.Parameters.AddWithValue("@section", section);
                cmd.Parameters.AddWithValue("@pageSize", pageSize);
                cmd.Parameters.AddWithValue("@offset", offset);

                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        int resId = ReadInt(reader, "resource_id");
                        resourceIds.Add(resId);
                        items.Add(new Dictionary<string, object>
                        {
                            ["resourceId"] = resId,
                            ["title"] = ReadString(reader, "title"),
                            ["author"] = ReadString(reader, "author"),
                            ["itemType"] = ReadString(reader, "item_type"),
                            ["section"] = ReadString(reader, "section"),
                            ["coverPath"] = NormalizeAssetPath(ReadString(reader, "cover_path"), false),
                            ["pubYear"] = reader["pub_year"] == DBNull.Value ? (int?)null : Convert.ToInt32(reader["pub_year"]),
                            ["publisher"] = ReadString(reader, "publisher"),
                            ["totalCopies"] = 0,
                            ["availableCopies"] = 0
                        });
                    }
                }
            }

            if (resourceIds.Count > 0)
            {
                var inParams = string.Join(",", resourceIds.Select((id, idx) => "@id" + idx));
                string copiesSql = @"
                    SELECT resource_id,
                        COUNT(*) AS total_copies,
                        SUM(CASE WHEN is_available = 1 AND status_condition = 'Good' THEN 1 ELSE 0 END) AS available_copies
                    FROM item_copies
                    WHERE resource_id IN (" + inParams + @")
                    GROUP BY resource_id";

                var copyMap = new Dictionary<int, Tuple<int, int>>();
                using (var conn = OpenConnection())
                using (var cmd = new MySqlCommand(copiesSql, conn))
                {
                    for (int i = 0; i < resourceIds.Count; i++) cmd.Parameters.AddWithValue("@id" + i, resourceIds[i]);
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            copyMap[ReadInt(reader, "resource_id")] = Tuple.Create(ReadInt(reader, "total_copies"), ReadInt(reader, "available_copies"));
                        }
                    }
                }

                foreach (var item in items)
                {
                    int resId = (int)item["resourceId"];
                    if (copyMap.ContainsKey(resId))
                    {
                        item["totalCopies"] = copyMap[resId].Item1;
                        item["availableCopies"] = copyMap[resId].Item2;
                    }
                }
            }

            int totalPages = pageSize > 0 ? (int)Math.Ceiling(total / (double)pageSize) : 1;

            return new
            {
                items = items,
                page = page,
                pageSize = pageSize,
                total = total,
                totalPages = totalPages
            };
        }

        private object GetContactInfo()
        {
            const string sql = @"SELECT address, phone, email, hours_weekdays, hours_saturday, hours_sunday, facebook_url, map_embed_url
                                  FROM library_contact_info ORDER BY contact_id DESC LIMIT 1";

            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(sql, conn))
            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                {
                    return new
                    {
                        address = ReadString(reader, "address"),
                        phone = ReadString(reader, "phone"),
                        email = ReadString(reader, "email"),
                        hoursWeekdays = ReadString(reader, "hours_weekdays"),
                        hoursSaturday = ReadString(reader, "hours_saturday"),
                        hoursSunday = ReadString(reader, "hours_sunday"),
                        facebookUrl = ReadString(reader, "facebook_url"),
                        mapEmbedUrl = ReadString(reader, "map_embed_url")
                    };
                }
            }

            return null;
        }

        private object GetAboutUs()
        {
            const string sql = @"SELECT heading, body, stat1_label, stat1_value, stat2_label, stat2_value, stat3_label, stat3_value
                                  FROM library_about_us ORDER BY about_id DESC LIMIT 1";

            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(sql, conn))
            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                {
                    return new
                    {
                        heading = ReadString(reader, "heading"),
                        body = ReadString(reader, "body"),
                        stat1Label = ReadString(reader, "stat1_label"),
                        stat1Value = ReadString(reader, "stat1_value"),
                        stat2Label = ReadString(reader, "stat2_label"),
                        stat2Value = ReadString(reader, "stat2_value"),
                        stat3Label = ReadString(reader, "stat3_label"),
                        stat3Value = ReadString(reader, "stat3_value")
                    };
                }
            }

            return null;
        }

        private object GetPublicServices()
        {
            const string sql = @"SELECT service_id, icon_class, title, description
                                  FROM library_services
                                  WHERE is_active = 1
                                  ORDER BY sort_order ASC, service_id ASC";

            var list = new List<object>();
            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(sql, conn))
            using (var reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    list.Add(new
                    {
                        serviceId = ReadInt(reader, "service_id"),
                        iconClass = ReadString(reader, "icon_class"),
                        title = ReadString(reader, "title"),
                        description = ReadString(reader, "description")
                    });
                }
            }

            return list;
        }

        private object GetActiveTerms()
        {
            const string sql = @"SELECT terms_id, title, version_label, file_path, uploaded_at
                                  FROM library_terms
                                  WHERE is_active = 1
                                  ORDER BY uploaded_at DESC LIMIT 1";

            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(sql, conn))
            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                {
                    return new
                    {
                        termsId = ReadInt(reader, "terms_id"),
                        title = ReadString(reader, "title"),
                        versionLabel = ReadString(reader, "version_label"),
                        filePath = ReadString(reader, "file_path").Replace('\\', '/'),
                        uploadedAt = reader["uploaded_at"] == DBNull.Value ? "" : Convert.ToDateTime(reader["uploaded_at"]).ToString("MMMM d, yyyy")
                    };
                }
            }

            return null;
        }

        // --------------------------------------------------------------------------
        // NEW: organization_logos
        // Returns [] gracefully if the table has not been created yet — the
        // master page's LogoHelper already falls back to static assets.
        // --------------------------------------------------------------------------
        private object GetOrganizationLogos(string entityType)
        {
            var list = new List<object>();
            try
            {
                using (var conn = OpenConnection())
                {
                    string sql = @"SELECT logo_id, entity_type, entity_name, logo_path, sort_order
                                   FROM organization_logos
                                   WHERE is_active = 1";
                    if (!string.IsNullOrWhiteSpace(entityType))
                        sql += " AND entity_type = @entityType";
                    sql += " ORDER BY sort_order ASC, logo_id ASC";

                    using (var cmd = new MySqlCommand(sql, conn))
                    {
                        if (!string.IsNullOrWhiteSpace(entityType))
                            cmd.Parameters.AddWithValue("@entityType", entityType);

                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                list.Add(new
                                {
                                    logoId = ReadInt(reader, "logo_id"),
                                    entityType = ReadString(reader, "entity_type"),
                                    entityName = ReadString(reader, "entity_name"),
                                    logoPath = NormalizeAssetPath(ReadString(reader, "logo_path"), false),
                                    sortOrder = ReadInt(reader, "sort_order")
                                });
                            }
                        }
                    }
                }
            }
            catch
            {
                // Table may not exist yet — degrade to empty list rather than error.
            }
            return list;
        }

        // ==========================================================================
        // HELPERS
        // ==========================================================================

        private static MySqlConnection OpenConnection()
        {
            var connStringSetting = ConfigurationManager.ConnectionStrings["LmsDb"];

            if (connStringSetting == null)
            {
                throw new ConfigurationErrorsException(
                    "No connection string named 'LmsDb' was found in Web.config.");
            }

            var conn = new MySqlConnection(connStringSetting.ConnectionString);
            conn.Open();
            return conn;
        }

        private static string ReadString(System.Data.Common.DbDataReader reader, string col)
        {
            int idx = reader.GetOrdinal(col);
            return reader.IsDBNull(idx) ? string.Empty : reader.GetValue(idx).ToString();
        }

        private static int ReadInt(System.Data.Common.DbDataReader reader, string col)
        {
            int idx = reader.GetOrdinal(col);
            return reader.IsDBNull(idx) ? 0 : Convert.ToInt32(reader.GetValue(idx));
        }

        private static string ToProperCase(string s)
        {
            if (string.IsNullOrWhiteSpace(s)) return string.Empty;
            var ti = CultureInfo.InvariantCulture.TextInfo;
            return ti.ToTitleCase(s.Trim().ToLowerInvariant());
        }

        private static string BuildFullName(string first, string middle, string last)
        {
            string f = ToProperCase(first);
            string l = ToProperCase(last);
            string mi = string.IsNullOrWhiteSpace(middle) ? "" : (char.ToUpperInvariant(middle.Trim()[0]) + ".");

            var parts = new List<string>();
            if (!string.IsNullOrEmpty(f)) parts.Add(f);
            if (!string.IsNullOrEmpty(mi)) parts.Add(mi);
            if (!string.IsNullOrEmpty(l)) parts.Add(l);
            return string.Join(" ", parts);
        }

        private static string NormalizeAssetPath(string rawPath, bool isProfile)
        {
            if (!string.IsNullOrWhiteSpace(rawPath)) return rawPath.Replace('\\', '/');
            return isProfile ? "Assets/Profile/default-cover.png" : "Assets/Covers/default-cover.jpg";
        }

        private static string GetStringParam(HttpContext context, string key, string fallback)
        {
            string v = context.Request.QueryString[key];
            return string.IsNullOrWhiteSpace(v) ? fallback : v.Trim();
        }

        private static int GetIntParam(HttpContext context, string key, int fallback, int min, int max)
        {
            string v = context.Request.QueryString[key];
            int parsed;
            if (!int.TryParse(v, out parsed)) parsed = fallback;
            if (parsed < min) parsed = min;
            if (parsed > max) parsed = max;
            return parsed;
        }

        private static void WriteJson(HttpContext context, object payload)
        {
            var serializer = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
            context.Response.Write(serializer.Serialize(payload));
        }
    }
}