using System;
using System.Diagnostics;

namespace spmst_lms_development.Assets.Helper.Notifications
{
    /// <summary>
    /// Persistent in-app (dashboard) notifications for library penalties.
    ///
    /// IMPORTANT — scope of this channel:
    ///   * This writes a row to the `Notifications` table via the existing
    ///     NotificationHelper. It shows up in the dashboard bell.
    ///   * This is NOT a mobile/browser push notification. There is no
    ///     device subscription table, no FCM/VAPID credentials, and no
    ///     service worker in the schema or helpers. Delivering true push
    ///     would additionally require:
    ///        - a client subscription (service worker + endpoint/token),
    ///        - a push provider (FCM / Web Push gateway),
    ///        - a new `Device_Subscriptions` table,
    ///        - and a delivery worker.
    ///     Those pieces do not exist and are not assumed here.
    /// </summary>
    public static class PenaltyPushService
    {
        public const string Channel = "Push";

        public class PushSendOutcome
        {
            public string Status;    // Success / Failed / Skipped
            public string Message;
            public string Error;
        }

        public static PushSendOutcome SendPenaltyPush(PenaltyService.PenaltyRecord record)
        {
            var outcome = new PushSendOutcome();

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
                Trace.TraceInformation("[PenaltyPushService] Skipped — fully paid penalty_id={0}",
                    record.PenaltyID);
                return outcome;
            }

            if (PenaltyNotificationLog.IsAlreadySent(record.PenaltyID, Channel, record.Balance))
            {
                outcome.Status = "Skipped";
                outcome.Message = "Duplicate in-app notification suppressed.";
                Trace.TraceWarning("[PenaltyPushService] Duplicate in-app notification penalty_id={0}",
                    record.PenaltyID);
                return outcome;
            }

            if (string.IsNullOrWhiteSpace(record.UserID))
            {
                outcome.Status = "Skipped";
                outcome.Message = "No target UserID.";
                return outcome;
            }

            string title = "Library Penalty: " + PenaltySmsService.DescribePenaltyType(record.PenaltyType);
            string message = string.Format(
                "{0} — Balance {1}. Please visit the Circulation Desk to settle.",
                string.IsNullOrWhiteSpace(record.Book) ? "Library item" : record.Book,
                PenaltySmsService.Peso(record.Balance));

            Trace.TraceInformation(
                "[PenaltyPushService] Inserting in-app notification penalty_id={0} user={1}",
                record.PenaltyID, record.UserID);

            bool ok = false;
            string err = null;
            try
            {
                // Existing helper swallows DB exceptions internally, so we
                // can only detect a hard crash here. Still log our intent.
                NotificationHelper.SendSystemNotification(
                    record.UserID, title, message, DbHelper.ConnStr);
                ok = true;
            }
            catch (Exception ex)
            {
                err = ex.Message;
                ok = false;
                Trace.TraceError("[PenaltyPushService] Insert exception: {0}", ex.Message);
            }

            if (ok)
            {
                outcome.Status = "Success";
                outcome.Message = "In-app notification inserted.";

                PenaltyNotificationLog.RecordResult(record.PenaltyID, record.TransactionID, Channel,
                    record.Balance, true, MaskUser(record.UserID), null, null);
                AuditLog.Log(null, "PENALTY_NOTIF", "Notifications",
                    string.Format("In-app notif penalty_id={0} txn={1} user={2}",
                        record.PenaltyID, record.TransactionID, record.UserID));
            }
            else
            {
                outcome.Status = "Failed";
                outcome.Message = "In-app notification failed.";
                outcome.Error = err ?? "Unknown error.";

                PenaltyNotificationLog.RecordResult(record.PenaltyID, record.TransactionID, Channel,
                    record.Balance, false, MaskUser(record.UserID), null, err);
                AuditLog.Log(null, "PENALTY_NOTIF", "Notifications",
                    string.Format("In-app notif FAILED penalty_id={0} txn={1}",
                        record.PenaltyID, record.TransactionID));
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