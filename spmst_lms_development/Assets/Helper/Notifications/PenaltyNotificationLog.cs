using System;
using System.Configuration;
using System.Diagnostics;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Assets.Helper.Notifications
{
    /// <summary>
    /// Idempotency ledger for penalty notifications.
    /// </summary>
    internal static class PenaltyNotificationLog
    {
        private static string ConnStr
        {
            get { return ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString; }
        }

        public static bool IsAlreadySent(int penaltyId, string channel, decimal balance)
        {
            const string sql = @"
                SELECT 1 FROM Penalty_Notification_Log
                WHERE penalty_id = @pid
                  AND channel = @ch
                  AND balance_at_send = @bal
                  AND status = 'Sent'
                LIMIT 1";

            try
            {
                using (var conn = new MySqlConnection(ConnStr))
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@pid", penaltyId);
                    cmd.Parameters.AddWithValue("@ch", channel);
                    cmd.Parameters.AddWithValue("@bal", balance);
                    conn.Open();
                    object o = cmd.ExecuteScalar();
                    return o != null && o != DBNull.Value;
                }
            }
            catch (Exception ex)
            {
                // Fail open: allow the attempt; a duplicate is preferable to silence.
                Trace.TraceError("[PenaltyNotificationLog] IsAlreadySent failed: " + ex.Message);
                return false;
            }
        }

        public static void RecordResult(int penaltyId, int transactionId, string channel,
                                        decimal balance, bool success,
                                        string recipientMasked, string messageId, string error)
        {
            const string sql = @"
                INSERT INTO Penalty_Notification_Log
                    (penalty_id, transaction_id, channel, balance_at_send, status,
                     attempt_count, recipient_masked, message_id, error_details)
                VALUES
                    (@pid, @tid, @ch, @bal, @status, 1, @rec, @mid, @err)
                ON DUPLICATE KEY UPDATE
                    status           = VALUES(status),
                    attempt_count    = attempt_count + 1,
                    recipient_masked = VALUES(recipient_masked),
                    message_id       = VALUES(message_id),
                    error_details    = VALUES(error_details),
                    updated_at       = NOW()";

            try
            {
                using (var conn = new MySqlConnection(ConnStr))
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@pid", penaltyId);
                    cmd.Parameters.AddWithValue("@tid", transactionId);
                    cmd.Parameters.AddWithValue("@ch", channel);
                    cmd.Parameters.AddWithValue("@bal", balance);
                    cmd.Parameters.AddWithValue("@status", success ? "Sent" : "Failed");
                    cmd.Parameters.AddWithValue("@rec",
                        string.IsNullOrEmpty(recipientMasked) ? (object)DBNull.Value : recipientMasked);
                    cmd.Parameters.AddWithValue("@mid",
                        string.IsNullOrEmpty(messageId) ? (object)DBNull.Value : messageId);
                    cmd.Parameters.AddWithValue("@err",
                        string.IsNullOrEmpty(error) ? (object)DBNull.Value : Truncate(error, 500));

                    conn.Open();
                    cmd.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                Trace.TraceError("[PenaltyNotificationLog] RecordResult failed: " + ex.Message);
            }
        }

        private static string Truncate(string s, int max)
        {
            if (string.IsNullOrEmpty(s)) return null;
            return s.Length <= max ? s : s.Substring(0, max);
        }
    }
}