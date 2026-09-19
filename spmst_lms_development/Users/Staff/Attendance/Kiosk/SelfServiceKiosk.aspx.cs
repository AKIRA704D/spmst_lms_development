using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Web.Script.Services;
using System.Web.Services;
using System.Web.UI;
using spmst_lms_development.Assets.Helper;   // adjust if needed

namespace spmst_lms_development.Users.Staff.Attendance.Kiosk   // ← changed to match .aspx Inherits
{
    public partial class SelfServiceKiosk : Page
    {
        private static readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private static readonly string EncryptionKey = "SPAMAST_LMS_SECURE_KEY_2026";
        private static string currentUser = "SELF_KIOSK";

        // =====================================================================
        // PAGE LOAD
        // =====================================================================
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session != null && Session["UserID"] != null)
                currentUser = Session["UserID"].ToString();

            if (!IsPostBack)
            {
                DateTime ph = DateTime.UtcNow.AddHours(8);
                litDateTime.Text = ph.ToString("dddd, MMMM dd, yyyy");
                litDateHeader.Text = ph.ToString("MMMM dd, yyyy");

                int month = ph.Month;
                string sem = month >= 8 && month <= 12 ? "1st Semester"
                             : month >= 1 && month <= 5 ? "2nd Semester"
                             : "Summer";
                int sy1 = month >= 8 ? ph.Year : ph.Year - 1;
                int sy2 = sy1 + 1;
                litSemHeader.Text = $"SY: {sy1}–{sy2} | {sem}";

                string staffId = Request.QueryString["staff"];
                string sessionId = Request.QueryString["session"];
                if (!string.IsNullOrEmpty(staffId) && !string.IsNullOrEmpty(sessionId))
                    hfCurrentStaff.Value = staffId;

                AuditLog.Log(currentUser, "VIEW", "SelfServiceKiosk", "Page accessed");
            }
        }

        // =====================================================================
        // BUTTON LOGIN CLICK (server-side fallback)
        // =====================================================================
        protected void btnLogin_Click(object sender, EventArgs e)
        {
            string userId = hfUserId.Value;
            string purpose = ddlPurpose.SelectedValue;

            if (string.IsNullOrEmpty(userId))
            {
                RegisterAlert("error", "Please verify your ID first.");
                return;
            }

            if (hfCurrentStatus.Value != "Entry" && (string.IsNullOrEmpty(purpose) || purpose == "Select…"))
            {
                RegisterAlert("error", "Please select a valid purpose for your visit.");
                return;
            }

            var result = RecordAttendanceLocal(userId, purpose);
            if (result.success)
            {
                string action = result.action == "checkin" ? "Check-in Successful!" : "Check-out Successful!";
                string escaped = EscapeJs(result.message);
                AuditLog.Log(currentUser, result.action == "checkin" ? "CHECKIN" : "CHECKOUT",
                    "Library_Attendance", $"User {userId} {result.action} at self-service kiosk.");
                ClientScript.RegisterStartupScript(GetType(), "ok",
                    $"Swal.fire({{icon:'success',title:'{action}',text:'{escaped}'," +
                    "timer:3000,showConfirmButton:true,confirmButtonColor:'#1b4d2e'}}).then(() => { resetAllFields(); });", true);
            }
            else
            {
                AuditLog.Log(currentUser, "ATTENDANCE_FAILED", "Library_Attendance", $"Failed for {userId}: {result.message}");
                RegisterAlert("error", result.message);
            }
        }

        private void RegisterAlert(string icon, string message) =>
            ClientScript.RegisterStartupScript(GetType(), "alert",
                $"Swal.fire({{icon:'{icon}',text:'{EscapeJs(message)}',confirmButtonColor:'#1b4d2e'}});", true);

        // =====================================================================
        // LOCAL RECORD ATTENDANCE (same as web method but used for server postback)
        // =====================================================================
        private RecordResult RecordAttendanceLocal(string userId, string purpose)
        {
            MySqlTransaction tx = null;
            try
            {
                DateTime ph = DateTime.UtcNow.AddHours(8);
                using (var conn = new MySqlConnection(_connStr))
                {
                    conn.Open();
                    tx = conn.BeginTransaction();

                    int? existingId = null;
                    DateTime? timeIn = null;
                    string currentStatus = null;

                    using (var cmd = new MySqlCommand(
                        @"SELECT attendance_id, attendance_status, time_in
                          FROM Library_Attendance
                          WHERE user_id = @id AND DATE(time_in) = CURDATE() AND time_out IS NULL
                          ORDER BY time_in DESC LIMIT 1", conn, tx))
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

                    bool inside = existingId.HasValue && currentStatus == "Entry";

                    if (inside)
                    {
                        using (var cmd = new MySqlCommand(
                            "UPDATE Library_Attendance SET time_out = @t, attendance_status = 'Exited' WHERE attendance_id = @aid",
                            conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@t", ph);
                            cmd.Parameters.AddWithValue("@aid", existingId.Value);
                            if (cmd.ExecuteNonQuery() > 0)
                            {
                                tx.Commit();
                                string dur = BuildDuration(ph, timeIn);
                                return new RecordResult { success = true, action = "checkout", message = $"✅ Checked out at {ph:hh:mm tt}!{dur} Thank you!" };
                            }
                        }
                        tx.Rollback();
                        return new RecordResult { success = false, message = "Failed to update check-out record." };
                    }
                    else
                    {
                        using (var cmd = new MySqlCommand(
                            @"INSERT INTO Library_Attendance
                              (user_id, time_in, purpose, entry_method, session_type, attendance_status, encoded_by)
                              VALUES(@id, @t, @p, 'QR_SCAN', 'KIOSK_SELF_SERVICE', 'Entry', 'SELF_KIOSK')", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@id", userId);
                            cmd.Parameters.AddWithValue("@t", ph);
                            cmd.Parameters.AddWithValue("@p", purpose);
                            if (cmd.ExecuteNonQuery() > 0)
                            {
                                tx.Commit();
                                return new RecordResult { success = true, action = "checkin", message = $"✅ Checked in at {ph:hh:mm tt}! Purpose: {purpose}. Welcome!" };
                            }
                        }
                        tx.Rollback();
                        return new RecordResult { success = false, message = "Failed to insert check-in record." };
                    }
                }
            }
            catch (Exception ex)
            {
                tx?.Rollback();
                AuditLog.Log("SYSTEM", "ERROR", "SelfServiceKiosk", $"RecordAttendanceLocal error: {ex.Message}");
                return new RecordResult { success = false, message = $"Error: {ex.Message}" };
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
                string userId = DecryptString(inputData);
                if (string.IsNullOrEmpty(userId)) userId = inputData;

                using (var conn = new MySqlConnection(_connStr))
                {
                    conn.Open();
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
                                AuditLog.Log(currentUser, "VERIFY_FAILED", "SelfServiceKiosk", $"User {userId} not found");
                                return new VerifyResult { success = false, message = "User not found or account is inactive." };
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

                    AuditLog.Log(currentUser, "VERIFY", "SelfServiceKiosk", $"Verified {userId} - {fullName} - Status: {currentStatus}");
                    return new VerifyResult
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
                AuditLog.Log("SYSTEM", "ERROR", "SelfServiceKiosk", $"VerifyUser error: {ex.Message}");
                return new VerifyResult { success = false, message = $"Error: {ex.Message}" };
            }
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static RecordResult RecordAttendance(string userId, string purpose)
        {
            MySqlTransaction tx = null;
            try
            {
                DateTime ph = DateTime.UtcNow.AddHours(8);
                using (var conn = new MySqlConnection(_connStr))
                {
                    conn.Open();
                    tx = conn.BeginTransaction();

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
                                    TimeSpan duration = ph - timeIn.Value;
                                    if (duration.TotalMinutes >= 1)
                                        durationMsg = duration.TotalHours >= 1
                                            ? $" You stayed for {(int)duration.TotalHours}h {duration.Minutes}m."
                                            : $" You stayed for {duration.Minutes} minute(s).";
                                }
                                AuditLog.Log(currentUser, "CHECKOUT", "Library_Attendance", $"User {userId} checked out at {ph:hh:mm tt}");
                                return new RecordResult { success = true, action = "checkout", message = $"✅ Checked out at {ph:hh:mm tt}!{durationMsg} Thank you!" };
                            }
                        }
                        tx.Rollback();
                        return new RecordResult { success = false, message = "Failed to update check-out record." };
                    }
                    else
                    {
                        string insertQuery = @"
                            INSERT INTO Library_Attendance 
                            (user_id, time_in, purpose, entry_method, session_type, attendance_status, encoded_by) 
                            VALUES (@id, @t, @p, 'QR_SCAN', 'KIOSK_SELF_SERVICE', 'Entry', 'SELF_KIOSK')";
                        using (var cmd = new MySqlCommand(insertQuery, conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@id", userId);
                            cmd.Parameters.AddWithValue("@t", ph);
                            cmd.Parameters.AddWithValue("@p", purpose);
                            if (cmd.ExecuteNonQuery() > 0)
                            {
                                tx.Commit();
                                AuditLog.Log(currentUser, "CHECKIN", "Library_Attendance", $"User {userId} checked in for purpose: {purpose}");
                                return new RecordResult { success = true, action = "checkin", message = $"✅ Checked in at {ph:hh:mm tt}! Purpose: {purpose}. Welcome!" };
                            }
                        }
                        tx.Rollback();
                        return new RecordResult { success = false, message = "Failed to insert check-in record." };
                    }
                }
            }
            catch (Exception ex)
            {
                tx?.Rollback();
                AuditLog.Log("SYSTEM", "ERROR", "Library_Attendance", $"RecordAttendance web method error: {ex.Message}");
                return new RecordResult { success = false, message = $"Error: {ex.Message}" };
            }
        }

        // =====================================================================
        // HELPER METHODS
        // =====================================================================
        private static string BuildDuration(DateTime now, DateTime? timeIn)
        {
            if (!timeIn.HasValue) return "";
            var ts = now - timeIn.Value;
            if (ts.TotalMinutes < 1) return "";
            return ts.TotalHours >= 1
                ? $" You stayed for {(int)ts.TotalHours}h {ts.Minutes}m."
                : $" You stayed for {ts.Minutes} minute(s).";
        }

        public static string DecryptString(string cipherText)
        {
            try
            {
                cipherText = cipherText.Replace(" ", "+");
                byte[] bytes = Convert.FromBase64String(cipherText);
                using (Aes aes = Aes.Create())
                {
                    var pdb = new Rfc2898DeriveBytes(EncryptionKey,
                        new byte[] { 0x49, 0x76, 0x61, 0x6e, 0x20, 0x4d, 0x65, 0x64, 0x76, 0x65, 0x64, 0x65, 0x76 });
                    aes.Key = pdb.GetBytes(32);
                    aes.IV = pdb.GetBytes(16);
                    using (var ms = new MemoryStream())
                    using (var cs = new CryptoStream(ms, aes.CreateDecryptor(), CryptoStreamMode.Write))
                    {
                        cs.Write(bytes, 0, bytes.Length);
                        cs.Close();
                        return Encoding.Unicode.GetString(ms.ToArray());
                    }
                }
            }
            catch
            {
                return null;
            }
        }

        private static string EscapeJs(string s) =>
            (s ?? "").Replace("\\", "\\\\").Replace("'", "\\'").Replace("\r", "").Replace("\n", " ");

        // DTO classes
        public class VerifyResult
        {
            public bool success { get; set; }
            public string message { get; set; }
            public string userId { get; set; }
            public string fullName { get; set; }
            public string institute { get; set; }
            public string status { get; set; }
            public string lastPurpose { get; set; }
        }

        public class RecordResult
        {
            public bool success { get; set; }
            public string message { get; set; }
            public string action { get; set; }
        }
    }
}