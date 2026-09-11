using DocumentFormat.OpenXml.Office.Word;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Admin
{
    public partial class adminDashC : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                txtDateFrom.Text = DateTime.Now.AddDays(-30).ToString("yyyy-MM-dd");
                txtDateTo.Text = DateTime.Now.ToString("yyyy-MM-dd");
                LoadDashboardStats();
                LoadUnifiedAnalytics(txtDateFrom.Text, txtDateTo.Text);
               // LoadLowCirculationData();
                LoadTopBorrowedData();

                // Load the default analytics tab(Low Circulation)
                analyticsFrame.Attributes["src"] = "Analytics_LowCirc.aspx";
            }
        }

        protected void btnFilter_Click(object sender, EventArgs e)
        {
            LoadUnifiedAnalytics(txtDateFrom.Text, txtDateTo.Text);
        }
            
        private void LoadDashboardStats()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT 
                        (SELECT COUNT(*) FROM Library_Attendance la INNER JOIN Faculty f ON la.user_id = f.faculty_id) as FacultyVisits,
                        (SELECT COUNT(*) FROM Transactions WHERE status = 'Borrowed') as Circulated,
                        (SELECT COUNT(*) FROM Transactions WHERE status = 'Overdue') as OverdueCount,
                        (SELECT IFNULL(SUM(balance), 0) FROM Transactions) as PendingTotal,
                        (SELECT COUNT(DISTINCT user_id) FROM Library_Attendance) as ActivePatrons,
                        (SELECT COUNT(*) FROM Item_Copies WHERE status_condition = 'Damage') as DamageCount,
                        (SELECT COUNT(*) FROM Item_Copies WHERE status_condition = 'Lost') as LostCount,
                        (SELECT IFNULL(SUM(amount_paid), 0) FROM Transactions) as Collected";
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
                        litDamageFines.Text = dr["DamageCount"].ToString();   // count of damaged copies
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

                // 1. Top Sections – count transactions per section
                string sectionJson = GetJsonData(
                    @"SELECT lr.section, COUNT(t.transaction_id) as count 
              FROM Transactions t 
              JOIN Item_Copies ic ON t.accession_number = ic.accession_number 
              JOIN Library_Resources lr ON ic.resource_id = lr.resource_id 
              WHERE t.borrow_date BETWEEN @start AND @end 
              GROUP BY lr.section 
              ORDER BY count DESC 
              LIMIT 10", conn, "section", start, end);

                // 2. Top Subjects (DDC) – count transactions per dewey_decimal
                string subjectJson = GetJsonData(
                    @"SELECT lr.dewey_decimal, COUNT(t.transaction_id) as count 
              FROM Transactions t 
              JOIN Item_Copies ic ON t.accession_number = ic.accession_number 
              JOIN Library_Resources lr ON ic.resource_id = lr.resource_id 
              WHERE t.borrow_date BETWEEN @start AND @end 
              GROUP BY lr.dewey_decimal 
              ORDER BY count DESC 
              LIMIT 10", conn, "dewey_decimal", start, end);

                // 3. Borrowing Distribution – by Institute (all roles, with role breakdown)
                string instJson = GetStackedJsonDataWithRoles(
                    @"SELECT 
                COALESCE(s.institute, f.institute, st.office_department) AS institute,
                SUM(CASE WHEN t.status IN ('Borrowed', 'Overdue') THEN 1 ELSE 0 END) AS Borrowed,
                SUM(CASE WHEN t.status = 'Returned' THEN 1 ELSE 0 END) AS Returned,
                SUM(CASE WHEN t.status IN ('Reserved', 'Ready') THEN 1 ELSE 0 END) AS Reserved,
                SUM(CASE WHEN u.role = 'student' AND t.status IN ('Borrowed', 'Overdue') THEN 1 ELSE 0 END) AS StudentBorrowed,
                SUM(CASE WHEN u.role = 'faculty' AND t.status IN ('Borrowed', 'Overdue') THEN 1 ELSE 0 END) AS FacultyBorrowed,
                SUM(CASE WHEN u.role = 'staff' AND t.status IN ('Borrowed', 'Overdue') THEN 1 ELSE 0 END) AS StaffBorrowed
            FROM Transactions t
            JOIN Users u ON t.user_id = u.user_id
            LEFT JOIN Students s ON u.user_id = s.student_id
            LEFT JOIN Faculty f ON u.user_id = f.faculty_id
            LEFT JOIN Staff st ON u.user_id = st.staff_id
            WHERE t.borrow_date BETWEEN @start AND @end
            GROUP BY institute", conn, "institute", start, end);

                // 4. Borrowing Distribution – by Program (all roles, with role breakdown)
                string progJson = GetStackedJsonDataWithRoles(
                    @"SELECT 
                COALESCE(s.course, f.institute, st.office_department) AS program,
                SUM(CASE WHEN t.status IN ('Borrowed', 'Overdue') THEN 1 ELSE 0 END) AS Borrowed,
                SUM(CASE WHEN t.status = 'Returned' THEN 1 ELSE 0 END) AS Returned,
                SUM(CASE WHEN t.status IN ('Reserved', 'Ready') THEN 1 ELSE 0 END) AS Reserved,
                SUM(CASE WHEN u.role = 'student' AND t.status IN ('Borrowed', 'Overdue') THEN 1 ELSE 0 END) AS StudentBorrowed,
                SUM(CASE WHEN u.role = 'faculty' AND t.status IN ('Borrowed', 'Overdue') THEN 1 ELSE 0 END) AS FacultyBorrowed,
                SUM(CASE WHEN u.role = 'staff' AND t.status IN ('Borrowed', 'Overdue') THEN 1 ELSE 0 END) AS StaffBorrowed
            FROM Transactions t
            JOIN Users u ON t.user_id = u.user_id
            LEFT JOIN Students s ON u.user_id = s.student_id
            LEFT JOIN Faculty f ON u.user_id = f.faculty_id
            LEFT JOIN Staff st ON u.user_id = st.staff_id
            WHERE t.borrow_date BETWEEN @start AND @end
            GROUP BY program", conn, "program", start, end);

                // 5. Penalty Breakdown – dynamically computed fines
                string sqlFine = @"
            SELECT 
                SUM(CASE WHEN t.is_damaged = 1 THEN 100 ELSE 0 END) AS DamageAmount,
                SUM(CASE WHEN t.is_damaged = 1 THEN 1 ELSE 0 END) AS DamageCount,
                SUM(CASE WHEN t.is_lost = 1 THEN 600 ELSE 0 END) AS LostAmount,
                SUM(CASE WHEN t.is_lost = 1 THEN 1 ELSE 0 END) AS LostCount,
                SUM(
                    CASE 
                        WHEN t.return_date IS NULL THEN 
                            CASE WHEN t.due_date < CURDATE() THEN DATEDIFF(CURDATE(), t.due_date) * 5 ELSE 0 END
                        ELSE 
                            CASE WHEN t.return_date > t.due_date THEN DATEDIFF(t.return_date, t.due_date) * 5 ELSE 0 END
                    END
                ) AS OverdueAmount,
                SUM(
                    CASE 
                        WHEN t.return_date IS NULL THEN 
                            CASE WHEN t.due_date < CURDATE() THEN 1 ELSE 0 END
                        ELSE 
                            CASE WHEN t.return_date > t.due_date THEN 1 ELSE 0 END
                    END
                ) AS OverdueCount,
                SUM(
                    CASE WHEN t.is_damaged = 1 THEN 100 ELSE 0 END
                    + CASE WHEN t.is_lost = 1 THEN 600 ELSE 0 END
                    + CASE 
                        WHEN t.return_date IS NULL THEN 
                            CASE WHEN t.due_date < CURDATE() THEN DATEDIFF(CURDATE(), t.due_date) * 5 ELSE 0 END
                        ELSE 
                            CASE WHEN t.return_date > t.due_date THEN DATEDIFF(t.return_date, t.due_date) * 5 ELSE 0 END
                      END
                ) AS TotalComputedFine,
                IFNULL(SUM(t.amount_paid), 0) AS TotalPaid,
                GREATEST(0, 
                    SUM(
                        CASE WHEN t.is_damaged = 1 THEN 100 ELSE 0 END
                        + CASE WHEN t.is_lost = 1 THEN 600 ELSE 0 END
                        + CASE 
                            WHEN t.return_date IS NULL THEN 
                                CASE WHEN t.due_date < CURDATE() THEN DATEDIFF(CURDATE(), t.due_date) * 5 ELSE 0 END
                            ELSE 
                                CASE WHEN t.return_date > t.due_date THEN DATEDIFF(t.return_date, t.due_date) * 5 ELSE 0 END
                          END
                    ) - IFNULL(SUM(t.amount_paid), 0)
                ) AS BalanceComputed
            FROM Transactions t 
            WHERE t.borrow_date BETWEEN @start AND @end";

                using (MySqlCommand cmd = new MySqlCommand(sqlFine, conn))
                {
                    cmd.Parameters.AddWithValue("@start", start);
                    cmd.Parameters.AddWithValue("@end", end);

                    using (MySqlDataReader dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            // SAFELY CONVERT VALUES – handle DBNull
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

        // Helper methods for safe conversion – add these inside your class
        private decimal SafeGetDecimal(MySqlDataReader reader, string columnName)
        {
            return reader[columnName] == DBNull.Value ? 0m : Convert.ToDecimal(reader[columnName]);
        }

        private int SafeGetInt(MySqlDataReader reader, string columnName)
        {
            return reader[columnName] == DBNull.Value ? 0 : Convert.ToInt32(reader[columnName]);
        }

        // -----------------------------------------------------------------
        // Helper methods
        // -----------------------------------------------------------------

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
                labels.Add(row[0].ToString());      // first column = label
                values.Add(Convert.ToInt32(row[1])); // second column = value
            }
            return new JavaScriptSerializer().Serialize(new { labels, values });
        }

        // Enhanced version that includes role breakdown for Borrowed
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
                        (SELECT COUNT(*) FROM Transactions t INNER JOIN Item_Copies ic ON t.accession_number = ic.accession_number WHERE ic.resource_id = lr.resource_id AND t.status IN ('Borrowed','Returned')) AS Checkouts,
                        (SELECT COUNT(*) FROM Transactions t INNER JOIN Item_Copies ic ON t.accession_number = ic.accession_number WHERE ic.resource_id = lr.resource_id AND t.status IN ('Reserved','Ready')) AS Waiting
                    FROM Library_Resources lr ORDER BY Checkouts DESC LIMIT 5";
                conn.Open();
                DataTable dt = new DataTable();
                new MySqlDataAdapter(query, conn).Fill(dt);
                rptrTopBooks.DataSource = dt;
                rptrTopBooks.DataBind();
            }
        }

        protected string GetBookIconClass(int index)
        {
            int mod = index % 5;
            if (mod == 0) return "icon-book-purple";
            else if (mod == 1) return "icon-book-green";
            else if (mod == 2) return "icon-book-blue";
            else if (mod == 3) return "icon-book-orange";
            else return "icon-book-red";
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