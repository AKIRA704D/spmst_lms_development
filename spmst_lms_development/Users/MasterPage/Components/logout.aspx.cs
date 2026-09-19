using System;
using System.Web;

namespace spmst_lms_development.Users.MasterPage.Components
{
    public partial class Logout : System.Web.UI.Page
    {
        protected string UserInitials { get; private set; }
        protected string UserFullName { get; private set; }
        protected string UserRoleLabel { get; private set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            UserInitials = HttpUtility.HtmlEncode(sessionHelper.GetInitials());
            UserFullName = HttpUtility.HtmlEncode(sessionHelper.FullName);
            UserRoleLabel = HttpUtility.HtmlEncode(sessionHelper.GetRoleDisplayName());
        }
    }
}
