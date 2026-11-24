using System;

namespace spmst_lms_development.Assets.Helper.Handlers
{
    /// <summary>The three tabs of the Admin Dashboard.</summary>
    public enum DashTab
    {
        Circulation,
        Patrons,
        Attendance
    }

    /// <summary>
    /// SINGLE SOURCE OF TRUTH for which role may see which dashboard tab.
    ///
    ///   Role        Circulation   Patrons   Attendance
    ///   admin           yes         yes        yes
    ///   staff-c         yes         no         no
    ///   staff-m         no          yes        yes
    ///   everyone else   no          no         no
    ///
    /// The role always comes from the server-side session (sessionHelper.UserRole),
    /// which is written only by the login page. It is never read from a query string,
    /// form field, cookie or any other client-controlled value.
    ///
    /// Used by:
    ///   - adminDashC.aspx(.cs)   : decides which tabs/panels are rendered at all
    ///   - DashboardData.ashx(.cs): re-checks on EVERY data request (JSON and export)
    ///   - adminDashPp / adminDashAa / Analytics_* : legacy direct URLs
    /// </summary>
    public static class DashboardAccess
    {
        public static bool CanAccess(string role, DashTab tab)
        {
            string r = (role ?? string.Empty).Trim().ToLowerInvariant();

            switch (tab)
            {
                case DashTab.Circulation:
                    return r == sessionHelper.RoleAdmin || r == sessionHelper.RoleStaffC;

                case DashTab.Patrons:
                case DashTab.Attendance:
                    return r == sessionHelper.RoleAdmin || r == sessionHelper.RoleStaffM;

                default:
                    return false;
            }
        }

        /// <summary>True when the signed-in session may view the given tab.</summary>
        public static bool CanAccessCurrent(DashTab tab)
        {
            return sessionHelper.IsLoggedIn() && CanAccess(sessionHelper.UserRole, tab);
        }

        /// <summary>True when the signed-in session may view at least one tab.</summary>
        public static bool CanAccessAny()
        {
            return CanAccessCurrent(DashTab.Circulation)
                || CanAccessCurrent(DashTab.Patrons)
                || CanAccessCurrent(DashTab.Attendance);
        }

        /// <summary>Key of the first tab the current role may see ("circ", "patron", "attend" or "").</summary>
        public static string PrimaryTabKey()
        {
            if (CanAccessCurrent(DashTab.Circulation)) return "circ";
            if (CanAccessCurrent(DashTab.Patrons)) return "patron";
            if (CanAccessCurrent(DashTab.Attendance)) return "attend";
            return string.Empty;
        }

        /// <summary>
        /// Minimal, data-free "Access Denied" page used by legacy pages that are opened directly.
        /// </summary>
        public static string AccessDeniedHtml(string bootstrapCssUrl)
        {
            return "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Access Denied</title>"
                 + "<link href='" + bootstrapCssUrl + "' rel='stylesheet' />"
                 + "<style>body{background:#f8faf7;font-family:Segoe UI,sans-serif;}</style></head>"
                 + "<body class='d-flex align-items-center justify-content-center' style='min-height:100vh;'>"
                 + "<div class='text-center'><h3 style='color:#c0392b;font-weight:700;'>Access Denied</h3>"
                 + "<p class='text-muted'>You do not have permission to view this page.</p></div></body></html>";
        }
    }
}
