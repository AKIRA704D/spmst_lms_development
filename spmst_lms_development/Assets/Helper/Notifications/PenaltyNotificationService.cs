using System;
using System.Diagnostics;

namespace spmst_lms_development.Assets.Helper.Notifications
{
    /// <summary>
    /// Central orchestrator for penalty notifications across SMS, Email and
    /// in-app (dashboard) channels. Each channel is executed independently:
    /// a failure in one channel does not stop the others.
    /// </summary>
    public static class PenaltyNotificationService
    {
        public class ChannelResult
        {
            public string Channel { get; set; }
            public string Status { get; set; }   // Success / Failed / Skipped
            public string Message { get; set; }
            public string Error { get; set; }
        }

        public class PenaltyNotificationResult
        {
            public int TransactionId { get; set; }
            public int PenaltyId { get; set; }
            public bool PenaltyFound { get; set; }
            public bool FullyPaid { get; set; }
            public decimal Balance { get; set; }
            public ChannelResult Sms { get; set; }
            public ChannelResult Email { get; set; }
            public ChannelResult Push { get; set; }
        }

        /// <summary>
        /// Retrieves the latest penalty state for the given transaction and
        /// dispatches penalty notifications on every configured channel.
        /// Never throws — inspect the returned result to see per-channel status.
        /// </summary>
        public static PenaltyNotificationResult SendPenaltyNotifications(int transactionId)
        {
            var result = new PenaltyNotificationResult
            {
                TransactionId = transactionId,
                Sms = new ChannelResult { Channel = "SMS", Status = "Skipped", Message = "Not attempted." },
                Email = new ChannelResult { Channel = "Email", Status = "Skipped", Message = "Not attempted." },
                Push = new ChannelResult { Channel = "Push", Status = "Skipped", Message = "Not attempted." }
            };

            Trace.TraceInformation(
                "[PenaltyNotificationService] START txn={0} at {1}",
                transactionId, DateTime.Now.ToString("u"));

            // -------- 1. Fetch penalty --------
            PenaltyService.PenaltyRecord record = null;
            try
            {
                record = PenaltyService.GetPenaltyRecord(transactionId);
            }
            catch (Exception ex)
            {
                Trace.TraceError(
                    "[PenaltyNotificationService] GetPenaltyRecord failed txn={0}: {1}",
                    transactionId, ex.Message);

                result.Sms.Status = result.Email.Status = result.Push.Status = "Failed";
                result.Sms.Error = result.Email.Error = result.Push.Error = ex.Message;
                result.Sms.Message = result.Email.Message = result.Push.Message = "Penalty lookup failed.";
                return result;
            }

            if (record == null)
            {
                Trace.TraceWarning(
                    "[PenaltyNotificationService] Penalty record not found txn={0}", transactionId);

                result.PenaltyFound = false;
                result.Sms.Message = result.Email.Message = result.Push.Message =
                    "Penalty record not found.";
                return result;
            }

            result.PenaltyFound = true;
            result.PenaltyId = record.PenaltyID;
            result.Balance = record.Balance;

            Trace.TraceInformation(
                "[PenaltyNotificationService] penalty_id={0} txn={1} type={2} amount={3} paid={4} balance={5} status={6}",
                record.PenaltyID, record.TransactionID, record.PenaltyType,
                record.Amount, record.Amount - record.Balance, record.Balance, record.Status);

            // -------- 2. Skip fully paid --------
            if (record.Balance <= 0)
            {
                result.FullyPaid = true;
                result.Sms.Message = result.Email.Message = result.Push.Message =
                    "Penalty fully paid — no notification sent.";
                Trace.TraceInformation(
                    "[PenaltyNotificationService] Fully paid — all channels skipped penalty_id={0}",
                    record.PenaltyID);
                return result;
            }

            // -------- 3. SMS --------
            try
            {
                var sms = PenaltySmsService.SendPenaltySms(record);
                result.Sms.Status = sms.Status;
                result.Sms.Message = sms.Message;
                result.Sms.Error = sms.Error;
            }
            catch (Exception ex)
            {
                result.Sms.Status = "Failed";
                result.Sms.Message = "Unhandled SMS error.";
                result.Sms.Error = ex.Message;
                Trace.TraceError("[PenaltyNotificationService] SMS channel crashed: {0}", ex.Message);
            }

            // -------- 4. Email --------
            try
            {
                var em = PenaltyEmailService.SendPenaltyEmail(record);
                result.Email.Status = em.Status;
                result.Email.Message = em.Message;
                result.Email.Error = em.Error;
            }
            catch (Exception ex)
            {
                result.Email.Status = "Failed";
                result.Email.Message = "Unhandled Email error.";
                result.Email.Error = ex.Message;
                Trace.TraceError("[PenaltyNotificationService] Email channel crashed: {0}", ex.Message);
            }

            // -------- 5. Push / In-app --------
            try
            {
                var push = PenaltyPushService.SendPenaltyPush(record);
                result.Push.Status = push.Status;
                result.Push.Message = push.Message;
                result.Push.Error = push.Error;
            }
            catch (Exception ex)
            {
                result.Push.Status = "Failed";
                result.Push.Message = "Unhandled Push error.";
                result.Push.Error = ex.Message;
                Trace.TraceError("[PenaltyNotificationService] Push channel crashed: {0}", ex.Message);
            }

            Trace.TraceInformation(
                "[PenaltyNotificationService] END txn={0} penalty_id={1} SMS={2} EMAIL={3} PUSH={4}",
                transactionId, record.PenaltyID,
                result.Sms.Status, result.Email.Status, result.Push.Status);

            return result;
        }
    }
}