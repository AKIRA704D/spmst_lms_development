using System;

namespace spmst_lms_development.Users.Admin.Settings
{
    public partial class LibraryAboutSettings : System.Web.UI.Page // <-- Change the class name for each page to match its filename
    {
        protected void Page_Load(object sender, EventArgs e)
        {
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