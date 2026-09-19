using System;

namespace spmst_lms_development.Users.MasterPage
{
    public partial class admin : System.Web.UI.MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                EnforceAuthentication();
            }
        }

        /// <summary>
        /// Redirects to the login page when there is no active session.
        /// Everything else that used to live here (notification lookups,
        /// user-profile display, role-badge text, etc.) now belongs to the
        /// individual component pages under /masterpages/components/,
        /// which each own their own small piece of the layout.
        /// </summary>
        private void EnforceAuthentication()
        {
            if (!sessionHelper.IsLoggedIn())
            {
                Response.Redirect("~/Login/login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
            }
        }
    }
}
