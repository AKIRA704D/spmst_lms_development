using System;
using spmst_lms_development.Assets.Helper.Handlers;

namespace spmst_lms_development.Users.Admin.Dashboard
{
    /// <summary>
    /// Legacy address of the Attendance tab (it used to be an iframe page). The content is now part of
    /// adminDashC.aspx and served by DashboardData.ashx. This page contains no data: it re-checks the
    /// role (DashboardAccess) and either forwards to the unified dashboard or shows "Access Denied".
    /// </summary>
    public partial class adminDashAa : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!DashboardAccess.CanAccessCurrent(DashTab.Attendance))
            {
                Response.Clear();
                Response.StatusCode = 403;
                Response.ContentType = "text/html";
                Response.Write(DashboardAccess.AccessDeniedHtml(ResolveUrl("~/Assets/Vendor/bootstrap/5.3.3/css/bootstrap.min.css")));
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            Response.Redirect("~/Users/Admin/Dashboard/adminDashC.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
    }
}
