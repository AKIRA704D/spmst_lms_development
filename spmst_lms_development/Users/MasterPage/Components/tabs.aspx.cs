using System;

namespace spmst_lms_development.Users.MasterPage.Components
{
    public partial class tabs : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // The navigation list is static, so there's nothing to load
            // server-side. Active-link highlighting is done client-side in
            // the markup below, because it depends on the PARENT page's
            // URL, which only the browser (not this iframe) knows about.
        }
    }
}
