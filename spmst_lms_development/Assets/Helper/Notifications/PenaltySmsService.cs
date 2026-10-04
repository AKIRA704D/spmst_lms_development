using System;
using System.Diagnostics;
using System.Globalization;

namespace spmst_lms_development.Assets.Helper.Notifications
{
    public static class PenaltySmsService
    {
        public const string Channel = "SMS";

        public class SmsSendOutcome
        {
            public string Status;    // Success / Failed / Skipped
            public string Message;
            public string Error;
        }

        public static SmsSendOutcome SendPenaltySms(PenaltyService.PenaltyRecord record)
        {
            var outcome = new SmsSendOutcome();

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
                Trace.TraceInformation("[PenaltySmsService] Skipped — fully paid penalty_id={0}",
                    record.PenaltyID);
                return outcome;
            }

            if (PenaltyNotificationLog.IsAlreadySent(record.PenaltyID, Channel, record.Balance))
            {
                outcome.Status = "Skipped";
                outcome.Message = "Duplicate SMS suppressed.";
                Trace.TraceWarning("[PenaltySmsService] Duplicate SMS suppressed penalty_id={0} bal={1}",
                    record.PenaltyID, record.Balance);
                return outcome;
            }

            string mobile = PatronContactResolver.GetMobileNumber(record.UserID);
            if (string.IsNullOrWhiteSpace(mobile))
            {
                outcome.Status = "Skipped";
                outcome.Message = "No mobile number on file.";
                Trace.TraceWarning("[PenaltySmsService] No mobile_number for user={0}", record.UserID);

                PenaltyNotificationLog.RecordResult(record.PenaltyID, record.TransactionID, Channel,
                    record.Balance, false, null, null, "No mobile number on file.");
                AuditLog.Log(null, "PENALTY_NOTIF", "Penalties",
                    string.Format("SMS skipped (no mobile) penalty_id={0} txn={1}",
                        record.PenaltyID, record.TransactionID));
                return outcome;
            }

            string message = BuildMessage(record);
            Trace.TraceInformation("[PenaltySmsService] Sending SMS penalty_id={0} txn={1} to {2}",
                record.PenaltyID, record.TransactionID, Mask(mobile));

            SmsResult result;
            try
            {
                result = SmsHelper.Send(mobile, message);
            }
            catch (Exception ex)
            {
                result = SmsResult.Fail(ex.Message);
            }

            if (result != null && result.Success)
            {
                outcome.Status = "Success";
                outcome.Message = "SMS sent.";
                Trace.TraceInformation("[PenaltySmsService] SMS OK penalty_id={0} msgId={1}",
                    record.PenaltyID, result.MessageId);

                PenaltyNotificationLog.RecordResult(record.PenaltyID, record.TransactionID, Channel,
                    record.Balance, true, Mask(mobile), result.MessageId, null);
                AuditLog.Log(null, "PENALTY_NOTIF", "Penalties",
                    string.Format("SMS sent penalty_id={0} txn={1} to {2}",
                        record.PenaltyID, record.TransactionID, Mask(mobile)));
            }
            else
            {
                string err = result == null
                    ? "Unknown SMS failure."
                    : (result.Error ?? "SMS gateway returned failure.");

                outcome.Status = "Failed";
                outcome.Message = "SMS failed.";
                outcome.Error = err;
                Trace.TraceError("[PenaltySmsService] SMS FAILED penalty_id={0}: {1}",
                    record.PenaltyID, err);

                PenaltyNotificationLog.RecordResult(record.PenaltyID, record.TransactionID, Channel,
                    record.Balance, false, Mask(mobile), null, err);
                AuditLog.Log(null, "PENALTY_NOTIF", "Penalties",
                    string.Format("SMS failed penalty_id={0} txn={1}: {2}",
                        record.PenaltyID, record.TransactionID, Truncate(err, 120)));
            }

            return outcome;
        }

        internal static string BuildMessage(PenaltyService.PenaltyRecord r)
        {
            string name = string.IsNullOrWhiteSpace(r.PatronName) || r.PatronName == "Unknown"
                ? "Patron" : r.PatronName;

            string book = string.IsNullOrWhiteSpace(r.Book) ? "Unknown item" : r.Book;

            string msg =
                "[SPAMAST Library] Hi " + name + ", you have an outstanding library penalty.\n" +
                "Book: " + book + "\n" +
                (string.IsNullOrWhiteSpace(r.AccessionNumber) ? "" : "Acc#: " + r.AccessionNumber + "\n") +
                "Penalty: " + DescribePenaltyType(r.PenaltyType) +
                    (string.IsNullOrWhiteSpace(r.Reason) ? "" : " (" + r.Reason + ")") + "\n" +
                "Total: " + Peso(r.Amount) + "\n" +
                "Paid: " + Peso(r.Amount - r.Balance) + "\n" +
                "Balance: " + Peso(r.Balance) + "\n" +
                "Please visit the Circulation Desk to settle. - SPAMAST Library";

            return msg;
        }

        internal static string DescribePenaltyType(string type)
        {
            if (string.IsNullOrEmpty(type)) return "Penalty";
            switch (type)
            {
                case "Overdue": return "Overdue";
                case "Damaged": return "Damaged";
                case "Lost": return "Lost";
                case "Overdue_Damaged": return "Overdue + Damaged";
                case "Overdue_Lost": return "Overdue + Lost";
                case "Damaged_Lost": return "Damaged + Lost";
                case "Overdue_Damaged_Lost": return "Overdue + Damaged + Lost";
                case "Other": return "Other";
                default: return type.Replace('_', ' ');
            }
        }

        internal static string Peso(decimal amount)
        {
            // \u20B1 is the Peso Sign (₱)
            return "\u20B1" + amount.ToString("N2", CultureInfo.InvariantCulture);
        }

        internal static string Mask(string mobile)
        {
            if (string.IsNullOrWhiteSpace(mobile) || mobile.Length < 4) return "***";
            return "***" + mobile.Substring(mobile.Length - 4);
        }

        internal static string Truncate(string s, int max)
        {
            if (string.IsNullOrEmpty(s)) return "";
            return s.Length <= max ? s : s.Substring(0, max) + "...";
        }
    }
}