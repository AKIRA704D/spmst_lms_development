using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Patron.Reservations
{
    public partial class ToPickUp : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            string userId = Session["UserID"]?.ToString();
            if (string.IsNullOrEmpty(userId))
            {
                Response.Redirect("~/Login/login.aspx");
                return;
            }

            if (!IsPostBack)
            {
                // Expire any reservations that passed 5:00 PM (library closing)
                ExpirePastDueReservations();
                LoadReservations();
            }
        }

        private void ExpirePastDueReservations()
        {
            DateTime now = DateTime.Now;
            DateTime closingTime = new DateTime(now.Year, now.Month, now.Day, 17, 0, 0); // 5:00 PM

            if (now > closingTime)
            {
                using (MySqlConnection conn = new MySqlConnection(connStr))
                {
                    string sql = @"
                        UPDATE Transactions t
                        JOIN Item_Copies ic ON t.accession_number = ic.accession_number
                        SET t.status = 'Cancelled',
                            ic.is_available = 1,
                            ic.status_condition = 'Good'
                        WHERE t.status = 'Ready' AND t.due_date < CURDATE()";
                    MySqlCommand cmd = new MySqlCommand(sql, conn);
                    conn.Open();
                    cmd.ExecuteNonQuery();
                }
            }
        }

        private void LoadReservations()
        {
            string userId = Session["UserID"].ToString();
            int readyCount = 0;
            int processingCount = 0;

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                string query = @"
                    SELECT 
                        t.transaction_id AS TransactionID,
                        t.accession_number AS AccessionNumber,
                        lr.title AS Title,
                        lr.author AS Author,
                        t.borrow_date AS ReservedDate,
                        t.due_date AS DeadlineDate,
                        t.status AS Status
                    FROM Transactions t
                    INNER JOIN Item_Copies ic ON t.accession_number = ic.accession_number
                    INNER JOIN Library_Resources lr ON ic.resource_id = lr.resource_id
                    WHERE t.user_id = @UserId AND t.status IN ('Reserved', 'Ready')
                    ORDER BY t.borrow_date DESC";

                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@UserId", userId);
                    using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);

                        foreach (DataRow row in dt.Rows)
                        {
                            string status = row["Status"].ToString();
                            if (status == "Ready") readyCount++;
                            else if (status == "Reserved") processingCount++;
                        }

                        litReadyCount.Text = readyCount.ToString();
                        litProcessingCount.Text = processingCount.ToString();

                        rptReservations.DataSource = dt;
                        rptReservations.DataBind();
                    }
                }
            }
        }

        protected void rptReservations_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "CancelReservation")
            {
                string[] args = e.CommandArgument.ToString().Split('|');
                if (args.Length >= 3)
                {
                    string transactionId = args[0];
                    string accessionNum = args[1];
                    string bookTitle = args[2];

                    using (MySqlConnection conn = new MySqlConnection(connStr))
                    {
                        conn.Open();
                        using (MySqlTransaction trans = conn.BeginTransaction())
                        {
                            try
                            {
                                // Update transaction status
                                string cancelSql = "UPDATE Transactions SET status = 'Cancelled' WHERE transaction_id = @TransID";
                                MySqlCommand cancelCmd = new MySqlCommand(cancelSql, conn, trans);
                                cancelCmd.Parameters.AddWithValue("@TransID", transactionId);
                                cancelCmd.ExecuteNonQuery();

                                // Make copy available again
                                string updateSql = "UPDATE Item_Copies SET status_condition = 'Good', is_available = 1 WHERE accession_number = @Accession";
                                MySqlCommand updateCmd = new MySqlCommand(updateSql, conn, trans);
                                updateCmd.Parameters.AddWithValue("@Accession", accessionNum);
                                updateCmd.ExecuteNonQuery();

                                trans.Commit();

                                ShowSweetAlert("Cancelled", $"Your reservation for '{bookTitle}' has been cancelled.", "success");
                                LoadReservations();
                            }
                            catch (Exception ex)
                            {
                                trans.Rollback();
                                ShowSweetAlert("Error", ex.Message, "error");
                            }
                        }
                    }
                }
            }
        }

        // ========== UI HELPER METHODS ==========
        protected string GetStatusCss(string status)
        {
            return status == "Ready" ? "status-ready" : "status-processing";
        }

        protected string GetDeadlineDate(string status, object deadlineObj)
        {
            if (status == "Ready" && deadlineObj != DBNull.Value)
                return Convert.ToDateTime(deadlineObj).ToString("MMM dd, yyyy");
            return "Estimating...";
        }

        protected string GetDeadlineTime(string status)
        {
            return status == "Ready" ? "Expires Today at 5:00 PM" : "";
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"showSweetAlert('{cleanTitle}', '{cleanMsg}', '{icon}');";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }
    }
}