using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Admin.Dashboard
{
    public partial class adminDashAa : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                RefreshUI();
            }
        }

        private void RefreshUI()
        {
            UpdateOccupancyStats();
            LoadAttendance(GetCurrentFilter(), txtSearch.Text.Trim());
            UpdateStayDuration();
        }

        private string GetCurrentFilter()
        {
            if (lnkFaculty.CssClass.Contains("active")) return "Faculty";
            if (lnkStudent.CssClass.Contains("active")) return "Student";
            return "All";
        }

        private void UpdateStayDuration()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string sql = @"
                    SELECT 
                        AVG(CASE WHEN f.faculty_id IS NOT NULL THEN TIMESTAMPDIFF(MINUTE, la.time_in, la.time_out) END) as FacultyAvg,
                        AVG(CASE WHEN s.student_id IS NOT NULL THEN TIMESTAMPDIFF(MINUTE, la.time_in, la.time_out) END) as StudentAvg
                    FROM Library_Attendance la
                    LEFT JOIN Students s ON la.user_id = s.student_id
                    LEFT JOIN Faculty f ON la.user_id = f.faculty_id
                    WHERE la.time_out IS NOT NULL";
                try
                {
                    conn.Open();
                    using (MySqlCommand cmd = new MySqlCommand(sql, conn))
                    using (MySqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            double facMin = reader["FacultyAvg"] != DBNull.Value ? Convert.ToDouble(reader["FacultyAvg"]) : 0;
                            double stuMin = reader["StudentAvg"] != DBNull.Value ? Convert.ToDouble(reader["StudentAvg"]) : 0;

                            litFacultyAvg.Text = FormatDuration(facMin);
                            litStudentAvg.Text = FormatDuration(stuMin);

                            double total = facMin + stuMin;
                            double facPercent = (total > 0) ? (facMin / total) * 100 : 50;
                            chartCircle.Style["background"] = $"conic-gradient(#0d6efd 0% {facPercent}%, #198754 {facPercent}% 100%)";
                        }
                    }
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Error", "Failed to load stay duration: " + ex.Message, "error");
                }
            }
        }

        private string FormatDuration(double minutes)
        {
            if (minutes >= 60)
                return (minutes / 60.0).ToString("0.#") + "h";
            return Math.Round(minutes) + "m";
        }

        private void UpdateOccupancyStats()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string sql = @"
                    SELECT 
                        COUNT(*) as Total,
                        SUM(CASE WHEN purpose = 'Study' THEN 1 ELSE 0 END) as GeneralArea,
                        SUM(CASE WHEN purpose = 'Research' THEN 1 ELSE 0 END) as VirtualRoom
                    FROM Library_Attendance 
                    WHERE attendance_status = 'Entry' AND time_out IS NULL";
                try
                {
                    conn.Open();
                    using (MySqlCommand cmd = new MySqlCommand(sql, conn))
                    using (MySqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            int total = reader["Total"] != DBNull.Value ? Convert.ToInt32(reader["Total"]) : 0;
                            int general = reader["GeneralArea"] != DBNull.Value ? Convert.ToInt32(reader["GeneralArea"]) : 0;
                            int virtualRoom = reader["VirtualRoom"] != DBNull.Value ? Convert.ToInt32(reader["VirtualRoom"]) : 0;

                            UpdateBar(pbTotal, litCurrentOccupancy, lblTotalPercent, total, 100);
                            UpdateBar(pbGeneral, litGeneralCount, null, general, 80);
                            UpdateBar(pbVirtual, litVirtualCount, null, virtualRoom, 20);
                        }
                    }
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Error", "Failed to load occupancy stats: " + ex.Message, "error");
                }
            }
        }

        private void UpdateBar(System.Web.UI.HtmlControls.HtmlGenericControl bar, Literal lit, System.Web.UI.HtmlControls.HtmlGenericControl percentLbl, int count, int capacity)
        {
            double percentage = (capacity > 0) ? ((double)count / capacity) * 100 : 0;
            if (percentage > 100) percentage = 100;

            if (lit != null) lit.Text = count.ToString();
            if (bar != null)
            {
                bar.Style["width"] = percentage.ToString("0") + "%";
                if (bar.ID == "pbTotal")
                {
                    if (percentage > 85) bar.Attributes["class"] = "progress-bar bg-danger";
                    else if (percentage > 50) bar.Attributes["class"] = "progress-bar bg-warning";
                    else bar.Attributes["class"] = "progress-bar bg-success";
                }
            }
            if (percentLbl != null) percentLbl.InnerText = percentage.ToString("0") + "%";
        }

        private void LoadAttendance(string type, string searchTerm = "")
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string sql = @"
                    SELECT 
                        COALESCE(CONCAT(s.first_name, ' ', s.last_name), CONCAT(f.first_name, ' ', f.last_name)) as FullName,
                        la.user_id as UserID,
                        COALESCE(s.institute, f.institute) as Institute,
                        COALESCE(s.course, 'N/A') as Program,
                        la.purpose as Purpose,
                        COALESCE(s.year_level, '-') as Year,
                        la.time_in as Login,
                        la.time_out as Logout,
                        CASE WHEN la.attendance_status = 'Entry' THEN 'IN' ELSE 'OUT' END as Status
                    FROM Library_Attendance la
                    LEFT JOIN Students s ON la.user_id = s.student_id
                    LEFT JOIN Faculty f ON la.user_id = f.faculty_id
                    WHERE 1=1";
                if (type == "Faculty") sql += " AND f.faculty_id IS NOT NULL";
                else if (type == "Student") sql += " AND s.student_id IS NOT NULL";
                if (!string.IsNullOrEmpty(searchTerm))
                    sql += " AND (s.first_name LIKE @search OR s.last_name LIKE @search OR f.first_name LIKE @search OR f.last_name LIKE @search OR la.user_id LIKE @search)";
                sql += " ORDER BY la.time_in DESC";

                try
                {
                    conn.Open();
                    using (MySqlCommand cmd = new MySqlCommand(sql, conn))
                    {
                        if (!string.IsNullOrEmpty(searchTerm))
                            cmd.Parameters.AddWithValue("@search", "%" + searchTerm + "%");
                        DataTable dt = new DataTable();
                        using (MySqlDataAdapter da = new MySqlDataAdapter(cmd)) { da.Fill(dt); }
                        gvAttendance.DataSource = dt;
                        gvAttendance.DataBind();
                        litCount.Text = dt.Rows.Count.ToString();
                    }
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Error", "Failed to load attendance: " + ex.Message, "error");
                }
            }
        }

        protected void Filter_Click(object sender, EventArgs e)
        {
            LinkButton btn = (LinkButton)sender;
            lnkAll.CssClass = "nav-link";
            lnkFaculty.CssClass = "nav-link";
            lnkStudent.CssClass = "nav-link";
            btn.CssClass = "nav-link active";
            RefreshUI();
        }

        protected void txtSearch_TextChanged(object sender, EventArgs e)
        {
            RefreshUI();
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"Swal.fire({{ title: '{cleanTitle}', text: '{cleanMsg}', icon: '{icon}', confirmButtonColor: '#0d6efd' }});";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }
    }
}