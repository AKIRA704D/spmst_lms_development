using System.Web;

namespace spmst_lms_development.Users.MasterPage.Handlers
{
    /// <summary>
    /// Single shared logout endpoint. Both logout.aspx (sidebar footer) and
    /// headergroup.aspx (header) link straight to this instead of each
    /// having their own copy of the session-clearing logic.
    ///
    /// Note: the original admin.Master's logout button only navigated to
    /// the login page without actually clearing the session — this handler
    /// fixes that by calling Session.Clear()/Abandon() first.
    /// </summary>
    public class Logout : IHttpHandler
    {
        public bool IsReusable
        {
            get { return false; }
        }

        public void ProcessRequest(HttpContext context)
        {
            context.Session.Clear();
            context.Session.Abandon();
            context.Response.Redirect("~/Login/login.aspx", false);
        }
    }
}
