using System;
using System.Collections.Generic;
using System.Configuration;
using System.Web;
using System.Web.Caching;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Assets.Helper
{
    public static class LogoHelper
    {
        // Corrected default filenames to match the physical files in the project
        public const string DefaultSchoolLogo = "Assets/Logo/spmst_logo_wbg.png";
        public const string DefaultLibraryLogo = "Assets/Logo/lib_logo_wbg.png";
        public const string DefaultInstituteLogo = "Assets/Logo/lmsa_logo.png";

        private const int CacheMinutes = 10;

        public static string GetHeaderLogo(string entityType)
        {
            if (string.IsNullOrWhiteSpace(entityType)) return DefaultSchoolLogo;

            string cacheKey = "lmsa_logo_" + entityType;
            var cached = HttpRuntime.Cache[cacheKey] as string;
            if (!string.IsNullOrEmpty(cached)) return cached;

            string path = null;
            try
            {
                using (var conn = new MySqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    using (var cmd = new MySqlCommand(
                        @"SELECT logo_path FROM organization_logos
                          WHERE entity_type = @type AND is_active = 1
                          ORDER BY sort_order ASC, logo_id ASC
                          LIMIT 1", conn))
                    {
                        cmd.Parameters.AddWithValue("@type", entityType);
                        var result = cmd.ExecuteScalar();
                        if (result != null && result != DBNull.Value)
                        {
                            string candidate = result.ToString();
                            if (!string.IsNullOrWhiteSpace(candidate)) path = candidate;
                        }
                    }
                }
            }
            catch
            {
                // Fallback
            }

            if (string.IsNullOrWhiteSpace(path))
            {
                path = FallbackForEntity(entityType);
            }

            HttpRuntime.Cache.Insert(
                cacheKey,
                path,
                null,
                DateTime.UtcNow.AddMinutes(CacheMinutes),
                Cache.NoSlidingExpiration);

            return path;
        }

        /// <summary>
        /// Same lookup as <see cref="GetHeaderLogo"/> (database logo first), but the file is
        /// verified to exist and be non-empty on disk. If the database logo is missing,
        /// empty or corrupt, the built-in default for that entity is returned instead, so
        /// callers never receive a path that would render as a broken image.
        /// Returns an app-relative path without a leading "~" or "/" (e.g. "Assets/Logo/x.png").
        /// </summary>
        public static string GetVerifiedLogo(string entityType)
        {
            string candidate = NormalizeRelative(GetHeaderLogo(entityType));
            if (IsUsableAsset(candidate)) return candidate;

            string fallback = NormalizeRelative(FallbackForEntity(entityType));
            return fallback;
        }

        private static string NormalizeRelative(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) return string.Empty;
            string p = path.Trim().Replace('\\', '/');
            if (p.StartsWith("~/")) p = p.Substring(2);
            else if (p.StartsWith("~")) p = p.Substring(1);
            return p.TrimStart('/');
        }

        private static bool IsUsableAsset(string relativePath)
        {
            if (string.IsNullOrWhiteSpace(relativePath) || relativePath.Contains("..")) return false;
            try
            {
                string physical = System.Web.Hosting.HostingEnvironment.MapPath("~/" + relativePath);
                if (string.IsNullOrEmpty(physical) || !System.IO.File.Exists(physical)) return false;
                return new System.IO.FileInfo(physical).Length > 0;
            }
            catch { return false; }
        }

        public static List<OrganizationLogo> GetActiveLogos(string entityType = null)
        {
            var list = new List<OrganizationLogo>();
            try
            {
                using (var conn = new MySqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    string sql = @"SELECT logo_id, entity_type, entity_name, logo_path,
                                          is_active, sort_order, created_at, updated_at
                                   FROM organization_logos
                                   WHERE is_active = 1";
                    if (!string.IsNullOrWhiteSpace(entityType))
                        sql += " AND entity_type = @type";
                    sql += " ORDER BY sort_order ASC, logo_id ASC";

                    using (var cmd = new MySqlCommand(sql, conn))
                    {
                        if (!string.IsNullOrWhiteSpace(entityType))
                            cmd.Parameters.AddWithValue("@type", entityType);

                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                list.Add(new OrganizationLogo
                                {
                                    LogoId = Convert.ToInt32(reader["logo_id"]),
                                    EntityType = reader["entity_type"].ToString(),
                                    EntityName = reader["entity_name"].ToString(),
                                    LogoPath = reader["logo_path"].ToString(),
                                    IsActive = Convert.ToBoolean(reader["is_active"]),
                                    SortOrder = Convert.ToInt32(reader["sort_order"]),
                                    CreatedAt = Convert.ToDateTime(reader["created_at"]),
                                    UpdatedAt = Convert.ToDateTime(reader["updated_at"])
                                });
                            }
                        }
                    }
                }
            }
            catch { }
            return list;
        }

        public static void InvalidateCache(string entityType)
        {
            if (string.IsNullOrWhiteSpace(entityType))
            {
                foreach (var t in new[] { "School", "Library", "Institute", "Department", "Other" })
                {
                    HttpRuntime.Cache.Remove("lmsa_logo_" + t);
                }
            }
            else
            {
                HttpRuntime.Cache.Remove("lmsa_logo_" + entityType);
            }
        }

        private static string FallbackForEntity(string entityType)
        {
            switch ((entityType ?? string.Empty).ToLowerInvariant())
            {
                case "library": return DefaultLibraryLogo;
                case "school": return DefaultSchoolLogo;
                default: return DefaultInstituteLogo;
            }
        }

        private static string GetConnectionString()
        {
            var setting = ConfigurationManager.ConnectionStrings["LmsDb"];
            if (setting == null)
                throw new ConfigurationErrorsException("No connection string named 'LmsDb' was found in Web.config.");
            return setting.ConnectionString;
        }
    }

    public class OrganizationLogo
    {
        public int LogoId { get; set; }
        public string EntityType { get; set; }
        public string EntityName { get; set; }
        public string LogoPath { get; set; }
        public bool IsActive { get; set; }
        public int SortOrder { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}