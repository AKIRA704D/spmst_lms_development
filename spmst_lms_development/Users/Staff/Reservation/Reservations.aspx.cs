using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;
using spmst_lms_development.Assets.Helper;

namespace spmst_lms_development.Users.Staff.Reservation
{
    public partial class Reservations : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadData();
                LoadExpiringSoon();
            }
        }

        private void LoadData()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT t.transaction_id, t.user_id, t.accession_number, t.status,
                           r.title, r.call_number,
                           COALESCE(
                        CONCAT(s.first_name,  ' ', s.last_name),
                        CONCAT(f.first_name,  ' ', f.last_name),
                        CONCAT(st.first_name, ' ', st.last_name)
                    ) AS patron_name
                    FROM Transactions t
                    INNER JOIN Item_Copies c ON t.accession_number = c.accession_number
                    INNER JOIN Library_Resources r ON c.resource_id = r.resource_id
                    LEFT JOIN Students s  ON t.user_id = s.student_id
                    LEFT JOIN Faculty  f  ON t.user_id = f.faculty_id
                    LEFT JOIN Staff    st ON t.user_id = st.staff_id
                    WHERE t.status IN ('Reserved', 'Ready')
                      AND t.return_date IS NULL";

                if (!string.IsNullOrEmpty(txtSearchPatron.Text))
                {
                    query += " AND (t.user_id LIKE @search OR s.last_name LIKE @search OR f.last_name LIKE @search OR st.last_name LIKE @search)"; ;
                }
                query += " ORDER BY t.borrow_date DESC";

                MySqlCommand cmd = new MySqlCommand(query, conn);
                if (!string.IsNullOrEmpty(txtSearchPatron.Text))
                    cmd.Parameters.AddWithValue("@search", "%" + txtSearchPatron.Text.Trim() + "%");

                DataTable dt = new DataTable();
                dt.Columns.Add("patron_name");
                dt.Columns.Add("user_id");
                dt.Columns.Add("title");
                dt.Columns.Add("call_number");
                dt.Columns.Add("accession_number");
                dt.Columns.Add("status");
                dt.Columns.Add("transaction_id");

                conn.Open();
                using (MySqlDataReader reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        dt.Rows.Add(
                            reader["patron_name"]?.ToString() ?? "Unknown",
                            reader["user_id"].ToString(),
                            reader["title"].ToString(),
                            reader["call_number"].ToString(),
                            reader["accession_number"].ToString(),
                            reader["status"].ToString(),
                            reader["transaction_id"].ToString()
                        );
                    }
                }
                rptReservations.DataSource = dt;
                rptReservations.DataBind();
                litTotalHolds.Text = dt.Rows.Count.ToString();
            }
        }

        private void LoadExpiringSoon()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                // 1 hour = 3600 seconds. Auto-cancel event runs every minute when updated_at <= NOW() - INTERVAL 1 HOUR.
                // Remaining seconds = (updated_at + 1 hour) - NOW().
                // Show only those with <= 1200 seconds (20 minutes) and > 0 seconds left.
                string query = @"
                    SELECT r.title,
                           t.user_id,
                           COALESCE(
                        CONCAT(s.first_name,  ' ', s.last_name),
                        CONCAT(f.first_name,  ' ', f.last_name),
                        CONCAT(st.first_name, ' ', st.last_name)
                    ) AS patron_name,
                    TIMESTAMPDIFF(SECOND, NOW(), DATE_ADD(t.updated_at, INTERVAL 1 HOUR)) AS seconds_left
                    FROM Transactions t
                    INNER JOIN Item_Copies c ON t.accession_number = c.accession_number
                    INNER JOIN Library_Resources r ON c.resource_id = r.resource_id
                    LEFT JOIN Students s  ON t.user_id = s.student_id
                    LEFT JOIN Faculty  f  ON t.user_id = f.faculty_id
                    LEFT JOIN Staff    st ON t.user_id = st.staff_id
                    WHERE t.status = 'Ready'
                      AND t.return_date IS NULL
                      AND TIMESTAMPDIFF(SECOND, NOW(), DATE_ADD(t.updated_at, INTERVAL 1 HOUR)) <= 1200
                      AND TIMESTAMPDIFF(SECOND, NOW(), DATE_ADD(t.updated_at, INTERVAL 1 HOUR)) > 0
                    ORDER BY t.updated_at ASC";

                DataTable dt = new DataTable();
                using (MySqlDataAdapter da = new MySqlDataAdapter(query, conn))
                    da.Fill(dt);

                rptExpiring.DataSource = dt;
                rptExpiring.DataBind();

                // Update count badge and placeholder
                litExpiringCount.Text = dt.Rows.Count.ToString();
                phNoExpiring.Visible = dt.Rows.Count == 0;
            }
        }

        protected void HandleAction_Click(object sender, EventArgs e)
        {
            LinkButton btn = (LinkButton)sender;
            string transId = btn.CommandArgument;

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                conn.Open();
                using (MySqlTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        // Get patron and book info for notification
                        string infoQuery = @"
                            SELECT t.user_id, r.title
                            FROM Transactions t
                            JOIN Item_Copies c ON t.accession_number = c.accession_number
                            JOIN Library_Resources r ON c.resource_id = r.resource_id
                            WHERE t.transaction_id = @tid";
                        string userId = "";
                        string bookTitle = "";
                        using (MySqlCommand cmdInfo = new MySqlCommand(infoQuery, conn, trans))
                        {
                            cmdInfo.Parameters.AddWithValue("@tid", transId);
                            using (MySqlDataReader reader = cmdInfo.ExecuteReader())
                            {
                                if (reader.Read())
                                {
                                    userId = reader["user_id"].ToString();
                                    bookTitle = reader["title"].ToString();
                                }
                            }
                        }

                        if (string.IsNullOrEmpty(userId))
                        {
                            trans.Rollback();
                            ShowSweetAlert("Error", "Transaction not found.", "error");
                            LoadData();
                            return;
                        }

                        // Update status to 'Ready' (updated_at will auto-update to NOW())
                        string updateSql = "UPDATE Transactions SET status = 'Ready' WHERE transaction_id = @tid AND status = 'Reserved'";
                        MySqlCommand cmdUpdate = new MySqlCommand(updateSql, conn, trans);
                        cmdUpdate.Parameters.AddWithValue("@tid", transId);
                        int rowsAffected = cmdUpdate.ExecuteNonQuery();

                        if (rowsAffected > 0)
                        {
                            trans.Commit();

                            // In-app notification (existing)
                            InsertNotification(userId, bookTitle);

                            // ✨ SMS notification (NEW)
                            int txnId = Convert.ToInt32(transId);
                            SmsResult sms = ReservationSmsService.SendReadySms(userId, bookTitle, txnId);

                            string msg = string.Format(
                                "Book marked as Ready. Patron notified about '{0}'.", bookTitle);

                            if (!sms.Success)
                                msg += " (SMS not sent: " + sms.Error + ")";

                            ShowSweetAlert("Success", msg, sms.Success ? "success" : "warning");
                        }
                        else
                        {
                            trans.Rollback();
                            ShowSweetAlert("Info", "This reservation may have already been processed.", "info");
                        }
                    }
                    catch (Exception ex)
                    {
                        trans.Rollback();
                        ShowSweetAlert("Error", ex.Message, "error");
                    }
                }
            }
            LoadData();
            LoadExpiringSoon();
        }

        private void InsertNotification(string userId, string bookTitle)
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string insertSql = @"
                    INSERT INTO Notifications (user_id, title, message, is_read, created_at)
                    VALUES (@uid, 'Book Ready for Pickup', @msg, 0, NOW())";
                string message = $"Your reserved book '{bookTitle}' is now ready for pickup at the circulation desk. Please claim it before the library closes today.";
                MySqlCommand cmd = new MySqlCommand(insertSql, conn);
                cmd.Parameters.AddWithValue("@uid", userId);
                cmd.Parameters.AddWithValue("@msg", message);
                conn.Open();
                cmd.ExecuteNonQuery();
            }
        }

        protected void FilterReservations(object sender, EventArgs e)
        {
            LoadData();
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"showSweetAlert('{cleanTitle}', '{cleanMsg}', '{icon}');";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }

        // ============================================
        // Helper methods used by the Expiring Soon card
        // ============================================
        protected string GetCountdownClass(object secondsLeft)
        {
            if (secondsLeft == null || secondsLeft == DBNull.Value) return "countdown-warn";
            int secs = Convert.ToInt32(secondsLeft);
            return secs <= 300 ? "countdown-urgent" : "countdown-warn";
        }

        protected string FormatTimeLeft(object secondsLeft)
        {
            if (secondsLeft == null || secondsLeft == DBNull.Value) return "";
            int secs = Convert.ToInt32(secondsLeft);
            if (secs <= 0) return "Expiring now";
            int mins = secs / 60;
            return mins < 1 ? "< 1 min left" : mins + " min left";
        }
    }
}