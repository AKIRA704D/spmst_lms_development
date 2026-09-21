using System;

namespace spmst_lms_development.Users.Admin.Settings
{
    public partial class LibrarySettings : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Mirrors the role check already used in admin.Master's header badge
            // (currentRole.Equals("admin", StringComparison.OrdinalIgnoreCase)).
            // Everything else on this page loads client-side via
            // LibrarySettingsData.ashx, which independently re-checks this same
            // condition on every call — this Page_Load gate just keeps
            // non-admins from ever seeing the settings screen itself.
            string userId = spmst_lms_development.sessionHelper.UserID;
            if (string.IsNullOrEmpty(userId))
            {
                Response.Redirect(ResolveUrl("~/Login/login.aspx"), true);
                return;
            }

            string role = spmst_lms_development.sessionHelper.GetRoleDisplayName() ?? "";
            if (!role.Equals("admin", StringComparison.OrdinalIgnoreCase))
            {
                Response.Redirect(ResolveUrl("~/Users/Admin/Dashboard/adminDashC.aspx"), true);
            }
        }
    }
}
