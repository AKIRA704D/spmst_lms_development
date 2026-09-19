using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Patron.History
{
    public partial class History : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                string userId = Session["UserID"]?.ToString();
                if (string.IsNullOrEmpty(userId))
                {
                    Response.Redirect("~/Login/login.aspx");
                    return;
                }

                LoadDashboardMetrics(userId);
                LoadTransactionHistory(userId);
            }
        }

        private void LoadDashboardMetrics(string userId)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();

                // Active loans
                string activeQuery = "SELECT COUNT(*) FROM Transactions WHERE user_id = @id AND status IN ('Borrowed', 'Renewed', 'Renewal')";
                MySqlCommand cmdActive = new MySqlCommand(activeQuery, conn);
                cmdActive.Parameters.AddWithValue("@id", userId);
                string activeCount = cmdActive.ExecuteScalar().ToString();
                litTopActive.Text = activeCount;
                litCardActive.Text = activeCount;

                // Overdue count
                string overdueQuery = "SELECT COUNT(*) FROM Transactions WHERE user_id = @id AND status = 'Overdue'";
                MySqlCommand cmdOverdue = new MySqlCommand(overdueQuery, conn);
                cmdOverdue.Parameters.AddWithValue("@id", userId);
                litTopOverdue.Text = cmdOverdue.ExecuteScalar().ToString();

                // Pending fines
                string fineQuery = "SELECT SUM(balance) FROM Transactions WHERE user_id = @id AND fine_status IN ('Unpaid', 'Partial')";
                MySqlCommand cmdFine = new MySqlCommand(fineQuery, conn);
                cmdFine.Parameters.AddWithValue("@id", userId);
                object result = cmdFine.ExecuteScalar();
                string pendingFines = result != DBNull.Value ? Convert.ToDecimal(result).ToString("0.00") : "0.00";
                litCardFines.Text = pendingFines;

                // Returned books count
                string returnedQuery = "SELECT COUNT(*) FROM Transactions WHERE user_id = @id AND status = 'Returned'";
                MySqlCommand cmdReturned = new MySqlCommand(returnedQuery, conn);
                cmdReturned.Parameters.AddWithValue("@id", userId);
                litCardReturned.Text = cmdReturned.ExecuteScalar().ToString();
            }
        }

        private void LoadTransactionHistory(string userId)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                string query = @"
                    SELECT 
                        t.transaction_id, 
                        t.accession_number, 
                        r.title, 
                        r.item_type,
                        t.due_date, 
                        t.return_date, 
                        t.status, 
                        t.balance
                    FROM Transactions t
                    INNER JOIN Item_Copies c ON t.accession_number = c.accession_number
                    INNER JOIN Library_Resources r ON c.resource_id = r.resource_id
                    WHERE t.user_id = @id 
                    AND t.status IN ('Borrowed', 'Returned', 'Renewal')
                    ORDER BY 
                        CASE WHEN t.status IN ('Borrowed', 'Renewal') THEN 1 ELSE 2 END,
                        t.borrow_date DESC";

                MySqlCommand cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@id", userId);
                DataTable dt = new DataTable();
                using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                    da.Fill(dt);
                rptHistory.DataSource = dt;
                rptHistory.DataBind();
            }
        }

        protected void rptHistory_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "RenewBook")
            {
                string transactionId = e.CommandArgument.ToString();

                using (MySqlConnection conn = new MySqlConnection(connStr))
                {
                    string query = "UPDATE Transactions SET status = 'Renewal' WHERE transaction_id = @id AND status = 'Borrowed'";
                    MySqlCommand cmd = new MySqlCommand(query, conn);
                    cmd.Parameters.AddWithValue("@id", transactionId);
                    conn.Open();
                    int rowsAffected = cmd.ExecuteNonQuery();

                    if (rowsAffected > 0)
                    {
                        ShowSweetAlert("Success", "Renewal requested successfully! Awaiting librarian approval.", "success");
                        string userId = Session["UserID"].ToString();
                        LoadDashboardMetrics(userId);
                        LoadTransactionHistory(userId);
                        upHistory.Update();
                    }
                    else
                    {
                        ShowSweetAlert("Notice", "This book cannot be renewed at this time.", "info");
                    }
                }
            }
            else if (e.CommandName == "ViewInfo")
            {
                // Optional: redirect to book details page
                // string accession = e.CommandArgument.ToString();
                // Response.Redirect($"BookDetails.aspx?acc={accession}");
            }
        }

        // ========== UI HELPER METHODS ==========
        protected string GetStatusCssClass(string status)
        {
            switch (status)
            {
                case "Overdue": return "status-overdue";
                case "Borrowed": return "status-borrowed";
                case "Renewal": return "status-renewal";
                case "Returned": return "status-returned";
                default: return "bg-secondary text-white";
            }
        }

        protected string GetStatusSubtext(string status, object balanceObj)
        {
            if (status == "Overdue")
            {
                decimal balance = balanceObj != DBNull.Value ? Convert.ToDecimal(balanceObj) : 0;
                if (balance > 0)
                    return "<div class='small text-danger mt-1'>Settle at counter</div>";
            }
            return "";
        }

        protected string GetDueDateClass(string status, object dueDateObj)
        {
            if (status == "Returned" || status == "Cancelled")
                return "text-secondary";
            if (status == "Overdue")
                return "text-danger fw-bold";
            return "text-dark";
        }

        protected string GetDueDateSubtext(string status, object dueDateObj)
        {
            if (dueDateObj == DBNull.Value) return "-";
            if (status == "Returned") return "Returned";

            DateTime dueDate = Convert.ToDateTime(dueDateObj).Date;
            DateTime today = DateTime.Now.Date;

            if (status == "Overdue" || dueDate < today)
            {
                int days = (today - dueDate).Days;
                return $"{days} days overdue";
            }
            if (dueDate == today)
                return "Return Today";
            int daysRemaining = (dueDate - today).Days;
            return $"In {daysRemaining} days";
        }

        protected string GetBookCoverClass(string itemType)
        {
            if (string.IsNullOrEmpty(itemType)) return "";
            if (itemType.ToLower().Contains("code") || itemType.ToLower().Contains("journal"))
                return "code journal";
            return "";
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