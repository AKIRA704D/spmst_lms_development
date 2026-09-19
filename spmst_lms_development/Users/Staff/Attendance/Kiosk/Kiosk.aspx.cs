using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Web.Services;
using System.Web.Script.Services;
using System.Web.UI;
using spmst_lms_development.Assets.Helper;  // adjust namespace if your AuditLog is elsewhere

namespace spmst_lms_development.Users.Staff.Attendance.Kiosk
{
    public partial class Kiosk : Page
    {
        private static readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private static string currentUser = "STAFF_KIOSK";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session != null && Session["UserID"] != null)
                currentUser = Session["UserID"].ToString();

            if (!IsPostBack)
            {
                AuditLog.Log(currentUser, "VIEW", "Kiosk", "Staff-Assisted Kiosk page loaded");
            }
        }

        // =====================================================================
        // WEB METHODS (called from JavaScript)
        // =====================================================================

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object VerifyUser(string inputData)
        {
            try
            {
                // Attempt decryption (if QR contains encrypted data) – otherwise treat as plain ID
                string userId = DecryptIfNeeded(inputData);
                if (string.IsNullOrEmpty(userId)) userId = inputData;

                using (var conn = new MySqlConnection(connStr))
                {
                    conn.Open();

                    // Fetch user details from combined Users + Students/Faculty/Staff tables
                    string userQuery = @"
                        SELECT u.user_id,
                               COALESCE(st.first_name, f.first_name, s.first_name) AS first_name,
                               COALESCE(st.middle_name, f.middle_name, s.middle_name) AS middle_name,
                               COALESCE(st.last_name, f.last_name, s.last_name) AS last_name,
                               COALESCE(st.extension_name, f.extension_name, s.extension_name) AS ext,
                               CASE
                                   WHEN st.student_id IS NOT NULL THEN CONCAT(st.course, ' - ', st.year_level)
                                   WHEN f.faculty_id IS NOT NULL THEN f.institute
                                   WHEN s.staff_id IS NOT NULL THEN s.office_department
                                   ELSE ''
                               END AS institute
                        FROM Users u
                        LEFT JOIN Students st ON u.user_id = st.student_id
                        LEFT JOIN Faculty f ON u.user_id = f.faculty_id
                        LEFT JOIN Staff s ON u.user_id = s.staff_id
                        WHERE u.user_id = @id AND u.is_active = 1";

                    string firstName = "", middleName = "", lastName = "", extension = "", institute = "";

                    using (var cmd = new MySqlCommand(userQuery, conn))
                    {
                        cmd.Parameters.AddWithValue("@id", userId);
                        using (var rdr = cmd.ExecuteReader())
                        {
                            if (!rdr.Read())
                            {
                                AuditLog.Log(currentUser, "VERIFY_FAILED", "Kiosk", $"User {userId} not found or inactive");
                                return new { success = false, message = "User not found or account is inactive." };
                            }
                            firstName = rdr["first_name"]?.ToString() ?? "";
                            middleName = rdr["middle_name"]?.ToString() ?? "";
                            lastName = rdr["last_name"]?.ToString() ?? "";
                            extension = rdr["ext"]?.ToString() ?? "";
                            institute = rdr["institute"]?.ToString() ?? "Not specified";
                        }
                    }

                    string middleInitial = !string.IsNullOrEmpty(middleName) ? middleName.Substring(0, 1) + ". " : "";
                    string extName = !string.IsNullOrEmpty(extension) ? " " + extension : "";
                    string fullName = $"{firstName} {middleInitial}{lastName}{extName}".Trim();

                    // Get current attendance status for today
                    string statusQuery = @"
                        SELECT attendance_status, purpose 
                        FROM Library_Attendance 
                        WHERE user_id = @id AND DATE(time_in) = CURDATE() AND time_out IS NULL
                        ORDER BY time_in DESC LIMIT 1";

                    string currentStatus = "Exited";
                    string lastPurpose = "";

                    using (var cmd = new MySqlCommand(statusQuery, conn))
                    {
                        cmd.Parameters.AddWithValue("@id", userId);
                        using (var rdr = cmd.ExecuteReader())
                        {
                            if (rdr.Read())
                            {
                                currentStatus = rdr["attendance_status"]?.ToString() ?? "Exited";
                                lastPurpose = rdr["purpose"]?.ToString() ?? "";
                            }
                        }
                    }

                    AuditLog.Log(currentUser, "VERIFY", "Kiosk", $"User verified: {userId} - {fullName} - Status: {currentStatus}");
                    return new
                    {
                        success = true,
                        userId = userId,
                        fullName = fullName,
                        institute = institute,
                        status = currentStatus,
                        lastPurpose = lastPurpose
                    };
                }
            }
            catch (Exception ex)
            {
                AuditLog.Log("SYSTEM", "ERROR", "Kiosk", $"VerifyUser error: {ex.Message}");
                return new { success = false, message = "Server error. Please try again." };
            }
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object RecordAttendance(string userId, string purpose)
        {
            MySqlTransaction tx = null;
            try
            {
                DateTime ph = DateTime.UtcNow.AddHours(8); // Philippine Time
                using (var conn = new MySqlConnection(connStr))
                {
                    conn.Open();
                    tx = conn.BeginTransaction();

                    // Check for existing open session today
                    string checkQuery = @"
                        SELECT attendance_id, attendance_status, time_in 
                        FROM Library_Attendance 
                        WHERE user_id = @id AND DATE(time_in) = CURDATE() AND time_out IS NULL
                        ORDER BY time_in DESC LIMIT 1";

                    int? existingId = null;
                    DateTime? timeIn = null;
                    string currentStatus = null;

                    using (var cmd = new MySqlCommand(checkQuery, conn, tx))
                    {
                        cmd.Parameters.AddWithValue("@id", userId);
                        using (var rdr = cmd.ExecuteReader())
                        {
                            if (rdr.Read())
                            {
                                existingId = Convert.ToInt32(rdr["attendance_id"]);
                                currentStatus = rdr["attendance_status"]?.ToString();
                                timeIn = rdr["time_in"] != DBNull.Value ? Convert.ToDateTime(rdr["time_in"]) : (DateTime?)null;
                            }
                        }
                    }

                    bool isCurrentlyInside = (existingId.HasValue && currentStatus == "Entry");

                    if (isCurrentlyInside)
                    {
                        // CHECKOUT
                        string updateQuery = @"
                            UPDATE Library_Attendance 
                            SET time_out = @t, attendance_status = 'Exited'
                            WHERE attendance_id = @id";

                        using (var cmd = new MySqlCommand(updateQuery, conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@t", ph);
                            cmd.Parameters.AddWithValue("@id", existingId.Value);
                            if (cmd.ExecuteNonQuery() > 0)
                            {
                                tx.Commit();
                                string durationMsg = "";
                                if (timeIn.HasValue)
                                {
                                    var duration = ph - timeIn.Value;
                                    if (duration.TotalMinutes >= 1)
                                        durationMsg = duration.TotalHours >= 1
                                            ? $" You stayed for {(int)duration.TotalHours}h {duration.Minutes}m."
                                            : $" You stayed for {duration.Minutes} minute(s).";
                                }
                                AuditLog.Log(currentUser, "CHECKOUT", "Library_Attendance", $"User {userId} checked out at {ph:hh:mm tt}");
                                return new { success = true, action = "checkout", message = $"✅ Checked out at {ph:hh:mm tt}!{durationMsg} Thank you!" };
                            }
                        }
                        tx.Rollback();
                        return new { success = false, message = "Check-out failed. Please try again." };
                    }
                    else
                    {
                        // CHECKIN
                        string insertQuery = @"
                            INSERT INTO Library_Attendance 
                            (user_id, time_in, purpose, entry_method, session_type, attendance_status, encoded_by) 
                            VALUES (@id, @t, @p, 'STAFF_ASSISTED', 'KIOSK_STAFF', 'Entry', @staff)";

                        using (var cmd = new MySqlCommand(insertQuery, conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@id", userId);
                            cmd.Parameters.AddWithValue("@t", ph);
                            cmd.Parameters.AddWithValue("@p", purpose);
                            cmd.Parameters.AddWithValue("@staff", currentUser);
                            if (cmd.ExecuteNonQuery() > 0)
                            {
                                tx.Commit();
                                AuditLog.Log(currentUser, "CHECKIN", "Library_Attendance", $"User {userId} checked in for purpose: {purpose}");
                                return new { success = true, action = "checkin", message = $"✅ Checked in at {ph:hh:mm tt}! Purpose: {purpose}. Welcome!" };
                            }
                        }
                        tx.Rollback();
                        return new { success = false, message = "Check-in failed. Please try again." };
                    }
                }
            }
            catch (Exception ex)
            {
                AuditLog.Log("SYSTEM", "ERROR", "Kiosk", $"RecordAttendance error: {ex.Message}");
                return new { success = false, message = "Server error. Please contact support." };
            }
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static List<string> GetPurposes()
        {
            // Return a static list or fetch from database
            return new List<string>
            {
                "Study / Self-review",
                "Research",
                "Borrow / Return Books",
                "Computer Use",
                "Group Work",
                "Reading",
                "Other"
            };
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static List<object> GetRecentActivity()
        {
            var activities = new List<object>();
            try
            {
                using (var conn = new MySqlConnection(connStr))
                {
                    conn.Open();
                    string query = @"
                        SELECT 
                            CONCAT(COALESCE(st.first_name, f.first_name, s.first_name, ''), ' ',
                                   COALESCE(st.last_name, f.last_name, s.last_name, '')) AS Name,
                            COALESCE(la.purpose, 'N/A') AS Purpose,
                            DATE_FORMAT(la.time_in, '%h:%i %s %p') AS TimeIn,
                            IF(la.time_out IS NOT NULL, DATE_FORMAT(la.time_out, '%h:%i %s %p'), '---') AS TimeOut,
                            la.attendance_status AS Status
                        FROM Library_Attendance la
                        LEFT JOIN Students st ON la.user_id = st.student_id
                        LEFT JOIN Faculty f ON la.user_id = f.faculty_id
                        LEFT JOIN Staff s ON la.user_id = s.staff_id
                        WHERE DATE(la.time_in) = CURDATE()
                        ORDER BY la.time_in DESC
                        LIMIT 20";

                    using (var cmd = new MySqlCommand(query, conn))
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            activities.Add(new
                            {
                                Name = rdr["Name"].ToString(),
                                Purpose = rdr["Purpose"].ToString(),
                                TimeIn = rdr["TimeIn"].ToString(),
                                TimeOut = rdr["TimeOut"].ToString(),
                                Status = rdr["Status"].ToString()
                            });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                AuditLog.Log("SYSTEM", "ERROR", "Kiosk", $"GetRecentActivity error: {ex.Message}");
            }
            return activities;
        }

        private static string DecryptIfNeeded(string input)
        {
            // Implement your decryption logic if QR codes are encrypted
            // For now, return null to indicate no decryption needed
            return null;
        }
    }
}