using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.IO;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Patron.History
{
    public partial class History : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private const string DefaultCoverRelativePath = "~/Assets/Covers/default-cover.jpg";

        protected string DefaultCoverUrl
        {
            get { return ResolveUrl(DefaultCoverRelativePath); }
        }

        // ================================================================
        // PAGE LIFECYCLE
        // ================================================================
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
                LoadAll(userId);
            }
        }

        // ================================================================
        // DATA LOADING
        // ================================================================
        private void LoadAll(string userId)
        {
            DataTable dt;
            try
            {
                dt = FetchTransactions(userId);
            }
            catch
            {
                dt = BuildEmptyTable();
            }

            ComputeDerivedFields(dt);

            // IMPORTANT: Sort column names must match the DataTable column names
            // (i.e. the SQL aliases below), NOT C#-style PascalCase names.
            const string sortExpr = "borrow_date DESC, transaction_id DESC";

            DataView activeView = new DataView(dt)
            {
                RowFilter = "IsActiveFlag = 1",
                Sort = sortExpr
            };
            DataView inactiveView = new DataView(dt)
            {
                RowFilter = "IsActiveFlag = 0",
                Sort = sortExpr
            };

            rptActive.DataSource = activeView;
            rptActive.DataBind();

            rptInactive.DataSource = inactiveView;
            rptInactive.DataBind();

            UpdateSummary(dt);
        }

        private DataTable FetchTransactions(string userId)
        {
            DataTable dt = new DataTable();

            using (var conn = new MySqlConnection(connStr))
            {
                // NOTE: Transactions has NO 'balance' or 'fine_status' column.
                //       Fines are sourced ONLY from the Penalties table.
                //       LEFT JOIN preserves transactions that have no penalty yet.
                const string query = @"
                    SELECT
                        t.transaction_id,
                        t.accession_number,
                        t.borrow_date,
                        t.due_date,
                        t.return_date,
                        t.status,
                        t.is_damaged,
                        t.is_lost,
                        t.created_at       AS txn_created_at,
                        r.title,
                        r.author,
                        r.item_type,
                        r.cover_path,
                        p.penalty_id,
                        p.penalty_type,
                        p.reason           AS penalty_reason,
                        p.fine_amount,
                        p.amount_paid,
                        p.fine_status
                    FROM Transactions t
                    INNER JOIN Item_Copies       c ON t.accession_number = c.accession_number
                    INNER JOIN Library_Resources r ON c.resource_id      = r.resource_id
                    LEFT  JOIN Penalties         p ON p.transaction_id   = t.transaction_id
                    WHERE t.user_id = @userId
                    ORDER BY t.borrow_date DESC, t.transaction_id DESC";

                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@userId", userId);
                    using (var da = new MySqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }

            return dt;
        }

        private static DataTable BuildEmptyTable()
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("transaction_id", typeof(int));
            dt.Columns.Add("accession_number", typeof(string));
            dt.Columns.Add("borrow_date", typeof(DateTime));
            dt.Columns.Add("due_date", typeof(DateTime));
            dt.Columns.Add("return_date", typeof(DateTime));
            dt.Columns.Add("status", typeof(string));
            dt.Columns.Add("is_damaged", typeof(int));
            dt.Columns.Add("is_lost", typeof(int));
            dt.Columns.Add("txn_created_at", typeof(DateTime));
            dt.Columns.Add("title", typeof(string));
            dt.Columns.Add("author", typeof(string));
            dt.Columns.Add("item_type", typeof(string));
            dt.Columns.Add("cover_path", typeof(string));
            dt.Columns.Add("penalty_id", typeof(int));
            dt.Columns.Add("penalty_type", typeof(string));
            dt.Columns.Add("penalty_reason", typeof(string));
            dt.Columns.Add("fine_amount", typeof(decimal));
            dt.Columns.Add("amount_paid", typeof(decimal));
            dt.Columns.Add("fine_status", typeof(string));
            return dt;
        }

        // ================================================================
        // DERIVED FIELDS
        // ================================================================
        private void ComputeDerivedFields(DataTable dt)
        {
            dt.Columns.Add("IsActiveFlag", typeof(int));
            dt.Columns.Add("IsOverdueFlag", typeof(int));
            dt.Columns.Add("DaysOverdue", typeof(int));
            dt.Columns.Add("Balance", typeof(decimal));
            dt.Columns.Add("StatusDisplay", typeof(string));
            dt.Columns.Add("StatusCssClass", typeof(string));
            dt.Columns.Add("CoverUrl", typeof(string));
            dt.Columns.Add("BorrowDateText", typeof(string));
            dt.Columns.Add("DueDateText", typeof(string));
            dt.Columns.Add("ReturnDateText", typeof(string));
            dt.Columns.Add("DueDateSubtext", typeof(string));
            dt.Columns.Add("CanRenew", typeof(int));

            foreach (DataRow row in dt.Rows)
            {
                string status = GetString(row, "status");
                DateTime borrowDate = GetDate(row, "borrow_date");
                DateTime dueDate = GetDate(row, "due_date");
                DateTime? returnDate = GetNullableDate(row, "return_date");
                DateTime txnCreated = GetDate(row, "txn_created_at");

                bool isLoanIn = borrowDate != DateTime.MinValue
                                && dueDate != DateTime.MinValue
                                && borrowDate.Date == dueDate.Date;

                bool isActive = IsActiveStatus(status);
                bool isOverdue = ComputeIsOverdue(status, isLoanIn, dueDate, txnCreated, returnDate);

                int unitsOverdue = 0;
                if (isOverdue)
                {
                    unitsOverdue = isLoanIn
                        ? (int)Math.Floor((DateTime.Now - txnCreated).TotalHours)
                        : Math.Max(0, (DateTime.Today - dueDate.Date).Days);
                }

                decimal fineAmount = GetDecimal(row, "fine_amount");
                decimal amountPaid = GetDecimal(row, "amount_paid");
                decimal balance = Math.Max(0m, fineAmount - amountPaid);

                row["IsActiveFlag"] = isActive ? 1 : 0;
                row["IsOverdueFlag"] = isOverdue ? 1 : 0;
                row["DaysOverdue"] = unitsOverdue;
                row["Balance"] = balance;
                row["StatusDisplay"] = BuildStatusDisplay(status, isOverdue, isLoanIn, unitsOverdue);
                row["StatusCssClass"] = BuildStatusCssClass(status, isOverdue);
                row["CoverUrl"] = ResolveCoverUrl(GetString(row, "cover_path"));

                row["BorrowDateText"] = borrowDate == DateTime.MinValue ? "—" : borrowDate.ToString("MMM d, yyyy");
                row["DueDateText"] = dueDate == DateTime.MinValue ? "—" : dueDate.ToString("MMM d, yyyy");
                row["ReturnDateText"] = returnDate.HasValue ? returnDate.Value.ToString("MMM d, yyyy") : "—";

                row["DueDateSubtext"] = BuildDueDateSubtext(
                    status, isLoanIn, isOverdue, unitsOverdue, dueDate, returnDate, balance);

                row["CanRenew"] = (status == "Borrowed" && !isOverdue && !returnDate.HasValue) ? 1 : 0;
            }
        }

        // ================================================================
        // CLASSIFICATION / STATUS HELPERS
        // ================================================================
        private static bool IsActiveStatus(string status)
        {
            // 'Renewed' is treated as inactive: schema comment "closed by an approved renewal".
            switch (status)
            {
                case "Borrowed":
                case "Renewal":
                case "Reserved":
                case "Ready":
                    return true;
                case "Returned":
                case "Cancelled":
                case "Renewed":
                default:
                    return false;
            }
        }

        private static bool ComputeIsOverdue(
            string status, bool isLoanIn, DateTime dueDate, DateTime txnCreated, DateTime? returnDate)
        {
            if (returnDate.HasValue) return false;
            if (status != "Borrowed") return false;

            if (isLoanIn)
                return (DateTime.Now - txnCreated).TotalHours >= 1;

            return dueDate != DateTime.MinValue && DateTime.Today > dueDate.Date;
        }

        private static string BuildStatusDisplay(string status, bool isOverdue, bool isLoanIn, int units)
        {
            if (isOverdue)
                return isLoanIn ? $"Overdue ({units}h)" : $"Overdue ({units}d)";

            switch (status)
            {
                case "Borrowed": return "Borrowed";
                case "Renewal": return "Renewal Pending";
                case "Renewed": return "Renewed";
                case "Reserved": return "Reserved";
                case "Ready": return "Ready for Pickup";
                case "Returned": return "Returned";
                case "Cancelled": return "Cancelled";
                default: return string.IsNullOrEmpty(status) ? "Unknown" : status;
            }
        }

        private static string BuildStatusCssClass(string status, bool isOverdue)
        {
            if (isOverdue) return "sp-badge-overdue";
            switch (status)
            {
                case "Borrowed": return "sp-badge-borrowed";
                case "Renewal": return "sp-badge-renewal";
                case "Renewed": return "sp-badge-renewed";
                case "Reserved": return "sp-badge-reserved";
                case "Ready": return "sp-badge-ready";
                case "Returned": return "sp-badge-returned";
                case "Cancelled": return "sp-badge-cancelled";
                default: return "sp-badge-unknown";
            }
        }

        private static string BuildDueDateSubtext(
            string status, bool isLoanIn, bool isOverdue, int units,
            DateTime dueDate, DateTime? returnDate, decimal balance)
        {
            if (status == "Returned")
                return returnDate.HasValue ? $"Returned on {returnDate.Value:MMM d, yyyy}" : "Returned";

            if (status == "Cancelled") return "Cancelled.";
            if (status == "Renewed") return "Loan replaced by an approved renewal.";

            if (isOverdue)
            {
                string lead = isLoanIn
                    ? $"{units} hour(s) overdue"
                    : $"{units} day(s) overdue";
                if (balance > 0m) lead += $" · Fine ₱{balance:0.00}";
                return lead + ". Please return immediately.";
            }

            if (status == "Renewal") return "Renewal request submitted. Awaiting librarian approval.";
            if (status == "Ready") return "Ready for pickup. Reservation held for 1 hour.";
            if (status == "Reserved") return "Reservation submitted.";

            if (dueDate != DateTime.MinValue)
            {
                if (dueDate.Date == DateTime.Today) return "Due today.";
                if (dueDate.Date > DateTime.Today)
                {
                    int days = (dueDate.Date - DateTime.Today).Days;
                    return $"Due in {days} day(s).";
                }
            }
            return string.Empty;
        }

        // ================================================================
        // COVER RESOLUTION
        // ================================================================
        private string ResolveCoverUrl(string coverPath)
        {
            string fallback = DefaultCoverUrl;
            if (string.IsNullOrWhiteSpace(coverPath)) return fallback;

            string path = coverPath.Trim().Replace('\\', '/');
            int idx = path.IndexOf("Assets/", StringComparison.OrdinalIgnoreCase);
            if (idx < 0) return fallback;

            string relative = "~/" + path.Substring(idx);
            try
            {
                string physical = Server.MapPath(relative);
                if (string.IsNullOrEmpty(physical) || !File.Exists(physical))
                    return fallback;
            }
            catch
            {
                return fallback;
            }
            return ResolveUrl(relative);
        }

        // ================================================================
        // SUMMARY METRICS
        // ================================================================
        private void UpdateSummary(DataTable dt)
        {
            int active = 0, overdue = 0, returned = 0;
            decimal fines = 0m;

            foreach (DataRow row in dt.Rows)
            {
                if ((int)row["IsActiveFlag"] == 1) active++;
                if ((int)row["IsOverdueFlag"] == 1) overdue++;
                if (GetString(row, "status") == "Returned") returned++;
                fines += (decimal)row["Balance"];
            }

            int inactive = dt.Rows.Count - active;

            litTopActive.Text = active.ToString();
            litTopOverdue.Text = overdue.ToString();
            litCardActive.Text = active.ToString();
            litCardOverdue.Text = overdue.ToString();
            litCardFines.Text = fines.ToString("0.00");
            litCardReturned.Text = returned.ToString();
            litActiveTabCount.Text = active.ToString();
            litInactiveTabCount.Text = inactive.ToString();
        }

        // ================================================================
        // RENEWAL SUBMISSION
        // ================================================================
        protected void btnSubmitRenewal_Click(object sender, EventArgs e)
        {
            string userId = Session["UserID"]?.ToString();
            if (string.IsNullOrEmpty(userId))
            {
                Response.Redirect("~/Login/login.aspx");
                return;
            }

            int txnId;
            if (!int.TryParse(hfRenewTxnId.Value, out txnId) || txnId <= 0)
            {
                ShowAlert("Error", "Invalid transaction reference.", "error");
                return;
            }

            try
            {
                string message = TrySubmitRenewal(userId, txnId);
                if (message == null)
                    ShowAlert("Success", "Renewal request submitted. Awaiting librarian approval.", "success");
                else
                    ShowAlert("Notice", message, "info");
            }
            catch
            {
                ShowAlert("Error", "A system error occurred. Please try again later.", "error");
            }

            LoadAll(userId);
            upSummary.Update();
            upActive.Update();
        }

        private string TrySubmitRenewal(string userId, int transactionId)
        {
            using (var conn = new MySqlConnection(connStr))
            {
                conn.Open();

                string status;
                DateTime borrowDate, dueDate, txnCreated;
                bool hasReturn;

                const string fetchSql = @"
                    SELECT status, borrow_date, due_date, return_date, created_at
                    FROM Transactions
                    WHERE transaction_id = @id AND user_id = @uid";

                using (var cmd = new MySqlCommand(fetchSql, conn))
                {
                    cmd.Parameters.AddWithValue("@id", transactionId);
                    cmd.Parameters.AddWithValue("@uid", userId);
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (!reader.Read())
                            return "Transaction not found or does not belong to you.";

                        status = reader["status"].ToString();
                        borrowDate = Convert.ToDateTime(reader["borrow_date"]);
                        dueDate = Convert.ToDateTime(reader["due_date"]);
                        txnCreated = Convert.ToDateTime(reader["created_at"]);
                        hasReturn = reader["return_date"] != DBNull.Value;
                    }
                }

                if (status != "Borrowed" || hasReturn)
                    return "This transaction is not eligible for renewal.";

                bool isLoanIn = borrowDate.Date == dueDate.Date;
                bool isOverdue = isLoanIn
                    ? (DateTime.Now - txnCreated).TotalHours >= 1
                    : DateTime.Today > dueDate.Date;

                if (isOverdue)
                    return "Overdue books cannot be renewed. Please return the item first.";

                const string updateSql = @"
                    UPDATE Transactions
                    SET status = 'Renewal'
                    WHERE transaction_id = @id
                      AND user_id = @uid
                      AND status = 'Borrowed'
                      AND return_date IS NULL";

                using (var cmd = new MySqlCommand(updateSql, conn))
                {
                    cmd.Parameters.AddWithValue("@id", transactionId);
                    cmd.Parameters.AddWithValue("@uid", userId);
                    if (cmd.ExecuteNonQuery() == 0)
                        return "Unable to process the renewal request.";
                }
            }

            return null;
        }

        // ================================================================
        // ALERT HELPER
        // ================================================================
        private void ShowAlert(string title, string message, string icon)
        {
            string script =
                "if (typeof Swal !== 'undefined') {" +
                "  Swal.fire({title:" + JsString(title) +
                ", text:" + JsString(message) +
                ", icon:" + JsString(icon) +
                ", confirmButtonColor:'#14532d'});" +
                "} else { alert(" + JsString(title + ": " + message) + "); }";

            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }

        private static string JsString(string s)
        {
            if (s == null) return "''";
            return "'"
                + s.Replace("\\", "\\\\")
                   .Replace("'", "\\'")
                   .Replace("\r", "\\r")
                   .Replace("\n", "\\n")
                + "'";
        }

        // ================================================================
        // SAFE ACCESSORS
        // ================================================================
        private static string GetString(DataRow row, string col)
        {
            if (!row.Table.Columns.Contains(col)) return string.Empty;
            object v = row[col];
            return (v == null || v == DBNull.Value) ? string.Empty : v.ToString();
        }

        private static decimal GetDecimal(DataRow row, string col)
        {
            if (!row.Table.Columns.Contains(col)) return 0m;
            object v = row[col];
            if (v == null || v == DBNull.Value) return 0m;
            decimal d;
            return decimal.TryParse(v.ToString(), out d) ? d : 0m;
        }

        private static DateTime GetDate(DataRow row, string col)
        {
            if (!row.Table.Columns.Contains(col)) return DateTime.MinValue;
            object v = row[col];
            if (v == null || v == DBNull.Value) return DateTime.MinValue;
            DateTime d;
            return DateTime.TryParse(v.ToString(), out d) ? d : DateTime.MinValue;
        }

        private static DateTime? GetNullableDate(DataRow row, string col)
        {
            if (!row.Table.Columns.Contains(col)) return null;
            object v = row[col];
            if (v == null || v == DBNull.Value) return null;
            DateTime d;
            return DateTime.TryParse(v.ToString(), out d) ? (DateTime?)d : null;
        }

        protected string FormatText(object value, string fallback = "—")
        {
            if (value == null || value == DBNull.Value) return fallback;
            string s = value.ToString();
            return string.IsNullOrWhiteSpace(s) ? fallback : s;
        }
    }
}