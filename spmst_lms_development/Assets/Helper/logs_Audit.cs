using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Web;

namespace spmst_lms_development.Assets.Helper
{
    public class AuditLog
    {
        private static readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        /// <summary>
        /// Log an action to the Audit_Logs table
        /// </summary>
        /// <param name="userId">User ID performing the action</param>
        /// <param name="actionType">LOGIN, LOGOUT, INSERT, UPDATE, DELETE, ARCHIVE, RESTORE, DEACTIVATE, REACTIVATE, SEARCH, FILTER, IMPORT, EXPORT</param>
        /// <param name="tableAffected">Name of table affected (optional)</param>
        /// <param name="actionDetails">Additional details about the action</param>
        /// <param name="ipAddress">IP address of the user (optional - will auto-detect if not provided)</param>
        public static void Log(string userId, string actionType, string tableAffected = null, string actionDetails = null, string ipAddress = null)
        {
            try
            {
                // Auto-get IP if not provided
                if (string.IsNullOrEmpty(ipAddress))
                {
                    ipAddress = GetUserIP();
                }

                using (MySqlConnection conn = new MySqlConnection(_connStr))
                {
                    conn.Open();
                    string query = @"INSERT INTO Audit_Logs 
                                    (user_id, action_type, table_affected, action_details, ip_address, created_at) 
                                    VALUES (@userId, @actionType, @tableAffected, @actionDetails, @ipAddress, NOW())";

                    using (MySqlCommand cmd = new MySqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@userId", userId);
                        cmd.Parameters.AddWithValue("@actionType", actionType);
                        cmd.Parameters.AddWithValue("@tableAffected", string.IsNullOrEmpty(tableAffected) ? (object)DBNull.Value : tableAffected);
                        cmd.Parameters.AddWithValue("@actionDetails", string.IsNullOrEmpty(actionDetails) ? (object)DBNull.Value : actionDetails);
                        cmd.Parameters.AddWithValue("@ipAddress", ipAddress);
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch (Exception ex)
            {
                // Log to debug output but don't break the main functionality
                System.Diagnostics.Debug.WriteLine($"Audit Log Error: {ex.Message}");
            }
        }

        /// <summary>
        /// Get the user's IP address
        /// </summary>
        private static string GetUserIP()
        {
            try
            {
                string ip = string.Empty;
                if (HttpContext.Current != null && HttpContext.Current.Request != null)
                {
                    var request = HttpContext.Current.Request;
                    ip = request.ServerVariables["HTTP_X_FORWARDED_FOR"];
                    if (string.IsNullOrEmpty(ip))
                    {
                        ip = request.ServerVariables["REMOTE_ADDR"];
                    }
                    if (string.IsNullOrEmpty(ip))
                    {
                        ip = request.UserHostAddress;
                    }
                }
                return ip ?? "Unknown";
            }
            catch
            {
                return "Unknown";
            }
        }

        // Convenience methods for common actions
        public static void LogLogin(string userId, bool success, string reason = null)
        {
            string details = success ? "User logged in successfully" : $"Login failed: {reason}";
            Log(userId, "LOGIN", "Users", details);
        }

        public static void LogLogout(string userId)
        {
            Log(userId, "LOGOUT", null, "User logged out");
        }

        public static void LogInsert(string userId, string tableAffected, string recordId, string details = null)
        {
            string actionDetails = details ?? $"Inserted record: {recordId} into {tableAffected}";
            Log(userId, "INSERT", tableAffected, actionDetails);
        }

        public static void LogUpdate(string userId, string tableAffected, string recordId, string details = null)
        {
            string actionDetails = details ?? $"Updated record: {recordId} in {tableAffected}";
            Log(userId, "UPDATE", tableAffected, actionDetails);
        }

        public static void LogDelete(string userId, string tableAffected, string recordId, string details = null)
        {
            string actionDetails = details ?? $"Deleted record: {recordId} from {tableAffected}";
            Log(userId, "DELETE", tableAffected, actionDetails);
        }

        public static void LogArchive(string userId, string tableAffected, string recordId, string details = null)
        {
            string actionDetails = details ?? $"Archived record: {recordId} from {tableAffected}";
            Log(userId, "ARCHIVE", tableAffected, actionDetails);
        }

        public static void LogRestore(string userId, string tableAffected, string recordId, string details = null)
        {
            string actionDetails = details ?? $"Restored record: {recordId} from {tableAffected}";
            Log(userId, "RESTORE", tableAffected, actionDetails);
        }

        public static void LogDeactivate(string userId, string targetUserId, string details = null)
        {
            string actionDetails = details ?? $"Deactivated user: {targetUserId}";
            Log(userId, "DEACTIVATE", "Users", actionDetails);
        }

        public static void LogReactivate(string userId, string targetUserId, string details = null)
        {
            string actionDetails = details ?? $"Reactivated user: {targetUserId}";
            Log(userId, "REACTIVATE", "Users", actionDetails);
        }

        public static void LogExport(string userId, string tableAffected, string details = null)
        {
            string actionDetails = details ?? $"Exported data from {tableAffected}";
            Log(userId, "EXPORT", tableAffected, actionDetails);
        }

        public static void LogSearch(string userId, string searchTerm, string tableAffected = null)
        {
            string actionDetails = $"Searched for: '{searchTerm}'" + (tableAffected != null ? $" in {tableAffected}" : "");
            Log(userId, "SEARCH", tableAffected, actionDetails);
        }

        public static void LogActivate(string userId, string targetUserId, bool success, string details = null)
        {
            string actionDetails = details ?? (success ? $"Successfully activated user: {targetUserId}" : $"Failed to activate user: {targetUserId}");
            Log(userId, "ACTIVATE", "Users", actionDetails);
        }

        public static void LogPasswordResetRequest(string userId, string email, bool success, string reason = null)
        {
            string details = success ? $"Password reset requested for {email}" : $"Password reset failed: {reason}";
            Log(userId, "PASSWORD_RESET_REQUEST", "Users", details);
        }

        public static void LogPasswordResetVerified(string userId, bool success, string reason = null)
        {
            string details = success ? "OTP verified successfully" : $"OTP verification failed: {reason}";
            Log(userId, "PASSWORD_RESET_VERIFIED", "Users", details);
        }

        public static void LogPasswordReset(string userId, bool success, string reason = null)
        {
            string details = success ? "Password reset completed successfully" : $"Password reset failed: {reason}";
            Log(userId, "PASSWORD_RESET", "Users", details);
        }
                public static void LogView(string userId, string pageName, string details = null)
        {
            string actionDetails = details ?? $"Viewed {pageName} page";
            Log(userId, "VIEW", pageName, actionDetails);
        }

        public static void LogFilter(string userId, string filterType, string filterValue, string tableAffected = null)
        {
            string actionDetails = $"Applied filter {filterType} = {filterValue}";
            Log(userId, "FILTER", tableAffected ?? "AccountManagement", actionDetails);
        }

        public static void LogRefresh(string userId, string pageName, string details = null)
        {
            string actionDetails = details ?? $"Refreshed {pageName} data";
            Log(userId, "REFRESH", pageName, actionDetails);
        }

        public static void LogFilterApply(string userId, string filterDetails, string tableAffected = null)
        {
            Log(userId, "FILTER_APPLY", tableAffected ?? "AccountManagement", filterDetails);
        }

        public static void LogLoad(string userId, string pageName, string details = null)
        {
            string actionDetails = details ?? $"Loaded data on {pageName}";
            Log(userId, "LOAD", pageName, actionDetails);
        }

        public static void LogUpdateFailed(string userId, string tableAffected, string recordId, string details = null)
        {
            string actionDetails = details ?? $"Failed to update record {recordId} in {tableAffected}";
            Log(userId, "UPDATE_FAILED", tableAffected, actionDetails);
        }

        public static void LogLoadFailed(string userId, string tableAffected, string details = null)
        {
            string actionDetails = details ?? $"Failed to load data from {tableAffected}";
            Log(userId, "LOAD_FAILED", tableAffected, actionDetails);
        }

        public static void LogPrint(string userId, string pageName, string details = null)
        {
            string actionDetails = details ?? $"Printed report from {pageName}";
            Log(userId, "PRINT", pageName, actionDetails);
        }

        public static void LogAPICall(string userId, string apiName, string details = null)
        {
            string actionDetails = details ?? $"API call: {apiName}";
            Log(userId, "API_CALL", "Reports", actionDetails);
        }

        public static void LogCheckIn(string userId, string purpose, string details = null)
        {
            string actionDetails = details ?? $"User {userId} checked in for purpose: {purpose}";
            Log(userId, "CHECKIN", "Library_Attendance", actionDetails);
        }

        public static void LogCheckOut(string userId, TimeSpan duration, string details = null)
        {
            string actionDetails = details ?? $"User {userId} checked out. Duration: {duration.TotalMinutes:F0} minutes";
            Log(userId, "CHECKOUT", "Library_Attendance", actionDetails);
        }

        public static void LogVerify(string userId, bool success, string details = null)
        {
            string actionDetails = details ?? (success ? $"User {userId} verified successfully" : $"User {userId} verification failed");
            Log(userId, success ? "VERIFY" : "VERIFY_FAILED", "Kiosk", actionDetails);
        }

        public static void LogAttendanceFailed(string userId, string reason, string details = null)
        {
            string actionDetails = details ?? $"Attendance transaction failed for user {userId}: {reason}";
            Log(userId, "ATTENDANCE_FAILED", "Library_Attendance", actionDetails);
        }

        public static void LogInsertFailed(string userId, string tableAffected, string details = null)
        {
            string actionDetails = details ?? $"Failed to insert into {tableAffected}";
            Log(userId, "INSERT_FAILED", tableAffected, actionDetails);
        }

        public static void LogAutoRefresh(string userId, string pageName, string details = null)
        {
            string actionDetails = details ?? $"Auto-refresh triggered on {pageName}";
            Log(userId, "AUTO_REFRESH", pageName, actionDetails);
        }

        // Add to your AuditLog.cs class

        public static void LogReservation(string userId, string bookTitle, string accession, string location, string details = null)
        {
            string actionDetails = details ?? $"User reserved '{bookTitle}' (Accession: {accession}, Location: {location})";
            Log(userId, "RESERVATION", "Transactions", actionDetails);
        }

        public static void LogReservationFailed(string userId, string bookTitle, string reason, string details = null)
        {
            string actionDetails = details ?? $"Reservation failed for '{bookTitle}': {reason}";
            Log(userId, "RESERVATION_FAILED", "ReservedBook", actionDetails);
        }

        public static void LogStep(string userId, string stepName, string pageName, string details = null)
        {
            string actionDetails = details ?? $"User progressed to {stepName} on {pageName}";
            Log(userId, "STEP", pageName, actionDetails);
        }

        public static void LogReserveClick(string userId, string bookTitle, string bookId, string details = null)
        {
            string actionDetails = details ?? $"User initiated reservation for '{bookTitle}' (ID: {bookId})";
            Log(userId, "RESERVE_CLICK", "BookDetails", actionDetails);
        }

        public static void LogReserveFailed(string userId, string bookTitle, string reason, string details = null)
        {
            string actionDetails = details ?? $"Reservation initiation failed for '{bookTitle}': {reason}";
            Log(userId, "RESERVE_FAILED", "BookDetails", actionDetails);
        }
    }
}