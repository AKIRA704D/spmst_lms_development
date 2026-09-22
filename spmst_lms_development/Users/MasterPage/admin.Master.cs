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
        #region Role tokens (aliased to canonical constants)

        private const string RoleAdmin = sessionHelper.RoleAdmin;
        private const string RoleStaffC = sessionHelper.RoleStaffC;
        private const string RoleStaffM = sessionHelper.RoleStaffM;
        private const string RoleStaffO = sessionHelper.RoleStaffO;
        private const string RoleStudent = sessionHelper.RoleStudent;
        private const string RoleFaculty = sessionHelper.RoleFaculty;

        private static readonly string[] Everyone =
            { RoleAdmin, RoleStaffC, RoleStaffM, RoleStaffO, RoleStudent, RoleFaculty };

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

            // Session already stores a canonical code — no parsing needed.
            _roles = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                sessionHelper.UserRole
            };

            ApplyRoleBasedNavigation();

            if (!IsPostBack)
            {
                LoadUserProfileFooter();
            }
        }

        private void LoadUserProfileFooter()
        {
            // Intentionally left empty — kept for future footer data hooks.
        }

        // =====================================================================
        //  ROLE → TAB MATRIX
        // =====================================================================
        private void ApplyRoleBasedNavigation()
        {
            // -------- Dashboards (one per audience) --------
            Allow(lnkAdminDashboard, RoleAdmin);
            Allow(lnkPatronDashboard, PatronsOnly);
            Allow(lnkMgtDashboard, RoleAdmin, RoleStaffM);
            Allow(lnkCirDashboard, RoleAdmin, RoleStaffC);

            // -------- Core Operations --------
            Allow(lnkBookBorrow, RoleAdmin, RoleStaffC);
            Allow(lnkCatalog, Everyone);
            Allow(lnkToPickUp, PatronsOnly);
            Allow(lnkReservations, RoleAdmin, RoleStaffC, RoleStaffM);
            Allow(lnkPenalties, RoleAdmin, RoleStaffC);
            Allow(lnkAttendance, RoleAdmin, RoleStaffM);

            // -------- Management --------
            Allow(lnkInventory, RoleAdmin, RoleStaffC);
            Allow(lnkAccounts, RoleAdmin, RoleStaffM);
            Allow(lnkProfile, Everyone);
            Allow(lnkNotifications, Everyone);
            Allow(lnkLibrarySettings, RoleAdmin);

            // -------- System Registry --------
            Allow(lnkFeedbackRequest, Everyone);
            Allow(lnkFeedback, PatronsOnly);
            Allow(lnkReports, RoleAdmin, RoleStaffM);
            Allow(lnkGenerateReports, RoleAdmin);
            Allow(lnkSystemLogs, RoleAdmin);

            // Hide section headers when every child tab is hidden
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
    }
}