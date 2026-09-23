using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Admin.Dashboard
{
    public partial class adminDashPp : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                RefreshDashboard();
            }
        }

        private void RefreshDashboard()
        {
            LoadProgressBars();
            LoadCharts();
            LoadPenaltyTable();
        }

        private void LoadProgressBars()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                try
                {
                    conn.Open();
                    // Top Programs (only Students)
                    string progQuery = @"
                        SELECT course, COUNT(*) as Count,
                               ROUND(COUNT(*) * 100 / (SELECT NULLIF(COUNT(*), 0) FROM Students), 0) as Percentage
                        FROM Students GROUP BY course ORDER BY Count DESC LIMIT 4";
                    MySqlDataAdapter daP = new MySqlDataAdapter(progQuery, conn);
                    DataTable dtP = new DataTable();
                    daP.Fill(dtP);
                    rptPrograms.DataSource = dtP;
                    rptPrograms.DataBind();

                    // Top Institutes (from Students + Faculty, unified)
                    string instQuery = @"
                        SELECT institute, COUNT(*) as Count,
                               ROUND(COUNT(*) * 100 / (SELECT NULLIF(COUNT(*), 0) FROM (SELECT institute FROM Students UNION ALL SELECT institute FROM Faculty) AS allInst), 0) as Percentage
                        FROM (SELECT institute FROM Students UNION ALL SELECT institute FROM Faculty) AS Combined
                        WHERE institute IS NOT NULL AND institute != ''
                        GROUP BY institute ORDER BY Count DESC LIMIT 4";
                    MySqlDataAdapter daI = new MySqlDataAdapter(instQuery, conn);
                    DataTable dtI = new DataTable();
                    daI.Fill(dtI);
                    rptInstitutes.DataSource = dtI;
                    rptInstitutes.DataBind();
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Error", "Failed to load progress bars: " + ex.Message, "error");
                }
            }
        }

        private void LoadCharts()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                try
                {
                    conn.Open();
                    string query = @"
                        SELECT
                            SUM(CASE WHEN source = 'Faculty' THEN 1 ELSE 0 END) as TotalFaculty,
                            SUM(CASE WHEN source = 'Student' THEN 1 ELSE 0 END) as TotalStudents,
                            SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) as TotalMale,
                            SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) as TotalFemale
                        FROM (
                            SELECT 'Student' as source, gender FROM Students
                            UNION ALL
                            SELECT 'Faculty' as source, gender FROM Faculty
                        ) as Combined";
                    MySqlCommand cmd = new MySqlCommand(query, conn);
                    using (MySqlDataReader dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            var data = new
                            {
                                patron = new[] { Convert.ToInt32(dr["TotalFaculty"]), Convert.ToInt32(dr["TotalStudents"]) },
                                gender = new[] { Convert.ToInt32(dr["TotalMale"]), Convert.ToInt32(dr["TotalFemale"]) }
                            };
                            litChartData.Text = $"<script type='application/json' id='chartDataJSON'>{new JavaScriptSerializer().Serialize(data)}</script>";
                        }
                    }
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Error", "Failed to load charts: " + ex.Message, "error");
                }
            }
        }

        private void LoadPenaltyTable(string search = "")
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                try
                {
                    conn.Open();
                    // CHANGES:
                    //  • Source of truth is now Penalties (fine_amount, fine_status, penalty_type).
                    //  • Join Transactions to keep borrow_date available as PenaltyDate context.
                    //  • PenaltyType displays the actual enum value from Penalties.penalty_type.
                    //  • All filter/sort columns come from the Penalties row (p.penalty_id PK ordering is stable).
                    string query = @"
                SELECT 
                    t.borrow_date        AS PenaltyDate,
                    CONCAT(u.first_name, ' ', u.last_name) AS FullName,
                    u.user_id            AS PatronID,
                    u.program            AS Program,
                    r.title              AS BookTitle,
                    p.penalty_type       AS PenaltyType,
                    p.fine_amount        AS Amount,
                    p.fine_status        AS Status
                FROM Penalties p
                INNER JOIN Transactions t ON p.transaction_id = t.transaction_id
                INNER JOIN (
                    SELECT student_id AS user_id, first_name, last_name, course     AS program FROM Students
                    UNION ALL
                    SELECT faculty_id AS user_id, first_name, last_name, institute  AS program FROM Faculty
                ) u ON p.user_id = u.user_id
                LEFT JOIN Item_Copies c        ON p.accession_number = c.accession_number
                LEFT JOIN Library_Resources r  ON c.resource_id = r.resource_id
                WHERE p.fine_amount > 0";

                    if (!string.IsNullOrEmpty(search))
                    {
                        query += " AND (u.first_name LIKE @s OR u.last_name LIKE @s OR u.user_id LIKE @s)";
                    }
                    query += " ORDER BY p.created_at DESC";

                    MySqlCommand cmd = new MySqlCommand(query, conn);
                    if (!string.IsNullOrEmpty(search))
                        cmd.Parameters.AddWithValue("@s", "%" + search + "%");

                    MySqlDataAdapter da = new MySqlDataAdapter(cmd);
                    DataTable dt = new DataTable();
                    da.Fill(dt);
                    gvPenalties.DataSource = dt;
                    gvPenalties.DataBind();
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Error", "Failed to load penalties: " + ex.Message, "error");
                }
            }
        }

        protected void txtSearch_TextChanged(object sender, EventArgs e)
        {
            LoadPenaltyTable(txtSearch.Text.Trim());
            upnlGridView.Update();
        }

        protected string GetProgressColor(int index)
        {
            string[] colors = { "bg-primary", "bg-success", "bg-warning", "bg-info", "bg-danger" };
            return colors[index % colors.Length];
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