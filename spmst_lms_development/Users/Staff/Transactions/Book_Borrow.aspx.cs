using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Web.UI;

namespace spmst_lms_development.Users.Staff.Transactions
{
    public partial class Book_Borrow : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private readonly string EncryptionKey = "SPAMAST_LMS_SECURE_KEY_2026";

        // Sections that are restricted to LOAN-IN only.
        // Add new sections here as needed.
        private static readonly HashSet<string> LoanInOnlySections =
            new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "Periodicals",
            "Reference",
            "Thesis"
        };

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Set active tab
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

        protected void txtPatronQR_TextChanged(object sender, EventArgs e)
        {
            string scannedText = txtPatronQR.Text.Trim();
            if (string.IsNullOrEmpty(scannedText)) return;

            string decryptedId = DecryptString(scannedText);
            string id = !string.IsNullOrEmpty(decryptedId) ? decryptedId : scannedText;

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                // Include Staff in the union
                string query = @"
            SELECT first_name, last_name, course as dept, 'student' as role FROM Students WHERE student_id = @id
            UNION
            SELECT first_name, last_name, institute as dept, 'faculty' as role FROM Faculty WHERE faculty_id = @id
            UNION
            SELECT first_name, last_name, office_department as dept, 'staff' as role FROM Staff WHERE staff_id = @id";
                MySqlCommand cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@id", id);
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

                        ViewState["DecryptedPatronID"] = id;
                        ViewState["UserRole"] = reader["role"].ToString();

                        txtPatronQR.Text = "VALID ID SCANNED";
                        divBookStep.Attributes["class"] = "mb-4";
                        txtBookBarcode.Enabled = true;
                        btnBookCam.Disabled = false;
                        txtBookBarcode.Focus();
                    }
                    else
                    {
                        ShowToast("User not found or invalid QR code.", "error");
                        ResetForm();
                    }
                }
            }
        }

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

            try
            {
                using (MySqlConnection conn = new MySqlConnection(_connStr))
                {
                    // Add section to SELECT
                    string query = @"
                SELECT r.resource_id, r.title, r.author, r.section, c.accession_number, c.is_available,
                       t.user_id AS active_user, t.status AS active_status
                FROM Library_Resources r
                JOIN Item_Copies c ON r.resource_id = c.resource_id
                LEFT JOIN Transactions t ON c.accession_number = t.accession_number
                     AND t.status IN ('Reserved', 'Ready', 'Borrowed')
                WHERE c.accession_number = @acc LIMIT 1";

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

                            // Check availability / reservation (same as before)
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
                            else
                            {
                                if (!isAvailable)
                                {
                                    ShowToast("This book is currently unavailable.", "error");
                                    txtBookBarcode.Text = "";
                                    txtBookBarcode.Focus();
                                    return;
                                }
                            }

                            // Show book info
                            pnlBookInfo.Visible = true;
                            litBookTitle.Text = reader["title"].ToString();
                            litBookAuthor.Text = reader["author"].ToString();
                            litBookSection.Text = section;
                            litBookAccNo.Text = reader["accession_number"].ToString();
                            ViewState["ScannedResourceID"] = resourceId;

                            // Save section for server-side validation later
                            ViewState["ScannedSection"] = section;

                            // Control loan type dropdown based on section
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
                                // Periodicals, Reference, Thesis => LOAN-IN only
                                loanOutItem.Enabled = false;
                                loanInItem.Enabled = true;
                                ddlLoanType.SelectedValue = "LOAN-IN";
                            }
                            else
                            {
                                // All other sections => both allowed, default LOAN-OUT
                                loanOutItem.Enabled = true;
                                loanInItem.Enabled = true;
                                ddlLoanType.SelectedValue = "LOAN-OUT";
                            }

                            ShowToast("Book Recognized: " + reader["title"].ToString(), "success");
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

        protected void btnComplete_Click(object sender, EventArgs e)
        {
            string studentID = ViewState["DecryptedPatronID"]?.ToString();
            string barcode = litBookAccNo.Text;
            string bookTitle = litBookTitle.Text;
            string role = ViewState["UserRole"]?.ToString() ?? "student";
            string resourceId = ViewState["ScannedResourceID"]?.ToString();
            string loanType = ddlLoanType.SelectedValue;

            if (string.IsNullOrEmpty(studentID) || string.IsNullOrEmpty(barcode))
            {
                ShowSweetAlert("Error", "Missing Patron or Book information.", "error");
                return;
            }

            // Server-side validation for loan type based on section
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
            string status = "Borrowed";

            if (loanType == "LOAN-OUT")
                dueDate = (role == "faculty" || role == "staff") ? borrowDate.AddDays(150) : borrowDate.AddDays(3);
            else
                dueDate = borrowDate;

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                conn.Open();
                using (MySqlTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        string oldAccessionNumber = null;
                        bool isReservationSwap = false;

                        // Check exact reservation
                        string checkExact = "SELECT transaction_id FROM Transactions WHERE user_id = @uid AND accession_number = @acc AND status IN ('Reserved', 'Ready') LIMIT 1";
                        MySqlCommand cmdExact = new MySqlCommand(checkExact, conn, trans);
                        cmdExact.Parameters.AddWithValue("@uid", studentID);
                        cmdExact.Parameters.AddWithValue("@acc", barcode);
                        object exactResId = cmdExact.ExecuteScalar();

                        if (exactResId != null)
                        {
                            string updateTrans = "UPDATE Transactions SET status = @status, borrow_date = @borrowDate, due_date = @dueDate, fine_amount = 0 WHERE transaction_id = @tid";
                            MySqlCommand cmdUp = new MySqlCommand(updateTrans, conn, trans);
                            cmdUp.Parameters.AddWithValue("@status", status);
                            cmdUp.Parameters.AddWithValue("@borrowDate", borrowDate);
                            cmdUp.Parameters.AddWithValue("@dueDate", dueDate);
                            cmdUp.Parameters.AddWithValue("@tid", exactResId);
                            cmdUp.ExecuteNonQuery();
                        }
                        else
                        {
                            string checkDiff = @"SELECT t.transaction_id, t.accession_number FROM Transactions t
                                                JOIN Item_Copies c ON t.accession_number = c.accession_number
                                                WHERE t.user_id = @uid AND c.resource_id = @resId AND t.status IN ('Reserved', 'Ready') AND t.accession_number != @acc LIMIT 1";
                            MySqlCommand cmdDiff = new MySqlCommand(checkDiff, conn, trans);
                            cmdDiff.Parameters.AddWithValue("@uid", studentID);
                            cmdDiff.Parameters.AddWithValue("@resId", resourceId);
                            cmdDiff.Parameters.AddWithValue("@acc", barcode);
                            using (MySqlDataReader reader = cmdDiff.ExecuteReader())
                            {
                                if (reader.Read())
                                {
                                    object diffResId = reader["transaction_id"];
                                    oldAccessionNumber = reader["accession_number"].ToString();
                                    isReservationSwap = true;
                                    reader.Close();

                                    string updateDiff = "UPDATE Transactions SET accession_number = @newAcc, status = @status, borrow_date = @borrowDate, due_date = @dueDate, fine_amount = 0 WHERE transaction_id = @tid";
                                    MySqlCommand cmdUpDiff = new MySqlCommand(updateDiff, conn, trans);
                                    cmdUpDiff.Parameters.AddWithValue("@newAcc", barcode);
                                    cmdUpDiff.Parameters.AddWithValue("@status", status);
                                    cmdUpDiff.Parameters.AddWithValue("@borrowDate", borrowDate);
                                    cmdUpDiff.Parameters.AddWithValue("@dueDate", dueDate);
                                    cmdUpDiff.Parameters.AddWithValue("@tid", diffResId);
                                    cmdUpDiff.ExecuteNonQuery();
                                }
                                else
                                {
                                    reader.Close();
                                    string insertTrans = "INSERT INTO Transactions (user_id, accession_number, borrow_date, due_date, status, fine_amount) VALUES (@uid, @acc, @borrowDate, @dueDate, @status, 0)";
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

                        string dueDateMessage = loanType == "LOAN-IN" ? "Must be returned today" : $"Due on: {dueDate:MMMM dd, yyyy}";
                        string successMessage = isReservationSwap ? $"Reservation swapped and {dueDateMessage}" : $"Transaction successful! {dueDateMessage}";
                        ShowSweetAlert("Success!", successMessage, "success");
                        ResetForm();
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
            ViewState["ScannedResourceID"] = null;
            ViewState["ScannedSection"] = null;   // clear saved section
            txtPatronQR.Focus();
        }

        private void LoadTodayTransactions()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                                SELECT 
                                    CONCAT(COALESCE(s.first_name, f.first_name, st.first_name), ' ', 
                                           COALESCE(s.last_name, f.last_name, st.last_name)) AS PatronName,
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
                                WHERE DATE(t.borrow_date) = CURDATE() AND t.status = 'Borrowed'
                                ORDER BY t.transaction_id DESC LIMIT 50";
                DataTable dt = new DataTable();
                using (MySqlDataAdapter da = new MySqlDataAdapter(query, conn))
                    da.Fill(dt);
                rptFeed.DataSource = dt;
                rptFeed.DataBind();
                divAwaiting.Visible = (dt.Rows.Count == 0);
            }
        }

        private void UpdateLiveFeed()
        {
            LoadTodayTransactions();
        }

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