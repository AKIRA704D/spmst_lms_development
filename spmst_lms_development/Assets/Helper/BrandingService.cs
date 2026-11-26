using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Assets.Helper
{
    /// <summary>
    /// SINGLE source of truth for every logo shown in the LMS.
    /// All pages call this class; nothing else queries branding_logos or builds logo URLs.
    ///
    /// Design:
    ///  * One query loads every active logo into an immutable snapshot cached in HttpRuntime.Cache.
    ///  * Every write path calls Invalidate(); the next request reloads the snapshot.
    ///  * Every returned URL is app-absolute (VirtualPathUtility.ToAbsolute), so it works from
    ///    any folder depth, and carries ?v=&lt;version&gt; so browsers refetch after a replace.
    ///  * Nothing is stored in page fields, so postbacks / validation errors cannot lose logos.
    ///  * A missing or empty file falls back along the documented chain, ending at the bundled
    ///    default PNGs in Assets/Logo. Book icons are never used.
    /// </summary>
    public static class BrandingService
    {
        // Bundled files that ship with the app (final fallback only).
        public const string DefaultSchool  = "Assets/Logo/spamast_logo.png";
        public const string DefaultLibrary = "Assets/Logo/spamast_library_logo.png";
        public const string DefaultSystem  = "Assets/Logo/spamast_lmsa_logo.png";
        public const string DefaultAvatar  = "Assets/Logo/spamast_logo.png"; // used only when even the School logo is unusable

        private const string CacheKey = "lmsa_branding_snapshot_v2";
        private const int CacheMinutes = 30; // safety net only; writes invalidate immediately

        // ------------------------------------------------------------------ model
        public sealed class LogoEntry
        {
            public int LogoId;
            public string Category;      // School | Department | System | Institute | Program
            public string Name;
            public string Path;          // app-relative
            public int? DepartmentId, InstituteId, ProgramId;
            public bool IsDefault;
            public int Version;
        }

        private sealed class Snapshot
        {
            public LogoEntry School, System;
            public LogoEntry DefaultDepartment;
            public List<LogoEntry> Departments = new List<LogoEntry>();
            public Dictionary<int, LogoEntry> ByDepartment = new Dictionary<int, LogoEntry>();
            public Dictionary<int, LogoEntry> ByInstitute  = new Dictionary<int, LogoEntry>();
            public Dictionary<int, LogoEntry> ByProgram    = new Dictionary<int, LogoEntry>();
        }

        // ------------------------------------------------------------------ page-level API
        /// <summary>School logo URL (never null).</summary>
        public static string SchoolUrl  { get { return Url(Snap().School, DefaultSchool); } }
        /// <summary>System (LMSA) logo URL (never null).</summary>
        public static string SystemUrl  { get { return Url(Snap().System, DefaultSystem); } }
        /// <summary>School Library logo = the default Department logo (never null).</summary>
        public static string LibraryUrl { get { return Url(Snap().DefaultDepartment, DefaultLibrary); } }

        /// <summary>All active department logos, default (School Library) first. For the landing page group.</summary>
        public static IList<LogoEntry> DepartmentLogos()
        {
            return Snap().Departments.Where(d => IsUsable(d.Path)).ToList();
        }

        public static string DepartmentUrl(int? departmentId)
        {
            return departmentId.HasValue ? UrlOrNull(Get(Snap().ByDepartment, departmentId.Value)) : null;
        }
        public static string InstituteUrl(int? instituteId)
        {
            return instituteId.HasValue ? UrlOrNull(Get(Snap().ByInstitute, instituteId.Value)) : null;
        }
        public static string ProgramUrl(int? programId)
        {
            return programId.HasValue ? UrlOrNull(Get(Snap().ByProgram, programId.Value)) : null;
        }

        /// <summary>Institute logo for dashboards: the institute's logo, else the School logo.</summary>
        public static string InstituteUrlOrSchool(int? instituteId)
        {
            return InstituteUrl(instituteId) ?? SchoolUrl;
        }

        /// <summary>
        /// Borrower picture with the mandated priority:
        ///  1 uploaded profile picture  2 org logo for the borrower type  3 School logo  4 generic avatar.
        /// Student -> Program, then Institute.  Faculty -> Institute.  Staff -> Department.
        /// The System logo is never used.  IDs must be the borrower's real ProgramID / InstituteID / DepartmentID.
        /// </summary>
        public static string BorrowerImageUrl(string role, string profilePath,
                                              int? programId, int? instituteId, int? departmentId)
        {
            string own = ProfileHelper.ResolveProfileImage(profilePath);
            if (!string.IsNullOrEmpty(own)) return own;

            string org = null;
            switch ((role ?? string.Empty).Trim().ToLowerInvariant())
            {
                case "student": org = ProgramUrl(programId) ?? InstituteUrl(instituteId); break;
                case "faculty": org = InstituteUrl(instituteId); break;
                case "staff":   org = DepartmentUrl(departmentId); break;
            }
            if (!string.IsNullOrEmpty(org)) return org;

            var school = Snap().School;
            if (school != null && IsUsable(school.Path)) return Url(school, DefaultSchool);
            return AbsoluteUrl(DefaultAvatar);
        }

        /// <summary>
        /// Attribute string for &lt;img&gt;: one-shot error handler. If the file 404s, swap ONCE to the
        /// fallback. onerror is cleared first, so a missing fallback can never loop.
        /// </summary>
        public static string OnErrorAttr(string fallbackUrl)
        {
            string safe = (fallbackUrl ?? string.Empty).Replace("\\", "\\\\").Replace("'", "\\'");
            return "onerror=\"this.onerror=null;this.src='" + HttpUtility.HtmlAttributeEncode(safe) + "';\"";
        }

        /// <summary>Convenience: a complete, standard &lt;img&gt; tag (class lmsa-brand-img + safe fallback).</summary>
        public static string Img(string url, string alt, string cssClass, string fallbackUrl)
        {
            return "<img src=\"" + HttpUtility.HtmlAttributeEncode(url) + "\" alt=\"" +
                   HttpUtility.HtmlAttributeEncode(alt) + "\" class=\"lmsa-brand-img " +
                   HttpUtility.HtmlAttributeEncode(cssClass ?? string.Empty) + "\" decoding=\"async\" " +
                   OnErrorAttr(fallbackUrl) + " />";
        }

        // ------------------------------------------------------------------ ready-made tags (what pages use)
        /// <summary>School logo &lt;img&gt; with safe one-shot fallback to the bundled default.</summary>
        public static string SchoolImg(string cssClass)  { return Img(SchoolUrl,  "School logo",         cssClass, AbsoluteUrl(DefaultSchool)); }
        /// <summary>School Library (default department) logo &lt;img&gt;.</summary>
        public static string LibraryImg(string cssClass) { return Img(LibraryUrl, "School Library logo", cssClass, AbsoluteUrl(DefaultLibrary)); }
        /// <summary>System (LMSA) logo &lt;img&gt;.</summary>
        public static string SystemImg(string cssClass)  { return Img(SystemUrl,  "LMSA system logo",    cssClass, AbsoluteUrl(DefaultSystem)); }

        // ------------------------------------------------------------------ cache control
        /// <summary>Call after ANY add / replace / edit / activate / deactivate / delete of a logo or its entity.</summary>
        public static void Invalidate()
        {
            HttpRuntime.Cache.Remove(CacheKey);
        }

        // ------------------------------------------------------------------ internals
        private static LogoEntry Get(Dictionary<int, LogoEntry> d, int id)
        {
            LogoEntry e; return d.TryGetValue(id, out e) ? e : null;
        }

        private static string UrlOrNull(LogoEntry e)
        {
            return (e != null && IsUsable(e.Path)) ? Url(e, null) : null;
        }

        private static string Url(LogoEntry e, string defaultRelative)
        {
            if (e != null && IsUsable(e.Path)) return AbsoluteUrl(e.Path) + "?v=" + e.Version;
            return AbsoluteUrl(defaultRelative);
        }

        private static string AbsoluteUrl(string relative)
        {
            if (string.IsNullOrEmpty(relative)) return null;
            string p = relative.Trim().Replace('\\', '/');
            if (p.StartsWith("~/")) p = p.Substring(2);
            p = p.TrimStart('/');
            return VirtualPathUtility.ToAbsolute("~/" + p);
        }

        /// <summary>The file must exist, be non-empty and live inside the web root (no traversal).</summary>
        public static bool IsUsable(string relative)
        {
            if (string.IsNullOrWhiteSpace(relative)) return false;
            string p = relative.Trim().Replace('\\', '/').TrimStart('~', '/');
            if (p.Contains("..")) return false;
            try
            {
                string root = Path.GetFullPath(HostingEnvironment.MapPath("~/"));
                string full = Path.GetFullPath(HostingEnvironment.MapPath("~/" + p));
                if (!full.StartsWith(root, StringComparison.OrdinalIgnoreCase)) return false;
                var fi = new FileInfo(full);
                return fi.Exists && fi.Length > 0;
            }
            catch { return false; }
        }

        private static Snapshot Snap()
        {
            var cached = HttpRuntime.Cache[CacheKey] as Snapshot;
            if (cached != null) return cached;

            var s = new Snapshot();
            try
            {
                var cs = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
                using (var conn = new MySqlConnection(cs))
                {
                    conn.Open();
                    using (var cmd = new MySqlCommand(
                        @"SELECT logo_id, logo_category, logo_name, logo_path,
                                 department_id, institute_id, program_id, is_default, version
                          FROM branding_logos
                          WHERE is_active = 1
                          ORDER BY is_default DESC, logo_name ASC, logo_id ASC", conn))
                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            var e = new LogoEntry
                            {
                                LogoId = Convert.ToInt32(r["logo_id"]),
                                Category = Convert.ToString(r["logo_category"]),
                                Name = Convert.ToString(r["logo_name"]),
                                Path = Convert.ToString(r["logo_path"]),
                                DepartmentId = r["department_id"] == DBNull.Value ? (int?)null : Convert.ToInt32(r["department_id"]),
                                InstituteId = r["institute_id"] == DBNull.Value ? (int?)null : Convert.ToInt32(r["institute_id"]),
                                ProgramId = r["program_id"] == DBNull.Value ? (int?)null : Convert.ToInt32(r["program_id"]),
                                IsDefault = Convert.ToInt32(r["is_default"]) == 1,
                                Version = Convert.ToInt32(r["version"])
                            };
                            switch (e.Category)
                            {
                                case "School": if (s.School == null) s.School = e; break;
                                case "System": if (s.System == null) s.System = e; break;
                                case "Department":
                                    s.Departments.Add(e);
                                    if (e.IsDefault && s.DefaultDepartment == null) s.DefaultDepartment = e;
                                    if (e.DepartmentId.HasValue) s.ByDepartment[e.DepartmentId.Value] = e;
                                    break;
                                case "Institute": if (e.InstituteId.HasValue) s.ByInstitute[e.InstituteId.Value] = e; break;
                                case "Program":   if (e.ProgramId.HasValue)   s.ByProgram[e.ProgramId.Value] = e; break;
                            }
                        }
                    }
                }
                if (s.DefaultDepartment == null && s.Departments.Count > 0) s.DefaultDepartment = s.Departments[0];
            }
            catch
            {
                // DB unreachable / table not migrated yet: serve bundled defaults and do NOT cache,
                // so the next request retries instead of pinning defaults for 30 minutes.
                return s;
            }

            HttpRuntime.Cache.Insert(CacheKey, s, null, DateTime.UtcNow.AddMinutes(CacheMinutes), Cache.NoSlidingExpiration);
            return s;
        }
    }
}
