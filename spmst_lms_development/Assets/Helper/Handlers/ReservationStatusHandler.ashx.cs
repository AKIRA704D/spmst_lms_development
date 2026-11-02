using System;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.SessionState;
using spmst_lms_development.Assets.Helper.Reservations;

namespace spmst_lms_development.Handlers
{
    public class ReservationStatusHandler : IHttpHandler, IRequiresSessionState
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
            context.Response.Cache.SetNoStore();
            context.Response.Cache.SetExpires(DateTime.UtcNow.AddYears(-1));

            string userId = null;
            try { userId = context.Session["UserID"] as string; }
            catch { /* session not available */ }

            if (string.IsNullOrEmpty(userId))
            {
                context.Response.StatusCode = 401;
                context.Response.Write("{\"Success\":false,\"Error\":\"Not authenticated\"}");
                return;
            }

            try
            {
                var service = new ReservationStatusService();
                var payload = service.GetPatronStatuses(userId);
                var json = new JavaScriptSerializer().Serialize(payload);
                context.Response.Write(json);
            }
            catch (Exception)
            {
                context.Response.StatusCode = 500;
                context.Response.Write("{\"Success\":false,\"Error\":\"Unable to load reservation statuses.\"}");
            }
        }

        public bool IsReusable { get { return false; } }
    }
}