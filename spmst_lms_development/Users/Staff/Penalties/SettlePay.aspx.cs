using System.Web;
using System.Web.Services;
using spmst_lms_development.Assets.Helper;

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

            return success ? (object)true : error;
        }
    }
}