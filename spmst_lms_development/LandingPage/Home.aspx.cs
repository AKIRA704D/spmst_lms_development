using System;

namespace spmst_lms_development.LandingPage
{
    public partial class Home : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // All dynamic content (top borrowers, top institutes, most borrowed
            // resources/sections, catalog grid) is loaded client-side via AJAX
            // calls to LandingData.ashx — see the inline script in Home.aspx.
        }
    }
}
