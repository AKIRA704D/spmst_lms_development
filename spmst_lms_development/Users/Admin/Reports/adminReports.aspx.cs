using System;
using System.Collections.Generic;
using System.Configuration;
using System.Web.Script.Serialization;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Users.Admin.Reports
{
    public partial class adminReports : System.Web.UI.Page
    {
        // Reuses the same connection string key used across the rest of the LMS admin area
        // (see admin.Master, which reads ConnectionStrings["LmsDb"]).
        private string ConnStr => ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        // KPI values, exposed as protected properties so the markup can bind them directly with <%= %>
        protected int TotalTitles { get; private set; }
        protected int TotalCopies { get; private set; }
        protected int AvailableCopies { get; private set; }
        protected int CurrentlyBorrowed { get; private set; }
        protected int OverdueCount { get; private set; }
        protected decimal OutstandingFines { get; private set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            // Consistent with the rest of the LMS admin area, which relies on sessionHelper
            // rather than raw Session[] lookups.
            if (string.IsNullOrEmpty(spmst_lms_development.sessionHelper.UserID))
            {
                Response.Redirect("~/Login/login.aspx");
                return;
            }

            if (!IsPostBack)
            {
                LoadKpis();
                LoadReportDataJson();
                BindOverdueList();
                BindTopBorrowers();
            }
        }

        private void LoadKpis()
        {
            using (var conn = new MySqlConnection(ConnStr))
            {
                conn.Open();

                TotalTitles = ExecScalarInt(conn, "SELECT COUNT(*) FROM library_resources");
                TotalCopies = ExecScalarInt(conn, "SELECT COUNT(*) FROM item_copies");
                AvailableCopies = ExecScalarInt(conn, "SELECT COUNT(*) FROM item_copies WHERE is_available = 1");

                // "Currently borrowed" = active, un-returned loans.
                CurrentlyBorrowed = ExecScalarInt(conn, @"
                    SELECT COUNT(*) FROM transactions
                    WHERE status = 'Borrowed' AND return_date IS NULL");

                // Overdue is no longer an enum value - derive it from due_date + return_date.
                OverdueCount = ExecScalarInt(conn, @"
                    SELECT COUNT(*) FROM transactions
                    WHERE return_date IS NULL
                      AND status NOT IN ('Returned','Cancelled')
                      AND due_date < CURDATE()");

                // Fines now live in the Penalties table.
                // Outstanding = SUM(fine_amount - amount_paid) for anything not fully paid.
                using (var cmd = new MySqlCommand(@"
                    SELECT COALESCE(SUM(fine_amount - amount_paid), 0)
                    FROM penalties
                    WHERE fine_status IN ('Unpaid','Partial')", conn))
                {
                    OutstandingFines = Convert.ToDecimal(cmd.ExecuteScalar());
                }
            }
        }

        private static int ExecScalarInt(MySqlConnection conn, string sql)
        {
            using (var cmd = new MySqlCommand(sql, conn))
            {
                var result = cmd.ExecuteScalar();
                return result == null || result == DBNull.Value ? 0 : Convert.ToInt32(result);
            }
        }

        // Builds one JSON payload (trend series, status breakdown, top titles, genre mix,
        // fine status, condition mix) and drops it into a <script type="application/json">
        // block so the client-side Chart.js code can render everything without extra AJAX calls.
        private void LoadReportDataJson()
        {
            var payload = new Dictionary<string, object>
            {
                { "trend", GetCirculationTrend() },
                { "statusBreakdown", GetStatusBreakdown() },
                { "topTitles", GetTopBorrowedTitles() },
                { "genreBreakdown", GetGenreBreakdown() },
                { "fineStatus", GetFineStatusBreakdown() },
                { "conditionBreakdown", GetGroupedCounts("item_copies", "status_condition", null, 0) }
            };

            var serializer = new JavaScriptSerializer();
            litReportDataJson.Text = serializer.Serialize(payload);
        }

        private object GetCirculationTrend()
        {
            using (var conn = new MySqlConnection(ConnStr))
            {
                conn.Open();

                var daily = new List<Dictionary<string, object>>();
                using (var cmd = new MySqlCommand(@"
                    SELECT DATE(borrow_date) AS d, COUNT(*) AS c
                    FROM transactions
                    WHERE borrow_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                    GROUP BY DATE(borrow_date)
                    ORDER BY d", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        daily.Add(new Dictionary<string, object>
                        {
                            { "label", Convert.ToDateTime(reader["d"]).ToString("MMM d") },
                            { "count", Convert.ToInt32(reader["c"]) }
                        });
                    }
                }

                var weekly = new List<Dictionary<string, object>>();
                using (var cmd = new MySqlCommand(@"
                    SELECT YEARWEEK(borrow_date, 3) AS yw, MIN(DATE(borrow_date)) AS wk_start, COUNT(*) AS c
                    FROM transactions
                    WHERE borrow_date >= DATE_SUB(CURDATE(), INTERVAL 12 WEEK)
                    GROUP BY yw
                    ORDER BY yw", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        weekly.Add(new Dictionary<string, object>
                        {
                            { "label", "Wk of " + Convert.ToDateTime(reader["wk_start"]).ToString("MMM d") },
                            { "count", Convert.ToInt32(reader["c"]) }
                        });
                    }
                }

                var monthly = new List<Dictionary<string, object>>();
                using (var cmd = new MySqlCommand(@"
                    SELECT DATE_FORMAT(borrow_date, '%Y-%m-01') AS ym, COUNT(*) AS c
                    FROM transactions
                    WHERE borrow_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
                    GROUP BY ym
                    ORDER BY ym", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        monthly.Add(new Dictionary<string, object>
                        {
                            { "label", Convert.ToDateTime(reader["ym"]).ToString("MMM yyyy") },
                            { "count", Convert.ToInt32(reader["c"]) }
                        });
                    }
                }

                return new Dictionary<string, object> { { "daily", daily }, { "weekly", weekly }, { "monthly", monthly } };
            }
        }

        // Status breakdown with the virtual "Overdue" state derived from due_date/return_date.
        private List<Dictionary<string, object>> GetStatusBreakdown()
        {
            var list = new List<Dictionary<string, object>>();
            using (var conn = new MySqlConnection(ConnStr))
            using (var cmd = new MySqlCommand(@"
                SELECT
                    CASE
                        WHEN status = 'Borrowed' AND return_date IS NULL AND due_date < CURDATE()
                            THEN 'Overdue'
                        ELSE status
                    END AS grp,
                    COUNT(*) AS c
                FROM transactions
                GROUP BY grp
                ORDER BY c DESC", conn))
            {
                conn.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        list.Add(new Dictionary<string, object>
                        {
                            { "label", reader["grp"] == DBNull.Value ? "Unspecified" : reader["grp"].ToString() },
                            { "count", Convert.ToInt32(reader["c"]) }
                        });
                    }
                }
            }
            return list;
        }

        // Generic "GROUP BY column, COUNT(*)" helper used for condition breakdowns.
        private List<Dictionary<string, object>> GetGroupedCounts(string table, string column, string whereClause, int limit)
        {
            var list = new List<Dictionary<string, object>>();
            string sql = $"SELECT {column} AS grp, COUNT(*) AS c FROM {table}";
            if (!string.IsNullOrEmpty(whereClause)) sql += " WHERE " + whereClause;
            sql += $" GROUP BY {column} ORDER BY c DESC";
            if (limit > 0) sql += $" LIMIT {limit}";

            using (var conn = new MySqlConnection(ConnStr))
            using (var cmd = new MySqlCommand(sql, conn))
            {
                conn.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        list.Add(new Dictionary<string, object>
                        {
                            { "label", reader["grp"] == DBNull.Value ? "Unspecified" : reader["grp"].ToString() },
                            { "count", Convert.ToInt32(reader["c"]) }
                        });
                    }
                }
            }
            return list;
        }

        private List<Dictionary<string, object>> GetTopBorrowedTitles()
        {
            var list = new List<Dictionary<string, object>>();
            using (var conn = new MySqlConnection(ConnStr))
            using (var cmd = new MySqlCommand(@"
                SELECT lr.title AS title, COUNT(*) AS c
                FROM transactions t
                JOIN item_copies ic ON ic.accession_number = t.accession_number
                JOIN library_resources lr ON lr.resource_id = ic.resource_id
                GROUP BY lr.resource_id, lr.title
                ORDER BY c DESC
                LIMIT 8", conn))
            {
                conn.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        list.Add(new Dictionary<string, object>
                        {
                            { "title", reader["title"].ToString() },
                            { "count", Convert.ToInt32(reader["c"]) }
                        });
                    }
                }
            }
            return list;
        }

        private List<Dictionary<string, object>> GetGenreBreakdown()
        {
            var list = new List<Dictionary<string, object>>();
            using (var conn = new MySqlConnection(ConnStr))
            using (var cmd = new MySqlCommand(@"
                SELECT COALESCE(NULLIF(genre, ''), 'Uncategorized') AS genre, COUNT(*) AS c
                FROM library_resources
                GROUP BY genre
                ORDER BY c DESC
                LIMIT 10", conn))
            {
                conn.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        list.Add(new Dictionary<string, object>
                        {
                            { "label", reader["genre"].ToString() },
                            { "count", Convert.ToInt32(reader["c"]) }
                        });
                    }
                }
            }
            return list;
        }

        // Fine status now sourced from the Penalties table. The chart value is the
        // OUTSTANDING amount (fine_amount - amount_paid), not the original fine.
        private List<Dictionary<string, object>> GetFineStatusBreakdown()
        {
            var list = new List<Dictionary<string, object>>();
            using (var conn = new MySqlConnection(ConnStr))
            using (var cmd = new MySqlCommand(@"
                SELECT fine_status,
                       COALESCE(SUM(fine_amount - amount_paid), 0) AS outstanding_amount,
                       COUNT(*) AS c
                FROM penalties
                WHERE fine_amount > 0
                GROUP BY fine_status", conn))
            {
                conn.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        list.Add(new Dictionary<string, object>
                        {
                            { "label",  reader["fine_status"].ToString() },
                            { "amount", Convert.ToDouble(reader["outstanding_amount"]) },
                            { "count",  Convert.ToInt32(reader["c"]) }
                        });
                    }
                }
            }
            return list;
        }

        private void BindOverdueList()
        {
            var list = new List<OverdueRow>();
            using (var conn = new MySqlConnection(ConnStr))
            using (var cmd = new MySqlCommand(@"
                SELECT
                    lr.title AS title,
                    COALESCE(s.first_name, f.first_name, st.first_name, t.user_id) AS first_name,
                    COALESCE(s.last_name,  f.last_name,  st.last_name,  '')        AS last_name,
                    t.due_date AS due_date,
                    DATEDIFF(CURDATE(), t.due_date) AS days_overdue,
                    COALESCE(p.fine_amount - p.amount_paid, 0) AS balance
                FROM transactions t
                JOIN item_copies ic        ON ic.accession_number = t.accession_number
                JOIN library_resources lr  ON lr.resource_id      = ic.resource_id
                LEFT JOIN students s       ON s.student_id        = t.user_id
                LEFT JOIN faculty  f       ON f.faculty_id        = t.user_id
                LEFT JOIN staff    st      ON st.staff_id         = t.user_id
                LEFT JOIN penalties p      ON p.transaction_id    = t.transaction_id
                WHERE t.return_date IS NULL
                  AND t.status NOT IN ('Returned','Cancelled')
                  AND t.due_date < CURDATE()
                ORDER BY days_overdue DESC
                LIMIT 10", conn))
            {
                conn.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        list.Add(new OverdueRow
                        {
                            BorrowerName = ($"{reader["first_name"]} {reader["last_name"]}").Trim(),
                            Title = reader["title"].ToString(),
                            DueDate = Convert.ToDateTime(reader["due_date"]).ToString("MMM d, yyyy"),
                            DaysOverdue = Convert.ToInt32(reader["days_overdue"]),
                            Balance = Convert.ToDecimal(reader["balance"])
                        });
                    }
                }
            }

            rptOverdue.DataSource = list;
            rptOverdue.DataBind();
            pnlOverdueEmpty.Visible = list.Count == 0;
        }

        private void BindTopBorrowers()
        {
            var list = new List<BorrowerRow>();
            using (var conn = new MySqlConnection(ConnStr))
            using (var cmd = new MySqlCommand(@"
                SELECT
                    COALESCE(s.first_name, f.first_name, st.first_name, t.user_id) AS first_name,
                    COALESCE(s.last_name, f.last_name, st.last_name, '') AS last_name,
                    u.role AS role,
                    COUNT(*) AS total_borrows
                FROM transactions t
                LEFT JOIN users u ON u.user_id = t.user_id
                LEFT JOIN students s ON s.student_id = t.user_id
                LEFT JOIN faculty f ON f.faculty_id = t.user_id
                LEFT JOIN staff st ON st.staff_id = t.user_id
                GROUP BY t.user_id, first_name, last_name, u.role
                ORDER BY total_borrows DESC
                LIMIT 8", conn))
            {
                conn.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        list.Add(new BorrowerRow
                        {
                            Name = ($"{reader["first_name"]} {reader["last_name"]}").Trim(),
                            Role = reader["role"] == DBNull.Value ? "N/A" : reader["role"].ToString(),
                            TotalBorrows = Convert.ToInt32(reader["total_borrows"])
                        });
                    }
                }
            }

            rptTopBorrowers.DataSource = list;
            rptTopBorrowers.DataBind();
            pnlBorrowersEmpty.Visible = list.Count == 0;
        }

        // Handles the "Export CSV" button - streams a simple CSV of the current overdue list.
        protected void btnExportOverdueCsv_Click(object sender, EventArgs e)
        {
            var rows = new List<OverdueRow>();
            using (var conn = new MySqlConnection(ConnStr))
            using (var cmd = new MySqlCommand(@"
                SELECT
                    lr.title AS title,
                    COALESCE(s.first_name, f.first_name, st.first_name, t.user_id) AS first_name,
                    COALESCE(s.last_name,  f.last_name,  st.last_name,  '')        AS last_name,
                    t.due_date AS due_date,
                    DATEDIFF(CURDATE(), t.due_date) AS days_overdue,
                    COALESCE(p.fine_amount - p.amount_paid, 0) AS balance
                FROM transactions t
                JOIN item_copies ic        ON ic.accession_number = t.accession_number
                JOIN library_resources lr  ON lr.resource_id      = ic.resource_id
                LEFT JOIN students s       ON s.student_id        = t.user_id
                LEFT JOIN faculty  f       ON f.faculty_id        = t.user_id
                LEFT JOIN staff    st      ON st.staff_id         = t.user_id
                LEFT JOIN penalties p      ON p.transaction_id    = t.transaction_id
                WHERE t.return_date IS NULL
                  AND t.status NOT IN ('Returned','Cancelled')
                  AND t.due_date < CURDATE()
                ORDER BY days_overdue DESC", conn))
            {
                conn.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        rows.Add(new OverdueRow
                        {
                            BorrowerName = ($"{reader["first_name"]} {reader["last_name"]}").Trim(),
                            Title = reader["title"].ToString(),
                            DueDate = Convert.ToDateTime(reader["due_date"]).ToString("yyyy-MM-dd"),
                            DaysOverdue = Convert.ToInt32(reader["days_overdue"]),
                            Balance = Convert.ToDecimal(reader["balance"])
                        });
                    }
                }
            }

            Response.Clear();
            Response.ContentType = "text/csv";
            Response.AddHeader("Content-Disposition", "attachment; filename=overdue_report.csv");
            Response.Write("Borrower,Title,Due Date,Days Overdue,Balance\n");
            foreach (var r in rows)
            {
                Response.Write($"\"{r.BorrowerName.Replace("\"", "\"\"")}\",\"{r.Title.Replace("\"", "\"\"")}\",{r.DueDate},{r.DaysOverdue},{r.Balance:F2}\n");
            }
            Response.End();
        }
    }

    public class OverdueRow
    {
        public string BorrowerName { get; set; }
        public string Title { get; set; }
        public string DueDate { get; set; }
        public int DaysOverdue { get; set; }
        public decimal Balance { get; set; }
    }

    public class BorrowerRow
    {
        public string Name { get; set; }
        public string Role { get; set; }
        public int TotalBorrows { get; set; }
    }
}