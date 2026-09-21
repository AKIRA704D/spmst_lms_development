using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Users.Admin.Settings
{
    /// <summary>
    /// Admin-only CRUD endpoint backing the Library Settings page
    /// (Users/Admin/Settings/LibrarySettings.aspx). Manages the four
    /// admin-editable content sources used by the public landing page:
    /// library_contact_info, library_about_us, library_services, library_terms.
    ///
    /// Every action — including the "get" reads — re-verifies the caller is
    /// an authenticated admin via sessionHelper before touching the database,
    /// so this handler cannot be used to bypass the page-level gate.
    ///
    /// GET  ?action=getcontact
    /// GET  ?action=getabout
    /// GET  ?action=listservices
    /// GET  ?action=listterms
    /// POST ?action=savecontact      (form: address, phone, email, hoursWeekdays, hoursSaturday, hoursSunday, facebookUrl, mapEmbedUrl)
    /// POST ?action=saveabout        (form: heading, body, stat1Label, stat1Value, stat2Label, stat2Value, stat3Label, stat3Value)
    /// POST ?action=saveservice      (form: serviceId [blank = new], iconClass, title, description, sortOrder, isActive)
    /// POST ?action=deleteservice    (form: serviceId)
    /// POST ?action=uploadterms      (multipart: file, title, versionLabel, isActive)
    /// POST ?action=setactiveterms   (form: termsId)
    /// POST ?action=deleteterms      (form: termsId)
    /// </summary>
    public class LibrarySettingsData : IHttpHandler
    {
        public bool IsReusable { get { return false; } }

        private static readonly string[] TermsAllowedExtensions = { ".pdf" };

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);

            string action = (context.Request.QueryString["action"] ?? "").Trim().ToLowerInvariant();

            if (!IsCallerAdmin())
            {
                WriteJson(context, new { success = false, message = "You must be signed in as an administrator to do this." });
                return;
            }

            try
            {
                object result;

                switch (action)
                {
                    case "getcontact":
                        result = GetContact();
                        break;
                    case "getabout":
                        result = GetAbout();
                        break;
                    case "listservices":
                        result = ListServices();
                        break;
                    case "listterms":
                        result = ListTerms();
                        break;
                    case "savecontact":
                        result = SaveContact(context);
                        break;
                    case "saveabout":
                        result = SaveAbout(context);
                        break;
                    case "saveservice":
                        result = SaveService(context);
                        break;
                    case "deleteservice":
                        result = DeleteService(context);
                        break;
                    case "uploadterms":
                        result = UploadTerms(context);
                        break;
                    case "setactiveterms":
                        result = SetActiveTerms(context);
                        break;
                    case "deleteterms":
                        result = DeleteTerms(context);
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
        // CONTACT INFO (single row)
        // ==========================================================================

        private object GetContact()
        {
            const string sql = @"SELECT contact_id, address, phone, email, hours_weekdays, hours_saturday, hours_sunday, facebook_url, map_embed_url, updated_at
                                  FROM library_contact_info ORDER BY contact_id DESC LIMIT 1";
            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(sql, conn))
            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                {
                    return new
                    {
                        contactId = ReadInt(reader, "contact_id"),
                        address = ReadString(reader, "address"),
                        phone = ReadString(reader, "phone"),
                        email = ReadString(reader, "email"),
                        hoursWeekdays = ReadString(reader, "hours_weekdays"),
                        hoursSaturday = ReadString(reader, "hours_saturday"),
                        hoursSunday = ReadString(reader, "hours_sunday"),
                        facebookUrl = ReadString(reader, "facebook_url"),
                        mapEmbedUrl = ReadString(reader, "map_embed_url"),
                        updatedAt = ReadDate(reader, "updated_at")
                    };
                }
            }
            return null;
        }

        private object SaveContact(HttpContext context)
        {
            var f = context.Request.Form;
            string adminId = CurrentUserId();

            int? existingId = GetSingleRowId("library_contact_info", "contact_id");

            using (var conn = OpenConnection())
            {
                MySqlCommand cmd;
                if (existingId.HasValue)
                {
                    cmd = new MySqlCommand(@"UPDATE library_contact_info SET
                        address=@address, phone=@phone, email=@email,
                        hours_weekdays=@hw, hours_saturday=@hs, hours_sunday=@hsu,
                        facebook_url=@fb, map_embed_url=@map, updated_by=@by
                        WHERE contact_id=@id", conn);
                    cmd.Parameters.AddWithValue("@id", existingId.Value);
                }
                else
                {
                    cmd = new MySqlCommand(@"INSERT INTO library_contact_info
                        (address, phone, email, hours_weekdays, hours_saturday, hours_sunday, facebook_url, map_embed_url, updated_by)
                        VALUES (@address, @phone, @email, @hw, @hs, @hsu, @fb, @map, @by)", conn);
                }

                cmd.Parameters.AddWithValue("@address", f["address"] ?? "");
                cmd.Parameters.AddWithValue("@phone", f["phone"] ?? "");
                cmd.Parameters.AddWithValue("@email", f["email"] ?? "");
                cmd.Parameters.AddWithValue("@hw", f["hoursWeekdays"] ?? "");
                cmd.Parameters.AddWithValue("@hs", f["hoursSaturday"] ?? "");
                cmd.Parameters.AddWithValue("@hsu", f["hoursSunday"] ?? "");
                cmd.Parameters.AddWithValue("@fb", f["facebookUrl"] ?? "");
                cmd.Parameters.AddWithValue("@map", f["mapEmbedUrl"] ?? "");
                cmd.Parameters.AddWithValue("@by", (object)adminId ?? DBNull.Value);

                using (cmd) cmd.ExecuteNonQuery();
            }

            return GetContact();
        }

        // ==========================================================================
        // ABOUT US (single row)
        // ==========================================================================

        private object GetAbout()
        {
            const string sql = @"SELECT about_id, heading, body, stat1_label, stat1_value, stat2_label, stat2_value, stat3_label, stat3_value, updated_at
                                  FROM library_about_us ORDER BY about_id DESC LIMIT 1";
            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(sql, conn))
            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                {
                    return new
                    {
                        aboutId = ReadInt(reader, "about_id"),
                        heading = ReadString(reader, "heading"),
                        body = ReadString(reader, "body"),
                        stat1Label = ReadString(reader, "stat1_label"),
                        stat1Value = ReadString(reader, "stat1_value"),
                        stat2Label = ReadString(reader, "stat2_label"),
                        stat2Value = ReadString(reader, "stat2_value"),
                        stat3Label = ReadString(reader, "stat3_label"),
                        stat3Value = ReadString(reader, "stat3_value"),
                        updatedAt = ReadDate(reader, "updated_at")
                    };
                }
            }
            return null;
        }

        private object SaveAbout(HttpContext context)
        {
            var f = context.Request.Form;
            string adminId = CurrentUserId();

            int? existingId = GetSingleRowId("library_about_us", "about_id");

            using (var conn = OpenConnection())
            {
                MySqlCommand cmd;
                if (existingId.HasValue)
                {
                    cmd = new MySqlCommand(@"UPDATE library_about_us SET
                        heading=@heading, body=@body,
                        stat1_label=@s1l, stat1_value=@s1v,
                        stat2_label=@s2l, stat2_value=@s2v,
                        stat3_label=@s3l, stat3_value=@s3v,
                        updated_by=@by
                        WHERE about_id=@id", conn);
                    cmd.Parameters.AddWithValue("@id", existingId.Value);
                }
                else
                {
                    cmd = new MySqlCommand(@"INSERT INTO library_about_us
                        (heading, body, stat1_label, stat1_value, stat2_label, stat2_value, stat3_label, stat3_value, updated_by)
                        VALUES (@heading, @body, @s1l, @s1v, @s2l, @s2v, @s3l, @s3v, @by)", conn);
                }

                cmd.Parameters.AddWithValue("@heading", f["heading"] ?? "");
                cmd.Parameters.AddWithValue("@body", f["body"] ?? "");
                cmd.Parameters.AddWithValue("@s1l", f["stat1Label"] ?? "");
                cmd.Parameters.AddWithValue("@s1v", f["stat1Value"] ?? "");
                cmd.Parameters.AddWithValue("@s2l", f["stat2Label"] ?? "");
                cmd.Parameters.AddWithValue("@s2v", f["stat2Value"] ?? "");
                cmd.Parameters.AddWithValue("@s3l", f["stat3Label"] ?? "");
                cmd.Parameters.AddWithValue("@s3v", f["stat3Value"] ?? "");
                cmd.Parameters.AddWithValue("@by", (object)adminId ?? DBNull.Value);

                using (cmd) cmd.ExecuteNonQuery();
            }

            return GetAbout();
        }

        // ==========================================================================
        // SERVICES (multi-row)
        // ==========================================================================

        private object ListServices()
        {
            const string sql = @"SELECT service_id, icon_class, title, description, sort_order, is_active
                                  FROM library_services ORDER BY sort_order ASC, service_id ASC";
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
                        description = ReadString(reader, "description"),
                        sortOrder = ReadInt(reader, "sort_order"),
                        isActive = ReadBool(reader, "is_active")
                    });
                }
            }
            return list;
        }

        private object SaveService(HttpContext context)
        {
            var f = context.Request.Form;
            int serviceId;
            bool isUpdate = int.TryParse(f["serviceId"], out serviceId) && serviceId > 0;
            bool isActive = string.Equals(f["isActive"], "true", StringComparison.OrdinalIgnoreCase) || f["isActive"] == "on" || f["isActive"] == "1";
            int sortOrder;
            if (!int.TryParse(f["sortOrder"], out sortOrder)) sortOrder = 0;

            string title = (f["title"] ?? "").Trim();
            if (string.IsNullOrEmpty(title))
            {
                throw new ArgumentException("Service title is required.");
            }

            using (var conn = OpenConnection())
            {
                MySqlCommand cmd;
                if (isUpdate)
                {
                    cmd = new MySqlCommand(@"UPDATE library_services SET
                        icon_class=@icon, title=@title, description=@desc, sort_order=@sort, is_active=@active
                        WHERE service_id=@id", conn);
                    cmd.Parameters.AddWithValue("@id", serviceId);
                }
                else
                {
                    cmd = new MySqlCommand(@"INSERT INTO library_services
                        (icon_class, title, description, sort_order, is_active)
                        VALUES (@icon, @title, @desc, @sort, @active)", conn);
                }

                cmd.Parameters.AddWithValue("@icon", string.IsNullOrWhiteSpace(f["iconClass"]) ? "fa-book" : f["iconClass"].Trim());
                cmd.Parameters.AddWithValue("@title", title);
                cmd.Parameters.AddWithValue("@desc", f["description"] ?? "");
                cmd.Parameters.AddWithValue("@sort", sortOrder);
                cmd.Parameters.AddWithValue("@active", isActive ? 1 : 0);

                using (cmd) cmd.ExecuteNonQuery();
            }

            return ListServices();
        }

        private object DeleteService(HttpContext context)
        {
            int serviceId;
            if (!int.TryParse(context.Request.Form["serviceId"], out serviceId))
            {
                throw new ArgumentException("A valid serviceId is required.");
            }

            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand("DELETE FROM library_services WHERE service_id=@id", conn))
            {
                cmd.Parameters.AddWithValue("@id", serviceId);
                cmd.ExecuteNonQuery();
            }

            return ListServices();
        }

        // ==========================================================================
        // TERMS & CONDITIONS (PDF uploads)
        // ==========================================================================

        private object ListTerms()
        {
            const string sql = @"SELECT terms_id, title, version_label, file_path, is_active, uploaded_at
                                  FROM library_terms ORDER BY uploaded_at DESC";
            var list = new List<object>();
            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand(sql, conn))
            using (var reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    list.Add(new
                    {
                        termsId = ReadInt(reader, "terms_id"),
                        title = ReadString(reader, "title"),
                        versionLabel = ReadString(reader, "version_label"),
                        filePath = ReadString(reader, "file_path").Replace('\\', '/'),
                        isActive = ReadBool(reader, "is_active"),
                        uploadedAt = ReadDate(reader, "uploaded_at")
                    });
                }
            }
            return list;
        }

        private object UploadTerms(HttpContext context)
        {
            if (context.Request.Files.Count == 0)
            {
                throw new ArgumentException("No file was uploaded.");
            }

            HttpPostedFile file = context.Request.Files["file"] ?? context.Request.Files[0];
            if (file == null || file.ContentLength <= 0)
            {
                throw new ArgumentException("The uploaded file is empty.");
            }

            string ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            bool extOk = false;
            foreach (var allowed in TermsAllowedExtensions) if (ext == allowed) extOk = true;
            if (!extOk)
            {
                throw new ArgumentException("Only PDF files are allowed for Terms & Conditions.");
            }

            string title = context.Request.Form["title"];
            if (string.IsNullOrWhiteSpace(title)) title = Path.GetFileNameWithoutExtension(file.FileName);
            string versionLabel = context.Request.Form["versionLabel"] ?? "";
            bool setActive = string.Equals(context.Request.Form["isActive"], "true", StringComparison.OrdinalIgnoreCase)
                              || context.Request.Form["isActive"] == "on" || context.Request.Form["isActive"] == "1";

            string folderPhysical = context.Server.MapPath("~/Assets/Terms/");
            if (!Directory.Exists(folderPhysical)) Directory.CreateDirectory(folderPhysical);

            string safeName = SanitizeFileName(Path.GetFileNameWithoutExtension(file.FileName));
            string storedFileName = DateTime.Now.ToString("yyyyMMddHHmmss") + "_" + safeName + ".pdf";
            string physicalPath = Path.Combine(folderPhysical, storedFileName);
            file.SaveAs(physicalPath);

            string relativePath = "Assets/Terms/" + storedFileName;

            using (var conn = OpenConnection())
            {
                if (setActive)
                {
                    using (var deact = new MySqlCommand("UPDATE library_terms SET is_active = 0", conn))
                        deact.ExecuteNonQuery();
                }

                using (var cmd = new MySqlCommand(@"INSERT INTO library_terms
                    (title, version_label, file_path, is_active, uploaded_by)
                    VALUES (@title, @ver, @path, @active, @by)", conn))
                {
                    cmd.Parameters.AddWithValue("@title", title.Trim());
                    cmd.Parameters.AddWithValue("@ver", versionLabel.Trim());
                    cmd.Parameters.AddWithValue("@path", relativePath);
                    cmd.Parameters.AddWithValue("@active", setActive ? 1 : 0);
                    cmd.Parameters.AddWithValue("@by", (object)CurrentUserId() ?? DBNull.Value);
                    cmd.ExecuteNonQuery();
                }
            }

            return ListTerms();
        }

        private object SetActiveTerms(HttpContext context)
        {
            int termsId;
            if (!int.TryParse(context.Request.Form["termsId"], out termsId))
            {
                throw new ArgumentException("A valid termsId is required.");
            }

            using (var conn = OpenConnection())
            {
                using (var deact = new MySqlCommand("UPDATE library_terms SET is_active = 0", conn))
                    deact.ExecuteNonQuery();

                using (var act = new MySqlCommand("UPDATE library_terms SET is_active = 1 WHERE terms_id = @id", conn))
                {
                    act.Parameters.AddWithValue("@id", termsId);
                    act.ExecuteNonQuery();
                }
            }

            return ListTerms();
        }

        private object DeleteTerms(HttpContext context)
        {
            int termsId;
            if (!int.TryParse(context.Request.Form["termsId"], out termsId))
            {
                throw new ArgumentException("A valid termsId is required.");
            }

            string filePath = null;
            using (var conn = OpenConnection())
            {
                using (var sel = new MySqlCommand("SELECT file_path FROM library_terms WHERE terms_id=@id", conn))
                {
                    sel.Parameters.AddWithValue("@id", termsId);
                    var result = sel.ExecuteScalar();
                    if (result != null) filePath = result.ToString();
                }

                using (var del = new MySqlCommand("DELETE FROM library_terms WHERE terms_id=@id", conn))
                {
                    del.Parameters.AddWithValue("@id", termsId);
                    del.ExecuteNonQuery();
                }
            }

            if (!string.IsNullOrWhiteSpace(filePath))
            {
                try
                {
                    string physical = context.Server.MapPath("~/" + filePath.TrimStart('/'));
                    if (File.Exists(physical)) File.Delete(physical);
                }
                catch
                {
                    // Best-effort cleanup — the DB row is already gone even if the
                    // physical file couldn't be removed (e.g. locked/permissions).
                }
            }

            return ListTerms();
        }

        // ==========================================================================
        // HELPERS
        // ==========================================================================

        /// <summary>
        /// Confirms the current session belongs to a signed-in admin. Mirrors the
        /// role check already used in admin.Master
        /// (currentRole.Equals("admin", StringComparison.OrdinalIgnoreCase)).
        /// </summary>
        private static bool IsCallerAdmin()
        {
            try
            {
                string userId = spmst_lms_development.sessionHelper.UserID;
                if (string.IsNullOrEmpty(userId)) return false;

                string role = spmst_lms_development.sessionHelper.GetRoleDisplayName() ?? "";
                return role.Equals("admin", StringComparison.OrdinalIgnoreCase);
            }
            catch
            {
                return false;
            }
        }

        private static string CurrentUserId()
        {
            try { return spmst_lms_development.sessionHelper.UserID; }
            catch { return null; }
        }

        private static int? GetSingleRowId(string table, string idColumn)
        {
            using (var conn = OpenConnection())
            using (var cmd = new MySqlCommand("SELECT " + idColumn + " FROM " + table + " ORDER BY " + idColumn + " DESC LIMIT 1", conn))
            {
                var result = cmd.ExecuteScalar();
                return result == null ? (int?)null : Convert.ToInt32(result);
            }
        }

        private static string SanitizeFileName(string name)
        {
            foreach (char c in Path.GetInvalidFileNameChars()) name = name.Replace(c, '_');
            name = name.Replace(' ', '-');
            return name.Length > 60 ? name.Substring(0, 60) : name;
        }

        private static MySqlConnection OpenConnection()
        {
            var connStringSetting = ConfigurationManager.ConnectionStrings["LmsDb"];
            if (connStringSetting == null)
            {
                throw new ConfigurationErrorsException("No connection string named 'LmsDb' was found in Web.config.");
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

        private static bool ReadBool(System.Data.Common.DbDataReader reader, string col)
        {
            int idx = reader.GetOrdinal(col);
            return !reader.IsDBNull(idx) && Convert.ToInt32(reader.GetValue(idx)) == 1;
        }

        private static string ReadDate(System.Data.Common.DbDataReader reader, string col)
        {
            int idx = reader.GetOrdinal(col);
            return reader.IsDBNull(idx) ? "" : Convert.ToDateTime(reader.GetValue(idx)).ToString("MMMM d, yyyy 'at' h:mm tt");
        }

        private static void WriteJson(HttpContext context, object payload)
        {
            var serializer = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
            context.Response.Write(serializer.Serialize(payload));
        }
    }
}
