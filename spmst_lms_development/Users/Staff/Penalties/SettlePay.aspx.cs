using spmst_lms_development.Assets.Helper;
using spmst_lms_development.Assets.Helper.Notifications;
using System;
using System.Web;
using System.Web.Hosting;
using System.Web.Services;

namespace spmst_lms_development.Users.Staff.Penalties
{
    public partial class SettlePay : System.Web.UI.Page
    {
        [WebMethod]
        public static PenaltyService.PenaltyRecord GetPenaltyDetails(int transactionId)
        {
            return PenaltyService.GetPenaltyRecord(transactionId);
        }

        [WebMethod]
        public static object ProcessPayment(
            int transactionId,
            decimal amount,
            decimal cashTendered,
            string method,
            string reference,
            string notes)
        {
            // Best-effort: who processed the payment.
            string receivedBy = null;
            try
            {
                if (HttpContext.Current != null && HttpContext.Current.Session != null)
                    receivedBy = HttpContext.Current.Session["UserID"] as string;
            }
            catch { /* session may not exist in some contexts */ }

            string error;
            bool success = PenaltyService.ProcessPayment(
                transactionId,
                amount,
                cashTendered,
                method,
                reference,
                notes,
                receivedBy,
                out error);

            // ===== 1: notify patron of the new outstanding balance (partial payment) =====
            if (success)
            {
                int txnSnapshot = transactionId;
                HostingEnvironment.QueueBackgroundWorkItem(ct =>
                {
                    try
                    {
                        var rec = PenaltyService.GetPenaltyRecord(txnSnapshot);

                        // Fully paid → nothing to notify (orchestrator would skip anyway).
                        // Partial payment → new balance → new notification event fires.
                        if (rec != null && rec.Balance > 0)
                        {
                            PenaltyNotificationService.SendPenaltyNotifications(txnSnapshot);
                        }
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Trace.TraceError(
                            "[SettlePay] BG penalty notify failed txn=" + txnSnapshot + ": " + ex.Message);
                    }
                });
            }


            return success ? (object)true : error;
        }
    }
}