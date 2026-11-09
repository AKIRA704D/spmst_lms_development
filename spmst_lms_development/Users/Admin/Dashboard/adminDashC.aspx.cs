using DocumentFormat.OpenXml.Office.Word;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Admin.Dashboard
{
    public partial class adminDashC : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        // =================================================================
        // ROLE-BASED TAB VISIBILITY
        // =================================================================
        protected bool ShowCircTab
        {
            get
            {
                string r = sessionHelper.UserRole;
                return r == sessionHelper.RoleAdmin || r == sessionHelper.RoleStaffC;
            }
        }

        protected bool ShowPatronTab
        {
            get
            {
                string r = sessionHelper.UserRole;
                return r == sessionHelper.RoleAdmin || r == sessionHelper.RoleStaffM;
            }
        }

        protected bool ShowAttendTab
        {
            get
            {
                string r = sessionHelper.UserRole;
                return r == sessionHelper.RoleAdmin || r == sessionHelper.RoleStaffM;
            }
        }

        /// <summary>Returns the key of the first visible tab for this role.</summary>
        protected string PrimaryTab
        {
            get
            {
                if (ShowCircTab) return "circ";
                if (ShowPatronTab) return "patron";
                if (ShowAttendTab) return "attend";
                return "";
            }
        }

        /// <summary>Returns "active" if the supplied tab is the primary tab for this role.</summary>
        protected string ActiveTabClass(string tabKey)
        {
            return PrimaryTab == tabKey ? "active" : "";
        }

        /// <summary>Returns "show active" if the supplied pane is the primary pane for this role.</summary>
        protected string ActivePaneClass(string tabKey)
        {
            return PrimaryTab == tabKey ? "show active" : "";
        }

        // =================================================================
        // PAGE LOAD
        // =================================================================
        protected void Page_Load(object sender, EventArgs e)
        {
            // --- Access check: only Admin / StaffC / StaffM may view this page ---
            string role = sessionHelper.UserRole;
            bool isAuthorized = role == sessionHelper.RoleAdmin
                             || role == sessionHelper.RoleStaffC
                             || role == sessionHelper.RoleStaffM;

            if (!isAuthorized)
            {
                Response.Redirect(sessionHelper.GetDashboardPath());
                return;
            }

            // --- Apply tab visibility (every request, so postbacks keep state) ---
            phTabCirc.Visible = ShowCircTab;
            phTabPatron.Visible = ShowPatronTab;
            phTabAttend.Visible = ShowAttendTab;
            phCircPanel.Visible = ShowCircTab;
            phPatronPanel.Visible = ShowPatronTab;
            phAttendPanel.Visible = ShowAttendTab;

            if (!IsPostBack)
            {
                txtDateFrom.Text = DateTime.Now.AddDays(-30).ToString("yyyy-MM-dd");
                txtDateTo.Text = DateTime.Now.ToString("yyyy-MM-dd");

                // --- Only load Circulation data if the role is allowed to see it ---
                if (ShowCircTab)
                {
                    LoadDashboardStats();
                    LoadUnifiedAnalytics(txtDateFrom.Text, txtDateTo.Text);
                    LoadTopBorrowedData();
                    if (analyticsFrame != null)
                        analyticsFrame.Attributes["src"] = "Analytics/Analytics_LowCirc.aspx";
                }
            }
        }

        protected void btnFilter_Click(object sender, EventArgs e)
        {
            if (!ShowCircTab) return; // defence-in-depth
            LoadUnifiedAnalytics(txtDateFrom.Text, txtDateTo.Text);
        }

        // =================================================================
        // DATA LOADERS (unchanged logic)
        // =================================================================
        private void LoadDashboardStats()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT 
                        (SELECT COUNT(*) FROM Library_Attendance la 
                            INNER JOIN Faculty f ON la.user_id = f.faculty_id) as FacultyVisits,
                        (SELECT COUNT(*) FROM Transactions WHERE status = 'Borrowed') as Circulated,
                        (SELECT COUNT(*) FROM Transactions 
                            WHERE status = 'Borrowed' AND due_date < CURDATE()) as OverdueCount,
                        (SELECT IFNULL(SUM(fine_amount - amount_paid), 0) 
                            FROM Penalties) as PendingTotal,
                        (SELECT COUNT(DISTINCT user_id) FROM Library_Attendance) as ActivePatrons,
                        (SELECT COUNT(*) FROM Item_Copies WHERE status_condition = 'Damage') as DamageCount,
                        (SELECT COUNT(*) FROM Item_Copies WHERE status_condition = 'Lost') as LostCount,
                        (SELECT IFNULL(SUM(amount_paid), 0) FROM Penalties) as Collected";
                conn.Open();
                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                using (MySqlDataReader dr = cmd.ExecuteReader())
                {
                    if (dr.Read())
                    {
                        litFacultyVisits.Text = dr["FacultyVisits"].ToString();
                        litCirculated.Text = dr["Circulated"].ToString();
                        litOverdue.Text = dr["OverdueCount"].ToString();
                        litPendingFines.Text = Convert.ToDecimal(dr["PendingTotal"]).ToString("N0");
                        litActivePatrons.Text = dr["ActivePatrons"].ToString();
                        litDamageFines.Text = dr["DamageCount"].ToString();
                        litLostBooks.Text = dr["LostCount"].ToString();
                        litFinesCollected.Text = (Convert.ToDouble(dr["Collected"]) / 1000.0).ToString("N1") + "k";
                    }
                }
            }
        }

        private void LoadUnifiedAnalytics(string start, string end)
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                conn.Open();

                string sectionJson = GetJsonData(
                    @"SELECT lr.section, COUNT(t.transaction_id) as count 
                      FROM Transactions t 
                      JOIN Item_Copies ic ON t.accession_number = ic.accession_number 
                      JOIN Library_Resources lr ON ic.resource_id = lr.resource_id 
                      WHERE t.borrow_date BETWEEN @start AND @end 
                      GROUP BY lr.section 
                      ORDER BY count DESC 
                      LIMIT 10", conn, "section", start, end);

                string subjectJson = GetJsonData(
                    @"SELECT lr.dewey_decimal, COUNT(t.transaction_id) as count 
                      FROM Transactions t 
                      JOIN Item_Copies ic ON t.accession_number = ic.accession_number 
                      JOIN Library_Resources lr ON ic.resource_id = lr.resource_id 
                      WHERE t.borrow_date BETWEEN @start AND @end 
                      GROUP BY lr.dewey_decimal 
                      ORDER BY count DESC 
                      LIMIT 10", conn, "dewey_decimal", start, end);

                string instJson = GetStackedJsonDataWithRoles(
                    @"SELECT 
                        COALESCE(s.institute, f.institute, st.office_department) AS institute,
                        SUM(CASE WHEN t.status = 'Borrowed' THEN 1 ELSE 0 END) AS Borrowed,
                        SUM(CASE WHEN t.status = 'Returned' THEN 1 ELSE 0 END) AS Returned,
                        SUM(CASE WHEN t.status IN ('Reserved','Ready') THEN 1 ELSE 0 END) AS Reserved,
                        SUM(CASE WHEN u.role = 'student' AND t.status = 'Borrowed' THEN 1 ELSE 0 END) AS StudentBorrowed,
                        SUM(CASE WHEN u.role = 'faculty' AND t.status = 'Borrowed' THEN 1 ELSE 0 END) AS FacultyBorrowed,
                        SUM(CASE WHEN u.role = 'staff'   AND t.status = 'Borrowed' THEN 1 ELSE 0 END) AS StaffBorrowed
                      FROM Transactions t
                      JOIN Users u ON t.user_id = u.user_id
                      LEFT JOIN Students s ON u.user_id = s.student_id
                      LEFT JOIN Faculty  f ON u.user_id = f.faculty_id
                      LEFT JOIN Staff   st ON u.user_id = st.staff_id
                      WHERE t.borrow_date BETWEEN @start AND @end
                      GROUP BY institute", conn, "institute", start, end);

                string progJson = GetStackedJsonDataWithRoles(
                    @"SELECT 
                        COALESCE(s.course, f.institute, st.office_department) AS program,
                        SUM(CASE WHEN t.status = 'Borrowed' THEN 1 ELSE 0 END) AS Borrowed,
                        SUM(CASE WHEN t.status = 'Returned' THEN 1 ELSE 0 END) AS Returned,
                        SUM(CASE WHEN t.status IN ('Reserved','Ready') THEN 1 ELSE 0 END) AS Reserved,
                        SUM(CASE WHEN u.role = 'student' AND t.status = 'Borrowed' THEN 1 ELSE 0 END) AS StudentBorrowed,
                        SUM(CASE WHEN u.role = 'faculty' AND t.status = 'Borrowed' THEN 1 ELSE 0 END) AS FacultyBorrowed,
                        SUM(CASE WHEN u.role = 'staff'   AND t.status = 'Borrowed' THEN 1 ELSE 0 END) AS StaffBorrowed
                      FROM Transactions t
                      JOIN Users u ON t.user_id = u.user_id
                      LEFT JOIN Students s ON u.user_id = s.student_id
                      LEFT JOIN Faculty  f ON u.user_id = f.faculty_id
                      LEFT JOIN Staff   st ON u.user_id = st.staff_id
                      WHERE t.borrow_date BETWEEN @start AND @end
                      GROUP BY program", conn, "program", start, end);

                string sqlFine = @"
                    SELECT 
                        SUM(CASE WHEN p.penalty_type LIKE '%Damaged%' THEN p.fine_amount ELSE 0 END) AS DamageAmount,
                        COUNT(CASE WHEN p.penalty_type LIKE '%Damaged%' THEN 1 END)                       AS DamageCount,
                        SUM(CASE WHEN p.penalty_type LIKE '%Lost%'    THEN p.fine_amount ELSE 0 END) AS LostAmount,
                        COUNT(CASE WHEN p.penalty_type LIKE '%Lost%'    THEN 1 END)                       AS LostCount,
                        SUM(CASE WHEN p.penalty_type LIKE '%Overdue%' THEN p.fine_amount ELSE 0 END) AS OverdueAmount,
                        COUNT(CASE WHEN p.penalty_type LIKE '%Overdue%' THEN 1 END)                       AS OverdueCount,
                        IFNULL(SUM(p.fine_amount), 0)                                          AS TotalComputedFine,
                        IFNULL(SUM(p.amount_paid), 0)                                          AS TotalPaid,
                        GREATEST(0, IFNULL(SUM(p.fine_amount), 0) 
                                  - IFNULL(SUM(p.amount_paid), 0))                             AS BalanceComputed
                    FROM Penalties p
                    JOIN Transactions t ON p.transaction_id = t.transaction_id
                    WHERE t.borrow_date BETWEEN @start AND @end";

                using (MySqlCommand cmd = new MySqlCommand(sqlFine, conn))
                {
                    cmd.Parameters.AddWithValue("@start", start);
                    cmd.Parameters.AddWithValue("@end", end);

                    using (MySqlDataReader dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            decimal damageAmt = SafeGetDecimal(dr, "DamageAmount");
                            decimal lostAmt = SafeGetDecimal(dr, "LostAmount");
                            decimal overdueAmt = SafeGetDecimal(dr, "OverdueAmount");
                            int damageCount = SafeGetInt(dr, "DamageCount");
                            int lostCount = SafeGetInt(dr, "LostCount");
                            int overdueCount = SafeGetInt(dr, "OverdueCount");
                            decimal totalFine = SafeGetDecimal(dr, "TotalComputedFine");
                            decimal totalPaid = SafeGetDecimal(dr, "TotalPaid");
                            decimal balance = SafeGetDecimal(dr, "BalanceComputed");

                            litTotalPenalties.Text = totalFine.ToString("N2");
                            litTotalPaid.Text = totalPaid.ToString("N2");
                            litTotalBalance.Text = balance.ToString("N2");

                            var penaltyData = new
                            {
                                amounts = new[] { damageAmt, lostAmt, overdueAmt },
                                counts = new[] { damageCount, lostCount, overdueCount }
                            };
                            string penaltyJson = new JavaScriptSerializer().Serialize(penaltyData);

                            string script = $"renderCharts({sectionJson}, {subjectJson}, {penaltyJson}, {instJson}, {progJson});";
                            ScriptManager.RegisterStartupScript(this, GetType(), "loadCharts", script, true);
                        }
                    }
                }
            }
        }

        private decimal SafeGetDecimal(MySqlDataReader reader, string columnName)
            => reader[columnName] == DBNull.Value ? 0m : Convert.ToDecimal(reader[columnName]);

        private int SafeGetInt(MySqlDataReader reader, string columnName)
            => reader[columnName] == DBNull.Value ? 0 : Convert.ToInt32(reader[columnName]);

        private string GetJsonData(string query, MySqlConnection conn, string labelField, string start, string end)
        {
            DataTable dt = new DataTable();
            using (MySqlCommand cmd = new MySqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("@start", start);
                cmd.Parameters.AddWithValue("@end", end);
                new MySqlDataAdapter(cmd).Fill(dt);
            }
            var labels = new List<string>();
            var values = new List<int>();
            foreach (DataRow row in dt.Rows)
            {
                labels.Add(row[0].ToString());
                values.Add(Convert.ToInt32(row[1]));
            }
            return new JavaScriptSerializer().Serialize(new { labels, values });
        }

        private string GetStackedJsonDataWithRoles(string query, MySqlConnection conn, string labelField, string start, string end)
        {
            DataTable dt = new DataTable();
            using (MySqlCommand cmd = new MySqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("@start", start);
                cmd.Parameters.AddWithValue("@end", end);
                new MySqlDataAdapter(cmd).Fill(dt);
            }
            var labels = new List<string>();
            var borrowed = new List<int>();
            var returned = new List<int>();
            var reserved = new List<int>();
            var borrowedRoles = new List<object>();

            foreach (DataRow row in dt.Rows)
            {
                labels.Add(row[labelField].ToString());
                borrowed.Add(Convert.ToInt32(row["Borrowed"]));
                returned.Add(Convert.ToInt32(row["Returned"]));
                reserved.Add(Convert.ToInt32(row["Reserved"]));
                borrowedRoles.Add(new
                {
                    student = Convert.ToInt32(row["StudentBorrowed"]),
                    faculty = Convert.ToInt32(row["FacultyBorrowed"]),
                    staff = Convert.ToInt32(row["StaffBorrowed"])
                });
            }
            return new JavaScriptSerializer().Serialize(new { labels, borrowed, returned, reserved, borrowedRoles });
        }

        private void LoadTopBorrowedData()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT lr.resource_id, lr.cover_path, lr.title, lr.author, lr.section AS Category,
                        (SELECT COUNT(*) FROM Transactions t 
                          INNER JOIN Item_Copies ic ON t.accession_number = ic.accession_number 
                          WHERE ic.resource_id = lr.resource_id 
                            AND t.status IN ('Borrowed','Returned')) AS Checkouts,
                        (SELECT COUNT(*) FROM Transactions t 
                          INNER JOIN Item_Copies ic ON t.accession_number = ic.accession_number 
                          WHERE ic.resource_id = lr.resource_id 
                            AND t.status IN ('Reserved','Ready')) AS Waiting
                    FROM Library_Resources lr 
                    ORDER BY Checkouts DESC 
                    LIMIT 5";
                conn.Open();
                DataTable dt = new DataTable();
                new MySqlDataAdapter(query, conn).Fill(dt);
                rptrTopBooks.DataSource = dt;
                rptrTopBooks.DataBind();
            }
        }

        protected string GetBookIconClass(int index)
        {
            switch (index % 5)
            {
                case 0: return "icon-book-purple";
                case 1: return "icon-book-green";
                case 2: return "icon-book-blue";
                case 3: return "icon-book-orange";
                default: return "icon-book-red";
            }
        }

        protected void rptrTopBooks_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                DataRowView row = (DataRowView)e.Item.DataItem;
                Image imgCover = (Image)e.Item.FindControl("imgCover");
                PlaceHolder phDefaultIcon = (PlaceHolder)e.Item.FindControl("phDefaultIcon");
                string path = row["cover_path"]?.ToString();
                if (!string.IsNullOrEmpty(path) && System.IO.File.Exists(Server.MapPath("~/" + path)))
                {
                    imgCover.ImageUrl = "~/" + path;
                    imgCover.Visible = true;
                    phDefaultIcon.Visible = false;
                }
                else
                {
                    imgCover.Visible = false;
                    phDefaultIcon.Visible = true;
                }
            }
        }
    }
}