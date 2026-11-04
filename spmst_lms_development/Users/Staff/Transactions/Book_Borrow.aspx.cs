using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Staff.Transactions
{
    public partial class Book_Borrow : System.Web.UI.Page
    {
        private readonly string _connStr =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        private readonly string EncryptionKey = "SPAMAST_LMS_SECURE_KEY_2026";

        // Sections restricted to LOAN-IN only.
        private static readonly HashSet<string> LoanInOnlySections =
            new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "Periodicals",
            "Reference",
            "Thesis"
        };

        protected string DefaultCoverUrl
        {
            get { return ResolveUrl("~/Assets/Covers/default-cover.jpg"); }
        }

      

        protected void Page_Load(object sender, EventArgs e)
        {
            hfDefaultCover.Value = DefaultCoverUrl;

            if (!IsPostBack)
            {
                string currentPage = System.IO.Path.GetFileName(Request.Url.AbsolutePath);
                if (currentPage.Equals("Book_Borrow.aspx", StringComparison.OrdinalIgnoreCase))
                {
                    lnkBorrow.CssClass = "nav-link active fw-semibold";
                    lnkReturn.CssClass = "nav-link text-secondary fw-semibold";
                    lnkRenew.CssClass = "nav-link text-secondary fw-semibold";
                }
                UpdateLiveFeed();
                LoadTodayTransactions();
            }
        }

        // ============================================================
        //  STEP 1 : PATRON SCAN
        // ============================================================
        protected void txtPatronQR_TextChanged(object sender, EventArgs e)
        {
            string scannedText = txtPatronQR.Text.Trim();
            if (string.IsNullOrEmpty(scannedText)) return;

            string decryptedId = DecryptString(scannedText);
            string id = !string.IsNullOrEmpty(decryptedId) ? decryptedId : scannedText;

            string firstName = null;
            string lastName = null;
            string dept = null;
            string role = null;

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT first_name, last_name, course AS dept, 'student' AS role
                      FROM Students WHERE student_id = @id
                    UNION
                    SELECT first_name, last_name, institute AS dept, 'faculty' AS role
                      FROM Faculty WHERE faculty_id = @id
                    UNION
                    SELECT first_name, last_name, office_department AS dept, 'staff' AS role
                      FROM Staff WHERE staff_id = @id";

                MySqlCommand cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@id", id);
                conn.Open();

                using (MySqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        firstName = reader["first_name"].ToString();
                        lastName = reader["last_name"].ToString();
                        dept = reader["dept"].ToString();
                        role = reader["role"].ToString();
                    }
                }
            }

            if (firstName == null)
            {
                ShowToast("User not found or invalid QR code.", "error");
                ResetForm();
                return;
            }

            pnlPatronInfo.Visible = true;
            litPatronName.Text = $"{firstName} {lastName}";
            litPatronDept.Text = dept;
            litPatronRole.Text = role.ToUpper();
            litInitial.Text = firstName.Length > 0 ? firstName.Substring(0, 1) : "?";

            ViewState["DecryptedPatronID"] = id;
            ViewState["UserRole"] = role;

            // Clear any previously selected reservation / book panel.
            ViewState["SelectedTransactionID"] = null;
            ViewState["SelectedAccession"] = null;
            ViewState["ScannedResourceID"] = null;
            ViewState["ScannedSection"] = null;
            pnlBookInfo.Visible = false;

            txtPatronQR.Text = "VALID ID SCANNED";
            divBookStep.Attributes["class"] = "mb-4";
            txtBookBarcode.Enabled = true;
            btnBookCam.Disabled = false;

            // Automatically retrieve this patron's Reserved and active transactions.
            BindPatronTransactions(id);

            txtBookBarcode.Focus();
        }

        // ============================================================
        //  STEP 2 : BOOK SCAN (MANUAL FALLBACK)
        // ============================================================
        protected void txtBookBarcode_TextChanged(object sender, EventArgs e)
        {
            string barcode = txtBookBarcode.Text.Trim();
            string patronId = ViewState["DecryptedPatronID"]?.ToString();

            if (string.IsNullOrEmpty(barcode)) return;
            if (string.IsNullOrEmpty(patronId))
            {
                ShowToast("Please scan Patron ID first.", "warning");
                txtBookBarcode.Text = "";
                return;
            }

            pnlBookInfo.Visible = false;
            ViewState["SelectedTransactionID"] = null;
            ViewState["SelectedAccession"] = null;

            try
            {
                using (MySqlConnection conn = new MySqlConnection(_connStr))
                {
                    string query = @"
                        SELECT r.resource_id, r.title, r.author, r.section,
                               c.accession_number, c.is_available,
                               t.user_id AS active_user, t.status AS active_status
                        FROM Library_Resources r
                        JOIN Item_Copies c ON r.resource_id = c.resource_id
                        LEFT JOIN Transactions t
                               ON c.accession_number = t.accession_number
                              AND t.status IN ('Reserved','Ready','Borrowed')
                        WHERE c.accession_number = @acc
                        LIMIT 1";

                    MySqlCommand cmd = new MySqlCommand(query, conn);
                    cmd.Parameters.AddWithValue("@acc", barcode);
                    conn.Open();

                    using (MySqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            string resourceId = reader["resource_id"].ToString();
                            string activeUser = reader["active_user"]?.ToString();
                            string activeStatus = reader["active_status"]?.ToString();
                            bool isAvailable = Convert.ToInt32(reader["is_available"]) == 1;
                            string section = reader["section"].ToString();

                            if (activeStatus == "Borrowed")
                            {
                                ShowToast("This book is currently borrowed.", "error");
                                txtBookBarcode.Text = "";
                                txtBookBarcode.Focus();
                                return;
                            }
                            else if (activeStatus == "Reserved" || activeStatus == "Ready")
                            {
                                if (activeUser != patronId)
                                {
                                    ShowToast("This book is already reserved by someone else.", "error");
                                    txtBookBarcode.Text = "";
                                    txtBookBarcode.Focus();
                                    return;
                                }
                            }
                            else if (!isAvailable)
                            {
                                ShowToast("This book is currently unavailable.", "error");
                                txtBookBarcode.Text = "";
                                txtBookBarcode.Focus();
                                return;
                            }

                            pnlBookInfo.Visible = true;
                            litBookTitle.Text = reader["title"].ToString();
                            litBookAuthor.Text = reader["author"].ToString();
                            litBookSection.Text = section;
                            litBookAccNo.Text = reader["accession_number"].ToString();

                            ViewState["ScannedResourceID"] = resourceId;
                            ViewState["ScannedSection"] = section;

                            ConfigureLoanTypeOptions(section);

                            ShowToast("Book Recognized: " + reader["title"], "success");
                        }
                        else
                        {
                            ShowToast("Accession number not found in system.", "warning");
                            txtBookBarcode.Text = "";
                            txtBookBarcode.Focus();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ShowToast("Database error: " + ex.Message, "error");
            }
        }

        // ============================================================
        //  SELECT EXISTING RESERVED TRANSACTION
        // ============================================================
        protected void rptReservedTransactions_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (!string.Equals(e.CommandName, "SelectReservation", StringComparison.OrdinalIgnoreCase))
                return;

            int transactionId;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out transactionId))
                return;

            string patronId = ViewState["DecryptedPatronID"]?.ToString();
            if (string.IsNullOrEmpty(patronId))
            {
                ShowToast("Please scan Patron ID first.", "warning");
                return;
            }

            DataRow row = GetReservedTransaction(patronId, transactionId);
            if (row == null)
            {
                ShowToast("This reservation is no longer available for this patron.", "error");
                BindPatronTransactions(patronId);
                return;
            }

            PopulateBookPanel(row, transactionId);
        }

        // ============================================================
        //  COMPLETE TRANSACTION
        // ============================================================
        protected void btnComplete_Click(object sender, EventArgs e)
        {
            string studentID = ViewState["DecryptedPatronID"]?.ToString();

            int selectedTransactionId;
            bool hasSelectedReservation =
                int.TryParse(Convert.ToString(ViewState["SelectedTransactionID"]), out selectedTransactionId)
                && selectedTransactionId > 0;

            string barcode = hasSelectedReservation
                ? Convert.ToString(ViewState["SelectedAccession"])
                : litBookAccNo.Text;

            barcode = (barcode ?? string.Empty).Trim();

            string role = ViewState["UserRole"]?.ToString() ?? "student";
            string resourceId = ViewState["ScannedResourceID"]?.ToString();
            string loanType = ddlLoanType.SelectedValue;

            if (string.IsNullOrEmpty(studentID) || string.IsNullOrEmpty(barcode))
            {
                ShowSweetAlert("Error", "Missing Patron or Book information.", "error");
                return;
            }

            string scannedSection = ViewState["ScannedSection"]?.ToString() ?? string.Empty;
            bool isLoanInOnly = LoanInOnlySections.Contains(scannedSection.Trim());

            if (isLoanInOnly && loanType != "LOAN-IN")
            {
                ShowSweetAlert("Invalid Loan Type", "This section is for LOAN-IN only.", "error");
                return;
            }
            if (!isLoanInOnly && loanType != "LOAN-OUT" && loanType != "LOAN-IN")
            {
                ShowSweetAlert("Invalid Loan Type", "Invalid loan type selected.", "error");
                return;
            }

            DateTime borrowDate = DateTime.Today;
            DateTime dueDate;

            if (loanType == "LOAN-OUT")
                dueDate = (role == "faculty" || role == "staff")
                          ? borrowDate.AddDays(150)
                          : borrowDate.AddDays(3);
            else
                dueDate = borrowDate;

            string status = "Borrowed";

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                conn.Open();
                using (MySqlTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        bool isReservationSwap = false;

                        if (hasSelectedReservation)
                        {
                            // Process the exact Reserved transaction selected by staff.
                            string checkSelected = @"
                                SELECT accession_number, status
                                  FROM Transactions
                                 WHERE transaction_id = @tid
                                   AND user_id = @uid
                                 FOR UPDATE";

                            string dbAcc = null;
                            string dbStatus = null;

                            MySqlCommand cmdSel = new MySqlCommand(checkSelected, conn, trans);
                            cmdSel.Parameters.AddWithValue("@tid", selectedTransactionId);
                            cmdSel.Parameters.AddWithValue("@uid", studentID);

                            using (MySqlDataReader r = cmdSel.ExecuteReader())
                            {
                                if (r.Read())
                                {
                                    dbAcc = r["accession_number"].ToString();
                                    dbStatus = r["status"].ToString();
                                }
                            }

                            if (string.IsNullOrEmpty(dbAcc))
                                throw new InvalidOperationException("The selected reservation was not found for this patron.");

                            if (!string.Equals(dbStatus, "Reserved", StringComparison.OrdinalIgnoreCase))
                                throw new InvalidOperationException("The selected transaction is no longer in Reserved status.");

                            barcode = dbAcc;

                            string updateSelected = @"
                                UPDATE Transactions
                                   SET status      = @status,
                                       borrow_date = @borrowDate,
                                       due_date    = @dueDate
                                 WHERE transaction_id = @tid
                                   AND user_id = @uid
                                   AND status = 'Reserved'";

                            MySqlCommand cmdUpSel = new MySqlCommand(updateSelected, conn, trans);
                            cmdUpSel.Parameters.AddWithValue("@status", status);
                            cmdUpSel.Parameters.AddWithValue("@borrowDate", borrowDate);
                            cmdUpSel.Parameters.AddWithValue("@dueDate", dueDate);
                            cmdUpSel.Parameters.AddWithValue("@tid", selectedTransactionId);
                            cmdUpSel.Parameters.AddWithValue("@uid", studentID);

                            int affected = cmdUpSel.ExecuteNonQuery();
                            if (affected != 1)
                                throw new InvalidOperationException("The reservation could not be processed because its status changed.");
                        }
                        else
                        {
                            // ---- 1. Exact reservation match? ----
                            string checkExact = @"
                                SELECT transaction_id FROM Transactions
                                WHERE user_id = @uid
                                  AND accession_number = @acc
                                  AND status IN ('Reserved','Ready')
                                LIMIT 1";

                            MySqlCommand cmdExact = new MySqlCommand(checkExact, conn, trans);
                            cmdExact.Parameters.AddWithValue("@uid", studentID);
                            cmdExact.Parameters.AddWithValue("@acc", barcode);
                            object exactResId = cmdExact.ExecuteScalar();

                            if (exactResId != null)
                            {
                                string updateTrans = @"
                                    UPDATE Transactions
                                       SET status      = @status,
                                           borrow_date = @borrowDate,
                                           due_date    = @dueDate
                                     WHERE transaction_id = @tid";

                                MySqlCommand cmdUp = new MySqlCommand(updateTrans, conn, trans);
                                cmdUp.Parameters.AddWithValue("@status", status);
                                cmdUp.Parameters.AddWithValue("@borrowDate", borrowDate);
                                cmdUp.Parameters.AddWithValue("@dueDate", dueDate);
                                cmdUp.Parameters.AddWithValue("@tid", exactResId);
                                cmdUp.ExecuteNonQuery();
                            }
                            else
                            {
                                // ---- 2. Reservation on a different copy of same resource? ----
                                string checkDiff = @"
                                    SELECT t.transaction_id, t.accession_number
                                    FROM Transactions t
                                    JOIN Item_Copies c ON t.accession_number = c.accession_number
                                    WHERE t.user_id = @uid
                                      AND c.resource_id = @resId
                                      AND t.status IN ('Reserved','Ready')
                                      AND t.accession_number <> @acc
                                    LIMIT 1";

                                MySqlCommand cmdDiff = new MySqlCommand(checkDiff, conn, trans);
                                cmdDiff.Parameters.AddWithValue("@uid", studentID);
                                cmdDiff.Parameters.AddWithValue("@resId", (object)resourceId ?? DBNull.Value);
                                cmdDiff.Parameters.AddWithValue("@acc", barcode);

                                int diffTxnId = 0;

                                using (MySqlDataReader reader = cmdDiff.ExecuteReader())
                                {
                                    if (reader.Read())
                                    {
                                        diffTxnId = Convert.ToInt32(reader["transaction_id"]);
                                        isReservationSwap = true;
                                    }
                                }

                                if (diffTxnId > 0)
                                {
                                    string updateDiff = @"
                                        UPDATE Transactions
                                           SET accession_number = @newAcc,
                                               status           = @status,
                                               borrow_date      = @borrowDate,
                                               due_date         = @dueDate
                                         WHERE transaction_id = @tid";

                                    MySqlCommand cmdUpDiff = new MySqlCommand(updateDiff, conn, trans);
                                    cmdUpDiff.Parameters.AddWithValue("@newAcc", barcode);
                                    cmdUpDiff.Parameters.AddWithValue("@status", status);
                                    cmdUpDiff.Parameters.AddWithValue("@borrowDate", borrowDate);
                                    cmdUpDiff.Parameters.AddWithValue("@dueDate", dueDate);
                                    cmdUpDiff.Parameters.AddWithValue("@tid", diffTxnId);
                                    cmdUpDiff.ExecuteNonQuery();
                                }
                                else
                                {
                                    // ---- 3. Plain new loan ----
                                    string insertTrans = @"
                                        INSERT INTO Transactions
                                            (user_id, accession_number, borrow_date, due_date, status)
                                        VALUES
                                            (@uid, @acc, @borrowDate, @dueDate, @status)";

                                    MySqlCommand cmdIn = new MySqlCommand(insertTrans, conn, trans);
                                    cmdIn.Parameters.AddWithValue("@uid", studentID);
                                    cmdIn.Parameters.AddWithValue("@acc", barcode);
                                    cmdIn.Parameters.AddWithValue("@borrowDate", borrowDate);
                                    cmdIn.Parameters.AddWithValue("@dueDate", dueDate);
                                    cmdIn.Parameters.AddWithValue("@status", status);
                                    cmdIn.ExecuteNonQuery();
                                }
                            }
                        }

                        trans.Commit();

                        string dueDateMessage = loanType == "LOAN-IN"
                            ? "Must be returned today"
                            : $"Due on: {dueDate:MMMM dd, yyyy}";

                        string successMessage;
                        if (hasSelectedReservation)
                            successMessage = $"Reservation processed! {dueDateMessage}";
                        else if (isReservationSwap)
                            successMessage = $"Reservation swapped and {dueDateMessage}";
                        else
                            successMessage = $"Transaction successful! {dueDateMessage}";

                        ShowSweetAlert("Success!", successMessage, "success");
                        ResetForm();

                        LoadTodayTransactions();
                        UPCirculation.Update();
                        UPLiveFeed.Update();
                    }
                    catch (Exception ex)
                    {
                        trans.Rollback();
                        ShowSweetAlert("Failed", ex.Message, "error");
                    }
                }
            }
        }

        // ============================================================
        //  PATRON TRANSACTION RETRIEVAL
        // ============================================================
        private DataTable GetPatronTransactions(string patronId, bool reservedOnly)
        {
            string statusClause = reservedOnly
                ? "t.status IN ('Reserved','Ready')"
                : "t.status IN ('Reserved','Ready','Borrowed','Renewal')";

            string query = $@"
                SELECT
                    t.transaction_id   AS TransactionID,
                    t.user_id          AS PatronID,
                    t.accession_number AS AccessionNumber,
                    t.status           AS Status,
                    t.borrow_date      AS BorrowDate,
                    t.due_date         AS DueDate,
                    CASE WHEN t.due_date = t.borrow_date
                         THEN 'LOAN-IN' ELSE 'LOAN-OUT' END AS LoanType,
                    r.resource_id      AS ResourceID,
                    r.title            AS BookTitle,
                    r.author           AS Author,
                    r.section          AS Section,
                    r.cover_path       AS CoverPath,
                    p.penalty_type     AS PenaltyType,
                    p.fine_amount      AS FineAmount,
                    p.fine_status      AS FineStatus
                FROM Transactions t
                JOIN Item_Copies       c ON t.accession_number = c.accession_number
                JOIN Library_Resources r ON c.resource_id      = r.resource_id
                LEFT JOIN Penalties    p ON p.penalty_id       = t.penalty_id
                WHERE t.user_id = @uid
                  AND {statusClause}
                ORDER BY t.transaction_id DESC";

            DataTable dt = new DataTable();

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            using (MySqlCommand cmd = new MySqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("@uid", patronId);
                using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                    da.Fill(dt);
            }

            return dt;
        }

        private DataRow GetReservedTransaction(string patronId, int transactionId)
        {
            string query = @"
                SELECT
                    t.transaction_id   AS TransactionID,
                    t.user_id          AS PatronID,
                    t.accession_number AS AccessionNumber,
                    t.status           AS Status,
                    t.borrow_date      AS BorrowDate,
                    t.due_date         AS DueDate,
                    CASE WHEN t.due_date = t.borrow_date
                         THEN 'LOAN-IN' ELSE 'LOAN-OUT' END AS LoanType,
                    r.resource_id      AS ResourceID,
                    r.title            AS BookTitle,
                    r.author           AS Author,
                    r.section          AS Section,
                    r.cover_path       AS CoverPath,
                    p.penalty_type     AS PenaltyType,
                    p.fine_amount      AS FineAmount,
                    p.fine_status      AS FineStatus
                FROM Transactions t
                JOIN Item_Copies       c ON t.accession_number = c.accession_number
                JOIN Library_Resources r ON c.resource_id      = r.resource_id
                LEFT JOIN Penalties    p ON p.penalty_id       = t.penalty_id
                WHERE t.transaction_id = @tid
                  AND t.user_id = @uid
                  AND t.status = 'Reserved'
                LIMIT 1";

            DataTable dt = new DataTable();

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            using (MySqlCommand cmd = new MySqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("@tid", transactionId);
                cmd.Parameters.AddWithValue("@uid", patronId);

                using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                    da.Fill(dt);
            }

            return dt.Rows.Count > 0 ? dt.Rows[0] : null;
        }

        private void BindPatronTransactions(string patronId)
        {
            DataTable reserved = GetPatronTransactions(patronId, true);
            rptReservedTransactions.DataSource = reserved;
            rptReservedTransactions.DataBind();
            pnlReservedTransactions.Visible = reserved.Rows.Count > 0;
            pnlNoReserved.Visible = reserved.Rows.Count == 0;
            litReservedCount.Text = reserved.Rows.Count.ToString();

            DataTable active = GetPatronTransactions(patronId, false);
            rptActiveTransactions.DataSource = active;
            rptActiveTransactions.DataBind();
            pnlActiveSummary.Visible = active.Rows.Count > 0;
            litActiveCount.Text = active.Rows.Count.ToString();
        }

        private void PopulateBookPanel(DataRow row, int? transactionId)
        {
            string section = Convert.ToString(row["Section"]);
            string accession = Convert.ToString(row["AccessionNumber"]);

            litBookTitle.Text = Convert.ToString(row["BookTitle"]);
            litBookAuthor.Text = DisplayText(row["Author"]);
            litBookSection.Text = DisplayText(section);
            litBookAccNo.Text = accession;

            pnlBookInfo.Visible = true;

            ViewState["ScannedResourceID"] = Convert.ToString(row["ResourceID"]);
            ViewState["ScannedSection"] = section;
            ViewState["SelectedTransactionID"] = transactionId;
            ViewState["SelectedAccession"] = accession;

            ConfigureLoanTypeOptions(section);

            ShowToast("Reservation selected: " + litBookTitle.Text, "success");
        }

        private void ConfigureLoanTypeOptions(string section)
        {
            string cleanSection = (section ?? string.Empty).Trim();
            bool isLoanInOnly = LoanInOnlySections.Contains(cleanSection);

            var loanOutItem = ddlLoanType.Items.FindByValue("LOAN-OUT");
            var loanInItem = ddlLoanType.Items.FindByValue("LOAN-IN");

            if (loanOutItem == null || loanInItem == null)
            {
                ShowToast("Loan type options are not configured correctly.", "error");
                return;
            }

            if (isLoanInOnly)
            {
                loanOutItem.Enabled = false;
                loanInItem.Enabled = true;
                ddlLoanType.SelectedValue = "LOAN-IN";
            }
            else
            {
                loanOutItem.Enabled = true;
                loanInItem.Enabled = true;
                ddlLoanType.SelectedValue = "LOAN-OUT";
            }
        }

        // ============================================================
        //  RESET / FEED / HELPERS
        // ============================================================
        private void ResetForm()
        {
            pnlPatronInfo.Visible = false;
            pnlBookInfo.Visible = false;
            pnlReservedTransactions.Visible = false;
            pnlNoReserved.Visible = false;
            pnlActiveSummary.Visible = false;

            rptReservedTransactions.DataSource = null;
            rptReservedTransactions.DataBind();
            rptActiveTransactions.DataSource = null;
            rptActiveTransactions.DataBind();

            litReservedCount.Text = "0";
            litActiveCount.Text = "0";

            txtPatronQR.Text = "";
            txtBookBarcode.Text = "";
            txtBookBarcode.Enabled = false;
            btnBookCam.Disabled = true;
            divBookStep.Attributes["class"] = "mb-4 step-locked";

            ViewState["DecryptedPatronID"] = null;
            ViewState["UserRole"] = null;
            ViewState["ScannedResourceID"] = null;
            ViewState["ScannedSection"] = null;
            ViewState["SelectedTransactionID"] = null;
            ViewState["SelectedAccession"] = null;

            txtPatronQR.Focus();
        }

        private void LoadTodayTransactions()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT
                        CONCAT(COALESCE(s.first_name, f.first_name, st.first_name), ' ',
                               COALESCE(s.last_name,  f.last_name,  st.last_name))  AS PatronName,
                        t.user_id          AS PatronID,
                        r.title            AS BookTitle,
                        c.accession_number AS AccessionNumber,
                        CASE WHEN t.due_date = t.borrow_date
                             THEN 'LOAN-IN' ELSE 'LOAN-OUT' END AS LoanType,
                        u.role             AS PatronRole
                    FROM Transactions t
                    JOIN Item_Copies       c ON t.accession_number = c.accession_number
                    JOIN Library_Resources r ON c.resource_id      = r.resource_id
                    JOIN Users             u ON t.user_id          = u.user_id
                    LEFT JOIN Students     s ON t.user_id          = s.student_id
                    LEFT JOIN Faculty      f ON t.user_id          = f.faculty_id
                    LEFT JOIN Staff        st ON t.user_id         = st.staff_id
                    WHERE DATE(t.borrow_date) = CURDATE()
                      AND t.status = 'Borrowed'
                    ORDER BY t.transaction_id DESC
                    LIMIT 50";

                DataTable dt = new DataTable();
                using (MySqlDataAdapter da = new MySqlDataAdapter(query, conn))
                    da.Fill(dt);

                rptFeed.DataSource = dt;
                rptFeed.DataBind();
                divAwaiting.Visible = (dt.Rows.Count == 0);
            }
        }

        private void UpdateLiveFeed() { LoadTodayTransactions(); }

        private void ShowToast(string message, string icon)
        {
            string cleanMsg = message.Replace("'", "\\'");
            string script = $@"
                Swal.fire({{
                    icon: '{icon}',
                    title: '{cleanMsg}',
                    toast: true,
                    position: 'top-end',
                    showConfirmButton: false,
                    timer: 4000,
                    timerProgressBar: true
                }});";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"Swal.fire({{ title: '{cleanTitle}', text: '{cleanMsg}', icon: '{icon}', confirmButtonColor: '#14532d' }});";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }

        public string DecryptString(string cipherText)
        {
            try
            {
                cipherText = cipherText.Replace(" ", "+");
                byte[] cipherBytes = Convert.FromBase64String(cipherText);
                using (Aes encryptor = Aes.Create())
                {
                    Rfc2898DeriveBytes pdb = new Rfc2898DeriveBytes(
                        EncryptionKey,
                        new byte[] { 0x49, 0x76, 0x61, 0x6e, 0x20, 0x4d, 0x65, 0x64, 0x76, 0x65, 0x64, 0x65, 0x76 });
                    encryptor.Key = pdb.GetBytes(32);
                    encryptor.IV = pdb.GetBytes(16);
                    using (MemoryStream ms = new MemoryStream())
                    {
                        using (CryptoStream cs = new CryptoStream(ms, encryptor.CreateDecryptor(), CryptoStreamMode.Write))
                        {
                            cs.Write(cipherBytes, 0, cipherBytes.Length);
                            cs.Close();
                        }
                        return Encoding.Unicode.GetString(ms.ToArray());
                    }
                }
            }
            catch { return ""; }
        }

        // ============================================================
        //  COVER / DISPLAY HELPERS
        // ============================================================
        protected string GetCoverUrl(object coverPathObj)
        {
            string fallback = DefaultCoverUrl;
            string coverPath = Convert.ToString(coverPathObj).Trim();

            if (string.IsNullOrWhiteSpace(coverPath))
                return fallback;

            string normalized = coverPath.Replace('\\', '/').Trim();

            // Allow fully qualified external image URLs.
            if (normalized.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                normalized.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
                return normalized;

            if (normalized.StartsWith("~/"))
                normalized = normalized.Substring(2);
            else
                normalized = normalized.TrimStart('/');

            // If a physical Windows path is stored, extract the Assets/... portion.
            int assetsIndex = normalized.IndexOf("Assets/", StringComparison.OrdinalIgnoreCase);
            if (assetsIndex >= 0)
                normalized = normalized.Substring(assetsIndex);

            // Do not expose absolute Windows paths as URLs.
            if (normalized.Contains(":"))
                return fallback;

            try
            {
                string physical = Server.MapPath("~/" + normalized);
                if (File.Exists(physical))
                    return ResolveUrl("~/" + normalized);
            }
            catch { }

            // Fallback attempt: use only the file name under Assets/Covers.
            try
            {
                string fileName = Path.GetFileName(normalized);
                if (!string.IsNullOrWhiteSpace(fileName))
                {
                    string coverRel = "Assets/Covers/" + fileName;
                    if (File.Exists(Server.MapPath("~/" + coverRel)))
                        return ResolveUrl("~/" + coverRel);
                }
            }
            catch { }

            return fallback;
        }

        protected string GetPenaltyDisplay(object penaltyTypeObj, object fineAmountObj)
        {
            string type = Convert.ToString(penaltyTypeObj);
            if (string.IsNullOrWhiteSpace(type))
                return "No Penalty";

            decimal amount = 0m;
            if (fineAmountObj != null && fineAmountObj != DBNull.Value)
                decimal.TryParse(Convert.ToString(fineAmountObj), out amount);

            return string.Format("{0} — ₱{1:N2}", type, amount);
        }

        protected string GetStatusBadgeClass(object statusObj)
        {
            string status = Convert.ToString(statusObj);

            switch ((status ?? string.Empty).ToLowerInvariant())
            {
                case "reserved":
                    return "sp-badge-reserved";
                case "ready":
                    return "sp-badge-ready";
                case "borrowed":
                    return "sp-badge-borrowed";
                case "renewal":
                    return "sp-badge-renewal";
                default:
                    return "sp-badge-neutral";
            }
        }

        protected string DisplayText(object value)
        {
            string text = Convert.ToString(value);
            return string.IsNullOrWhiteSpace(text) ? "N/A" : text;
        }
    }
}