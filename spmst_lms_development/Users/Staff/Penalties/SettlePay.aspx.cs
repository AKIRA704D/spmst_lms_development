using spmst_lms_development.Assets.Helper;
using spmst_lms_development.Assets.Helper.Notifications;
using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Hosting;
using System.Web.Services;

namespace spmst_lms_development.Users.Staff.Penalties
{
    public partial class SettlePay : System.Web.UI.Page
    {
        // ================================================================
        // 1. GetPenaltyDetails — component-level breakdown
        // ================================================================
        [WebMethod]
        public static PenaltyService.PenaltyRecord GetPenaltyDetails(int transactionId)
        {
            return PenaltyService.GetPenaltyRecord(transactionId);
        }

        // ================================================================
        // 2. ProcessPayment — validated, transactional, partial-aware
        // ================================================================
        [WebMethod]
        public static object ProcessPayment(
            int transactionId,
            decimal amount,
            decimal cashTendered,
            string method,
            string reference,
            string notes)
        {
            string receivedBy = GetAuthenticatedStaffId();
            if (string.IsNullOrEmpty(receivedBy))
                return "You must be signed in as staff to record a payment.";

            method = (method ?? "").Trim();
            if (method != "Cash" && method != "GCash" && method != "Other Banking App")
                return "Invalid payment method.";

            if (method != "Cash" && string.IsNullOrWhiteSpace(reference))
                return "A reference number is required for " + method + ".";

            if (method == "Cash" && cashTendered < amount)
                return "Cash tendered is less than the payment amount.";

            if (amount <= 0) return "Payment amount must be greater than zero.";

            string error;
            bool success = PenaltyService.ProcessPayment(
                transactionId,
                amount,
                method == "Cash" ? cashTendered : amount,
                method,
                reference ?? string.Empty,
                notes ?? string.Empty,
                receivedBy,
                out error);

            if (success)
            {
                int txn = transactionId;
                HostingEnvironment.QueueBackgroundWorkItem(ct =>
                {
                    try
                    {
                        var rec = PenaltyService.GetPenaltyRecord(txn);
                        if (rec != null && rec.Balance > 0)
                            PenaltyNotificationService.SendPenaltyNotifications(txn);
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Trace.TraceError(
                            "[SettlePay] BG notify failed txn=" + txn + ": " + ex.Message);
                    }
                });
            }

            return success ? (object)true : (error ?? "Payment failed.");
        }

        // ================================================================
        // 3. ProcessReplacement — auditable replacement settlement
        // ================================================================
        public class ReplacementInput
        {
            public string Type { get; set; }
            public string Accession { get; set; }
            public string Title { get; set; }
            public string Author { get; set; }
            public string Isbn { get; set; }
            public string Remarks { get; set; }
        }

        [WebMethod]
        public static object ProcessReplacement(
            int transactionId,
            List<ReplacementInput> replacements,
            string remarks)
        {
            string processedBy = GetAuthenticatedStaffId();
            if (string.IsNullOrEmpty(processedBy))
                return "You must be signed in as staff to record a replacement.";

            if (replacements == null || replacements.Count == 0)
                return "No replacements submitted.";

            var requests = new List<ReplacementService.ReplacementRequest>();
            foreach (var r in replacements)
            {
                requests.Add(new ReplacementService.ReplacementRequest
                {
                    Type = r.Type,
                    Accession = r.Accession,
                    Title = r.Title,
                    Author = r.Author,
                    Isbn = r.Isbn,
                    Remarks = r.Remarks
                });
            }

            string error;
            bool ok = ReplacementService.ProcessReplacements(
                transactionId, requests, remarks ?? string.Empty, processedBy, out error);

            return ok ? (object)true : (error ?? "Replacement failed.");
        }

        // ================================================================
        // Helper — safe staff lookup
        // ================================================================
        private static string GetAuthenticatedStaffId()
        {
            try
            {
                if (HttpContext.Current?.Session == null) return null;
                var id = HttpContext.Current.Session["UserID"] as string;
                var role = HttpContext.Current.Session["Role"] as string;
                if (string.IsNullOrEmpty(id)) return null;
                if (role != "staff" && role != "admin") return null;
                return id;
            }
            catch { return null; }
        }
    }
}