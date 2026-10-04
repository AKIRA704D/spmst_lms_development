using spmst_lms_development.Assets.Helper.Reservations;
using System;
using System.Diagnostics;
using System.Net.Mail;
using System.Text;
using System.Web;
using spmst_lms_development.Assets.Helper.Notifications;

namespace spmst_lms_development.Assets.Helper.Reservations
{
    public static class ReservationNoticeEmailService
    {
        public const string Channel = "Email";
        public const string EventType = "Ready";

        public class Outcome
        {
            public string Status { get; set; }
            public string Message { get; set; }
            public string Error { get; set; }
        }

        public static Outcome SendReadyEmail(int transactionId, string userId, string bookTitle)
        {
            var outcome = new Outcome();

            if (transactionId <= 0 || string.IsNullOrWhiteSpace(userId))
            {
                outcome.Status = "Skipped";
                outcome.Message = "Missing transaction or user.";
                return outcome;
            }

            if (ReservationNotificationLog.IsAlreadySent(transactionId, Channel, EventType))
            {
                outcome.Status = "Skipped";
                outcome.Message = "Duplicate email suppressed.";
                Trace.TraceWarning("[ReservationNoticeEmailService] Duplicate txn={0}", transactionId);
                return outcome;
            }

            string email = PatronContactResolver.GetEmail(userId);
            if (string.IsNullOrWhiteSpace(email) || !IsValidEmail(email))
            {
                outcome.Status = "Skipped";
                outcome.Message = "No valid email on file.";
                Trace.TraceWarning("[ReservationNoticeEmailService] No valid email user={0}", userId);

                ReservationNotificationLog.RecordResult(transactionId, Channel, EventType,
                    false, null, null, "No valid email on file.");
                AuditLog.Log(null, "RESERVATION_NOTIF", "Transactions",
                    string.Format("Ready email skipped (no email) txn={0}", transactionId));
                return outcome;
            }

            string name = PatronContactResolver.GetFullName(userId);
            string subject = "SPAMAST Library - Your Reserved Book Is Ready for Pickup";
            string body = BuildHtmlBody(name, bookTitle);

            Trace.TraceInformation("[ReservationNoticeEmailService] Sending txn={0} to {1}",
                transactionId, MaskEmail(email));

            bool ok;
            try { ok = EmailHelper.SendEmail(email, subject, body, true); }
            catch (Exception ex)
            {
                ok = false;
                Trace.TraceError("[ReservationNoticeEmailService] Exception: {0}", ex.Message);
            }

            if (ok)
            {
                outcome.Status = "Success";
                outcome.Message = "Email sent.";
                Trace.TraceInformation("[ReservationNoticeEmailService] OK txn={0}", transactionId);

                ReservationNotificationLog.RecordResult(transactionId, Channel, EventType,
                    true, MaskEmail(email), null, null);
                AuditLog.Log(null, "RESERVATION_NOTIF", "Transactions",
                    string.Format("Ready email sent txn={0} to {1}", transactionId, MaskEmail(email)));
            }
            else
            {
                outcome.Status = "Failed";
                outcome.Message = "Email failed.";
                outcome.Error = "SMTP send failed (see Debug/Trace output).";
                Trace.TraceError("[ReservationNoticeEmailService] FAILED txn={0}", transactionId);

                ReservationNotificationLog.RecordResult(transactionId, Channel, EventType,
                    false, MaskEmail(email), null, "SMTP send failed.");
                AuditLog.Log(null, "RESERVATION_NOTIF", "Transactions",
                    string.Format("Ready email failed txn={0}", transactionId));
            }

            return outcome;
        }

        internal static string BuildHtmlBody(string name, string bookTitle)
        {
            if (string.IsNullOrWhiteSpace(name)) name = "Library Patron";
            if (string.IsNullOrWhiteSpace(bookTitle)) bookTitle = "Your reserved book";

            var sb = new StringBuilder();
            sb.Append("<!DOCTYPE html><html><head><meta charset='utf-8'>");
            sb.Append("<meta name='viewport' content='width=device-width, initial-scale=1'></head>");
            sb.Append("<body style='margin:0;padding:0;background:#f3f4f6;");
            sb.Append("font-family:Arial,Helvetica,sans-serif;color:#111827;'>");
            sb.Append("<table role='presentation' cellpadding='0' cellspacing='0' width='100%' ");
            sb.Append("style='background:#f3f4f6;'><tr><td align='center' style='padding:20px;'>");
            sb.Append("<table role='presentation' cellpadding='0' cellspacing='0' width='600' ");
            sb.Append("style='max-width:600px;background:#ffffff;border-radius:8px;overflow:hidden;");
            sb.Append("box-shadow:0 2px 6px rgba(0,0,0,.06);'>");

            sb.Append("<tr><td style='background:#1d4ed8;color:#ffffff;padding:20px;text-align:center;'>");
            sb.Append("<h2 style='margin:0;font-size:20px;'>SPAMAST Library</h2>");
            sb.Append("<p style='margin:4px 0 0;font-size:13px;opacity:.9;'>Reservation Ready for Pickup</p>");
            sb.Append("</td></tr>");

            sb.Append("<tr><td style='padding:24px;'>");
            sb.AppendFormat("<p style='margin:0 0 12px;'>Dear {0},</p>", HttpUtility.HtmlEncode(name));
            sb.Append("<p style='margin:0 0 16px;'>Great news! Your reserved book is now ready for pickup ");
            sb.Append("at the <strong>SPAMAST Library Circulation Desk</strong>.</p>");

            sb.Append("<table cellpadding='6' cellspacing='0' width='100%' ");
            sb.Append("style='border-collapse:collapse;font-size:14px;'>");
            sb.AppendFormat(
                "<tr><td style='background:#f9fafb;border:1px solid #e5e7eb;'><strong>Book Title</strong></td>" +
                "<td style='border:1px solid #e5e7eb;'>{0}</td></tr>",
                HttpUtility.HtmlEncode(bookTitle));
            sb.Append("</table>");

            sb.Append("<p style='margin:20px 0 8px;color:#b91c1c;font-weight:bold;'>");
            sb.Append("Please claim within 1 hour.</p>");
            sb.Append("<p style='margin:0;font-size:13px;color:#6b7280;'>");
            sb.Append("If you do not claim the item within the hold period, ");
            sb.Append("the reservation will be automatically released.</p>");
            sb.Append("</td></tr>");

            sb.Append("<tr><td style='background:#f9fafb;text-align:center;padding:14px;");
            sb.Append("font-size:12px;color:#6b7280;'>SPAMAST Library Management System</td></tr>");
            sb.Append("</table></td></tr></table></body></html>");
            return sb.ToString();
        }

        private static bool IsValidEmail(string email)
        {
            if (string.IsNullOrWhiteSpace(email)) return false;
            try
            {
                var addr = new MailAddress(email);
                return !string.IsNullOrWhiteSpace(addr.Address);
            }
            catch { return false; }
        }

        internal static string MaskEmail(string email)
        {
            if (string.IsNullOrWhiteSpace(email)) return "***";
            int at = email.IndexOf('@');
            if (at <= 0) return "***";
            return email.Substring(0, 1) + "***" + email.Substring(at);
        }
    }
}