using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.Text;
using System.Web;
using System.Web.SessionState;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Users.Admin.Reports
{
    /// <summary>
    /// Data handler for the admin "Generate Report" builder page (generateReports.aspx).
    /// Modeled on the fish-record system's GetReports.ashx report-builder pattern, adapted
    /// for the LMS circulation/catalog domain. All queries are library-wide (no per-user
    /// scoping) since this is an admin-facing tool - unlike the original staff-scoped version.
    /// </summary>
    public class GetReports : IHttpHandler, IRequiresSessionState
    {
        private const string DefaultAvatarDataUri =
            "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjY0IiByeD0iMzIiIGZpbGw9IiNFNkU5RkYiLz48Y2lyY2xlIGN4PSIzMiIgY3k9IjI0IiByPSIxMiIgZmlsbD0iIzhDOTNENiIvPjxwYXRoIGQ9Ik0xMCA1NmMyLTE0IDEyLTIwIDIyLTIwczIwIDYgMjIgMjAiIGZpbGw9IiM4QzkzRDYiLz48L3N2Zz4=";

        // Reusable derived table that unifies students/faculty/staff into one borrower identity.
        // NOTE: assumes users.user_id == students.student_id == faculty.faculty_id == staff.staff_id
        // (the FK convention flagged for manual verification in project notes).
        private const string BorrowerNameJoin = @"
            (
                SELECT student_id AS uid,
                       CONCAT_WS(' ', first_name, middle_name, last_name, extension_name) AS full_name,
                       gender, mobile_number AS contact, institute AS org_unit, course, section
                FROM students
                UNION ALL
                SELECT faculty_id,
                       CONCAT_WS(' ', first_name, middle_name, last_name, extension_name),
                       gender, mobile_number, institute, NULL, NULL
                FROM faculty
                UNION ALL
                SELECT staff_id,
                       CONCAT_WS(' ', first_name, middle_name, last_name, extension_name),
                       gender, mobile_number, office_department, NULL, NULL
                FROM staff
            )";

        private class ReportQuery
        {
            public string Key;
            public string Label;
            public string Category;
            public string ChartType;
            public string[] Columns;
            public string Sql;
        }

        private static readonly List<ReportQuery> Catalog = new List<ReportQuery>
        {
            new ReportQuery {
                Key = "status_breakdown", Label = "Transactions by Status", Category = "Circulation",
                ChartType = "pie", Columns = new[] { "Status", "Count" },
                Sql = @"SELECT status AS Status, COUNT(*) AS Count
                        FROM transactions
                        GROUP BY status
                        ORDER BY Count DESC;"
            },
            new ReportQuery {
                Key = "campus_coverage", Label = "Checkouts by Campus", Category = "Coverage",
                ChartType = "bar", Columns = new[] { "Campus", "Checkouts" },
                Sql = @"SELECT COALESCE(NULLIF(ic.campus, ''), 'Unspecified') AS Campus, COUNT(*) AS Checkouts
                        FROM transactions t
                        LEFT JOIN item_copies ic ON ic.accession_number = t.accession_number
                        GROUP BY COALESCE(NULLIF(ic.campus, ''), 'Unspecified')
                        ORDER BY Checkouts DESC, Campus ASC
                        LIMIT 15;"
            },
            new ReportQuery {
                Key = "role_breakdown", Label = "Borrowers by Role", Category = "Demographics",
                ChartType = "pie", Columns = new[] { "Role", "Borrowers" },
                Sql = @"SELECT u.role AS Role, COUNT(DISTINCT t.user_id) AS Borrowers
                        FROM transactions t
                        INNER JOIN users u ON u.user_id = t.user_id
                        GROUP BY u.role
                        ORDER BY Borrowers DESC;"
            },
            new ReportQuery {
                Key = "gender_breakdown", Label = "Borrowers by Gender", Category = "Demographics",
                ChartType = "pie", Columns = new[] { "Gender", "Borrowers" },
                Sql = @"SELECT COALESCE(NULLIF(bn.gender, ''), 'Unspecified') AS Gender, COUNT(DISTINCT t.user_id) AS Borrowers
                        FROM transactions t
                        LEFT JOIN " + BorrowerNameJoin + @" bn ON bn.uid = t.user_id
                        GROUP BY COALESCE(NULLIF(bn.gender, ''), 'Unspecified')
                        ORDER BY Borrowers DESC;"
            },
            new ReportQuery {
                Key = "daily_trend", Label = "Daily Borrowing Trend", Category = "Circulation",
                ChartType = "line", Columns = new[] { "Date", "Checkouts" },
                Sql = @"SELECT DATE_FORMAT(borrow_date, '%Y-%m-%d') AS Date, COUNT(*) AS Checkouts
                        FROM transactions
                        WHERE borrow_date >= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
                        GROUP BY Date
                        ORDER BY Date ASC;"
            },
            new ReportQuery {
                Key = "weekly_trend", Label = "Weekly Borrowing Trend", Category = "Circulation",
                ChartType = "line", Columns = new[] { "Week", "Checkouts" },
                Sql = @"SELECT DATE_FORMAT(borrow_date, '%x-W%v') AS Week, COUNT(*) AS Checkouts
                        FROM transactions
                        GROUP BY Week
                        ORDER BY Week ASC;"
            },
            new ReportQuery {
                Key = "monthly_trend", Label = "Monthly Borrowing Trend", Category = "Circulation",
                ChartType = "line", Columns = new[] { "Month", "Checkouts" },
                Sql = @"SELECT DATE_FORMAT(borrow_date, '%Y-%m') AS Month, COUNT(*) AS Checkouts
                        FROM transactions
                        GROUP BY Month
                        ORDER BY Month ASC;"
            },
            new ReportQuery {
                Key = "yearly_trend", Label = "Yearly Borrowing Trend", Category = "Circulation",
                ChartType = "bar", Columns = new[] { "Year", "Checkouts" },
                Sql = @"SELECT DATE_FORMAT(borrow_date, '%Y') AS Year, COUNT(*) AS Checkouts
                        FROM transactions
                        GROUP BY Year
                        ORDER BY Year ASC;"
            },
            new ReportQuery {
                Key = "fines_trend", Label = "Fines Collected by Month", Category = "Fines",
                ChartType = "line", Columns = new[] { "Month", "Amount Collected" },
                Sql = @"SELECT DATE_FORMAT(paid_date, '%Y-%m') AS Month, COALESCE(SUM(amount_paid), 0) AS AmountCollected
                        FROM transactions
                        WHERE paid_date IS NOT NULL
                        GROUP BY Month
                        ORDER BY Month ASC;"
            },
            new ReportQuery {
                Key = "top_resources", Label = "Top Borrowed Resources", Category = "Catalog",
                ChartType = "bar", Columns = new[] { "Resource", "Checkouts" },
                Sql = @"SELECT lr.title AS Resource, COUNT(*) AS Checkouts
                        FROM transactions t
                        INNER JOIN item_copies ic ON ic.accession_number = t.accession_number
                        INNER JOIN library_resources lr ON lr.resource_id = ic.resource_id
                        GROUP BY lr.resource_id, lr.title
                        ORDER BY Checkouts DESC
                        LIMIT 10;"
            },
            new ReportQuery {
                Key = "top_genres", Label = "Top Genres Borrowed", Category = "Catalog",
                ChartType = "bar", Columns = new[] { "Genre", "Checkouts" },
                Sql = @"SELECT COALESCE(NULLIF(lr.genre, ''), 'Unspecified') AS Genre, COUNT(*) AS Checkouts
                        FROM transactions t
                        INNER JOIN item_copies ic ON ic.accession_number = t.accession_number
                        INNER JOIN library_resources lr ON lr.resource_id = ic.resource_id
                        GROUP BY COALESCE(NULLIF(lr.genre, ''), 'Unspecified')
                        ORDER BY Checkouts DESC
                        LIMIT 10;"
            },
            new ReportQuery {
                Key = "overdue_list", Label = "Overdue Transactions (List)", Category = "Circulation",
                ChartType = "none", Columns = new[] { "Borrower", "Title", "Due Date", "Days Overdue" },
                Sql = @"SELECT bn.full_name AS Borrower, lr.title AS Title, t.due_date AS DueDate,
                               DATEDIFF(CURDATE(), t.due_date) AS DaysOverdue
                        FROM transactions t
                        LEFT JOIN " + BorrowerNameJoin + @" bn ON bn.uid = t.user_id
                        LEFT JOIN item_copies ic ON ic.accession_number = t.accession_number
                        LEFT JOIN library_resources lr ON lr.resource_id = ic.resource_id
                        WHERE t.return_date IS NULL AND t.due_date < CURDATE()
                        ORDER BY DaysOverdue DESC
                        LIMIT 50;"
            },
            new ReportQuery {
                Key = "borrowers_list", Label = "Borrowers With Activity (List)", Category = "Demographics",
                ChartType = "none", Columns = new[] { "Name", "Role", "Contact", "Institute / Dept." },
                Sql = @"SELECT DISTINCT bn.full_name AS Name, u.role AS Role,
                               COALESCE(bn.contact, '-') AS Contact, COALESCE(bn.org_unit, '-') AS OrgUnit
                        FROM transactions t
                        INNER JOIN users u ON u.user_id = t.user_id
                        LEFT JOIN " + BorrowerNameJoin + @" bn ON bn.uid = u.user_id
                        ORDER BY Name ASC;"
            },
            new ReportQuery {
                Key = "resource_list_all",
                Label = "Resource List (All)",
                Category = "Catalog",
                ChartType = "none",
                Columns = new[] { "Cover", "Type", "Title", "Author", "Call Number", "Pub. Year" },
                Sql = @"SELECT cover_path AS Cover, COALESCE(NULLIF(item_type, ''), 'Unspecified') AS Type,
                               title AS Title, author AS Author, call_number AS CallNumber, pub_year AS PubYear
                        FROM library_resources
                        ORDER BY title ASC;"
            },
            new ReportQuery {
                Key = "resource_list_book",
                Label = "Resource List (Books)",
                Category = "Catalog",
                ChartType = "none",
                Columns = new[] { "Cover", "Type", "Title", "Author", "Call Number", "Pub. Year" },
                Sql = @"SELECT cover_path AS Cover, item_type AS Type, title AS Title, author AS Author,
                               call_number AS CallNumber, pub_year AS PubYear
                        FROM library_resources
                        WHERE LOWER(item_type) LIKE '%book%'
                        ORDER BY title ASC;"
            },
            new ReportQuery {
                Key = "resource_list_periodical",
                Label = "Resource List (Periodicals)",
                Category = "Catalog",
                ChartType = "none",
                Columns = new[] { "Cover", "Type", "Title", "Author", "Call Number", "Pub. Year" },
                Sql = @"SELECT cover_path AS Cover, item_type AS Type, title AS Title, author AS Author,
                               call_number AS CallNumber, pub_year AS PubYear
                        FROM library_resources
                        WHERE LOWER(item_type) LIKE '%periodical%'
                        ORDER BY title ASC;"
            }
        };

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";

            try
            {
                // NOTE: this only confirms a session exists. It does not verify an "admin" role,
                // since this project's role check goes through sessionHelper rather than a raw
                // Session["UserRole"] key (see masterpages/admin.master). Tighten this once the
                // exact sessionHelper API for role checks is confirmed.
                if (context.Session["UserId"] == null)
                {
                    context.Response.StatusCode = 401;
                    context.Response.Write("{\"error\":\"Not authorized.\"}");
                    return;
                }

                string action = context.Request["action"] ?? "list";

                switch (action)
                {
                    case "list": WriteCatalog(context); break;
                    case "data": WriteData(context, context.Request["query"]); break;
                    case "borrowers": WriteBorrowersList(context); break;
                    case "borrower_detail": WriteBorrowerDetail(context, context.Request["id"], context.Request["statuses"], context.Request["dateFrom"], context.Request["dateTo"]); break;
                    case "resources": WriteResourcesList(context); break;
                    case "resource_detail": WriteResourceDetail(context, context.Request["id"]); break;
                    default:
                        context.Response.StatusCode = 400;
                        context.Response.Write("{\"error\":\"Unknown action.\"}");
                        break;
                }
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write("{\"error\":\"" + JsonEscape(ex.Message) + "\"}");
            }
        }

        // NOTE: admin.master reads ConfigurationManager.ConnectionStrings["LmsDb"].
        // Prior project memory referenced the key "LmsDb" instead - please confirm
        // which key is actually present in Web.config and adjust if needed.
        private static MySqlConnection GetConnection()
        {
            string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
            return new MySqlConnection(connStr);
        }

        private static string GetSafeString(MySqlDataReader reader, string col)
        {
            try
            {
                object val = reader[col];
                return val == DBNull.Value ? null : Convert.ToString(val);
            }
            catch { return null; }
        }

        private static decimal? GetSafeDecimal(MySqlDataReader reader, string col)
        {
            try
            {
                object val = reader[col];
                return val == DBNull.Value ? (decimal?)null : Convert.ToDecimal(val);
            }
            catch { return null; }
        }

        private static int? GetSafeInt(MySqlDataReader reader, string col)
        {
            try
            {
                object val = reader[col];
                return val == DBNull.Value ? (int?)null : Convert.ToInt32(val);
            }
            catch { return null; }
        }

        private static string NullToDash(object val)
        {
            if (val == null || val == DBNull.Value) return "-";
            string s = Convert.ToString(val);
            return string.IsNullOrWhiteSpace(s) ? "-" : s;
        }

        private static string FormatCell(object val)
        {
            if (val == null || val == DBNull.Value) return "-";
            if (val is decimal dec) return dec.ToString("0.##", CultureInfo.InvariantCulture);
            if (val is DateTime dt) return dt.ToString("MMM dd, yyyy");
            return Convert.ToString(val);
        }

        private static string JsonEscape(string value)
        {
            if (string.IsNullOrEmpty(value)) return "";
            return value.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", " ").Replace("\n", " ");
        }

        private static string ResolveAppUrl(HttpContext context, string appRelativePath)
        {
            if (string.IsNullOrWhiteSpace(appRelativePath)) return "";
            if (appRelativePath.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                appRelativePath.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                return appRelativePath;
            }
            try
            {
                return VirtualPathUtility.ToAbsolute(appRelativePath);
            }
            catch
            {
                string appPath = context.Request.ApplicationPath;
                if (appPath == null) appPath = "/";
                if (!appPath.EndsWith("/")) appPath += "/";
                string trimmed = appRelativePath.StartsWith("~/") ? appRelativePath.Substring(2) : appRelativePath.TrimStart('/');
                return appPath + trimmed;
            }
        }

        private void WriteCatalog(HttpContext context)
        {
            var sb = new StringBuilder();
            sb.Append("[");
            for (int i = 0; i < Catalog.Count; i++)
            {
                var q = Catalog[i];
                if (i > 0) sb.Append(",");
                sb.Append("{\"key\":\"").Append(JsonEscape(q.Key)).Append("\",")
                  .Append("\"label\":\"").Append(JsonEscape(q.Label)).Append("\",")
                  .Append("\"category\":\"").Append(JsonEscape(q.Category)).Append("\",")
                  .Append("\"chartType\":\"").Append(JsonEscape(q.ChartType)).Append("\"}");
            }
            sb.Append("]");
            context.Response.Write(sb.ToString());
        }

        private void WriteData(HttpContext context, string key)
        {
            var query = Catalog.Find(q => q.Key == key);
            if (query == null)
            {
                context.Response.StatusCode = 400;
                context.Response.Write("{\"error\":\"Unknown query.\"}");
                return;
            }

            var rows = new List<string>();
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new MySqlCommand(query.Sql, conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var cells = new List<string>();
                            for (int c = 0; c < reader.FieldCount; c++)
                            {
                                object val = reader.GetValue(c);
                                string cellValue = FormatCell(val);

                                // For resource list queries, convert Cover (image path) into an HTML <Img> tag
                                if (key.StartsWith("resource_list") && c == 0 && !string.IsNullOrEmpty(cellValue) && cellValue != "-")
                                {
                                    string resolvedUrl = ResolveAppUrl(context, cellValue);
                                    if (!string.IsNullOrEmpty(resolvedUrl))
                                        cellValue = "<Img src=\"" + JsonEscape(resolvedUrl) + "\" style=\"width:40px;height:40px;object-fit:cover;border:1px solid #D9D9D9;\" />";
                                    else
                                        cellValue = "-";
                                }

                                cells.Add("\"" + JsonEscape(cellValue) + "\"");
                            }
                            rows.Add("[" + string.Join(",", cells) + "]");
                        }
                    }
                }
            }

            var sb = new StringBuilder();
            sb.Append("{");
            sb.Append("\"label\":\"").Append(JsonEscape(query.Label)).Append("\",");
            sb.Append("\"chartType\":\"").Append(JsonEscape(query.ChartType)).Append("\",");
            sb.Append("\"columns\":[").Append(string.Join(",", Array.ConvertAll(query.Columns, c => "\"" + JsonEscape(c) + "\""))).Append("],");
            sb.Append("\"rows\":[").Append(string.Join(",", rows)).Append("],");
            sb.Append("\"generatedAt\":\"").Append(JsonEscape(DateTime.Now.ToString("MMM dd, yyyy h:mm tt"))).Append("\"");
            sb.Append("}");
            context.Response.Write(sb.ToString());
        }

        // ============================================================
        //  WriteBorrowersList - all active student/faculty/staff users
        // ============================================================
        private void WriteBorrowersList(HttpContext context)
        {
            string sql = @"
                SELECT u.user_id AS Id, bn.full_name AS Name
                FROM users u
                INNER JOIN " + BorrowerNameJoin + @" bn ON bn.uid = u.user_id
                WHERE u.role IN ('student','faculty','staff')
                ORDER BY bn.full_name ASC;";

            var items = new List<string>();
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            items.Add("{\"id\":\"" + JsonEscape(Convert.ToString(reader["Id"])) + "\"," +
                                      "\"name\":\"" + JsonEscape(Convert.ToString(reader["Name"])) + "\"}");
                        }
                    }
                }
            }
            context.Response.Write("[" + string.Join(",", items) + "]");
        }

        // ============================================================
        //  WriteResourcesList - filtered by kind: all / book / periodical
        // ============================================================
        private void WriteResourcesList(HttpContext context)
        {
            string kind = (context.Request["kind"] ?? "all").Trim().ToLowerInvariant();
            string sql;
            if (kind == "book")
            {
                sql = "SELECT resource_id AS Id, title AS Name FROM library_resources WHERE LOWER(item_type) LIKE '%book%' ORDER BY title ASC;";
            }
            else if (kind == "periodical")
            {
                sql = "SELECT resource_id AS Id, title AS Name FROM library_resources WHERE LOWER(item_type) LIKE '%periodical%' ORDER BY title ASC;";
            }
            else if (kind == "all" || string.IsNullOrEmpty(kind))
            {
                sql = "SELECT resource_id AS Id, title AS Name FROM library_resources ORDER BY title ASC;";
            }
            else
            {
                context.Response.StatusCode = 400;
                context.Response.Write("{\"error\":\"Invalid kind filter.\"}");
                return;
            }

            var items = new List<string>();
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            items.Add("{\"id\":" + Convert.ToInt32(reader["Id"]) +
                                      ",\"name\":\"" + JsonEscape(Convert.ToString(reader["Name"])) + "\"}");
                        }
                    }
                }
            }
            context.Response.Write("[" + string.Join(",", items) + "]");
        }

        // ============================================================
        //  WriteResourceDetail - single library_resources reference card
        // ============================================================
        private void WriteResourceDetail(HttpContext context, string idRaw)
        {
            try
            {
                int resourceId;
                if (!int.TryParse(idRaw, out resourceId))
                {
                    context.Response.StatusCode = 400;
                    context.Response.Write("{\"error\":\"Invalid resource id.\"}");
                    return;
                }

                const string sql = @"
                    SELECT title, author, publisher, item_type, genre, call_number, isbn, issn,
                           edition, pub_year, description, cover_path
                    FROM library_resources
                    WHERE resource_id = @id
                    LIMIT 1;";

                using (var conn = GetConnection())
                {
                    conn.Open();

                    var sb = new StringBuilder();
                    bool found = false;

                    using (var cmd = new MySqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@id", resourceId);
                        using (var reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                found = true;
                                string coverPath = GetSafeString(reader, "cover_path");
                                string coverUrl = string.IsNullOrWhiteSpace(coverPath) ? "" : ResolveAppUrl(context, coverPath);
                                string isbn = GetSafeString(reader, "isbn");
                                string issn = GetSafeString(reader, "issn");
                                string isbnIssn = !string.IsNullOrWhiteSpace(isbn) ? isbn : (!string.IsNullOrWhiteSpace(issn) ? issn : null);

                                sb.Append("{");
                                sb.Append("\"resourceId\":").Append(resourceId).Append(",");
                                sb.Append("\"title\":\"").Append(JsonEscape(GetSafeString(reader, "title") ?? "Untitled")).Append("\",");
                                sb.Append("\"author\":\"").Append(JsonEscape(NullToDash(reader["author"]))).Append("\",");
                                sb.Append("\"publisher\":\"").Append(JsonEscape(NullToDash(reader["publisher"]))).Append("\",");
                                sb.Append("\"itemType\":\"").Append(JsonEscape(NullToDash(reader["item_type"]))).Append("\",");
                                sb.Append("\"genre\":\"").Append(JsonEscape(NullToDash(reader["genre"]))).Append("\",");
                                sb.Append("\"callNumber\":\"").Append(JsonEscape(NullToDash(reader["call_number"]))).Append("\",");
                                sb.Append("\"isbnIssn\":\"").Append(JsonEscape(isbnIssn ?? "-")).Append("\",");
                                sb.Append("\"edition\":\"").Append(JsonEscape(NullToDash(reader["edition"]))).Append("\",");
                                sb.Append("\"pubYear\":\"").Append(JsonEscape(NullToDash(reader["pub_year"]))).Append("\",");
                                sb.Append("\"description\":\"").Append(JsonEscape(GetSafeString(reader, "description") ?? "")).Append("\",");
                                sb.Append("\"coverUrl\":\"").Append(JsonEscape(coverUrl)).Append("\"");
                                sb.Append("}");
                            }
                        }
                    }

                    if (!found)
                    {
                        context.Response.StatusCode = 404;
                        context.Response.Write("{\"error\":\"Resource not found.\"}");
                        return;
                    }

                    // ---- Copy counts ----
                    int totalCopies = 0, copiesAvailable = 0, timesBorrowed = 0;
                    using (var cmd = new MySqlCommand(
                        "SELECT COUNT(*) AS Total, SUM(CASE WHEN is_available = 1 THEN 1 ELSE 0 END) AS Avail FROM item_copies WHERE resource_id = @id;",
                        conn))
                    {
                        cmd.Parameters.AddWithValue("@id", resourceId);
                        using (var reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                totalCopies = GetSafeInt(reader, "Total") ?? 0;
                                copiesAvailable = GetSafeInt(reader, "Avail") ?? 0;
                            }
                        }
                    }

                    using (var cmd = new MySqlCommand(
                        @"SELECT COUNT(*) AS Cnt FROM transactions t
                          INNER JOIN item_copies ic ON ic.accession_number = t.accession_number
                          WHERE ic.resource_id = @id;", conn))
                    {
                        cmd.Parameters.AddWithValue("@id", resourceId);
                        var result = cmd.ExecuteScalar();
                        timesBorrowed = result != null && result != DBNull.Value ? Convert.ToInt32(result) : 0;
                    }

                    string json = sb.ToString();
                    string tail = ",\"totalCopies\":" + totalCopies +
                                  ",\"copiesAvailable\":" + copiesAvailable +
                                  ",\"timesBorrowed\":" + timesBorrowed +
                                  ",\"generatedAt\":\"" + JsonEscape(DateTime.Now.ToString("MMM dd, yyyy h:mm tt")) + "\"";
                    json = json.Substring(0, json.Length - 1) + tail + "}";
                    context.Response.Write(json);
                }
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write("{\"error\":\"Resource detail error: " + JsonEscape(ex.Message) + "\"}");
            }
        }

        private static readonly HashSet<string> ValidStatuses = new HashSet<string>
        {
            "Borrowed", "Returned", "Overdue", "Reserved", "Ready", "Cancelled"
        };

        // ============================================================
        //  WriteBorrowerDetail - full borrower profile + loan history
        // ============================================================
        private void WriteBorrowerDetail(HttpContext context, string idRaw, string statusesRaw, string dateFromRaw, string dateToRaw)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(idRaw))
                {
                    context.Response.StatusCode = 400;
                    context.Response.Write("{\"error\":\"Invalid borrower id.\"}");
                    return;
                }
                string userId = idRaw.Trim();

                var statuses = new List<string>();
                if (!string.IsNullOrWhiteSpace(statusesRaw))
                {
                    foreach (var s in statusesRaw.Split(','))
                    {
                        var trimmed = s.Trim();
                        var match = "";
                        foreach (var vs in ValidStatuses)
                            if (string.Equals(vs, trimmed, StringComparison.OrdinalIgnoreCase)) match = vs;
                        if (!string.IsNullOrEmpty(match) && !statuses.Contains(match)) statuses.Add(match);
                    }
                }
                if (statuses.Count == 0)
                {
                    statuses.AddRange(ValidStatuses);
                }

                DateTime dateFrom;
                if (!DateTime.TryParse(dateFromRaw, CultureInfo.InvariantCulture, DateTimeStyles.None, out dateFrom))
                    dateFrom = new DateTime(2000, 1, 1);

                DateTime dateTo;
                if (!DateTime.TryParse(dateToRaw, CultureInfo.InvariantCulture, DateTimeStyles.None, out dateTo))
                    dateTo = DateTime.Today;
                if (dateTo < dateFrom) { var tmp = dateFrom; dateFrom = dateTo; dateTo = tmp; }

                var statusParamNames = new List<string>();
                for (int i = 0; i < statuses.Count; i++) statusParamNames.Add("@st" + i);
                string statusInClause = string.Join(",", statusParamNames);

                using (var conn = GetConnection())
                {
                    conn.Open();

                    // ---- PERMISSION / EXISTENCE CHECK ----
                    const string existsSql = "SELECT role FROM users WHERE user_id = @uid LIMIT 1;";
                    string role = null;
                    using (var cmd = new MySqlCommand(existsSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@uid", userId);
                        var result = cmd.ExecuteScalar();
                        if (result != null && result != DBNull.Value) role = Convert.ToString(result);
                    }
                    if (role == null)
                    {
                        context.Response.StatusCode = 404;
                        context.Response.Write("{\"error\":\"Borrower not found.\"}");
                        return;
                    }

                    // ---- PROFILE QUERY ----
                    string profileSql = @"
                        SELECT u.user_id, u.email, bn.full_name, bn.gender, bn.contact, bn.org_unit, bn.course, bn.section, u.created_at
                        FROM users u
                        LEFT JOIN " + BorrowerNameJoin + @" bn ON bn.uid = u.user_id
                        WHERE u.user_id = @uid;";

                    var sb = new StringBuilder();
                    bool found = false;

                    using (var cmd = new MySqlCommand(profileSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@uid", userId);
                        using (var reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                found = true;
                                string courseSection = "-";
                                string course = GetSafeString(reader, "course");
                                string section = GetSafeString(reader, "section");
                                if (!string.IsNullOrWhiteSpace(course) || !string.IsNullOrWhiteSpace(section))
                                    courseSection = (course ?? "-") + (string.IsNullOrWhiteSpace(section) ? "" : " / " + section);

                                sb.Append("{");
                                sb.Append("\"type\":\"borrower\",");
                                sb.Append("\"borrowerId\":\"").Append(JsonEscape(userId)).Append("\",");
                                sb.Append("\"fullName\":\"").Append(JsonEscape(GetSafeString(reader, "full_name") ?? "Unknown")).Append("\",");
                                sb.Append("\"role\":\"").Append(JsonEscape(role)).Append("\",");
                                sb.Append("\"gender\":\"").Append(JsonEscape(NullToDash(reader["gender"]))).Append("\",");
                                sb.Append("\"contact\":\"").Append(JsonEscape(NullToDash(reader["contact"]))).Append("\",");
                                sb.Append("\"email\":\"").Append(JsonEscape(NullToDash(reader["email"]))).Append("\",");
                                sb.Append("\"institute\":\"").Append(JsonEscape(NullToDash(reader["org_unit"]))).Append("\",");
                                sb.Append("\"courseSection\":\"").Append(JsonEscape(courseSection)).Append("\",");
                                sb.Append("\"photoUrl\":\"").Append(JsonEscape(DefaultAvatarDataUri)).Append("\",");
                                sb.Append("\"recordedOn\":\"").Append(JsonEscape(Convert.ToDateTime(reader["created_at"]).ToString("MMM dd, yyyy"))).Append("\",");
                                sb.Append("\"filterStatuses\":[").Append(string.Join(",", statuses.ConvertAll(s => "\"" + s + "\""))).Append("],");
                                sb.Append("\"filterDateFrom\":\"").Append(dateFrom.ToString("MMM dd, yyyy")).Append("\",");
                                sb.Append("\"filterDateTo\":\"").Append(dateTo.ToString("MMM dd, yyyy")).Append("\"");
                                sb.Append("}");
                            }
                        }
                    }

                    if (!found)
                    {
                        context.Response.StatusCode = 404;
                        context.Response.Write("{\"error\":\"Borrower record could not be loaded.\"}");
                        return;
                    }

                    // ---- STATS: loan count, fines paid, last borrow date ----
                    int loanCount = 0;
                    decimal totalFinesPaid = 0m;
                    DateTime? lastBorrowDate = null;

                    string statsSql = @"
                        SELECT COUNT(*) AS LoanCount, COALESCE(SUM(amount_paid), 0) AS FinesPaid, MAX(borrow_date) AS LastBorrow
                        FROM transactions
                        WHERE user_id = @uid
                          AND status IN (" + statusInClause + @")
                          AND borrow_date BETWEEN @dfrom AND @dto;";

                    using (var cmd = new MySqlCommand(statsSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@uid", userId);
                        cmd.Parameters.AddWithValue("@dfrom", dateFrom.ToString("yyyy-MM-dd"));
                        cmd.Parameters.AddWithValue("@dto", dateTo.ToString("yyyy-MM-dd"));
                        for (int i = 0; i < statuses.Count; i++) cmd.Parameters.AddWithValue(statusParamNames[i], statuses[i]);

                        using (var reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                loanCount = GetSafeInt(reader, "LoanCount") ?? 0;
                                totalFinesPaid = GetSafeDecimal(reader, "FinesPaid") ?? 0m;
                                var lb = reader["LastBorrow"];
                                if (lb != DBNull.Value) lastBorrowDate = Convert.ToDateTime(lb);
                            }
                        }
                    }

                    // ---- TRANSACTION RECORDS (may be empty) ----
                    string recordsSql = @"
                        SELECT t.borrow_date, t.due_date, t.return_date, t.status, t.accession_number, t.fine_amount
                        FROM transactions t
                        WHERE t.user_id = @uid
                          AND t.status IN (" + statusInClause + @")
                          AND t.borrow_date BETWEEN @dfrom AND @dto
                        ORDER BY t.borrow_date DESC;";

                    var recordRows = new List<string>();
                    using (var cmd = new MySqlCommand(recordsSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@uid", userId);
                        cmd.Parameters.AddWithValue("@dfrom", dateFrom.ToString("yyyy-MM-dd"));
                        cmd.Parameters.AddWithValue("@dto", dateTo.ToString("yyyy-MM-dd"));
                        for (int i = 0; i < statuses.Count; i++) cmd.Parameters.AddWithValue(statusParamNames[i], statuses[i]);

                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                DateTime bd = Convert.ToDateTime(reader["borrow_date"]);
                                DateTime dd = Convert.ToDateTime(reader["due_date"]);
                                object rdObj = reader["return_date"];
                                string returnDate = rdObj == DBNull.Value ? "-" : Convert.ToDateTime(rdObj).ToString("MMM dd, yyyy");
                                decimal fine = GetSafeDecimal(reader, "fine_amount") ?? 0m;

                                recordRows.Add("{\"borrowDate\":\"" + JsonEscape(bd.ToString("MMM dd, yyyy")) + "\"," +
                                               "\"dueDate\":\"" + JsonEscape(dd.ToString("MMM dd, yyyy")) + "\"," +
                                               "\"returnDate\":\"" + JsonEscape(returnDate) + "\"," +
                                               "\"status\":\"" + JsonEscape(NullToDash(reader["status"])) + "\"," +
                                               "\"accessionNumber\":\"" + JsonEscape(NullToDash(reader["accession_number"])) + "\"," +
                                               "\"fineAmount\":\"" + fine.ToString("0.##", CultureInfo.InvariantCulture) + "\"}");
                            }
                        }
                    }

                    // ---- RESOURCES BORROWED (grouped, may be empty) ----
                    string resourcesSql = @"
                        SELECT lr.title AS Title, lr.author AS Author, lr.genre AS Genre, lr.call_number AS CallNumber,
                               lr.cover_path AS CoverPath, COUNT(*) AS TimesBorrowed
                        FROM transactions t
                        INNER JOIN item_copies ic ON ic.accession_number = t.accession_number
                        INNER JOIN library_resources lr ON lr.resource_id = ic.resource_id
                        WHERE t.user_id = @uid
                          AND t.status IN (" + statusInClause + @")
                          AND t.borrow_date BETWEEN @dfrom AND @dto
                        GROUP BY lr.resource_id, lr.title, lr.author, lr.genre, lr.call_number, lr.cover_path
                        ORDER BY TimesBorrowed DESC;";

                    var resourceRows = new List<string>();
                    using (var cmd = new MySqlCommand(resourcesSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@uid", userId);
                        cmd.Parameters.AddWithValue("@dfrom", dateFrom.ToString("yyyy-MM-dd"));
                        cmd.Parameters.AddWithValue("@dto", dateTo.ToString("yyyy-MM-dd"));
                        for (int i = 0; i < statuses.Count; i++) cmd.Parameters.AddWithValue(statusParamNames[i], statuses[i]);

                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                string coverPath = GetSafeString(reader, "CoverPath");
                                string coverUrl = string.IsNullOrWhiteSpace(coverPath) ? "" : ResolveAppUrl(context, coverPath);

                                resourceRows.Add("{\"title\":\"" + JsonEscape(GetSafeString(reader, "Title") ?? "Untitled") + "\"," +
                                                  "\"author\":\"" + JsonEscape(NullToDash(reader["Author"])) + "\"," +
                                                  "\"genre\":\"" + JsonEscape(NullToDash(reader["Genre"])) + "\"," +
                                                  "\"callNumber\":\"" + JsonEscape(NullToDash(reader["CallNumber"])) + "\"," +
                                                  "\"coverUrl\":\"" + JsonEscape(coverUrl) + "\"," +
                                                  "\"timesBorrowed\":" + (GetSafeInt(reader, "TimesBorrowed") ?? 0) + "}");
                            }
                        }
                    }

                    // ---- BUILD FINAL JSON ----
                    string tail = ",\"loanCount\":" + loanCount +
                                  ",\"totalFinesPaid\":\"" + totalFinesPaid.ToString("0.##", CultureInfo.InvariantCulture) + "\"" +
                                  ",\"lastBorrowDate\":\"" + (lastBorrowDate.HasValue ? lastBorrowDate.Value.ToString("MMM dd, yyyy") : "-") + "\"" +
                                  ",\"resourcesBorrowed\":[" + string.Join(",", resourceRows) + "]" +
                                  ",\"transactionRecords\":[" + string.Join(",", recordRows) + "]" +
                                  ",\"generatedAt\":\"" + JsonEscape(DateTime.Now.ToString("MMM dd, yyyy h:mm tt")) + "\"";

                    string json2 = sb.ToString();
                    json2 = json2.Substring(0, json2.Length - 1) + tail + "}";
                    context.Response.Write(json2);
                }
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write("{\"error\":\"Borrower detail error: " + JsonEscape(ex.Message) + "\"}");
            }
        }

        public bool IsReusable => false;
    }
}
