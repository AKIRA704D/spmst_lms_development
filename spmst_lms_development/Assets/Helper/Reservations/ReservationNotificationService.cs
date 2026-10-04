using MySql.Data.MySqlClient;
using spmst_lms_development.Assets.Helper.Reservations;
using System;
using System.Configuration;
using System.Diagnostics;

namespace spmst_lms_development.Assets.Helper.Reservations
{
    /// <summary>
    /// Central orchestrator for reservation notifications across SMS, Email
    /// and in-app channels. Mirrors PenaltyNotificationService but is fully
    /// independent: separate dedup table, separate services, separate audit
    /// action code (RESERVATION_NOTIF vs PENALTY_NOTIF).
    /// </summary>
    public static class ReservationNotificationService
    {
        private static string ConnStr
        {
            get { return ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString; }
        }

        public class ChannelResult
        {
            public string Channel { get; set; }
            public string Status { get; set; }    // Success / Failed / Skipped
            public string Message { get; set; }
            public string Error { get; set; }
        }

        public class ReservationNotificationResult
        {
            public int TransactionId { get; set; }
            public bool Found { get; set; }
            public string UserId { get; set; }
            public string BookTitle { get; set; }
            public ChannelResult Sms { get; set; }
            public ChannelResult Email { get; set; }
            public ChannelResult Push { get; set; }
        }

        /// <summary>
        /// Sends three-way notification for a reservation that has just been
        /// marked Ready. Each channel runs independently — a failure in one
        /// does not stop the others. Never throws; inspect the returned result.
        /// </summary>
        public static ReservationNotificationResult SendReservationReadyNotifications(int transactionId)
        {
            var result = new ReservationNotificationResult
            {
                TransactionId = transactionId,
                Sms = new ChannelResult { Channel = "SMS", Status = "Skipped", Message = "Not attempted." },
                Email = new ChannelResult { Channel = "Email", Status = "Skipped", Message = "Not attempted." },
                Push = new ChannelResult { Channel = "Push", Status = "Skipped", Message = "Not attempted." }
            };

            Trace.TraceInformation(
                "[ReservationNotificationService] START txn={0} at {1}",
                transactionId, DateTime.Now.ToString("u"));

            // -------- 1. Lookup user + book title --------
            string userId = null;
            string bookTitle = null;
            try
            {
                const string sql = @"
                    SELECT t.user_id, r.title
                    FROM Transactions t
                    JOIN Item_Copies       c ON t.accession_number = c.accession_number
                    JOIN Library_Resources r ON c.resource_id      = r.resource_id
                    WHERE t.transaction_id = @tid";

                using (var conn = new MySqlConnection(ConnStr))
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@tid", transactionId);
                    conn.Open();
                    using (var dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            userId = dr["user_id"].ToString();
                            bookTitle = dr["title"].ToString();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Trace.TraceError(
                    "[ReservationNotificationService] Lookup failed txn={0}: {1}",
                    transactionId, ex.Message);

                result.Sms.Status = result.Email.Status = result.Push.Status = "Failed";
                result.Sms.Error = result.Email.Error = result.Push.Error = ex.Message;
                result.Sms.Message = result.Email.Message = result.Push.Message = "Lookup failed.";
                return result;
            }

            if (string.IsNullOrWhiteSpace(userId))
            {
                Trace.TraceWarning(
                    "[ReservationNotificationService] Transaction not found txn={0}", transactionId);

                result.Sms.Message = result.Email.Message = result.Push.Message =
                    "Transaction not found.";
                return result;
            }

            result.Found = true;
            result.UserId = userId;
            result.BookTitle = bookTitle;

            // -------- 2. SMS --------
            try
            {
                var o = ReservationNoticeSmsService.SendReadySms(transactionId, userId, bookTitle);
                result.Sms.Status = o.Status;
                result.Sms.Message = o.Message;
                result.Sms.Error = o.Error;
            }
            catch (Exception ex)
            {
                result.Sms.Status = "Failed";
                result.Sms.Message = "Unhandled SMS error.";
                result.Sms.Error = ex.Message;
                Trace.TraceError("[ReservationNotificationService] SMS crashed: {0}", ex.Message);
            }

            // -------- 3. Email --------
            try
            {
                var o = ReservationNoticeEmailService.SendReadyEmail(transactionId, userId, bookTitle);
                result.Email.Status = o.Status;
                result.Email.Message = o.Message;
                result.Email.Error = o.Error;
            }
            catch (Exception ex)
            {
                result.Email.Status = "Failed";
                result.Email.Message = "Unhandled Email error.";
                result.Email.Error = ex.Message;
                Trace.TraceError("[ReservationNotificationService] Email crashed: {0}", ex.Message);
            }

            // -------- 4. Push / In-app --------
            try
            {
                var o = ReservationNoticePushService.SendReadyPush(transactionId, userId, bookTitle);
                result.Push.Status = o.Status;
                result.Push.Message = o.Message;
                result.Push.Error = o.Error;
            }
            catch (Exception ex)
            {
                result.Push.Status = "Failed";
                result.Push.Message = "Unhandled Push error.";
                result.Push.Error = ex.Message;
                Trace.TraceError("[ReservationNotificationService] Push crashed: {0}", ex.Message);
            }

            Trace.TraceInformation(
                "[ReservationNotificationService] END txn={0} SMS={1} EMAIL={2} PUSH={3}",
                transactionId, result.Sms.Status, result.Email.Status, result.Push.Status);

            return result;
        }
    }
}