using spmst_lms_development.Assets.Helper;
using System;
using System.Web;

namespace spmst_lms_development
{
    public class SmsTick : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/plain";
            try
            {
                int sent = ReservationSmsService.SendExpiryReminders();
                context.Response.Write("OK | " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
                                       + " | sent=" + sent);
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write("ERROR: " + ex.Message);
            }
        }

        public bool IsReusable { get { return false; } }
    }
}