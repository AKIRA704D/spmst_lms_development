using System;
using System.Diagnostics;
using System.Net.Mail;
using System.Text;
using System.Web;

namespace spmst_lms_development.Assets.Helper.Notifications
{
    public static class PenaltyEmailService
    {
        public const string Channel = "Email";

        public class EmailSendOutcome
        {
            public string Status;    // Success / Failed / Skipped
            public string Message;
            public string Error;
        }

        public static EmailSendOutcome SendPenaltyEmail(PenaltyService.PenaltyRecord record)
        {
            var outcome = new EmailSendOutcome();

            if (record == null)
            {
                outcome.Status = "Skipped";
                outcome.Message = "No penalty record.";
                return outcome;
            }

            if (record.Balance <= 0)
            {
                outcome.Status = "Skipped";
                outcome.Message = "Penalty fully paid.";
                Trace.TraceInformation("[PenaltyEmailService] Skipped — fully paid penalty_id={0}",
                    record.PenaltyID);
                return outcome;
            }

            if (PenaltyNotificationLog.IsAlreadySent(record.PenaltyID, Channel, record.Balance))
            {
                outcome.Status = "Skipped";
                outcome.Message = "Duplicate email suppressed.";
                Trace.TraceWarning("[PenaltyEmailService] Duplicate email suppressed penalty_id={0}",
                    record.PenaltyID);
                return outcome;
            }

            string email = PatronContactResolver.GetEmail(record.UserID);
            if (string.IsNullOrWhiteSpace(email) || !IsValidEmail(email))
            {
                outcome.Status = "Skipped";
                outcome.Message = "No valid email on file.";
                Trace.TraceWarning("[PenaltyEmailService] No valid email for user={0}", record.UserID);

                PenaltyNotificationLog.RecordResult(record.PenaltyID, record.TransactionID, Channel,
                    record.Balance, false, null, null, "No valid email on file.");
                AuditLog.Log(null, "PENALTY_NOTIF", "Penalties",
                    string.Format("Email skipped (no valid email) penalty_id={0}", record.PenaltyID));
                return outcome;
            }

            string subject = BuildSubject(record);
            string body = BuildHtmlBody(record);

            Trace.TraceInformation("[PenaltyEmailService] Sending email penalty_id={0} txn={1} to {2}",
                record.PenaltyID, record.TransactionID, MaskEmail(email));

            bool ok;
            try
            {
                ok = EmailHelper.SendEmail(email, subject, body, true);
            }
            catch (Exception ex)
            {
                ok = false;
                Trace.TraceError("[PenaltyEmailService] Email exception: {0}", ex.Message);
            }

            if (ok)
            {
                outcome.Status = "Success";
                outcome.Message = "Email sent.";
                Trace.TraceInformation("[PenaltyEmailService] Email OK penalty_id={0}", record.PenaltyID);

                PenaltyNotificationLog.RecordResult(record.PenaltyID, record.TransactionID, Channel,
                    record.Balance, true, MaskEmail(email), null, null);
                AuditLog.Log(null, "PENALTY_NOTIF", "Penalties",
                    string.Format("Email sent penalty_id={0} txn={1} to {2}",
                        record.PenaltyID, record.TransactionID, MaskEmail(email)));
            }
            else
            {
                outcome.Status = "Failed";
                outcome.Message = "Email failed.";
                outcome.Error = "SMTP send failed (see Debug/Trace output for details).";
                Trace.TraceError("[PenaltyEmailService] Email FAILED penalty_id={0}", record.PenaltyID);

                PenaltyNotificationLog.RecordResult(record.PenaltyID, record.TransactionID, Channel,
                    record.Balance, false, MaskEmail(email), null, "SMTP send failed.");
                AuditLog.Log(null, "PENALTY_NOTIF", "Penalties",
                    string.Format("Email failed penalty_id={0} txn={1}",
                        record.PenaltyID, record.TransactionID));
            }

            return outcome;
        }

        internal static string BuildSubject(PenaltyService.PenaltyRecord r)
        {
            return "SPAMAST Library - Penalty Notice: "
                 + PenaltySmsService.DescribePenaltyType(r.PenaltyType)
                 + " (" + PenaltySmsService.Peso(r.Balance) + " outstanding)";
        }

        internal static string BuildHtmlBody(PenaltyService.PenaltyRecord r)
        {
            string name = string.IsNullOrWhiteSpace(r.PatronName) || r.PatronName == "Unknown"
                ? "Library Patron" : r.PatronName;
            decimal paid = r.Amount - r.Balance;

            var sb = new StringBuilder();
            sb.Append("<!DOCTYPE html><html><head><meta charset='utf-8'>");
            sb.Append("<meta name='viewport' content='width=device-width, initial-scale=1'>");
            sb.Append("<title>Penalty Notice</title></head>");
            sb.Append("<body style='margin:0;padding:0;background:#f3f4f6;");
            sb.Append("font-family:Arial,Helvetica,sans-serif;color:#111827;'>");
            sb.Append("<table role='presentation' cellpadding='0' cellspacing='0' width='100%' ");
            sb.Append("style='background:#f3f4f6;'><tr><td align='center' style='padding:20px;'>");
            sb.Append("<table role='presentation' cellpadding='0' cellspacing='0' width='600' ");
            sb.Append("style='max-width:600px;background:#ffffff;border-radius:8px;overflow:hidden;");
            sb.Append("box-shadow:0 2px 6px rgba(0,0,0,.06);'>");

            sb.Append("<tr><td style='background:#1d4ed8;color:#ffffff;padding:20px;text-align:center;'>");
            sb.Append("<h2 style='margin:0;font-size:20px;'>SPAMAST Library</h2>");
            sb.Append("<p style='margin:4px 0 0;font-size:13px;opacity:.9;'>Outstanding Penalty Notice</p>");
            sb.Append("</td></tr>");

            sb.Append("<tr><td style='padding:24px;'>");
            sb.AppendFormat("<p style='margin:0 0 12px;'>Dear {0},</p>", HttpUtility.HtmlEncode(name));
            sb.Append("<p style='margin:0 0 16px;'>This is a notice that your library account has an ");
            sb.Append("<strong>outstanding penalty</strong>. Please review the details below and settle ");
            sb.Append("it at your earliest convenience.</p>");

            sb.Append("<table cellpadding='6' cellspacing='0' width='100%' ");
            sb.Append("style='border-collapse:collapse;font-size:14px;'>");

            Row(sb, "Transaction ID", r.TransactionID.ToString(), false);
            Row(sb, "Book Title", r.Book ?? "Unknown", false);
            if (!string.IsNullOrWhiteSpace(r.AccessionNumber))
                Row(sb, "Accession No.", r.AccessionNumber, false);
            Row(sb, "Penalty Type", PenaltySmsService.DescribePenaltyType(r.PenaltyType), false);
            if (!string.IsNullOrWhiteSpace(r.Reason))
                Row(sb, "Breakdown", r.Reason, false);
            Row(sb, "Total Amount", PenaltySmsService.Peso(r.Amount), false);
            Row(sb, "Amount Paid", PenaltySmsService.Peso(paid), false);
            Row(sb, "Remaining Balance", PenaltySmsService.Peso(r.Balance), true);

            sb.Append("</table>");

            sb.Append("<p style='margin:20px 0 8px;'>To settle this penalty, please visit the ");
            sb.Append("<strong>SPAMAST Library Circulation Desk</strong> during office hours. ");
            sb.Append("Bring this notice or your student/staff ID.</p>");
            sb.Append("<p style='margin:0;font-size:12px;color:#6b7280;'>If you believe this notice ");
            sb.Append("was sent in error, please contact the library immediately.</p>");
            sb.Append("</td></tr>");

            sb.Append("<tr><td style='background:#f9fafb;text-align:center;padding:14px;");
            sb.Append("font-size:12px;color:#6b7280;'>SPAMAST Library Management System</td></tr>");
            sb.Append("</table></td></tr></table></body></html>");
            return sb.ToString();
        }

        private static void Row(StringBuilder sb, string label, string value, bool highlight)
        {
            string bg = highlight ? "#fef3c7" : "#f9fafb";
            string fg = highlight ? "color:#b91c1c;font-weight:bold;" : "";
            sb.AppendFormat(
                "<tr><td style='background:{0};border:1px solid #e5e7eb;'><strong>{1}</strong></td>" +
                "<td style='border:1px solid #e5e7eb;{2}'>{3}</td></tr>",
                bg, HttpUtility.HtmlEncode(label), fg, HttpUtility.HtmlEncode(value ?? ""));
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