using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using spmst_lms_development.Assets.Helper; 

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

            _roles = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                sessionHelper.UserRole
            };

            ApplyRoleBasedNavigation();
        }

        // =====================================================================
        //  PROFILE IMAGE RESOLUTION  (exact implementation required by spec)
        // =====================================================================
        private string ResolveProfileImage(string profilePath)
        => ProfileHelper.ResolveProfileImage(profilePath);

        // Exposed to the .Master markup for the mobile avatar fallback logic.
        protected string GetResolvedProfileImageUrl()
        => ResolveProfileImage(sessionHelper.ProfileImagePath);

        protected string RenderAvatar(string sizeVariant)
        {
            // sizeVariant: "mobile" | "header" | "footer"
            string imgClass = sizeVariant + "-avatar-image";
            string initialsClass = sizeVariant == "footer"
                ? "user-profile-avatar-initials"
                : sizeVariant + "-avatar-initials";

            string url = GetResolvedProfileImageUrl();
            string initials = HttpUtility.HtmlEncode(sessionHelper.GetInitials());

            if (!string.IsNullOrEmpty(url))
            {
                return string.Format(
                    "<img src=\"{0}\" alt=\"Profile\" class=\"{1}\" />",
                    HttpUtility.HtmlAttributeEncode(url),
                    imgClass);
            }

            return string.Format(
                "<div class=\"{0}\">{1}</div>",
                initialsClass,
                initials);
        }

        // =====================================================================
        //  ROLE → TAB MATRIX  (unchanged authorization, grouped for submenus)
        // =====================================================================
        private void ApplyRoleBasedNavigation()
        {
            // ---------- Core Operations → Dashboards ----------
            Allow(lnkAdminDashboard, RoleAdmin);
            Allow(lnkPatronDashboard, PatronsOnly);
            Allow(lnkMgtDashboard, RoleAdmin, RoleStaffM);
            Allow(lnkCirDashboard, RoleAdmin, RoleStaffC);

            // ---------- Core Operations → Circulation / Transactions ----------
            Allow(lnkBookBorrow, RoleAdmin, RoleStaffC);
            Allow(lnkToPickUp, PatronsOnly);
            Allow(lnkReservations, RoleAdmin, RoleStaffC, RoleStaffM);
            Allow(lnkPenalties, RoleAdmin, RoleStaffC);
            Allow(lnkHistory, PatronsOnly);
            Allow(lnkAttendance, RoleAdmin, RoleStaffM);


            // ---------- Core Operations → Catalog ----------
            Allow(lnkCatalog, Everyone);

            // ---------- Management → Library ----------
            Allow(lnkInventory, RoleAdmin, RoleStaffC);
            Allow(lnkLibrarySettings, RoleAdmin);
            Allow(lnkBookImports, RoleAdmin, RoleStaffC);

            // ---------- Management → Users ----------
            Allow(lnkAccounts, RoleAdmin, RoleStaffM);
            Allow(lnkUserImports, RoleAdmin, RoleStaffM);
            Allow(lnkProfile, Everyone);

            // ---------- Management → Transactions ----------
            Allow(lnkTransactionImports, RoleAdmin, RoleStaffC);

            // ---------- Management → Notifications ----------
            Allow(lnkNotifications, Everyone);

            // ---------- System Registry → Feedback ----------
            Allow(lnkFeedbackRequest, Everyone);
            Allow(lnkFeedback, PatronsOnly);

            // ---------- System Registry → Reports ----------
            Allow(lnkReports, RoleAdmin, RoleStaffM);
            Allow(lnkGenerateReports, RoleAdmin);

            // ---------- System Registry → System ----------
            Allow(lnkSystemLogs, RoleAdmin);

            // =====================================================
            //  SUBMENU VISIBILITY  (hide any submenu with zero children)
            // =====================================================
            subGroupDashboards.Visible = AnyVisible(
                lnkAdminDashboard, lnkPatronDashboard, lnkMgtDashboard, lnkCirDashboard);

            subGroupCirculation.Visible = AnyVisible(
                lnkBookBorrow, lnkToPickUp, lnkReservations,
                lnkPenalties, lnkAttendance);

            subGroupCatalog.Visible = AnyVisible(lnkCatalog);

            subGroupLibrary.Visible = AnyVisible(
                lnkInventory, lnkLibrarySettings, lnkBookImports);

            subGroupUsers.Visible = AnyVisible(
                lnkAccounts, lnkUserImports, lnkProfile);

            subGroupTransactions.Visible = AnyVisible(lnkTransactionImports);
            subGroupNotifications.Visible = AnyVisible(lnkNotifications);

            subGroupFeedback.Visible = AnyVisible(lnkFeedbackRequest, lnkFeedback);
            subGroupReports.Visible = AnyVisible(lnkReports, lnkGenerateReports);
            subGroupSystem.Visible = AnyVisible(lnkSystemLogs);

            // =====================================================
            //  CATEGORY HEADERS  (hide when every submenu is hidden)
            // =====================================================
            navGroupCoreOps.Visible = AnyVisible(
                subGroupDashboards, subGroupCirculation, subGroupCatalog);

            navGroupManagement.Visible = AnyVisible(
                subGroupLibrary, subGroupUsers,
                subGroupTransactions, subGroupNotifications);

            navGroupRegistry.Visible = AnyVisible(
                subGroupFeedback, subGroupReports, subGroupSystem);
        }

        private void Allow(HyperLink link, params string[] allowedRoles)
        {
            if (link == null) return;
            link.Visible = allowedRoles != null && allowedRoles.Any(r => _roles.Contains(r));
        }

        // Accepts HyperLink, HtmlGenericControl, and any other Control.
        private static bool AnyVisible(params Control[] controls)
            => controls.Any(c => c != null && c.Visible);
    }
}