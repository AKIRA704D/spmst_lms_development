using System;
using System.Collections.Generic;
using System.Configuration;
using System.Diagnostics;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Assets.Helper
{
    public static class ReservationSmsService
    {
        private static string ConnStr
        {
            get { return ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString; }
        }

        // Every table that stores a user + mobile_number.
        // Format: "table|id_column"  (admin lives inside Staff)
        private static readonly string[] UserTables =
        {
            "Students|student_id",
            "Faculty|faculty_id",
            "Staff|staff_id"
        };

        private class ReminderRow
        {
            public int TransactionId;
            public string Title;
            public string FirstName;
            public string MobileNumber;
            public int SecondsLeft;
        }

        // ===================================================================
        // 1. "Your hold is about to expire" — the 20-minute window
        // ===================================================================
        /// <summary>
        /// Finds every 'Ready' reservation with 20 minutes or less remaining
        /// that has not yet been reminded (no matching Audit_Logs row), texts
        /// the patron, and logs the result. Returns the number of SMS sent.
        /// Safe to call as often as you like.
        /// </summary>
        public static int SendExpiryReminders()
        {
            int sent = 0;
            var rows = new List<ReminderRow>();

            using (var conn = new MySqlConnection(ConnStr))
            {
                conn.Open();

                const string selectSql = @"
                    SELECT t.transaction_id,
                           r.title,
                           COALESCE(s.first_name, f.first_name, st.first_name)              AS first_name,
                           COALESCE(s.mobile_number, f.mobile_number, st.mobile_number)     AS mobile_number,
                           TIMESTAMPDIFF(SECOND, NOW(),
                               DATE_ADD(t.updated_at, INTERVAL 1 HOUR))                     AS seconds_left
                    FROM Transactions t
                    INNER JOIN Item_Copies       c  ON t.accession_number = c.accession_number
                    INNER JOIN Library_Resources r  ON c.resource_id      = r.resource_id
                    LEFT  JOIN Students          s  ON t.user_id          = s.student_id
                    LEFT  JOIN Faculty           f  ON t.user_id          = f.faculty_id
                    LEFT  JOIN Staff             st ON t.user_id          = st.staff_id
                    WHERE t.status        = 'Ready'
                      AND t.return_date   IS NULL
                      AND TIMESTAMPDIFF(SECOND, NOW(),
                              DATE_ADD(t.updated_at, INTERVAL 1 HOUR)) <= 1200
                      AND TIMESTAMPDIFF(SECOND, NOW(),
                              DATE_ADD(t.updated_at, INTERVAL 1 HOUR)) >  0
                      AND NOT EXISTS (
                            SELECT 1 FROM Audit_Logs al
                             WHERE al.action_type    = 'SMS_SENT'
                               AND al.table_affected = 'Transactions'
                               AND al.action_details = CONCAT('expiry_reminder:txn=', t.transaction_id)
                      )
                    ORDER BY t.updated_at ASC";

                using (var cmd = new MySqlCommand(selectSql, conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        rows.Add(new ReminderRow
                        {
                            TransactionId = Convert.ToInt32(reader["transaction_id"]),
                            Title = reader["title"].ToString(),
                            FirstName = reader["first_name"] == DBNull.Value ? "" : reader["first_name"].ToString(),
                            MobileNumber = reader["mobile_number"] == DBNull.Value ? null : reader["mobile_number"].ToString(),
                            SecondsLeft = Convert.ToInt32(reader["seconds_left"])
                        });
                    }
                }

                foreach (var row in rows)
                {
                    // No number on file → log a skip so we don't re-query this txn forever.
                    if (string.IsNullOrWhiteSpace(row.MobileNumber))
                    {
                        LogSmsAudit(conn, row.TransactionId, "SMS_SENT", "skipped: no mobile_number");
                        continue;
                    }

                    string msg = BuildExpiryMessage(row.FirstName, row.Title, row.SecondsLeft);
                    var result = SmsHelper.Send(row.MobileNumber, msg);

                    if (result.Success)
                    {
                        LogSmsAudit(conn, row.TransactionId, "SMS_SENT",
                            "sent to " + Mask(row.MobileNumber) + " id=" + result.MessageId);
                        sent++;
                    }
                    else
                    {
                        // Log the failure under a different action_type so we
                        // don't accidentally block the retry on the next tick.
                        LogSmsAudit(conn, row.TransactionId, "SMS_FAILED",
                            "error=" + Truncate(result.Error, 200));

                        Trace.TraceError("SMS expiry reminder failed for txn {0}: {1}",
                            row.TransactionId, result.Error);
                    }
                }
            }

            return sent;
        }

        // ===================================================================
        // 2. "Your book is ready for pickup" — fired from HandleAction_Click
        // ===================================================================
        public static SmsResult SendReadySms(string userId, string bookTitle, int transactionId)
        {
            string mobile = GetMobileNumber(userId);

            if (string.IsNullOrWhiteSpace(mobile))
            {
                using (var conn = new MySqlConnection(ConnStr))
                {
                    conn.Open();
                    LogSmsAudit(conn, transactionId, "SMS_SENT",
                        "skipped ready: no mobile_number for " + userId);
                }
                return SmsResult.Fail("No mobile_number on file for user " + userId + ".");
            }

            string msg = string.Format(
                "Good day! The book you reserved, \"{0}\", is now ready for pickup at the circulation desk. " +
                "Please claim it within 1 hour or the hold will be released. - SPAMAST Library",
                bookTitle);

            var result = SmsHelper.Send(mobile, msg);

            using (var conn = new MySqlConnection(ConnStr))
            {
                conn.Open();
                LogSmsAudit(conn, transactionId,
                    result.Success ? "SMS_SENT" : "SMS_FAILED",
                    result.Success
                        ? "ready notice to " + Mask(mobile) + " id=" + result.MessageId
                        : "ready notice failed: " + Truncate(result.Error, 200));
            }

            return result;
        }

        // ===================================================================
        //  Mobile-number lookup — walks Students → Faculty → Staff
        // ===================================================================
        public static string GetMobileNumber(string userId)
        {
            if (string.IsNullOrWhiteSpace(userId)) return null;

            using (var conn = new MySqlConnection(ConnStr))
            {
                conn.Open();

                foreach (var entry in UserTables)
                {
                    var parts = entry.Split('|');
                    var sql = string.Format(
                        "SELECT mobile_number FROM `{0}` WHERE `{1}` = @uid LIMIT 1",
                        parts[0], parts[1]);

                    using (var cmd = new MySqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@uid", userId);
                        object o = cmd.ExecuteScalar();

                        if (o != null && o != DBNull.Value && !string.IsNullOrWhiteSpace(o.ToString()))
                            return o.ToString().Trim();
                    }
                }
            }

            return null;
        }

        // ===================================================================
        //  Audit_Logs helpers — the "already reminded?" ledger
        // ===================================================================
        private static void LogSmsAudit(MySqlConnection conn, int transactionId,
                                        string actionType, string details)
        {
            const string sql = @"
                INSERT INTO Audit_Logs
                       (user_id, action_type, table_affected, action_details, created_at)
                VALUES (NULL,    @atype,     'Transactions', @details,      NOW())";

            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@atype", actionType);
                cmd.Parameters.AddWithValue("@details",
                    string.Format("expiry_reminder:txn={0} | {1}", transactionId, details ?? ""));
                cmd.ExecuteNonQuery();
            }
        }

        // ===================================================================
        //  Small utilities
        // ===================================================================
        private static string BuildExpiryMessage(string firstName, string title, int secondsLeft)
        {
            int mins = (int)Math.Ceiling(secondsLeft / 60.0);
            string who = string.IsNullOrWhiteSpace(firstName) ? "Patron" : firstName;

            return string.Format(
                "Hi {0}! Your reserved book \"{1}\" is only being held for about {2} more minute(s). " +
                "Please claim it at the circulation desk now or the hold will be cancelled. - SPAMAST Library",
                who, title, mins);
        }

        private static string Mask(string mobile)
        {
            if (string.IsNullOrWhiteSpace(mobile) || mobile.Length < 4) return "***";
            return "***" + mobile.Substring(mobile.Length - 4);
        }

        private static string Truncate(string s, int max)
        {
            if (string.IsNullOrEmpty(s)) return "";
            return s.Length <= max ? s : s.Substring(0, max) + "...";
        }
    }
}