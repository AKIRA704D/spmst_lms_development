using System.Collections.Generic;
using System.Configuration;
using System.Web;
using System.Web.Script.Serialization;

namespace spmst_lms_development.Users.MasterPage.Handlers
{
    /// <summary>
    /// Returns the current user's unread notifications as JSON:
    ///   { "count": 2, "items": [ { "title": "...", "message": "...", "createdAt": "..." }, ... ] }
    ///
    /// Called via fetch() from headergroup.aspx. Having this logic in one
    /// handler means the database query for notifications is written once,
    /// instead of being duplicated on every page that shows the bell icon
    /// (as it was in the old admin.Master, once for mobile and once for
    /// desktop).
    /// </summary>
    public class NotificationHandler : IHttpHandler
    {
        public bool IsReusable
        {
            get { return false; }
        }

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";

            string userId = sessionHelper.UserID;

            // NOTE: confirm "LmsDb" is still the correct connection-string
            // key against the current Web.config — tracked as an open
            // verification item for this project.
            string connString = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

            var notifications = NotificationHelper.GetUnreadNotificationsForUser(userId, connString);

            var items = new List<object>();
            if (notifications != null)
            {
                foreach (var item in notifications)
                {
                    items.Add(new
                    {
                        title = HttpUtility.HtmlEncode(item.Title),
                        message = HttpUtility.HtmlEncode(item.Message),
                        createdAt = item.CreatedAt.ToString("g")
                    });
                }
            }

            var payload = new
            {
                count = notifications != null ? notifications.Count : 0,
                items = items
            };

            context.Response.Write(new JavaScriptSerializer().Serialize(payload));
        }
    }
}
