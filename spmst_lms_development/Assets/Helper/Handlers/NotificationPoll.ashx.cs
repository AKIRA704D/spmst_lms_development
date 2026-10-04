using System;
using System.Configuration;
using System.Web;
using System.Web.Script.Serialization;

namespace spmst_lms_development.Assets.Helper.Handlers
{
    /// <summary>
    /// Minimal JSON endpoint polled by admin.Master to refresh the bell state
    /// without a full page reload. Reuses NotificationHelper — no new model.
    /// </summary>
    public class NotificationPoll : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);

            int count = 0;

            if (sessionHelper.IsLoggedIn())
            {
                string connString = ConfigurationManager
                    .ConnectionStrings["LmsDb"].ConnectionString;

                count = NotificationHelper.GetUnreadNotificationCount(
                    sessionHelper.UserID, connString);
            }

            var json = new JavaScriptSerializer().Serialize(new { count = count });
            context.Response.Write(json);
        }

        public bool IsReusable => false;
    }
}