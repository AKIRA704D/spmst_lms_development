using spmst_lms_development;
using System;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.masterpages
{
    public partial class admin : System.Web.UI.MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Enforce authorization checkpoint wall
                if (!sessionHelper.IsLoggedIn())
                {
                    Response.Redirect("~/Login/login.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }

                LoadUserProfileFooter();
            }
        }

        private void LoadUserProfileFooter()
        {
            
        }
    }
}