using System;
using System.Web;

namespace spmst_lms_development
{
    public static class sessionHelper
    {
        // =====================================================================
        // CANONICAL ROLE TOKENS — single source of truth for the entire app.
        // All lowercase so they align with case-insensitive comparisons.
        // =====================================================================
        public const string RoleAdmin = "admin";
        public const string RoleStaffC = "staff-c";   // Circulation Area
        public const string RoleStaffM = "staff-m";   // Management Area
        public const string RoleStaffO = "staff-o";   // Other staff (patron-level)
        public const string RoleStudent = "student";
        public const string RoleFaculty = "faculty";
        public const string RoleVisitor = "visitor";

        // =====================================================================
        // SESSION PROPERTIES
        // =====================================================================
        public static string UserID => HttpContext.Current.Session["UserID"]?.ToString() ?? string.Empty;
        public static string FullName => HttpContext.Current.Session["FullName"]?.ToString() ?? "Guest User";
        public static string UserRole => HttpContext.Current.Session["UserRole"]?.ToString() ?? RoleVisitor;
        public static string Email => HttpContext.Current.Session["Email"]?.ToString() ?? string.Empty;

        // =====================================================================
        // ROLE RESOLUTION — called only by login.aspx.cs after successful auth.
        // =====================================================================
        /// <summary>
        /// Maps (Users.role, Staff.office_department, Staff.is_head_librarian)
        /// to a canonical session role token.
        ///
        /// Admin priority (any of these → admin):
        ///   1. Users.role = 'admin'
        ///   2. Staff.is_head_librarian = 1
        ///   3. Staff.office_department contains "head office"
        /// </summary>
        public static string ResolveRole(string dbRole, string department, bool isHeadLibrarian)
        {
            string role = (dbRole ?? string.Empty).Trim().ToLowerInvariant();
            string dept = (department ?? string.Empty).Trim().ToLowerInvariant();

            // --- Admin wins first so department never overrides it ---
            if (role == "admin"
                || isHeadLibrarian
                || dept.Contains("head office"))
            {
                return RoleAdmin;
            }

            if (role == "staff")
            {
                if (dept.Contains("circulation")) return RoleStaffC;   // "Circulation Desk"/"Circulation Area"
                if (dept.Contains("management")) return RoleStaffM;   // "Management Desk"/"Management Area"
                return RoleStaffO;                                     // any other office
            }

            if (role == "student") return RoleStudent;
            if (role == "faculty") return RoleFaculty;

            return RoleVisitor;
        }

        // =====================================================================
        // DISPLAY — for UI labels only. NEVER parse this for logic.
        // =====================================================================
        public static string GetRoleDisplayName()
        {
            switch ((UserRole ?? string.Empty).Trim().ToLowerInvariant())
            {
                case RoleAdmin: return "Admin";
                case RoleStaffC: return "Circulation Area";
                case RoleStaffM: return "Management Area";
                case RoleStaffO: return "Library Staff";
                case RoleStudent: return "Student";
                case RoleFaculty: return "Faculty";
                default: return "Visitor";
            }
        }

        // =====================================================================
        // DASHBOARD ROUTING — resolves a role code to its landing page.
        // =====================================================================
        public static string GetDashboardPath(string roleCode = null)
        {
            switch ((roleCode ?? UserRole ?? string.Empty).Trim().ToLowerInvariant())
            {
                case RoleAdmin: return "~/Users/Admin/Dashboard/adminDashC.aspx";
                case RoleStaffC: return "~/Users/Staff/Dashboard/CirDash.aspx";
                case RoleStaffM: return "~/Users/Staff/Dashboard/MgtDash.aspx";
                case RoleStaffO:
                case RoleStudent:
                case RoleFaculty: return "~/Users/Patron/Dashboard/patronDash.aspx";
                default: return "~/Login/login.aspx";
            }
        }

        // =====================================================================
        // UI HELPERS
        // =====================================================================
        public static string GetInitials()
        {
            string name = FullName.Trim();
            if (string.IsNullOrWhiteSpace(name)
                || name.Equals("Guest User", StringComparison.OrdinalIgnoreCase)
                || name.Equals("System User", StringComparison.OrdinalIgnoreCase))
            {
                return "SU";
            }

            string[] tokens = name.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            if (tokens.Length == 1)
            {
                return tokens[0].Substring(0, Math.Min(2, tokens[0].Length)).ToUpper();
            }

            string firstInitial = tokens[0].Substring(0, 1);
            string lastInitial = tokens[tokens.Length - 1].Substring(0, 1);
            return (firstInitial + lastInitial).ToUpper();
        }

        public static bool IsLoggedIn() => !string.IsNullOrEmpty(UserID);
    }
}