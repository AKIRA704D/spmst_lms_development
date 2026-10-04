using System;
using System.Configuration;
using System.Diagnostics;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Assets.Helper.Reservations
{
    internal static class ReservationNotificationLog
    {
        private static string ConnStr
        {
            get { return ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString; }
        }

        public static bool IsAlreadySent(int transactionId, string channel, string eventType)
        {
            const string sql = @"
                SELECT 1 FROM Reservation_Notification_Log
                WHERE transaction_id = @tid
                  AND channel = @ch
                  AND event_type = @ev
                  AND status = 'Sent'
                LIMIT 1";

            try
            {
                using (var conn = new MySqlConnection(ConnStr))
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@tid", transactionId);
                    cmd.Parameters.AddWithValue("@ch", channel);
                    cmd.Parameters.AddWithValue("@ev", eventType);
                    conn.Open();
                    object o = cmd.ExecuteScalar();
                    return o != null && o != DBNull.Value;
                }
            }
            catch (Exception ex)
            {
                Trace.TraceError("[ReservationNotificationLog] IsAlreadySent failed: " + ex.Message);
                return false;
            }
        }

        public static void RecordResult(int transactionId, string channel, string eventType,
                                        bool success, string recipientMasked,
                                        string messageId, string error)
        {
            const string sql = @"
                INSERT INTO Reservation_Notification_Log
                    (transaction_id, channel, event_type, status,
                     attempt_count, recipient_masked, message_id, error_details)
                VALUES
                    (@tid, @ch, @ev, @status, 1, @rec, @mid, @err)
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
                    cmd.Parameters.AddWithValue("@tid", transactionId);
                    cmd.Parameters.AddWithValue("@ch", channel);
                    cmd.Parameters.AddWithValue("@ev", eventType);
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
                Trace.TraceError("[ReservationNotificationLog] RecordResult failed: " + ex.Message);
            }
        }

        private static string Truncate(string s, int max)
        {
            if (string.IsNullOrEmpty(s)) return null;
            return s.Length <= max ? s : s.Substring(0, max);
        }
    }
}