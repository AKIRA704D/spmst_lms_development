using spmst_lms_development.Assets.Helper.Notifications;
using System;
using System.Diagnostics;

namespace spmst_lms_development.Assets.Helper.Reservations
{
    public static class ReservationNoticeSmsService
    {
        public const string Channel = "SMS";
        public const string EventType = "Ready";

        public class Outcome
        {
            public string Status { get; set; }    // Success / Failed / Skipped
            public string Message { get; set; }
            public string Error { get; set; }
        }

        public static Outcome SendReadySms(int transactionId, string userId, string bookTitle)
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
                outcome.Message = "Duplicate SMS suppressed.";
                Trace.TraceWarning("[ReservationNoticeSmsService] Duplicate txn={0}", transactionId);
                return outcome;
            }

            string mobile = PatronContactResolver.GetMobileNumber(userId);
            if (string.IsNullOrWhiteSpace(mobile))
            {
                outcome.Status = "Skipped";
                outcome.Message = "No mobile number on file.";
                Trace.TraceWarning("[ReservationNoticeSmsService] No mobile for user={0}", userId);

                ReservationNotificationLog.RecordResult(transactionId, Channel, EventType,
                    false, null, null, "No mobile number on file.");
                AuditLog.Log(null, "RESERVATION_NOTIF", "Transactions",
                    string.Format("Ready SMS skipped (no mobile) txn={0}", transactionId));
                return outcome;
            }

            string message = BuildMessage(bookTitle);
            Trace.TraceInformation("[ReservationNoticeSmsService] Sending txn={0} to {1}",
                transactionId, Mask(mobile));

            SmsResult result;
            try { result = SmsHelper.Send(mobile, message); }
            catch (Exception ex) { result = SmsResult.Fail(ex.Message); }

            if (result != null && result.Success)
            {
                outcome.Status = "Success";
                outcome.Message = "SMS sent.";
                Trace.TraceInformation("[ReservationNoticeSmsService] OK txn={0} msgId={1}",
                    transactionId, result.MessageId);

                ReservationNotificationLog.RecordResult(transactionId, Channel, EventType,
                    true, Mask(mobile), result.MessageId, null);
                AuditLog.Log(null, "RESERVATION_NOTIF", "Transactions",
                    string.Format("Ready SMS sent txn={0} to {1}", transactionId, Mask(mobile)));
            }
            else
            {
                string err = result == null ? "Unknown SMS failure."
                                            : (result.Error ?? "Gateway failure.");
                outcome.Status = "Failed";
                outcome.Message = "SMS failed.";
                outcome.Error = err;
                Trace.TraceError("[ReservationNoticeSmsService] FAILED txn={0}: {1}", transactionId, err);

                ReservationNotificationLog.RecordResult(transactionId, Channel, EventType,
                    false, Mask(mobile), null, err);
                AuditLog.Log(null, "RESERVATION_NOTIF", "Transactions",
                    string.Format("Ready SMS failed txn={0}: {1}", transactionId, Truncate(err, 120)));
            }

            return outcome;
        }

        internal static string BuildMessage(string bookTitle)
        {
            string safeTitle = string.IsNullOrWhiteSpace(bookTitle) ? "your reserved book" : bookTitle;
            return "[SPAMAST Library] Good day! Your reserved book \"" + safeTitle +
                   "\" is now ready for pickup at the circulation desk. " +
                   "Please claim it within 1 hour or the hold will be released. - SPAMAST Library";
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