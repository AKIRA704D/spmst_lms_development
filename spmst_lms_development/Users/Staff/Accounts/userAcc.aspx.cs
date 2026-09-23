using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Globalization;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Staff.Accounts
{
    public partial class UserAcc : System.Web.UI.Page
    {
        private string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private string currentUser = "";

        protected void Page_Load(object sender, EventArgs e)
        {
            currentUser = Session["UserID"]?.ToString() ?? "SYSTEM";

            if (!IsPostBack)
            {
                if (Request.QueryString["isFilter"] == "1")
                {
                    string role = Request.QueryString["role"];
                    if (role == "Student")
                        ViewState["CurrentFilter"] = "student";
                    else if (role == "Faculty")
                        ViewState["CurrentFilter"] = "faculty";
                    else
                        ViewState["CurrentFilter"] = "all";
                    BindFilteredPatrons();
                }
                else
                {
                    if (ViewState["CurrentFilter"] == null)
                        ViewState["CurrentFilter"] = "all";
                    LoadPatrons(ViewState["CurrentFilter"].ToString());
                }
                SetActiveTab();   // Ensure correct tab is highlighted
                this.DataBind();
            }
        }

        private void SetActiveTab()
        {
            string currentFilter = ViewState["CurrentFilter"]?.ToString() ?? "all";
            // Reset all
            tabAll.Attributes["class"] = "nav-link";
            tabFaculty.Attributes["class"] = "nav-link";
            tabStudent.Attributes["class"] = "nav-link";
            tabStaff.Attributes["class"] = "nav-link";

            switch (currentFilter.ToLower())
            {
                case "faculty":
                    tabFaculty.Attributes["class"] = "nav-link active";
                    break;
                case "student":
                    tabStudent.Attributes["class"] = "nav-link active";
                    break;
                case "staff":
                    tabStaff.Attributes["class"] = "nav-link active";
                    break;
                default:
                    tabAll.Attributes["class"] = "nav-link active";
                    break;
            }
        }

        private void BindFilteredPatrons()
        {
            string role = Request.QueryString["role"];
            string inst = Request.QueryString["inst"]?.Replace("'", "''");
            string prog = Request.QueryString["prog"]?.Replace("'", "''");
            string year = Request.QueryString["year"]?.Replace("'", "''");
            string stat = Request.QueryString["stat"];

            string sql = "";

            if (role == "Student")
            {
                sql = @"SELECT s.student_id as user_id, CONCAT(s.first_name, ' ', s.last_name) as full_name, 
                        s.extension_name as ext_name, s.gender, s.institute, s.course, '' as section, s.year_level, 
                        u.role as display_role, CAST(u.is_active AS SIGNED) as is_active, '' as office_dept
                        FROM Students s INNER JOIN Users u ON s.student_id = u.user_id WHERE 1=1";
                if (!string.IsNullOrEmpty(inst)) sql += " AND s.institute = '" + inst + "'";
                if (!string.IsNullOrEmpty(prog)) sql += " AND s.course = '" + prog + "'";
                if (!string.IsNullOrEmpty(year)) sql += " AND s.year_level = '" + year + "'";
            }
            else if (role == "Faculty")
            {
                sql = @"SELECT f.faculty_id as user_id, CONCAT(f.first_name, ' ', f.last_name) as full_name, 
                        f.extension_name as ext_name, f.gender, f.institute, '' as course, '' as section, '' as year_level, 
                        u.role as display_role, CAST(u.is_active AS SIGNED) as is_active, '' as office_dept
                        FROM Faculty f INNER JOIN Users u ON f.faculty_id = u.user_id WHERE 1=1";
                if (!string.IsNullOrEmpty(inst)) sql += " AND f.institute = '" + inst + "'";
            }
            else
            {
                sql = @"SELECT u.user_id, u.role as display_role, CAST(u.is_active AS SIGNED) as is_active,
                        COALESCE(CONCAT(s.first_name, ' ', s.last_name), CONCAT(f.first_name, ' ', f.last_name)) as full_name,
                        COALESCE(s.extension_name, f.extension_name, '') as ext_name,
                        COALESCE(s.gender, f.gender, '') as gender,
                        COALESCE(s.institute, f.institute, '') as institute,
                        COALESCE(s.course, '') as course,
                        '' as section,
                        COALESCE(s.year_level, '') as year_level, '' as office_dept
                        FROM Users u
                        LEFT JOIN Students s ON u.user_id = s.student_id
                        LEFT JOIN Faculty f ON u.user_id = f.faculty_id
                        WHERE u.role IN ('Student', 'Faculty')";
                if (!string.IsNullOrEmpty(inst)) sql += " AND (s.institute = '" + inst + "' OR f.institute = '" + inst + "')";
            }

            if (!string.IsNullOrEmpty(stat)) sql += " AND u.is_active = " + stat;

            DataTable dt = ExecuteQuery(sql);
            rptPatrons.DataSource = dt;
            rptPatrons.DataBind();
        }

        protected void FilterTab_Click(object sender, EventArgs e)
        {
            System.Web.UI.HtmlControls.HtmlButton btn = (System.Web.UI.HtmlControls.HtmlButton)sender;
            string filter = btn.ID.Replace("tab", "").ToLower();
            ViewState["CurrentFilter"] = filter;
            SetActiveTab();               // Update active tab class
            LoadPatrons(filter, txtSearch.Text.Trim());
            // No need to DataBind here; LoadPatrons already binds the repeater
        }

        protected void HandleAccountAction(object sender, CommandEventArgs e)
        {
            string userId = e.CommandArgument.ToString();
            ToggleAccountStatus(userId);
        }

        private void ToggleAccountStatus(string userId)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                try
                {
                    conn.Open();
                    string checkSql = "SELECT CAST(is_active AS SIGNED) FROM Users WHERE user_id = @id";
                    int currentStatus = 0;
                    using (MySqlCommand checkCmd = new MySqlCommand(checkSql, conn))
                    {
                        checkCmd.Parameters.AddWithValue("@id", userId);
                        object result = checkCmd.ExecuteScalar();
                        if (result != null && result != DBNull.Value)
                            currentStatus = Convert.ToInt32(result);
                    }

                    int newStatus = (currentStatus == 2) ? 1 : 2;
                    string updateSql = "UPDATE Users SET is_active = @status WHERE user_id = @id";
                    using (MySqlCommand updateCmd = new MySqlCommand(updateSql, conn))
                    {
                        updateCmd.Parameters.Add("@status", MySqlDbType.Int32).Value = newStatus;
                        updateCmd.Parameters.Add("@id", MySqlDbType.VarChar).Value = userId;
                        if (updateCmd.ExecuteNonQuery() > 0)
                        {
                            ShowSweetAlert(newStatus == 1 ? "Account re-activated successfully." : "Account deactivated successfully.", "success");
                        }
                        else
                        {
                            ShowSweetAlert("Error: User ID not found.", "error");
                        }
                    }

                    string filter = ViewState["CurrentFilter"]?.ToString() ?? "all";
                    LoadPatrons(filter);
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Database Error: " + ex.Message, "error");
                }
            }
        }

        private void LoadPatrons(string filter, string searchTerm = "")
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                string sql = "";
                bool hasSearch = !string.IsNullOrEmpty(searchTerm);

                switch (filter.ToLower())
                {
                    case "student":
                        string studentSearch = hasSearch ? " AND (s.student_id LIKE @search OR s.first_name LIKE @search OR s.last_name LIKE @search OR s.course LIKE @search)" : "";
                        sql = $@"SELECT s.student_id as user_id, CONCAT(s.first_name, ' ', s.last_name) as full_name, 
                                s.extension_name as ext_name, s.gender, s.institute, s.course, s.section, s.year_level, 
                                u.role as display_role, CAST(u.is_active AS SIGNED) as is_active, '' as office_dept 
                                FROM Students s INNER JOIN Users u ON s.student_id = u.user_id 
                                WHERE 1=1 {studentSearch}";
                        break;
                    case "faculty":
                        string facultySearch = hasSearch ? " AND (f.faculty_id LIKE @search OR f.first_name LIKE @search OR f.last_name LIKE @search)" : "";
                        sql = $@"SELECT f.faculty_id as user_id, CONCAT(f.first_name, ' ', f.last_name) as full_name, 
                                f.extension_name as ext_name, f.gender, f.institute, '' as course, '' as section, '' as year_level, 
                                u.role as display_role, CAST(u.is_active AS SIGNED) as is_active, '' as office_dept 
                                FROM Faculty f INNER JOIN Users u ON f.faculty_id = u.user_id 
                                WHERE 1=1 {facultySearch}";
                        break;
                    case "staff":
                        string staffSearch = hasSearch ? " AND (st.staff_id LIKE @search OR st.first_name LIKE @search OR st.last_name LIKE @search OR st.office_department LIKE @search)" : "";
                        sql = $@"SELECT st.staff_id as user_id, CONCAT(st.first_name, ' ', st.last_name) as full_name, 
                                '' as ext_name, '' as gender, 'Library' as institute, '' as course, '' as section, '' as year_level, 
                                u.role as display_role, CAST(u.is_active AS SIGNED) as is_active, st.office_department as office_dept 
                                FROM Staff st INNER JOIN Users u ON st.staff_id = u.user_id 
                                WHERE 1=1 {staffSearch}";
                        break;
                    default:
                        string allSearch = hasSearch ? " AND (u.user_id LIKE @search OR s.first_name LIKE @search OR s.last_name LIKE @search OR f.first_name LIKE @search OR f.last_name LIKE @search OR s.course LIKE @search)" : "";
                        sql = $@"SELECT u.user_id, u.role as display_role, CAST(u.is_active AS SIGNED) as is_active,
                              COALESCE(CONCAT(s.first_name, ' ', s.last_name), CONCAT(f.first_name, ' ', f.last_name)) as full_name,
                              COALESCE(s.extension_name, f.extension_name, '') as ext_name,
                              COALESCE(s.gender, f.gender, '') as gender,
                              COALESCE(s.institute, f.institute) as institute,
                              COALESCE(s.course, '') as course,
                              COALESCE(s.year_level, '') as year_level,
                              '' as office_dept
                              FROM Users u
                              LEFT JOIN Students s ON u.user_id = s.student_id
                              LEFT JOIN Faculty f ON u.user_id = f.faculty_id
                              WHERE u.role IN ('Student', 'Faculty') {allSearch}";
                        break;
                }

                try
                {
                    conn.Open();
                    using (MySqlCommand cmd = new MySqlCommand(sql, conn))
                    {
                        if (hasSearch)
                            cmd.Parameters.AddWithValue("@search", "%" + searchTerm + "%");
                        MySqlDataAdapter da = new MySqlDataAdapter(cmd);
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        rptPatrons.DataSource = dt;
                        rptPatrons.DataBind();
                    }
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Search Error: " + ex.Message, "error");
                }
            }
        }

        private DataTable ExecuteQuery(string sql)
        {
            DataTable dt = new DataTable();
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                using (MySqlCommand cmd = new MySqlCommand(sql, conn))
                {
                    conn.Open();
                    using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                        da.Fill(dt);
                }
            }
            return dt;
        }

        private void ShowSweetAlert(string message, string icon)
        {
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"showSwal('Notification', '{cleanMsg}', '{icon}');";
            ScriptManager.RegisterStartupScript(this, GetType(), "swal", script, true);
        }

        protected void txtSearch_TextChanged(object sender, EventArgs e)
        {
            string filter = ViewState["CurrentFilter"]?.ToString() ?? "all";
            LoadPatrons(filter, txtSearch.Text.Trim());
        }

        protected void btnRefreshTable_Click(object sender, EventArgs e)
        {
            string filter = ViewState["CurrentFilter"]?.ToString() ?? "all";
            LoadPatrons(filter, txtSearch.Text.Trim());
            upMain.Update();
        }
    }
}