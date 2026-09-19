using ClosedXML.Excel;
using MySql.Data.MySqlClient;
using spmst_lms_development.Assets.Helper;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Web;
using System.Web.Script.Services;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Staff.Attendance
{
    /// <summary>
    /// AttendanceMonitor - Live dashboard for library entries/exits
    /// Supports Bootstrap 5 UI, real-time stats, chart.js integration, and SweetAlert notifications.
    /// </summary>
    public partial class AttendanceMonitor : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        // =====================================================================
        // PAGE LIFE-CYCLE EVENTS
        // =====================================================================
        protected void Page_Load(object sender, EventArgs e)
        {
            string currentUser = Session["UserID"]?.ToString() ?? "SYSTEM";

            if (!IsPostBack)
            {
                AuditLog.Log(currentUser, "VIEW", "AttendanceMonitor", "Accessed Attendance Monitor page");
                LoadDashboardStats();
                LoadAttendanceData();
            }
        }

        // =====================================================================
        // WEB METHODS (Called from client-side JavaScript for Chart.js)
        // =====================================================================
        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object GetHourlyChartData()
        {
            string currentUser = HttpContext.Current?.Session?["UserID"]?.ToString() ?? "SYSTEM";
            var labels = new List<string>();
            var values = new List<int>();

            try
            {
                string connStrLocal = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
                using (var conn = new MySqlConnection(connStrLocal))
                {
                    conn.Open();
                    // Generate hourly data from 7 AM to 9 PM
                    for (int i = 7; i <= 21; i++)
                    {
                        string label = i == 12 ? "12 PM" : (i < 12 ? $"{i} AM" : $"{i - 12} PM");
                        labels.Add(label);

                        string query = @"
                            SELECT COUNT(*) 
                            FROM Library_Attendance 
                            WHERE DATE(time_in) = CURDATE() 
                            AND HOUR(time_in) = @hour";
                        using (var cmd = new MySqlCommand(query, conn))
                        {
                            cmd.Parameters.AddWithValue("@hour", i);
                            int count = Convert.ToInt32(cmd.ExecuteScalar());
                            values.Add(count);
                        }
                    }
                }
                AuditLog.Log(currentUser, "API_CALL", "AttendanceMonitor", "GetHourlyChartData success");
                return new { labels, values };
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"GetHourlyChartData Error: {ex.Message}");
                AuditLog.Log(currentUser, "ERROR", "AttendanceMonitor", $"GetHourlyChartData error: {ex.Message}");
                // Return default empty data to avoid chart breakage
                for (int i = 7; i <= 21; i++)
                {
                    labels.Add(i == 12 ? "12 PM" : (i < 12 ? $"{i} AM" : $"{i - 12} PM"));
                    values.Add(0);
                }
                return new { labels, values };
            }
        }

        // =====================================================================
        // DATA LOADING METHODS (Stats + Attendance Grid)
        // =====================================================================

        /// <summary>
        /// Loads the five stat cards: patrons inside, peak rate, avg stay, total entries, peak time.
        /// </summary>
        private void LoadDashboardStats()
        {
            string currentUser = Session["UserID"]?.ToString() ?? "SYSTEM";
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                try
                {
                    conn.Open();

                    // 1. Patrons currently inside
                    string insideQuery = @"
                        SELECT COUNT(DISTINCT user_id) 
                        FROM Library_Attendance 
                        WHERE attendance_status = 'Entry' 
                        AND time_out IS NULL
                        AND DATE(time_in) = CURDATE()";
                    using (MySqlCommand cmd = new MySqlCommand(insideQuery, conn))
                    {
                        int inside = Convert.ToInt32(cmd.ExecuteScalar());
                        litPatronsInside.Text = inside.ToString();

                        // Compare with yesterday
                        string yesterdayQuery = @"
                            SELECT COUNT(DISTINCT user_id) 
                            FROM Library_Attendance 
                            WHERE DATE(time_in) = DATE_SUB(CURDATE(), INTERVAL 1 DAY)
                            AND attendance_status = 'Entry' AND time_out IS NULL";
                        using (MySqlCommand yestCmd = new MySqlCommand(yesterdayQuery, conn))
                        {
                            int yesterday = Convert.ToInt32(yestCmd.ExecuteScalar());
                            if (yesterday > 0 && inside > 0)
                            {
                                double percentChange = ((double)(inside - yesterday) / yesterday) * 100;
                                string trendClass = percentChange >= 0 ? "trend-up" : "trend-down";
                                string arrow = percentChange >= 0 ? "↑" : "↓";
                                litTrendInside.Text = $"<span class='{trendClass}'>{arrow} {Math.Abs(percentChange):F1}% vs yesterday</span>";
                            }
                            else if (inside > 0)
                                litTrendInside.Text = "<span class='trend-up'>📊 First entries today</span>";
                            else
                                litTrendInside.Text = "<span class='trend-up'>No entries yet</span>";
                        }
                    }

                    // 2. Total entries today
                    string totalQuery = "SELECT COUNT(*) FROM Library_Attendance WHERE DATE(time_in) = CURDATE()";
                    using (MySqlCommand cmd = new MySqlCommand(totalQuery, conn))
                        litTotalEntries.Text = Convert.ToInt32(cmd.ExecuteScalar()).ToString("N0");

                    // 3. Peak hour and count
                    string peakQuery = @"
                        SELECT HOUR(time_in) as hour, COUNT(*) as count 
                        FROM Library_Attendance 
                        WHERE DATE(time_in) = CURDATE() 
                        GROUP BY HOUR(time_in) 
                        ORDER BY count DESC LIMIT 1";
                    using (MySqlCommand cmd = new MySqlCommand(peakQuery, conn))
                    using (MySqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            int hour = Convert.ToInt32(reader["hour"]);
                            string ampm = hour >= 12 ? "PM" : "AM";
                            int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                            litPeakTime.Text = $"{displayHour}:00 {ampm}";
                            litPeakHour.Text = reader["count"].ToString();
                        }
                        else
                        {
                            litPeakTime.Text = "--:--";
                            litPeakHour.Text = "0";
                        }
                    }

                    // 4. Average stay duration (minutes)
                    string avgQuery = @"
                        SELECT AVG(TIMESTAMPDIFF(MINUTE, time_in, time_out)) 
                        FROM Library_Attendance 
                        WHERE DATE(time_in) = CURDATE() AND time_out IS NOT NULL";
                    using (MySqlCommand cmd = new MySqlCommand(avgQuery, conn))
                    {
                        object result = cmd.ExecuteScalar();
                        if (result != DBNull.Value && result != null)
                        {
                            int avgMinutes = Convert.ToInt32(result);
                            if (avgMinutes > 0)
                            {
                                int hours = avgMinutes / 60;
                                int minutes = avgMinutes % 60;
                                litAvgStay.Text = hours > 0 ? $"{hours}h {minutes}m" : $"{minutes}m";
                            }
                            else litAvgStay.Text = "N/A";
                        }
                        else litAvgStay.Text = "N/A";
                    }

                    AuditLog.Log(currentUser, "LOAD", "AttendanceMonitor", "Dashboard stats refreshed");
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Stats Error: {ex.Message}");
                    AuditLog.Log(currentUser, "ERROR", "AttendanceMonitor", $"LoadDashboardStats error: {ex.Message}");
                    SetDefaultStats();
                }
            }
        }

        private void SetDefaultStats()
        {
            litPatronsInside.Text = "0";
            litTotalEntries.Text = "0";
            litPeakTime.Text = "--:--";
            litPeakHour.Text = "0";
            litAvgStay.Text = "N/A";
            litTrendInside.Text = "";
        }

        /// <summary>
        /// Loads today's attendance records into GridView, supports search and pagination.
        /// </summary>
        private void LoadAttendanceData()
        {
            string currentUser = Session["UserID"]?.ToString() ?? "SYSTEM";
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                try
                {
                    conn.Open();
                    string searchFilter = txtSearch.Text.Trim();
                    string whereClause = "";

                    if (!string.IsNullOrEmpty(searchFilter))
                    {
                        whereClause = @" AND (
                            CONCAT(COALESCE(st.first_name, ''), ' ', COALESCE(st.last_name, '')) LIKE @search 
                            OR CONCAT(COALESCE(f.first_name, ''), ' ', COALESCE(f.last_name, '')) LIKE @search 
                            OR CONCAT(COALESCE(s.first_name, ''), ' ', COALESCE(s.last_name, '')) LIKE @search
                            OR la.user_id LIKE @search
                            OR la.purpose LIKE @search
                        )";
                    }

                    string query = $@"
                        SELECT 
                            la.attendance_id,
                            TRIM(CONCAT(
                                COALESCE(st.first_name, f.first_name, s.first_name, ''), 
                                ' ', 
                                COALESCE(st.last_name, f.last_name, s.last_name, '')
                            )) AS PatronName,
                            la.user_id AS IDNumber,
                            CASE 
                                WHEN st.student_id IS NOT NULL THEN 'Student'
                                WHEN f.faculty_id IS NOT NULL THEN 'Faculty'
                                WHEN s.staff_id IS NOT NULL THEN 'Staff'
                                ELSE 'Guest'
                            END AS UserType,
                            COALESCE(la.purpose, 'N/A') AS Purpose,
                            DATE_FORMAT(la.time_in, '%h:%i %s %p') AS TimeIn,
                            IF(la.time_out IS NOT NULL, DATE_FORMAT(la.time_out, '%h:%i %s %p'), '---:---:---') AS TimeOut,
                            CASE 
                                WHEN la.time_out IS NULL AND la.attendance_status = 'Entry' THEN 'IN'
                                ELSE 'OUT'
                            END AS Status
                        FROM Library_Attendance la
                        LEFT JOIN Students st ON la.user_id = st.student_id
                        LEFT JOIN Faculty f ON la.user_id = f.faculty_id
                        LEFT JOIN Staff s ON la.user_id = s.staff_id
                        WHERE DATE(la.time_in) = CURDATE() {whereClause}
                        ORDER BY la.time_in DESC";

                    DataTable dt = new DataTable();
                    using (MySqlDataAdapter da = new MySqlDataAdapter(query, conn))
                    {
                        if (!string.IsNullOrEmpty(searchFilter))
                            da.SelectCommand.Parameters.AddWithValue("@search", $"%{searchFilter}%");
                        da.Fill(dt);
                    }

                    gvAttendance.DataSource = dt;
                    gvAttendance.DataBind();

                    if (dt.Rows.Count > 0)
                    {
                        int start = gvAttendance.PageIndex * gvAttendance.PageSize + 1;
                        int end = Math.Min(start + gvAttendance.PageSize - 1, dt.Rows.Count);
                        litEntriesInfo.Text = $"Showing {start} to {end} of {dt.Rows.Count} entries (newest first)";
                    }
                    else
                    {
                        litEntriesInfo.Text = "No entries found for today";
                    }

                    if (!string.IsNullOrEmpty(searchFilter))
                        AuditLog.LogSearch(currentUser, searchFilter, "Library_Attendance");
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Attendance Error: {ex.Message}");
                    AuditLog.Log(currentUser, "ERROR", "AttendanceMonitor", $"LoadAttendanceData error: {ex.Message}");
                    gvAttendance.DataSource = null;
                    gvAttendance.DataBind();
                    litEntriesInfo.Text = "Error loading data";
                }
            }
        }

        // =====================================================================
        // BUTTON EVENT HANDLERS (Refresh, Search, Export, Pagination)
        // =====================================================================

        protected void btnRefresh_Click(object sender, EventArgs e)
        {
            string currentUser = Session["UserID"]?.ToString() ?? "SYSTEM";
            AuditLog.Log(currentUser, "REFRESH", "AttendanceMonitor", "Manual refresh requested");
            LoadDashboardStats();
            LoadAttendanceData();
            // Notify user via SweetAlert
            ScriptManager.RegisterStartupScript(this, GetType(), "refreshAlert",
                "Swal.fire({ icon: 'success', title: 'Refreshed', text: 'Dashboard updated.', toast: true, position: 'top-end', showConfirmButton: false, timer: 2000 });", true);
        }

        protected void TimerRefresh_Tick(object sender, EventArgs e)
        {
            string currentUser = Session["UserID"]?.ToString() ?? "SYSTEM";
            // Auto-refresh every 30 seconds – log occasionally
            if (DateTime.Now.Second % 30 == 0)
                AuditLog.Log(currentUser, "AUTO_REFRESH", "AttendanceMonitor", "Auto-refresh triggered");
            LoadDashboardStats();
            LoadAttendanceData();
        }

        protected void btnSearch_Click(object sender, EventArgs e)
        {
            gvAttendance.PageIndex = 0;
            LoadAttendanceData();
        }

        protected void btnExport_Click(object sender, EventArgs e)
        {
            string currentUser = Session["UserID"]?.ToString() ?? "SYSTEM";
            try
            {
                using (MySqlConnection conn = new MySqlConnection(connStr))
                {
                    conn.Open();
                    string query = @"
                        SELECT 
                            CONCAT(COALESCE(st.first_name, f.first_name, s.first_name, ''), ' ', 
                                   COALESCE(st.last_name, f.last_name, s.last_name, '')) AS 'Patron Name',
                            la.user_id AS 'ID Number',
                            CASE 
                                WHEN st.student_id IS NOT NULL THEN 'Student'
                                WHEN f.faculty_id IS NOT NULL THEN 'Faculty'
                                WHEN s.staff_id IS NOT NULL THEN 'Staff'
                                ELSE 'Guest'
                            END AS 'User Type',
                            COALESCE(la.purpose, 'N/A') AS 'Purpose',
                            DATE_FORMAT(la.time_in, '%Y-%m-%d %h:%i %s %p') AS 'Time In',
                            IF(la.time_out IS NOT NULL, DATE_FORMAT(la.time_out, '%Y-%m-%d %h:%i %s %p'), 'Not yet checked out') AS 'Time Out',
                            CASE 
                                WHEN la.time_out IS NULL AND la.attendance_status = 'Entry' THEN 'Currently Inside'
                                ELSE 'Exited'
                            END AS 'Status'
                        FROM Library_Attendance la
                        LEFT JOIN Students st ON la.user_id = st.student_id
                        LEFT JOIN Faculty f ON la.user_id = f.faculty_id
                        LEFT JOIN Staff s ON la.user_id = s.staff_id
                        WHERE DATE(la.time_in) = CURDATE()
                        ORDER BY la.time_in DESC";

                    using (var cmd = new MySqlCommand(query, conn))
                    using (var reader = cmd.ExecuteReader())
                    {
                        DataTable dt = new DataTable();
                        dt.Load(reader);
                        using (var wb = new XLWorkbook())
                        {
                            var ws = wb.Worksheets.Add(dt, "Attendance_" + DateTime.Now.ToString("yyyyMMdd"));
                            ws.Columns().AdjustToContents();

                            Response.Clear();
                            Response.Buffer = true;
                            Response.Charset = "";
                            Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                            Response.AddHeader("content-disposition", $"attachment;filename=Attendance_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx");
                            using (MemoryStream ms = new MemoryStream())
                            {
                                wb.SaveAs(ms);
                                ms.WriteTo(Response.OutputStream);
                                Response.Flush();
                                Response.End();
                            }
                        }
                    }
                }
                AuditLog.LogExport(currentUser, "Library_Attendance", $"Exported attendance data for {DateTime.Now:yyyy-MM-dd}");
            }
            catch (Exception ex)
            {
                AuditLog.Log(currentUser, "ERROR", "AttendanceMonitor", $"Export error: {ex.Message}");
                ScriptManager.RegisterStartupScript(this, GetType(), "exportError",
                    "Swal.fire({ icon: 'error', title: 'Export Failed', text: 'Could not generate Excel file. Please try again.', toast: true, position: 'top-end', showConfirmButton: false, timer: 4000 });", true);
            }
        }

        protected void gvAttendance_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            gvAttendance.PageIndex = e.NewPageIndex;
            LoadAttendanceData();
        }

        // Required for GridView rendering during export
        public override void VerifyRenderingInServerForm(Control control) { }
    }
}