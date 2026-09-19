using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Patron
{
    public partial class Profile : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                ToggleAccountEditMode(false);
                ToggleEmergencyEditMode(false);

                string currentUserId = Session["UserID"]?.ToString();
                if (!string.IsNullOrEmpty(currentUserId))
                {
                    LoadUserProfile(currentUserId);
                }
                else
                {
                    ShowSweetAlert("Session Error", "User session not found. Please log in again.", "error");
                }
            }
        }

        private string GetUserRole(string userId, MySqlConnection conn)
        {
            string role = "student";
            string query = "SELECT role FROM Users WHERE user_id = @id";
            using (MySqlCommand cmd = new MySqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("@id", userId);
                object result = cmd.ExecuteScalar();
                if (result != null)
                    role = result.ToString().ToLower();
            }
            return role;
        }

        private void LoadUserProfile(string userId)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                try
                {
                    conn.Open();
                    string role = GetUserRole(userId, conn);
                    string query = "";

                    if (role == "faculty")
                    {
                        query = @"SELECT first_name, middle_name, last_name, extension_name, 
                                         gender, mobile_number, email, 
                                         institute AS department, '' AS course_info 
                                  FROM Faculty WHERE faculty_id = @id";
                    }
                    else if (role == "staff" || role == "admin")
                    {
                        query = @"SELECT first_name, middle_name, last_name, extension_name, 
                                         gender, mobile_number, email, 
                                         office_department AS department, '' AS course_info 
                                  FROM Staff WHERE staff_id = @id";
                    }
                    else // student
                    {
                        query = @"SELECT first_name, middle_name, last_name, extension_name, 
                                         gender, mobile_number, email, 
                                         institute AS department, course AS course_info 
                                  FROM Students WHERE student_id = @id";
                    }

                    using (MySqlCommand cmd = new MySqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@id", userId);
                        using (MySqlDataReader reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                string fName = reader["first_name"].ToString().Trim();
                                string mName = reader["middle_name"]?.ToString().Trim() ?? "";
                                string lName = reader["last_name"].ToString().Trim();
                                string extName = reader["extension_name"]?.ToString().Trim() ?? "";
                                string gender = reader["gender"]?.ToString() ?? "";
                                string mobile = reader["mobile_number"]?.ToString() ?? "";

                                string fullName = $"{fName} {mName} {lName}".Trim();
                                if (!string.IsNullOrEmpty(extName))
                                    fullName += $" {extName}";

                                string initialF = fName.Length > 0 ? fName.Substring(0, 1).ToUpper() : "";
                                string initialL = lName.Length > 0 ? lName.Substring(0, 1).ToUpper() : "";
                                litInitials.Text = $"{initialF}{initialL}";
                                litCardName.Text = string.IsNullOrEmpty(fullName) ? "UNKNOWN" : fullName;
                                litCardID.Text = userId;

                                // ----- QR CODE: now using plain userId (no encryption) -----
                                string plainId = userId;
                                string urlEncodedId = HttpUtility.UrlEncode(plainId);
                                imgQRCode.ImageUrl = $"https://api.qrserver.com/v1/create-qr-code/?size=250x250&data={urlEncodedId}";
                                // Store the plain ID for download as well
                                ViewState["PlainUserID"] = plainId;

                                // Populate textboxes
                                SetTextBoxData(txtFirstName, fName);
                                SetTextBoxData(txtMiddleName, mName);
                                SetTextBoxData(txtLastName, lName);
                                SetTextBoxData(txtExtension, extName);
                                SetTextBoxData(txtGender, gender);
                                SetTextBoxData(txtMobile, mobile);
                                SetTextBoxData(txtStudentID, userId);
                                SetTextBoxData(txtEmail, reader["email"].ToString());
                                SetTextBoxData(txtDepartment, reader["department"].ToString());
                                SetTextBoxData(txtCourse, reader["course_info"].ToString());
                                SetTextBoxData(txtAddress, "");
                                SetTextBoxData(txtGuardianName, "");
                                SetTextBoxData(txtGuardianRel, "");
                                SetTextBoxData(txtGuardianContact, "");
                            }
                        }
                    }

                    LoadLibraryStatus(userId);
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Load Error", "Failed to load profile: " + ex.Message, "error");
                    System.Diagnostics.Debug.WriteLine("Load error: " + ex.Message);
                }
            }
        }

        private void LoadLibraryStatus(string userId)
        {
            StringBuilder html = new StringBuilder();
            decimal totalBalance = 0;

            string query = @"
                SELECT t.transaction_id, t.due_date, t.fine_amount, t.amount_paid, t.balance, t.fine_status,
                       r.title
                FROM Transactions t
                LEFT JOIN Item_Copies ic ON t.accession_number = ic.accession_number
                LEFT JOIN Library_Resources r ON ic.resource_id = r.resource_id
                WHERE t.user_id = @userId
                  AND t.fine_status IN ('Unpaid', 'Partial')
                ORDER BY t.due_date ASC";

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();
                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@userId", userId);
                    using (MySqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (!reader.HasRows)
                        {
                            html.Append("<p class='text-success mb-0'><i class='fas fa-check-circle'></i> No outstanding fines.</p>");
                        }
                        else
                        {
                            html.Append("<ul class='list-unstyled mb-0'>");
                            while (reader.Read())
                            {
                                string title = reader["title"]?.ToString() ?? "Unknown Item";
                                DateTime dueDate = Convert.ToDateTime(reader["due_date"]);
                                decimal fine = Convert.ToDecimal(reader["fine_amount"]);
                                decimal paid = Convert.ToDecimal(reader["amount_paid"]);
                                decimal balance = Convert.ToDecimal(reader["balance"]);
                                string status = reader["fine_status"].ToString();

                                totalBalance += balance;

                                html.Append("<li class='mb-2 p-2 border-bottom'>");
                                html.Append($"<div><strong>{HttpUtility.HtmlEncode(title)}</strong></div>");
                                html.Append($"<div class='small text-muted'>Due: {dueDate:MMM dd, yyyy} | Fine: ₱{fine:F2} | Paid: ₱{paid:F2} | Balance: ₱{balance:F2} | Status: {status}</div>");
                                html.Append("</li>");
                            }
                            html.Append("</ul>");
                            html.Append($"<div class='mt-2 fw-bold'>Total Unpaid Balance: ₱{totalBalance:F2}</div>");
                        }
                    }
                }
            }

            litLibraryStatusList.Text = html.ToString();
        }

        private void SetTextBoxData(TextBox txt, string value)
        {
            txt.Text = string.IsNullOrWhiteSpace(value) ? "N/A" : value;
        }

        // ========== ACCOUNT EDIT LOGIC ==========
        protected void btnEditAccount_Click(object sender, EventArgs e)
        {
            ToggleAccountEditMode(true);
        }

        protected void btnCancelAccount_Click(object sender, EventArgs e)
        {
            string currentUserId = Session["UserID"]?.ToString() ?? txtStudentID.Text;
            if (string.IsNullOrEmpty(currentUserId) || currentUserId == "N/A")
            {
                ShowSweetAlert("Error", "Cannot reload profile: user ID missing.", "error");
                return;
            }
            LoadUserProfile(currentUserId);
            ToggleAccountEditMode(false);
        }

        protected void btnSaveAccount_Click(object sender, EventArgs e)
        {
            string userId = txtStudentID.Text;
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                try
                {
                    conn.Open();
                    string role = GetUserRole(userId, conn);
                    string updateSql = "";

                    if (role == "faculty")
                        updateSql = @"UPDATE Faculty SET first_name = @fname, middle_name = @mname, last_name = @lname, 
                                      extension_name = @extname, gender = @gender, mobile_number = @mobile,
                                      email = @email, institute = @dept WHERE faculty_id = @id";
                    else if (role == "staff" || role == "admin")
                        updateSql = @"UPDATE Staff SET first_name = @fname, middle_name = @mname, last_name = @lname, 
                                      extension_name = @extname, gender = @gender, mobile_number = @mobile,
                                      email = @email, office_department = @dept WHERE staff_id = @id";
                    else
                        updateSql = @"UPDATE Students SET first_name = @fname, middle_name = @mname, last_name = @lname, 
                                      extension_name = @extname, gender = @gender, mobile_number = @mobile,
                                      email = @email, institute = @dept, course = @course WHERE student_id = @id";

                    using (MySqlCommand cmd = new MySqlCommand(updateSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@fname", txtFirstName.Text == "N/A" ? "" : txtFirstName.Text);
                        cmd.Parameters.AddWithValue("@mname", txtMiddleName.Text == "N/A" ? "" : txtMiddleName.Text);
                        cmd.Parameters.AddWithValue("@lname", txtLastName.Text == "N/A" ? "" : txtLastName.Text);
                        cmd.Parameters.AddWithValue("@extname", txtExtension.Text == "N/A" ? "" : txtExtension.Text);
                        cmd.Parameters.AddWithValue("@gender", txtGender.Text == "N/A" ? "" : txtGender.Text);
                        cmd.Parameters.AddWithValue("@mobile", txtMobile.Text == "N/A" ? "" : txtMobile.Text);
                        cmd.Parameters.AddWithValue("@email", txtEmail.Text == "N/A" ? "" : txtEmail.Text);
                        cmd.Parameters.AddWithValue("@dept", txtDepartment.Text == "N/A" ? "" : txtDepartment.Text);
                        cmd.Parameters.AddWithValue("@id", userId);
                        cmd.Parameters.AddWithValue("@course", txtCourse.Text == "N/A" ? "" : txtCourse.Text);

                        cmd.ExecuteNonQuery();
                    }

                    ShowSweetAlert("Success", "Profile updated successfully.", "success");
                    LoadUserProfile(userId);
                    ToggleAccountEditMode(false);
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Update Error", ex.Message, "error");
                }
            }
        }

        private void ToggleAccountEditMode(bool isEditing)
        {
            btnEditAccount.Visible = !isEditing;
            btnSaveAccount.Visible = isEditing;
            btnCancelAccount.Visible = isEditing;

            SetTextBoxEditability(txtFirstName, isEditing);
            SetTextBoxEditability(txtMiddleName, isEditing);
            SetTextBoxEditability(txtLastName, isEditing);
            SetTextBoxEditability(txtExtension, isEditing);
            SetTextBoxEditability(txtGender, isEditing);
            SetTextBoxEditability(txtMobile, isEditing);
            SetTextBoxEditability(txtEmail, isEditing);
            SetTextBoxEditability(txtDepartment, isEditing);
            SetTextBoxEditability(txtAddress, isEditing);
            SetTextBoxEditability(txtCourse, isEditing);

            txtStudentID.Enabled = false;
            upAccountInfo.Update();
        }

        // ========== EMERGENCY CONTACT LOGIC ==========
        protected void btnEditEmergency_Click(object sender, EventArgs e)
        {
            ToggleEmergencyEditMode(true);
        }

        protected void btnCancelEmergency_Click(object sender, EventArgs e)
        {
            ToggleEmergencyEditMode(false);
        }

        protected void btnSaveEmergency_Click(object sender, EventArgs e)
        {
            ShowSweetAlert("Info", "Emergency contact saving not yet implemented.", "info");
            ToggleEmergencyEditMode(false);
        }

        private void ToggleEmergencyEditMode(bool isEditing)
        {
            btnEditEmergency.Visible = !isEditing;
            btnSaveEmergency.Visible = isEditing;
            btnCancelEmergency.Visible = isEditing;

            SetTextBoxEditability(txtGuardianName, isEditing);
            SetTextBoxEditability(txtGuardianRel, isEditing);
            SetTextBoxEditability(txtGuardianContact, isEditing);

            upEmergencyContact.Update();
        }

        // ========== HELPER & ENCRYPTION ==========
        private void SetTextBoxEditability(TextBox txt, bool isEditing)
        {
            txt.Enabled = isEditing;
            if (isEditing)
            {
                if (txt.Text == "N/A") txt.Text = "";
                txt.CssClass = "editable-textbox";
            }
            else
            {
                if (string.IsNullOrWhiteSpace(txt.Text)) txt.Text = "N/A";
                txt.CssClass = "readonly-textbox";
            }
        }

        // ========== DOWNLOAD DIGITAL ID (UPDATED) ==========
        

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"showSweetAlert('{cleanTitle}', '{cleanMsg}', '{icon}');";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }
    }
}