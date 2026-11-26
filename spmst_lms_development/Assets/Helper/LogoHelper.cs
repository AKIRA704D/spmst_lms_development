using System;
using System.Collections.Generic;
using System.Configuration;
using System.Web;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Assets.Helper
{
    /// <summary>
    /// COMPATIBILITY SHIM. New code must use <see cref="BrandingService"/>.
    /// Kept so existing callers (LandingData.ashx, DashboardData.ashx, LibrarySettingsData.ashx)
    /// keep compiling; every method now delegates to the centralized service.
    /// </summary>
    public static class LogoHelper
    {
        // Corrected: these now point at files that actually exist in Assets/Logo.
        public const string DefaultSchoolLogo    = BrandingService.DefaultSchool;
        public const string DefaultLibraryLogo   = BrandingService.DefaultLibrary;
        public const string DefaultInstituteLogo = BrandingService.DefaultSystem;

        /// <summary>Returns an app-relative path (no leading slash) for "School" | "Library" | "System".</summary>
        public static string GetHeaderLogo(string entityType)
        {
            return StripToRelative(UrlFor(entityType));
        }

        public static string GetVerifiedLogo(string entityType)
        {
            return GetHeaderLogo(entityType); // BrandingService already verifies the file on disk
        }

        public static void InvalidateCache(string entityType) { BrandingService.Invalidate(); }

        private static string UrlFor(string entityType)
        {
            switch ((entityType ?? string.Empty).ToLowerInvariant())
            {
                case "library":
                case "department": return BrandingService.LibraryUrl;
                case "system":
                case "institute":
                case "other":      return BrandingService.SystemUrl;
                default:           return BrandingService.SchoolUrl;
            }
        }

        private static string StripToRelative(string url)
        {
            if (string.IsNullOrEmpty(url)) return string.Empty;
            int q = url.IndexOf('?'); if (q >= 0) url = url.Substring(0, q);
            string app = HttpRuntime.AppDomainAppVirtualPath ?? "/";
            if (app != "/" && url.StartsWith(app, StringComparison.OrdinalIgnoreCase)) url = url.Substring(app.Length);
            return url.TrimStart('/');
        }

        /// <summary>Legacy list used by the landing page JSON. Reads the new table, same shape as before.</summary>
        public static List<OrganizationLogo> GetActiveLogos(string entityType = null)
        {
            var list = new List<OrganizationLogo>();
            try
            {
                var cs = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
                using (var conn = new MySqlConnection(cs))
                {
                    conn.Open();
                    using (var cmd = new MySqlCommand(
                        @"SELECT logo_id, logo_category, logo_name, logo_path, is_active, is_default, created_at, updated_at
                          FROM branding_logos WHERE is_active = 1 ORDER BY is_default DESC, logo_id", conn))
                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            string cat = Convert.ToString(r["logo_category"]);
                            string legacy = cat == "Department" ? "Library" : cat == "System" ? "Other" : cat;
                            if (!string.IsNullOrWhiteSpace(entityType) &&
                                !string.Equals(legacy, entityType, StringComparison.OrdinalIgnoreCase)) continue;
                            list.Add(new OrganizationLogo
                            {
                                LogoId = Convert.ToInt32(r["logo_id"]),
                                EntityType = legacy,
                                EntityName = Convert.ToString(r["logo_name"]),
                                LogoPath = Convert.ToString(r["logo_path"]),
                                IsActive = true,
                                SortOrder = Convert.ToInt32(r["is_default"]) == 1 ? 0 : 1,
                                CreatedAt = r["created_at"] == DBNull.Value ? DateTime.MinValue : Convert.ToDateTime(r["created_at"]),
                                UpdatedAt = r["updated_at"] == DBNull.Value ? DateTime.MinValue : Convert.ToDateTime(r["updated_at"])
                            });
                        }
                    }
                }
            }
            catch { }
            return list;
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
