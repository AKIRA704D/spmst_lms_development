using System;
using System.Collections.Generic;
using System.Data;
using MySql.Data.MySqlClient; 
using System.Web;

namespace spmst_lms_development
{
    public class NotificationHelper
    {
        public class NotificationModel
        {
            public int NotificationId { get; set; }
            public string UserId { get; set; }
            public string Title { get; set; }
            public string Message { get; set; }
            public bool IsRead { get; set; }
            public DateTime CreatedAt { get; set; }
        }

        private const string SessionKeyMessage = "LMS_Notification_Message";
        private const string SessionKeyType = "LMS_Notification_Type";

        // ==========================================================================
        // TRANSIENT SESSION NOTIFICATIONS (TOAST ALERTS)
        // ==========================================================================

        public static void SetNotification(string message, string type = "success")
        {
            if (HttpContext.Current?.Session != null)
            {
                HttpContext.Current.Session[SessionKeyMessage] = message;
                HttpContext.Current.Session[SessionKeyType] = type.ToLower();
            }
        }

        public static Tuple<string, string> GetNotification()
        {
            if (HttpContext.Current?.Session != null && HttpContext.Current.Session[SessionKeyMessage] != null)
            {
                string msg = HttpContext.Current.Session[SessionKeyMessage].ToString();
                string type = HttpContext.Current.Session[SessionKeyType]?.ToString() ?? "success";

                HttpContext.Current.Session[SessionKeyMessage] = null;
                HttpContext.Current.Session[SessionKeyType] = null;

                return new Tuple<string, string>(msg, type);
            }
            return null;
        }

        // ==========================================================================
        // PERSISTENT DATABASE-BACKED ROLE NOTIFICATIONS
        // ==========================================================================

        /// <summary>
        /// Fetches unread database notifications from MySQL using your configuration connection string.
        /// </summary>
        public static List<NotificationModel> GetUnreadNotificationsForUser(string userId, string connectionString)
        {
            var notifications = new List<NotificationModel>();

            string query = @"
                SELECT notification_id, user_id, title, message, is_read, created_at 
                FROM Notifications 
                WHERE is_read = 0 AND (user_id = @UserId OR user_id IS NULL)
                ORDER BY created_at DESC";

            // Using MySqlConnection instead of SqlConnection
            using (MySqlConnection conn = new MySqlConnection(connectionString))
            {
                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@UserId", userId);
                    try
                    {
                        conn.Open();
                        using (MySqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                notifications.Add(new NotificationModel
                                {
                                    NotificationId = Convert.ToInt32(reader["notification_id"]),
                                    UserId = reader["user_id"]?.ToString(),
                                    Title = reader["title"]?.ToString(),
                                    Message = reader["message"]?.ToString(),
                                    IsRead = Convert.ToBoolean(reader["is_read"]),
                                    CreatedAt = Convert.ToDateTime(reader["created_at"])
                                });
                            }
                        }
                    }
                    catch
                    {
                        // Fail gracefully if MySQL server connection or database is down
                    }
                }
            }
            return notifications;
        }

        /// <summary>
        /// Lightweight COUNT(*) variant used by the client-side poller.
        /// Same table, same predicates — no duplicate logic.
        /// </summary>
        public static int GetUnreadNotificationCount(string userId, string connectionString)
        {
            const string query = @"
                SELECT COUNT(*) FROM Notifications
                WHERE is_read = 0 AND (user_id = @UserId OR user_id IS NULL)";

            try
            {
                using (var conn = new MySqlConnection(connectionString))
                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@UserId", userId ?? string.Empty);
                    conn.Open();
                    object result = cmd.ExecuteScalar();
                    return result == null || result == DBNull.Value
                        ? 0
                        : Convert.ToInt32(result);
                }
            }
            catch
            {
                return 0; // fail quietly, same policy as the existing helper
            }
        }

        /// <summary>
        /// Universal system method to write a persistent dashboard notification into the MySQL table.
        /// </summary>
        public static void SendSystemNotification(string targetUserId, string title, string message, string connectionString)
        {
            string query = "INSERT INTO Notifications (user_id, title, message, is_read) VALUES (@UserId, @Title, @Message, 0)";

            using (MySqlConnection conn = new MySqlConnection(connectionString))
            {
                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@UserId", string.IsNullOrEmpty(targetUserId) ? (object)DBNull.Value : targetUserId);
                    cmd.Parameters.AddWithValue("@Title", title);
                    cmd.Parameters.AddWithValue("@Message", message);

                    try
                    {
                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }
                    catch
                    {
                        // Gracefully absorb execution anomalies
                    }
                }
            }
        }
    }
}