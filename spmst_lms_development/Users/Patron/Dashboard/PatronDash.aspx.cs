using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Users.Patron.Dashboard
{
    public partial class PatronDash : System.Web.UI.Page
    {
        private readonly string _connStr =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["UserID"] == null)
            {
                Response.Redirect("~/Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            if (!IsPostBack)
            {
                LoadDashboard();
            }
        }

        // ---------------------------------------------------------------
        // Orchestration
        // ---------------------------------------------------------------
        private void LoadDashboard()
        {
            string uid = Session["UserID"].ToString();
            litTodayDate.Text = DateTime.Now.ToString("dddd, MMMM d, yyyy");

            LoadPatronName(uid);
            LoadStats(uid);
            LoadBorrowed(uid);
            LoadActivity(uid);
            LoadRecommendations(uid);
            LoadFines(uid);
            LoadNotifications(uid);
            LoadRank(uid);
        }

        // ---------------------------------------------------------------
        // 1. Patron name (Students OR Faculty, depending on role)
        // ---------------------------------------------------------------
        private void LoadPatronName(string uid)
        {
            const string sql = @"
                SELECT COALESCE(s.first_name, f.first_name) AS first_name
                FROM Users u
                LEFT JOIN Students s ON u.user_id = s.student_id
                LEFT JOIN Faculty  f ON u.user_id = f.faculty_id
                WHERE u.user_id = @uid
                LIMIT 1;";

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@uid", uid);
                    conn.Open();
                    object raw = cmd.ExecuteScalar();
                    string name = raw == null || raw == DBNull.Value ? null : raw.ToString();
                    litFirstName.Text = string.IsNullOrWhiteSpace(name) ? "Reader" : name;
                }
            }
            catch (MySqlException) { /* swallow; default remains */ }
        }

        // ---------------------------------------------------------------
        // 2. Summary statistics
        //    - Renewals counted from Transactions.status = 'Renewal'
        //      (patron submitted, awaiting staff).
        //    - Fines derived from Penalties (Transactions.balance does not exist).
        // ---------------------------------------------------------------
        private void LoadStats(string uid)
        {
            const string sql = @"
                SELECT
                    (SELECT COUNT(*) FROM Transactions
                       WHERE user_id = @uid AND status = 'Borrowed')                  AS borrowed,
                    (SELECT COUNT(*) FROM Transactions
                       WHERE user_id = @uid AND status IN ('Reserved','Ready'))       AS reservations,
                    (SELECT COUNT(*) FROM Transactions
                       WHERE user_id = @uid AND status = 'Ready')                     AS ready,
                    (SELECT COUNT(*) FROM Transactions
                       WHERE user_id = @uid AND status = 'Returned')                  AS returned,
                    (SELECT COUNT(*) FROM Transactions
                       WHERE user_id = @uid AND status = 'Renewal')                   AS pending_renewals,
                    (SELECT IFNULL(SUM(GREATEST(fine_amount - amount_paid, 0)), 0)
                       FROM Penalties
                       WHERE user_id = @uid
                         AND fine_status IN ('Unpaid','Partial')
                         AND fine_amount > amount_paid)                               AS outstanding;";

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@uid", uid);
                    conn.Open();
                    using (var dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            litOnHand.Text = SafeInt(dr["borrowed"]).ToString();
                            litReservations.Text = SafeInt(dr["reservations"]).ToString();
                            litReady.Text = SafeInt(dr["ready"]).ToString();
                            litReturned.Text = SafeInt(dr["returned"]).ToString();
                            litPendingRenewals.Text = SafeInt(dr["pending_renewals"]).ToString();

                            decimal outstanding = dr["outstanding"] == DBNull.Value
                                ? 0m : Convert.ToDecimal(dr["outstanding"]);
                            litFines.Text = "₱" + outstanding.ToString("N2");
                        }
                    }
                }
            }
            catch (MySqlException)
            {
                // Keep the safe defaults rendered in the ASPX markup.
            }
        }

        // ---------------------------------------------------------------
        // 3. Currently borrowed books
        // ---------------------------------------------------------------
        private void LoadBorrowed(string uid)
        {
            const string sql = @"
                SELECT r.title, r.author, r.cover_path, t.borrow_date, t.due_date,
                       DATEDIFF(t.due_date, CURDATE()) AS days_left
                FROM Transactions t
                JOIN Item_Copies      ic ON t.accession_number = ic.accession_number
                JOIN Library_Resources r ON ic.resource_id      = r.resource_id
                WHERE t.user_id = @uid AND t.status = 'Borrowed'
                ORDER BY t.due_date ASC;";

            DataTable dt = new DataTable();
            dt.Columns.Add("title", typeof(string));
            dt.Columns.Add("author", typeof(string));
            dt.Columns.Add("cover_path", typeof(string));
            dt.Columns.Add("borrow_date", typeof(DateTime));
            dt.Columns.Add("due_date", typeof(DateTime));
            dt.Columns.Add("days_left", typeof(int));
            dt.Columns.Add("pill_class", typeof(string));
            dt.Columns.Add("pill_text", typeof(string));

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                using (var cmd = new MySqlCommand(sql, conn))
                using (var da = new MySqlDataAdapter(cmd))
                {
                    cmd.Parameters.AddWithValue("@uid", uid);
                    conn.Open();
                    da.Fill(dt);
                }
            }
            catch (MySqlException)
            {
                // Fall through to empty state.
            }

            foreach (DataRow row in dt.Rows)
            {
                int days = row["days_left"] == DBNull.Value ? int.MinValue : Convert.ToInt32(row["days_left"]);
                row["pill_class"] = GetStatusClass(days);
                row["pill_text"] = GetStatusText(days);
            }

            if (dt.Rows.Count == 0)
            {
                rptBorrowed.Visible = false;
                pnlNoBorrowed.Visible = true;
            }
            else
            {
                rptBorrowed.DataSource = dt;
                rptBorrowed.DataBind();
                rptBorrowed.Visible = true;
                pnlNoBorrowed.Visible = false;
            }
        }

        // ---------------------------------------------------------------
        // 4. Reservations + renewals (both from Transactions, no cross join)
        // ---------------------------------------------------------------
        private void LoadActivity(string uid)
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("title", typeof(string));
            dt.Columns.Add("author", typeof(string));
            dt.Columns.Add("cover_path", typeof(string));
            dt.Columns.Add("meta", typeof(string));
            dt.Columns.Add("pill_class", typeof(string));
            dt.Columns.Add("pill_text", typeof(string));

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                {
                    conn.Open();

                    // Reservations / ready-for-pickup
                    const string resSql = @"
                        SELECT r.title, r.author, r.cover_path, t.status
                        FROM Transactions t
                        JOIN Item_Copies       ic ON t.accession_number = ic.accession_number
                        JOIN Library_Resources  r ON ic.resource_id      = r.resource_id
                        WHERE t.user_id = @uid AND t.status IN ('Reserved','Ready')
                        ORDER BY t.created_at DESC;";

                    using (var cmd = new MySqlCommand(resSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@uid", uid);
                        using (var dr = cmd.ExecuteReader())
                        {
                            while (dr.Read())
                            {
                                var row = dt.NewRow();
                                row["title"] = dr["title"];
                                row["author"] = dr["author"];
                                row["cover_path"] = dr["cover_path"];

                                if (string.Equals(dr["status"]?.ToString(), "Ready", StringComparison.Ordinal))
                                {
                                    row["meta"] = "Ready for pickup — please collect at the circulation desk.";
                                    row["pill_class"] = "pd-pill-ready";
                                    row["pill_text"] = "READY";
                                }
                                else
                                {
                                    row["meta"] = "Awaiting staff approval.";
                                    row["pill_class"] = "pd-pill-reserved";
                                    row["pill_text"] = "RESERVED";
                                }
                                dt.Rows.Add(row);
                            }
                        }
                    }

                    // Pending renewals (Transactions.status = 'Renewal')
                    const string renSql = @"
                        SELECT r.title, r.author, r.cover_path, t.due_date
                        FROM Transactions t
                        JOIN Item_Copies       ic ON t.accession_number = ic.accession_number
                        JOIN Library_Resources  r ON ic.resource_id      = r.resource_id
                        WHERE t.user_id = @uid AND t.status = 'Renewal'
                        ORDER BY t.updated_at DESC;";

                    using (var cmd = new MySqlCommand(renSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@uid", uid);
                        using (var dr = cmd.ExecuteReader())
                        {
                            while (dr.Read())
                            {
                                var row = dt.NewRow();
                                row["title"] = dr["title"];
                                row["author"] = dr["author"];
                                row["cover_path"] = dr["cover_path"];
                                row["meta"] = dr["due_date"] == DBNull.Value
                                    ? "Renewal submitted — awaiting librarian approval."
                                    : "Current due " + Convert.ToDateTime(dr["due_date"]).ToString("MMM dd, yyyy")
                                      + " — awaiting librarian approval.";
                                row["pill_class"] = "pd-pill-renewal";
                                row["pill_text"] = "PENDING RENEWAL";
                                dt.Rows.Add(row);
                            }
                        }
                    }
                }
            }
            catch (MySqlException) { /* empty state handles */ }

            if (dt.Rows.Count == 0)
            {
                rptActivity.Visible = false;
                pnlNoActivity.Visible = true;
            }
            else
            {
                rptActivity.DataSource = dt;
                rptActivity.DataBind();
                rptActivity.Visible = true;
                pnlNoActivity.Visible = false;
            }
        }

        // ---------------------------------------------------------------
        // 5. Recommendations based on patron's section history
        // ---------------------------------------------------------------
        private void LoadRecommendations(string uid)
        {
            const string sql = @"
                SELECT DISTINCT lr.resource_id, lr.title, lr.author, lr.cover_path
                FROM Library_Resources lr
                WHERE lr.section IS NOT NULL AND lr.section <> ''
                  AND lr.section IN (
                      SELECT DISTINCT r2.section
                      FROM Transactions t
                      JOIN Item_Copies ic ON t.accession_number = ic.accession_number
                      JOIN Library_Resources r2 ON ic.resource_id = r2.resource_id
                      WHERE t.user_id = @uid
                        AND r2.section IS NOT NULL AND r2.section <> ''
                  )
                  AND lr.resource_id NOT IN (
                      SELECT DISTINCT ic2.resource_id
                      FROM Transactions t2
                      JOIN Item_Copies ic2 ON t2.accession_number = ic2.accession_number
                      WHERE t2.user_id = @uid
                        AND t2.status IN ('Borrowed','Reserved','Ready','Renewal')
                  )
                LIMIT 6;";

            DataTable dt = new DataTable();
            try
            {
                using (var conn = new MySqlConnection(_connStr))
                using (var cmd = new MySqlCommand(sql, conn))
                using (var da = new MySqlDataAdapter(cmd))
                {
                    cmd.Parameters.AddWithValue("@uid", uid);
                    conn.Open();
                    da.Fill(dt);
                }
            }
            catch (MySqlException) { /* empty state handles */ }

            if (dt.Rows.Count == 0)
            {
                rptRecommendations.Visible = false;
                pnlNoRecs.Visible = true;
            }
            else
            {
                rptRecommendations.DataSource = dt;
                rptRecommendations.DataBind();
                rptRecommendations.Visible = true;
                pnlNoRecs.Visible = false;
            }
        }

        // ---------------------------------------------------------------
        // 6. Fines (per penalty, excludes paid balances)
        // ---------------------------------------------------------------
        private void LoadFines(string uid)
        {
            const string sql = @"
                SELECT
                    COALESCE(lr.title, 'Library charge') AS title,
                    p.reason,
                    (p.fine_amount - p.amount_paid)      AS balance
                FROM Penalties p
                LEFT JOIN Transactions t       ON p.transaction_id   = t.transaction_id
                LEFT JOIN Item_Copies ic       ON t.accession_number = ic.accession_number
                LEFT JOIN Library_Resources lr ON ic.resource_id     = lr.resource_id
                WHERE p.user_id = @uid
                  AND p.fine_status IN ('Unpaid','Partial')
                  AND p.fine_amount > p.amount_paid
                ORDER BY p.created_at DESC;";

            DataTable dt = new DataTable();
            try
            {
                using (var conn = new MySqlConnection(_connStr))
                using (var cmd = new MySqlCommand(sql, conn))
                using (var da = new MySqlDataAdapter(cmd))
                {
                    cmd.Parameters.AddWithValue("@uid", uid);
                    conn.Open();
                    da.Fill(dt);
                }
            }
            catch (MySqlException) { /* empty state handles */ }

            if (dt.Rows.Count == 0)
            {
                rptFines.Visible = false;
                pnlNoFines.Visible = true;
            }
            else
            {
                rptFines.DataSource = dt;
                rptFines.DataBind();
                rptFines.Visible = true;
                pnlNoFines.Visible = false;
            }
        }

        // ---------------------------------------------------------------
        // 7. Recent notifications (latest 5)
        // ---------------------------------------------------------------
        private void LoadNotifications(string uid)
        {
            const string sql = @"
                SELECT title, message, is_read, created_at
                FROM Notifications
                WHERE user_id = @uid
                ORDER BY created_at DESC
                LIMIT 5;";

            DataTable dt = new DataTable();
            dt.Columns.Add("title", typeof(string));
            dt.Columns.Add("message", typeof(string));
            dt.Columns.Add("created_at", typeof(DateTime));
            dt.Columns.Add("notif_class", typeof(string));

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@uid", uid);
                    conn.Open();
                    using (var dr = cmd.ExecuteReader())
                    {
                        while (dr.Read())
                        {
                            var row = dt.NewRow();
                            row["title"] = dr["title"] ?? "";
                            row["message"] = dr["message"] ?? "";
                            row["created_at"] = dr["created_at"] == DBNull.Value
                                ? (object)DBNull.Value
                                : Convert.ToDateTime(dr["created_at"]);

                            int isRead = dr["is_read"] == DBNull.Value
                                ? 1
                                : Convert.ToInt32(dr["is_read"]);
                            row["notif_class"] = isRead == 0 ? "is-unread" : "";

                            dt.Rows.Add(row);
                        }
                    }
                }
            }
            catch (MySqlException) { /* empty state handles */ }

            if (dt.Rows.Count == 0)
            {
                rptNotifications.Visible = false;
                pnlNoNotif.Visible = true;
            }
            else
            {
                rptNotifications.DataSource = dt;
                rptNotifications.DataBind();
                rptNotifications.Visible = true;
                pnlNoNotif.Visible = false;
            }
        }

        // ---------------------------------------------------------------
        // 8. Library standing — preserved from Dashboard.aspx.cs,
        //    using Transactions (Borrowed/Returned/Renewed) + Library_Attendance.
        // ---------------------------------------------------------------
        private void LoadRank(string uid)
        {
            const string sql = @"
                SELECT
                    ((SELECT COUNT(*) FROM Transactions
                        WHERE user_id = @uid
                          AND status IN ('Borrowed','Returned','Renewed'))
                     + (SELECT COUNT(*) FROM Library_Attendance
                        WHERE user_id = @uid)) AS my_points,
                    (SELECT COUNT(*) FROM Users
                        WHERE role IN ('student','faculty')
                          AND is_active = 1)   AS community;";

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@uid", uid);
                    conn.Open();
                    using (var dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            int myPoints = SafeInt(dr["my_points"]);
                            int community = SafeInt(dr["community"]);

                            // Same tiers as the original Dashboard.aspx.cs.
                            if (myPoints >= 30 || (community > 0 && myPoints > community * 0.15))
                                litRank.Text = "Top 5% Reader 🏅";
                            else if (myPoints >= 15)
                                litRank.Text = "Active Reader ⭐";
                            else if (myPoints >= 5)
                                litRank.Text = "Rising Reader 🌱";
                            else
                                litRank.Text = "New Explorer 📖";
                        }
                    }
                }
            }
            catch (MySqlException) { /* default remains */ }
        }

        // ---------------------------------------------------------------
        // Helpers
        // ---------------------------------------------------------------
        protected string ResolveCover(object path)
        {
            string p = path as string;
            if (string.IsNullOrWhiteSpace(p))
                return ResolveUrl("~/Images/default_cover.png");

            p = p.TrimStart('~', '/').Replace("\\", "/");
            return ResolveUrl("~/" + p);
        }

        protected static string GetStatusClass(int daysLeft)
        {
            if (daysLeft == int.MinValue) return "pd-pill-normal";
            if (daysLeft < 0) return "pd-pill-overdue";
            if (daysLeft == 0) return "pd-pill-today";
            if (daysLeft <= 3) return "pd-pill-soon";
            return "pd-pill-normal";
        }

        protected static string GetStatusText(int daysLeft)
        {
            if (daysLeft == int.MinValue) return "DUE DATE PENDING";
            if (daysLeft < 0)
            {
                int abs = Math.Abs(daysLeft);
                return abs == 1 ? "1 DAY OVERDUE" : abs + " DAYS OVERDUE";
            }
            if (daysLeft == 0) return "DUE TODAY";
            return daysLeft == 1 ? "1 DAY LEFT" : daysLeft + " DAYS LEFT";
        }

        private static int SafeInt(object o)
        {
            if (o == null || o == DBNull.Value) return 0;
            try { return Convert.ToInt32(o); }
            catch { return 0; }
        }
    }
}