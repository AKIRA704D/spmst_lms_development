using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Staff.Transactions
{
    public partial class Book_Renew : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private readonly string EncryptionKey = "SPAMAST_LMS_SECURE_KEY_2026";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Set active tab
                string currentPage = System.IO.Path.GetFileName(Request.Url.AbsolutePath);
                if (currentPage.Equals("Book_Renew.aspx", StringComparison.OrdinalIgnoreCase))
                {
                    lnkBorrow.CssClass = "nav-link text-secondary fw-semibold";
                    lnkReturn.CssClass = "nav-link text-secondary fw-semibold";
                    lnkRenew.CssClass = "nav-link active fw-semibold";
                }
                UpdateLiveFeed();
                LoadPendingRenewals();
            }
        }

        // ========== STEP 1: PATRON SCAN ==========
        protected void txtPatronQR_TextChanged(object sender, EventArgs e)
        {
            string scannedText = txtPatronQR.Text.Trim();
            if (string.IsNullOrEmpty(scannedText)) return;

            string decryptedId = DecryptString(scannedText);
            string patronId = !string.IsNullOrEmpty(decryptedId) ? decryptedId : scannedText;

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT first_name, last_name, course as dept, 'student' as role FROM Students WHERE student_id = @id
                    UNION
                    SELECT first_name, last_name, institute as dept, 'faculty' as role FROM Faculty WHERE faculty_id = @id
                    UNION
                    SELECT first_name, last_name, office_department as dept, 'staff' as role FROM Staff WHERE staff_id = @id";
                MySqlCommand cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@id", patronId);
                conn.Open();
                using (MySqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        pnlPatronInfo.Visible = true;
                        litPatronName.Text = $"{reader["first_name"]} {reader["last_name"]}";
                        litPatronDept.Text = reader["dept"].ToString();
                        litPatronRole.Text = reader["role"].ToString().ToUpper();
                        litInitial.Text = reader["first_name"].ToString().Substring(0, 1);

                        ViewState["DecryptedPatronID"] = patronId;
                        ViewState["UserRole"] = reader["role"].ToString();

                        txtPatronQR.Text = "VALID ID SCANNED";
                        divBookStep.Attributes["class"] = "mb-4";
                        txtBookBarcode.Enabled = true;
                        btnBookCam.Disabled = false;
                        txtBookBarcode.Focus();

                        // Load unsettled penalties for this patron
                        LoadPatronPenalties(patronId);
                    }
                    else
                    {
                        ShowSweetAlert("User Not Found", "Invalid QR code or user ID.", "error");
                        ResetForm();
                    }
                }
            }
        }

        private void LoadPatronPenalties(string patronId)
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT r.title AS BookTitle, c.accession_number AS AccessionNumber,
                           CASE 
                               WHEN t.status = 'Overdue' THEN 'Overdue'
                               WHEN ic.status_condition = 'Damage' THEN 'Damage'
                               WHEN ic.status_condition = 'Lost' THEN 'Lost'
                               ELSE 'Unpaid Fine'
                           END AS PenaltyType
                    FROM Transactions t
                    JOIN Item_Copies c ON t.accession_number = c.accession_number
                    JOIN Library_Resources r ON c.resource_id = r.resource_id
                    JOIN Item_Copies ic ON t.accession_number = ic.accession_number
                    WHERE t.user_id = @uid AND t.fine_amount > 0 AND t.fine_status != 'Paid'";
                MySqlCommand cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@uid", patronId);
                conn.Open();
                DataTable dt = new DataTable();
                using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                    da.Fill(dt);
                rptPenalties.DataSource = dt;
                rptPenalties.DataBind();
                penaltySection.Visible = (dt.Rows.Count > 0);
            }
        }

        // ========== STEP 2: BOOK SCAN ==========
        protected void txtBookBarcode_TextChanged(object sender, EventArgs e)
        {
            string barcode = txtBookBarcode.Text.Trim();
            string patronId = ViewState["DecryptedPatronID"]?.ToString();

            if (string.IsNullOrEmpty(barcode)) return;
            if (string.IsNullOrEmpty(patronId))
            {
                ShowSweetAlert("Warning", "Please scan Patron ID first.", "warning");
                txtBookBarcode.Text = "";
                return;
            }

            pnlBookInfo.Visible = false;

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT t.transaction_id, t.borrow_date, t.due_date, t.status, r.title, r.author, r.section, c.is_available,
                           CASE WHEN t.due_date = t.borrow_date THEN 'LOAN-IN' ELSE 'LOAN-OUT' END AS loan_type
                    FROM Transactions t 
                    JOIN Item_Copies c ON t.accession_number = c.accession_number
                    JOIN Library_Resources r ON c.resource_id = r.resource_id
                    WHERE t.accession_number = @acc AND t.user_id = @uid AND t.status IN ('Borrowed', 'Renewal') AND t.return_date IS NULL";
                MySqlCommand cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@acc", barcode);
                cmd.Parameters.AddWithValue("@uid", patronId);
                conn.Open();

                using (MySqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        DateTime dueDate = Convert.ToDateTime(reader["due_date"]);
                        DateTime borrowDate = Convert.ToDateTime(reader["borrow_date"]);
                        string loanType = reader["loan_type"].ToString();
                        string section = reader["section"].ToString();

                        // Check if it's a LOAN-IN (can't renew)
                        if (borrowDate.Date == dueDate.Date)
                        {
                            ShowSweetAlert("Not Eligible", "LOAN-IN books cannot be renewed.", "error");
                            txtBookBarcode.Text = "";
                            txtBookBarcode.Focus();
                            return;
                        }

                        litBookTitle.Text = reader["title"].ToString();
                        litBookAuthor.Text = reader["author"].ToString();
                        litBookSection.Text = section;
                        litBookAccNo.Text = barcode;

                        string status = reader["status"].ToString();
                        litDueDate.Text = dueDate.ToString("MMMM dd, yyyy");
                        if (dueDate < DateTime.Today)
                            litDueDate.Text += " (OVERDUE)";

                        // Set loan type dropdown (read-only)
                        if (loanType == "LOAN-IN")
                            ddlLoanType.SelectedValue = "LOAN-IN";
                        else
                            ddlLoanType.SelectedValue = "LOAN-OUT";

                        // Control section-based loan type (not used in renew, but keep for consistency)
                        string sectionLower = section.ToLower();
                        bool canLoanOut = (sectionLower == "fiction" || sectionLower == "circulation");
                        ddlLoanType.Enabled = false; // always disabled for renew

                        // Show/Hide Deny button if status is 'Renewal'
                        btnDeny.Visible = (status == "Renewal");
                        btnRenew.Text = (status == "Renewal") ? "Approve Renewal" : "Renew Book";

                        ViewState["TransID"] = reader["transaction_id"];
                        pnlBookInfo.Visible = true;
                        ShowSweetAlert("Active Loan Found", "Book is eligible for renewal.", "success");
                    }
                    else
                    {
                        ShowSweetAlert("Not Found", "No active loan found for this book and patron.", "warning");
                        txtBookBarcode.Text = "";
                        txtBookBarcode.Focus();
                    }
                }
            }
        }

        // ========== APPROVE RENEWAL ==========
        protected void btnRenew_Click(object sender, EventArgs e)
        {
            string patronId = ViewState["DecryptedPatronID"]?.ToString();
            string role = ViewState["UserRole"]?.ToString() ?? "student";
            string bookTitle = litBookTitle.Text;
            string patronName = litPatronName.Text;
            string barcode = litBookAccNo.Text;
            object oldTransId = ViewState["TransID"];

            if (string.IsNullOrEmpty(patronId) || oldTransId == null || string.IsNullOrEmpty(barcode))
            {
                ShowSweetAlert("Error", "Transaction failed: Missing details.", "error");
                return;
            }

            int extensionDays = 3; // Fixed 3 days extension

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                conn.Open();
                using (MySqlTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        // Close old transaction
                        string updateSql = "UPDATE Transactions SET status = 'Renewed', return_date = CURDATE() WHERE transaction_id = @tid";
                        MySqlCommand cmdUp = new MySqlCommand(updateSql, conn, trans);
                        cmdUp.Parameters.AddWithValue("@tid", oldTransId);
                        cmdUp.ExecuteNonQuery();

                        // Create new transaction
                        string insertSql = "INSERT INTO Transactions (user_id, accession_number, borrow_date, due_date, status, fine_amount) VALUES (@uid, @acc, CURDATE(), DATE_ADD(CURDATE(), INTERVAL @days DAY), 'Borrowed', 0)";
                        MySqlCommand cmdIn = new MySqlCommand(insertSql, conn, trans);
                        cmdIn.Parameters.AddWithValue("@uid", patronId);
                        cmdIn.Parameters.AddWithValue("@acc", barcode);
                        cmdIn.Parameters.AddWithValue("@days", extensionDays);
                        cmdIn.ExecuteNonQuery();

                        trans.Commit();

                        // Add to live feed
                        UpdateLiveFeed($"{patronName} renewed '{bookTitle}'", barcode, patronId, role, "LOAN-OUT");
                        LoadPendingRenewals();
                        ResetForm();
                        ShowSweetAlert("Success", "Book renewed successfully! New due date is 3 days from today.", "success");
                    }
                    catch (Exception ex)
                    {
                        trans.Rollback();
                        ShowSweetAlert("Failed", ex.Message, "error");
                    }
                }
            }
        }

        // ========== DENY RENEWAL ==========
        protected void btnDeny_Click(object sender, EventArgs e)
        {
            string patronId = ViewState["DecryptedPatronID"]?.ToString();
            string bookTitle = litBookTitle.Text;
            string patronName = litPatronName.Text;
            object oldTransId = ViewState["TransID"];

            if (string.IsNullOrEmpty(patronId) || oldTransId == null)
            {
                ShowSweetAlert("Error", "Transaction failed: Missing details.", "error");
                return;
            }

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                try
                {
                    string updateSql = "UPDATE Transactions SET status = CASE WHEN CURDATE() > due_date THEN 'Overdue' ELSE 'Borrowed' END WHERE transaction_id = @tid";
                    MySqlCommand cmd = new MySqlCommand(updateSql, conn);
                    cmd.Parameters.AddWithValue("@tid", oldTransId);
                    conn.Open();
                    cmd.ExecuteNonQuery();

                    UpdateLiveFeed($"Denied: {patronName}'s renewal for '{bookTitle}'", litBookAccNo.Text, patronId, ViewState["UserRole"]?.ToString() ?? "student", "LOAN-OUT");
                    LoadPendingRenewals();
                    ResetForm();
                    ShowSweetAlert("Renewal Denied", "The renewal request has been denied.", "info");
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Error", ex.Message, "error");
                }
            }
        }

        // ========== LIVE FEED ==========
        private void UpdateLiveFeed(string newMessage = null, string barcode = "", string patronId = "", string role = "", string loanType = "")
        {
            if (!string.IsNullOrEmpty(newMessage))
            {
                ShowToast(newMessage, "success");
            }

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT 
                        CONCAT(COALESCE(s.first_name, f.first_name, st.first_name), ' ', COALESCE(s.last_name, f.last_name, st.last_name)) AS PatronName,
                        t.user_id AS PatronID,
                        r.title AS BookTitle,
                        c.accession_number AS AccessionNumber,
                        CASE WHEN t.due_date = t.borrow_date THEN 'LOAN-IN' ELSE 'LOAN-OUT' END AS LoanType,
                        u.role AS PatronRole
                    FROM Transactions t
                    JOIN Item_Copies c ON t.accession_number = c.accession_number
                    JOIN Library_Resources r ON c.resource_id = r.resource_id
                    JOIN Users u ON t.user_id = u.user_id
                    LEFT JOIN Students s ON t.user_id = s.student_id
                    LEFT JOIN Faculty f ON t.user_id = f.faculty_id
                    LEFT JOIN Staff st ON t.user_id = st.staff_id
                    WHERE t.status = 'Renewed' AND DATE(t.return_date) = CURDATE()
                    ORDER BY t.transaction_id DESC LIMIT 20";
                DataTable dt = new DataTable();
                using (MySqlDataAdapter da = new MySqlDataAdapter(query, conn))
                    da.Fill(dt);
                rptFeed.DataSource = dt;
                rptFeed.DataBind();
                divAwaiting.Visible = (dt.Rows.Count == 0);
            }
        }

        private void LoadPendingRenewals()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT 
                        t.user_id,
                        t.accession_number,
                        CONCAT(COALESCE(s.first_name, f.first_name, st.first_name), ' ', COALESCE(s.last_name, f.last_name, st.last_name)) AS PatronName,
                        u.role AS PatronRole,
                        r.title AS BookTitle
                    FROM Transactions t
                    JOIN Item_Copies c ON t.accession_number = c.accession_number
                    JOIN Library_Resources r ON c.resource_id = r.resource_id
                    JOIN Users u ON t.user_id = u.user_id
                    LEFT JOIN Students s ON t.user_id = s.student_id
                    LEFT JOIN Faculty f ON t.user_id = f.faculty_id
                    LEFT JOIN Staff st ON t.user_id = st.staff_id
                    WHERE t.status = 'Renewal'";
                DataTable dt = new DataTable();
                using (MySqlDataAdapter da = new MySqlDataAdapter(query, conn))
                    da.Fill(dt);
                rptPendingRenewals.DataSource = dt;
                rptPendingRenewals.DataBind();
                divNoPending.Visible = (dt.Rows.Count == 0);
            }
        }

        // ========== HELPER METHODS ==========
        private void ResetForm()
        {
            pnlPatronInfo.Visible = false;
            pnlBookInfo.Visible = false;
            txtPatronQR.Text = "";
            txtBookBarcode.Text = "";
            txtBookBarcode.Enabled = false;
            btnBookCam.Disabled = true;
            divBookStep.Attributes["class"] = "mb-4 step-locked";
            ViewState["DecryptedPatronID"] = null;
            ViewState["UserRole"] = null;
            ViewState["TransID"] = null;
            txtPatronQR.Focus();
        }

        private void ShowToast(string message, string icon)
        {
            string cleanMsg = message.Replace("'", "\\'");
            string script = $@"Swal.fire({{ icon: '{icon}', title: '{cleanMsg}', toast: true, position: 'top-end', showConfirmButton: false, timer: 3000, timerProgressBar: true }});";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"Swal.fire({{ title: '{cleanTitle}', text: '{cleanMsg}', icon: '{icon}', confirmButtonColor: '#1e3a8a' }});";
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
                    Rfc2898DeriveBytes pdb = new Rfc2898DeriveBytes(EncryptionKey, new byte[] { 0x49, 0x76, 0x61, 0x6e, 0x20, 0x4d, 0x65, 0x64, 0x76, 0x65, 0x64, 0x65, 0x76 });
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
            catch
            {
                return "";
            }
        }
    }
}