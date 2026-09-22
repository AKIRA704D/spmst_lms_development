using MySql.Data.MySqlClient;
using spmst_lms_development.Assets.Helper;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Patron
{
    public partial class Profile : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        // 1. Define Role Groups (like admin.Master.cs)
        private static readonly string[] AnyRole = { "admin", "staff", "faculty", "student" };
        private static readonly string[] StudentRole = { "student" };

        private HashSet<string> _roles = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        private HashSet<string> _allowedFields = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

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

        // 2. The Allow() method (matching admin.Master.cs)
        private void Allow(Control control, string[] allowedRoles)
        {
            if (control == null) return;
            control.Visible = allowedRoles != null && allowedRoles.Any(r => _roles.Contains(r));
        }

        // 3. The Role-Based Visibility Matrix
        private void ApplyRoleBasedNavigation()
        {
            Allow(pnlFirstName, AnyRole);
            Allow(pnlMiddleName, AnyRole);
            Allow(pnlLastName, AnyRole);
            Allow(pnlExtensionName, AnyRole);

            Allow(pnlGender, AnyRole);
            Allow(pnlMobileNumber, AnyRole);
            Allow(pnlUserID, AnyRole);
            Allow(pnlInstitutionalEmail, AnyRole);

            Allow(pnlDepartment, AnyRole);
            Allow(pnlCourseYear, StudentRole); // Only visible for Students
            Allow(pnlHomeAddress, AnyRole);
        }

        private (string userId, string role) ResolveUser(string inputUserId, MySqlConnection conn)
        {
            string actualUserId = inputUserId;
            string role = "student";

            string query = "SELECT user_id, role FROM Users WHERE TRIM(user_id) = TRIM(@id) OR TRIM(email) = TRIM(@id)";
            using (MySqlCommand cmd = new MySqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("@id", inputUserId);
                using (MySqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        actualUserId = reader["user_id"].ToString();
                        role = reader["role"].ToString().ToLower().Trim();
                    }
                }
            }
            return (actualUserId, role);
        }

        private void LoadUserProfile(string inputUserId)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                try
                {
                    conn.Open();

                    var userInfo = ResolveUser(inputUserId, conn);
                    string userId = userInfo.userId;
                    string role = userInfo.role;

                    if (inputUserId != userId) Session["UserID"] = userId;

                    // 4. Populate _roles and Apply Navigation Visibility
                    _roles.Clear();
                    _roles.Add(role);
                    ApplyRoleBasedNavigation();

                    // 5. Build dynamic query based on allowed fields
                    _allowedFields = ProfileHelper.GetAllowedFields(role); // From Helper
                    string tableName = role == "faculty" ? "Faculty" : (role == "student" ? "Students" : "Staff");
                    string idColumn = role == "faculty" ? "faculty_id" : (role == "student" ? "student_id" : "staff_id");
                    string deptColumn = role == "faculty" ? "institute" : (role == "student" ? "institute" : "office_department");

                    List<string> selectFields = new List<string> { "first_name", "middle_name", "last_name", "extension_name", "gender", "mobile_number", "email", $"{deptColumn} AS department", "address" };

                    if (role == "student")
                    {
                        selectFields.Add("course");
                        selectFields.Add("year_level");
                        selectFields.Add("section");
                    }

                    string query = $"SELECT {string.Join(", ", selectFields)} FROM {tableName} WHERE TRIM({idColumn}) = TRIM(@id)";

                    using (MySqlCommand cmd = new MySqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@id", userId);
                        using (MySqlDataReader reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                PopulateProfileFields(reader, role, userId);
                            }
                            else
                            {
                                ShowSweetAlert("Data Not Found", $"No profile data found for role '{role}' with ID '{userId}'.", "warning");
                            }
                        }
                    }

                    LoadLibraryStatus(userId);
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Load Error", "Failed to load profile: " + ex.Message, "error");
                }
            }
        }

        // ... [The rest of the methods (PopulateProfileFields, LoadLibraryStatus, btnSaveAccount_Click, etc.) remain exactly as provided in the previous step] ...
        private void PopulateProfileFields(MySqlDataReader reader, string role, string userId)
        {
            string fName = reader["first_name"].ToString().Trim();
            string mName = reader["middle_name"]?.ToString().Trim() ?? "";
            string lName = reader["last_name"].ToString().Trim();
            string extName = reader["extension_name"]?.ToString().Trim() ?? "";
            string gender = reader["gender"]?.ToString() ?? "";
            string mobile = reader["mobile_number"]?.ToString() ?? "";

            string fullName = $"{fName} {mName} {lName}".Trim();
            if (!string.IsNullOrEmpty(extName)) fullName += $" {extName}";

            litInitials.Text = $"{(fName.Length > 0 ? fName.Substring(0, 1).ToUpper() : "")}{(lName.Length > 0 ? lName.Substring(0, 1).ToUpper() : "")}";
            litCardName.Text = string.IsNullOrEmpty(fullName) ? "UNKNOWN" : fullName;
            litCardID.Text = userId;

            imgQRCode.ImageUrl = $"https://api.qrserver.com/v1/create-qr-code/?size=250x250&data={HttpUtility.UrlEncode(userId)}";
            ViewState["PlainUserID"] = userId;

            SetTextBoxData(txtFirstName, fName);
            SetTextBoxData(txtMiddleName, mName);
            SetTextBoxData(txtLastName, lName);
            SetTextBoxData(txtExtension, extName);
            SetTextBoxData(txtGender, gender);
            SetTextBoxData(txtMobile, mobile);
            SetTextBoxData(txtStudentID, userId);
            SetTextBoxData(txtEmail, reader["email"].ToString());
            SetTextBoxData(txtDepartment, reader["department"].ToString());
            SetTextBoxData(txtAddress, reader["address"] != DBNull.Value ? reader["address"].ToString() : "");

            string courseInfo = "";
            if (role == "student")
            {
                string course = reader["course"]?.ToString() ?? "";
                string yearLevel = reader["year_level"]?.ToString() ?? "";
                string section = reader["section"]?.ToString() ?? "";

                courseInfo = course;
                if (!string.IsNullOrEmpty(yearLevel)) courseInfo += $" - {yearLevel}";
                if (!string.IsNullOrEmpty(section)) courseInfo += $" ({section})";
            }
            SetTextBoxData(txtCourse, courseInfo);

            SetTextBoxData(txtGuardianName, "");
            SetTextBoxData(txtGuardianRel, "");
            SetTextBoxData(txtGuardianContact, "");
        }

        private void LoadLibraryStatus(string userId)
        {
            StringBuilder html = new StringBuilder();
            decimal totalBalance = 0;

            string query = @"
                SELECT t.transaction_id, t.due_date, t.fine_amount, t.amount_paid, t.balance, t.fine_status, r.title
                FROM Transactions t
                LEFT JOIN Item_Copies ic ON t.accession_number = ic.accession_number
                LEFT JOIN Library_Resources r ON ic.resource_id = r.resource_id
                WHERE TRIM(t.user_id) = TRIM(@userId) AND t.fine_status IN ('Unpaid', 'Partial')
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
        protected void btnEditAccount_Click(object sender, EventArgs e) => ToggleAccountEditMode(true);

        protected void btnCancelAccount_Click(object sender, EventArgs e)
        {
            string currentUserId = Session["UserID"]?.ToString() ?? txtStudentID.Text;
            if (string.IsNullOrEmpty(currentUserId) || currentUserId == "N/A") return;
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
                    var userInfo = ResolveUser(userId, conn);
                    string role = userInfo.role;

                    string tableName = role == "faculty" ? "Faculty" : (role == "student" ? "Students" : "Staff");
                    string idColumn = role == "faculty" ? "faculty_id" : (role == "student" ? "student_id" : "staff_id");
                    string deptColumn = role == "faculty" ? "institute" : (role == "student" ? "institute" : "office_department");

                    // Apply Sentence Case to all relevant text fields
                    string fname = ProfileHelper.ToSentenceCase(txtFirstName.Text == "N/A" ? "" : txtFirstName.Text);
                    string mname = ProfileHelper.ToSentenceCase(txtMiddleName.Text == "N/A" ? "" : txtMiddleName.Text);
                    string lname = ProfileHelper.ToSentenceCase(txtLastName.Text == "N/A" ? "" : txtLastName.Text);
                    string extname = ProfileHelper.ToSentenceCase(txtExtension.Text == "N/A" ? "" : txtExtension.Text);
                    string gender = ProfileHelper.ToSentenceCase(txtGender.Text == "N/A" ? "" : txtGender.Text);
                    string mobile = txtMobile.Text == "N/A" ? "" : txtMobile.Text; // Keep numbers as is
                    string email = txtEmail.Text == "N/A" ? "" : txtEmail.Text; // Keep email as is
                    string dept = ProfileHelper.ToSentenceCase(txtDepartment.Text == "N/A" ? "" : txtDepartment.Text);
                    string address = ProfileHelper.ToSentenceCase(txtAddress.Text == "N/A" ? "" : txtAddress.Text);

                    // Dynamically build UPDATE query based on allowed fields
                    List<string> setClauses = new List<string>
                    {
                        "first_name = @fname", "middle_name = @mname", "last_name = @lname",
                        "extension_name = @extname", "gender = @gender", "mobile_number = @mobile",
                        "email = @email", $"{deptColumn} = @dept", "address = @address"
                    };

                    if (role == "student")
                    {
                        setClauses.Add("course = @course");
                        // Note: Year level and section are displayed in txtCourse but not edited separately here.
                        // If you need to save them separately, you'd need separate textboxes for them.
                    }

                    string updateSql = $"UPDATE {tableName} SET {string.Join(", ", setClauses)} WHERE TRIM({idColumn}) = TRIM(@id)";

                    using (MySqlCommand cmd = new MySqlCommand(updateSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@fname", fname);
                        cmd.Parameters.AddWithValue("@mname", mname);
                        cmd.Parameters.AddWithValue("@lname", lname);
                        cmd.Parameters.AddWithValue("@extname", extname);
                        cmd.Parameters.AddWithValue("@gender", gender);
                        cmd.Parameters.AddWithValue("@mobile", mobile);
                        cmd.Parameters.AddWithValue("@email", email);
                        cmd.Parameters.AddWithValue("@dept", dept);
                        cmd.Parameters.AddWithValue("@address", address);
                        cmd.Parameters.AddWithValue("@id", userId);

                        if (role == "student")
                        {
                            // Extract just the course part if needed, or save the whole string. 
                            // Assuming txtCourse holds the main course string.
                            cmd.Parameters.AddWithValue("@course", ProfileHelper.ToSentenceCase(txtCourse.Text == "N/A" ? "" : txtCourse.Text));
                        }

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
        protected void btnEditEmergency_Click(object sender, EventArgs e) => ToggleEmergencyEditMode(true);
        protected void btnCancelEmergency_Click(object sender, EventArgs e) => ToggleEmergencyEditMode(false);
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

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string script = $"showSweetAlert('{title.Replace("'", "\\'")}', '{message.Replace("'", "\\'")}', '{icon}');";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }
    }
}