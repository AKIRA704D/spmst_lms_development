using System;
using System.Web.UI;

namespace spmst_lms_development.Users.Admin.Reports
{
    public partial class PrintReports : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["UserId"] == null)
            {
                Response.Redirect("~/Login/login.aspx");
            }
        }
    }
}
