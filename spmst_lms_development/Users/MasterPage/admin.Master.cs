using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.MasterPage
{
    public partial class admin : System.Web.UI.MasterPage
    {
        #region Role tokens

        private const string RoleAdmin = "admin";
        private const string RoleStaff = "staff";   // umbrella
        private const string RoleStaffC = "staffC";  // Circulation
        private const string RoleStaffM = "staffM";  // Management
        private const string RoleStaffO = "staffO";  // Library Staff (other staff)
        private const string RoleStudent = "student";
        private const string RoleFaculty = "faculty";

        // Convenience groups
        private static readonly string[] Everyone =
            { RoleAdmin, RoleStaff, RoleStaffC, RoleStaffM, RoleStaffO, RoleStudent, RoleFaculty };

        private static readonly string[] PatronsOnly =
            { RoleStudent, RoleFaculty, RoleStaffO };

        private HashSet<string> _roles = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        #endregion

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!sessionHelper.IsLoggedIn())
            {
                Response.Redirect("~/Login/login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            _roles = NormalizeRoles(sessionHelper.GetRoleDisplayName());
            ApplyRoleBasedNavigation();

            if (!IsPostBack)
            {
                LoadUserProfileFooter();
            }
        }

        private void LoadUserProfileFooter()
        {
        }

        // =====================================================================
        //  ROLE → TAB MATRIX
        // =====================================================================
        private void ApplyRoleBasedNavigation()
        {
            // ---------------- Dashboards — one per audience ---------------
            Allow(lnkAdminDashboard, RoleAdmin);                              // Admin dashboard
            Allow(lnkPatronDashboard, PatronsOnly);                            // Patron dashboard
            Allow(lnkMgtDashboard, RoleAdmin, RoleStaffM);                  // Management dashboard
            Allow(lnkCirDashboard, RoleAdmin, RoleStaffC);                  // Circulation dashboard

            // ---------------- Core Operations -------------------------------
            Allow(lnkBookBorrow, RoleAdmin, RoleStaffC);                     // Circulation / Loans
            Allow(lnkCatalog, Everyone);                                  // Catalog — everyone
            Allow(lnkToPickUp, PatronsOnly);                               // To Pick Up — patrons only
            Allow(lnkReservations, RoleAdmin, RoleStaffC, RoleStaffM);         // Reservations
            Allow(lnkPenalties, RoleAdmin, RoleStaffC);                     // Penalties
            Allow(lnkAttendance, RoleAdmin, RoleStaffM);                     // Attendance

            // ---------------- Management ------------------------------------
            Allow(lnkInventory, RoleAdmin, RoleStaffC);                  // Inventory
            Allow(lnkAccounts, RoleAdmin, RoleStaffM);                  // Accounts
            Allow(lnkProfile, Everyone);                               // Profile — everyone
            Allow(lnkNotifications, Everyone);                               // Notifications — everyone
            Allow(lnkLibrarySettings, RoleAdmin);                              // Settings — admin only

            // ---------------- System Registry -------------------------------
            Allow(lnkFeedbackRequest, Everyone); // Feedback & Request
            Allow(lnkFeedback, PatronsOnly);                                     // Feedback
            Allow(lnkReports, RoleAdmin, RoleStaffM);                           // Reports
            Allow(lnkGenerateReports, RoleAdmin);                                       // Generate Reports
            Allow(lnkSystemLogs, RoleAdmin);                                       // System Logs

            // Hide section headers if every child tab is hidden
            navGroupCoreOps.Visible = AnyVisible(
                lnkAdminDashboard, lnkPatronDashboard, lnkMgtDashboard, lnkCirDashboard,
                lnkBookBorrow, lnkCatalog, lnkToPickUp,
                lnkReservations, lnkPenalties, lnkAttendance);

            navGroupManagement.Visible = AnyVisible(
                lnkInventory, lnkAccounts, lnkProfile,
                lnkNotifications, lnkLibrarySettings);

            navGroupRegistry.Visible = AnyVisible(
                lnkFeedbackRequest, lnkFeedback, lnkReports,
                lnkGenerateReports, lnkSystemLogs);
        }

        private void Allow(HyperLink link, params string[] allowedRoles)
        {
            if (link == null) return;
            link.Visible = allowedRoles != null && allowedRoles.Any(r => _roles.Contains(r));
        }

        private static bool AnyVisible(params HyperLink[] links)
            => links.Any(l => l != null && l.Visible);

        /// <summary>
        /// Maps sessionHelper.GetRoleDisplayName() output AND raw staff codes
        /// to the canonical role tokens used above.
        /// </summary>
        private static HashSet<string> NormalizeRoles(string rawRole)
        {
            var roles = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (string.IsNullOrWhiteSpace(rawRole)) return roles;

            string compact = rawRole.Trim().ToLowerInvariant()
                .Replace(" ", "").Replace("-", "").Replace("_", "").Replace(".", "");

            // Admin
            if (compact == "admin" || compact == "staffa" || compact.Contains("administrator"))
                roles.Add(RoleAdmin);

            // Circulation
            if (compact.Contains("circulation") || compact.Contains("staffc") || compact.Contains("librarian"))
            {
                roles.Add(RoleStaff);
                roles.Add(RoleStaffC);
            }

            // Management
            if (compact.Contains("management") || compact.Contains("staffm"))
            {
                roles.Add(RoleStaff);
                roles.Add(RoleStaffM);
            }

            // Other staff (Library Staff)
            if (compact.Contains("librarystaff") || compact.Contains("staffo"))
            {
                roles.Add(RoleStaff);
                roles.Add(RoleStaffO);
            }

            // Students / Faculty
            if (compact.Contains("student") || (compact.Contains("patron") && !compact.Contains("faculty")))
                roles.Add(RoleStudent);

            if (compact.Contains("faculty"))
                roles.Add(RoleFaculty);

            return roles;
        }
    }
}