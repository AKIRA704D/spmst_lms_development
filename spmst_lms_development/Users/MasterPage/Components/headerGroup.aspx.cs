using System;
using System.Web;

namespace spmst_lms_development.Users.MasterPage.Components
{
    public partial class headergroup : System.Web.UI.Page
    {
        protected string UserInitials { get; private set; }
        protected string RoleBadgeText { get; private set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            UserInitials = HttpUtility.HtmlEncode(sessionHelper.GetInitials());
            RoleBadgeText = HttpUtility.HtmlEncode(ResolveRoleBadgeText());
        }

        /// <summary>
        /// Maps the raw role code to the friendly label shown in the badge.
        /// This mirrors the if/else chain that used to sit inline in
        /// admin.Master's markup.
        /// </summary>
        private string ResolveRoleBadgeText()
        {
            string role = sessionHelper.GetRoleDisplayName() ?? "";

            if (role.Equals("admin", StringComparison.OrdinalIgnoreCase))
                return "Head Librarian";

            if (role.Equals("staff C", StringComparison.OrdinalIgnoreCase))
                return "Circulation Area";

            if (role.Equals("staff M", StringComparison.OrdinalIgnoreCase))
                return "Management Area";

            return role;
        }
    }
}
