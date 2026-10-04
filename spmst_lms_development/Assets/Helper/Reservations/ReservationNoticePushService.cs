using spmst_lms_development.Assets.Helper.Reservations;
using System;
using System.Diagnostics;

namespace spmst_lms_development.Assets.Helper.Reservations
{
    public static class ReservationNoticePushService
    {
        public const string Channel = "Push";
        public const string EventType = "Ready";

        public class Outcome
        {
            public string Status { get; set; }
            public string Message { get; set; }
            public string Error { get; set; }
        }

        public static Outcome SendReadyPush(int transactionId, string userId, string bookTitle)
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
                outcome.Message = "Duplicate in-app notification suppressed.";
                Trace.TraceWarning("[ReservationNoticePushService] Duplicate txn={0}", transactionId);
                return outcome;
            }

            string safeTitle = string.IsNullOrWhiteSpace(bookTitle) ? "your reserved book" : bookTitle;

            // Title kept as "Book Ready for Pickup" so the Notifications page's
            // existing role-based filter (title LIKE '%Ready%') still matches.
            string title = "Book Ready for Pickup";
            string message = "Your reserved book '" + safeTitle +
                             "' is now ready for pickup at the circulation desk. " +
                             "Please claim it before the library closes today.";

            Trace.TraceInformation("[ReservationNoticePushService] Inserting txn={0} user={1}",
                transactionId, userId);

            bool ok = false;
            string err = null;
            try
            {
                NotificationHelper.SendSystemNotification(userId, title, message, DbHelper.ConnStr);
                ok = true;
            }
            catch (Exception ex)
            {
                err = ex.Message;
                Trace.TraceError("[ReservationNoticePushService] Insert exception: {0}", ex.Message);
            }

            if (ok)
            {
                outcome.Status = "Success";
                outcome.Message = "In-app notification inserted.";

                ReservationNotificationLog.RecordResult(transactionId, Channel, EventType,
                    true, MaskUser(userId), null, null);
                AuditLog.Log(null, "RESERVATION_NOTIF", "Notifications",
                    string.Format("Ready in-app txn={0} user={1}", transactionId, userId));
            }
            else
            {
                outcome.Status = "Failed";
                outcome.Message = "In-app notification failed.";
                outcome.Error = err ?? "Unknown error.";

                ReservationNotificationLog.RecordResult(transactionId, Channel, EventType,
                    false, MaskUser(userId), null, err);
                AuditLog.Log(null, "RESERVATION_NOTIF", "Notifications",
                    string.Format("Ready in-app FAILED txn={0}", transactionId));
            }

            return outcome;
        }

        private static string MaskUser(string userId)
        {
            if (string.IsNullOrWhiteSpace(userId)) return "***";
            return userId.Length <= 4 ? "***" : "***" + userId.Substring(userId.Length - 4);
        }
    }
}