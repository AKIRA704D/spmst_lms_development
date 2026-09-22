using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;

namespace spmst_lms_development.Users.Staff.Accounts
{
    public partial class userNew : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        private const string ProfileFolderVirtual = "~/Assets/Profile/";
        private const int MaxPhotoBytes = 5 * 1024 * 1024;
        private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".webp" };

        protected void Page_Load(object sender, EventArgs e)
        {
            // Explicit – guarantees the form is multipart even if markup is edited later
            form1.Enctype = "multipart/form-data";

            if (!IsPostBack)
            {
                ClearFields();
            }
        }

        protected void BtnSave_Click(object sender, EventArgs e)
        {
            string role = ddlCategory.SelectedValue;
            string userId = txtID.Text.Trim();
            string email = txtEmail.Text.Trim();
            string fname = txtFName.Text.Trim();
            string lname = txtLName.Text.Trim();

            // ---------- Validation ----------
            if (string.IsNullOrEmpty(role))
            {
                SetResult("warning", "Validation Error", "Please select a role.");
                return;
            }
            if (string.IsNullOrEmpty(userId))
            {
                SetResult("warning", "Validation Error", "ID Number is required.");
                return;
            }
            if (string.IsNullOrEmpty(email))
            {
                SetResult("warning", "Validation Error", "Email Address is required.");
                return;
            }
            if (string.IsNullOrEmpty(fname) || string.IsNullOrEmpty(lname))
            {
                SetResult("warning", "Validation Error", "First Name and Last Name are required.");
                return;
            }

            string profilePath = null;

            // ---------- Save photo BEFORE the transaction ----------
            try
            {
                profilePath = SaveProfilePhoto(userId);
            }
            catch (Exception photoEx)
            {
                SetResult("error", "Photo Upload Failed", photoEx.Message);
                return;
            }

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                try
                {
                    conn.Open();
                }
                catch (MySqlException ex)
                {
                    DeleteProfilePhoto(profilePath);
                    SetResult("error", "Connection Error",
                        "Unable to connect to the database. Please try again later.\n\nDetails: " + ex.Message);
                    return;
                }

                using (MySqlTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        // 1. Patron row
                        string insertPatronSql = GetPatronInsertSql(role);
                        using (MySqlCommand cmd = new MySqlCommand(insertPatronSql, conn, trans))
                        {
                            AddPatronParameters(cmd, role, profilePath);
                            if (cmd.ExecuteNonQuery() != 1)
                                throw new Exception("Failed to insert patron record.");
                        }

                        // 2. Users login row
                        const string insertUserSql =
                            "INSERT INTO Users (user_id, email, password_hash, role, is_active) " +
                            "VALUES (@id, @email, NULL, @role, 0)";
                        using (MySqlCommand cmdUser = new MySqlCommand(insertUserSql, conn, trans))
                        {
                            cmdUser.Parameters.AddWithValue("@id", userId);
                            cmdUser.Parameters.AddWithValue("@email", email);
                            cmdUser.Parameters.AddWithValue("@role", role);
                            if (cmdUser.ExecuteNonQuery() != 1)
                                throw new Exception("Failed to insert user login record.");
                        }

                        trans.Commit();

                        SetResult("success", "Success!", "Patron account registered successfully.");
                    }
                    catch (MySqlException ex)
                    {
                        SafeRollback(trans);
                        DeleteProfilePhoto(profilePath);

                        switch (ex.Number)
                        {
                            case 1062:
                                SetResult("error", "Duplicate Record", DescribeDuplicate(ex));
                                break;
                            case 1406:
                                SetResult("error", "Invalid Input",
                                    "One of the fields is longer than the database allows.\n\nDetails: " + ex.Message);
                                break;
                            case 1048:
                                SetResult("error", "Missing Required Field",
                                    "A required field was left empty.\n\nDetails: " + ex.Message);
                                break;
                            default:
                                SetResult("error", "Database Error",
                                    $"MySQL error {ex.Number}.\n\n{ex.Message}");
                                break;
                        }
                    }
                    catch (Exception ex)
                    {
                        SafeRollback(trans);
                        DeleteProfilePhoto(profilePath);
                        SetResult("error", "System Error", ex.Message);
                    }
                }
            }
        }

        // =============================================================
        //  PROFILE PHOTO HANDLING
        // =============================================================

        private string SaveProfilePhoto(string userId)
        {
            // Try the control first, then the raw request as a fallback
            HttpPostedFile file = null;
            try
            {
                if (fuProfile != null && fuProfile.HasFile)
                    file = fuProfile.PostedFile;
            }
            catch { /* fall through to Request.Files */ }

            if (file == null && Request.Files.Count > 0)
            {
                // FileUpload renders name="fuProfile"; look it up both by name and by control UniqueID
                file = Request.Files["fuProfile"];
                if (file == null && fuProfile != null)
                    file = Request.Files[fuProfile.UniqueID];
            }

            if (file == null || file.ContentLength <= 0)
                return null;

            string originalName = file.FileName ?? string.Empty;
            string ext = Path.GetExtension(originalName)?.ToLowerInvariant() ?? string.Empty;

            if (!AllowedExtensions.Contains(ext))
                throw new Exception("Invalid image format. Allowed: JPG, JPEG, PNG, GIF, WEBP.");

            if (file.ContentLength > MaxPhotoBytes)
                throw new Exception("Profile photo must be 5 MB or smaller.");

            string physicalFolder = Server.MapPath(ProfileFolderVirtual);
            if (!Directory.Exists(physicalFolder))
                Directory.CreateDirectory(physicalFolder);

            string safeId = string.Join("_", userId.Split(Path.GetInvalidFileNameChars()));
            string fileName = $"{safeId}_{DateTime.Now:yyyyMMddHHmmssfff}{ext}";
            string physicalPath = Path.Combine(physicalFolder, fileName);

            file.SaveAs(physicalPath);

            return ProfileFolderVirtual + fileName;
        }

        private void DeleteProfilePhoto(string virtualPath)
        {
            if (string.IsNullOrEmpty(virtualPath)) return;
            try
            {
                string physical = Server.MapPath(virtualPath);
                if (File.Exists(physical)) File.Delete(physical);
            }
            catch { /* best-effort */ }
        }

        private static void SafeRollback(MySqlTransaction trans)
        {
            try { trans.Rollback(); } catch { /* swallow */ }
        }

        // =============================================================
        //  SQL BUILDERS
        // =============================================================

        private string GetPatronInsertSql(string role)
        {
            if (role == "student")
                return @"INSERT INTO Students 
                         (student_id, first_name, middle_name, last_name, extension_name, 
                          gender, mobile_number, email, institute, course, section, year_level, profile_path) 
                         VALUES 
                         (@id, @fname, @mname, @lname, @ext, @gender, @mobile, @email, @inst, @course, @sec, @year, @profilePath)";

            if (role == "faculty")
                return @"INSERT INTO Faculty 
                         (faculty_id, first_name, middle_name, last_name, extension_name, 
                          gender, mobile_number, email, institute, profile_path) 
                         VALUES 
                         (@id, @fname, @mname, @lname, @ext, @gender, @mobile, @email, @inst, @profilePath)";

            int isHead = (txtOffice.Text.Trim() == "Head Office") ? 1 : 0;
            return $@"INSERT INTO Staff 
                      (staff_id, first_name, middle_name, last_name, extension_name, 
                       gender, mobile_number, email, office_department, is_head_librarian, profile_path) 
                      VALUES 
                      (@id, @fname, @mname, @lname, @ext, @gender, @mobile, @email, @office, {isHead}, @profilePath)";
        }

        private void AddPatronParameters(MySqlCommand cmd, string role, string profilePath)
        {
            cmd.Parameters.AddWithValue("@id", txtID.Text.Trim());
            cmd.Parameters.AddWithValue("@fname", txtFName.Text.Trim());
            cmd.Parameters.AddWithValue("@mname", txtMName.Text.Trim());
            cmd.Parameters.AddWithValue("@lname", txtLName.Text.Trim());
            cmd.Parameters.AddWithValue("@ext", txtExt.Text.Trim());
            cmd.Parameters.AddWithValue("@gender", ddlGender.SelectedValue);
            cmd.Parameters.AddWithValue("@mobile", txtMobile.Text.Trim());
            cmd.Parameters.AddWithValue("@email", txtEmail.Text.Trim());

            if (role == "student")
            {
                cmd.Parameters.AddWithValue("@inst", txtInst.Text.Trim());
                cmd.Parameters.AddWithValue("@course", txtCourse.Text.Trim());
                cmd.Parameters.AddWithValue("@sec", txtSec.Text.Trim());
                cmd.Parameters.AddWithValue("@year", txtYear.Text.Trim());
            }
            else if (role == "faculty")
            {
                cmd.Parameters.AddWithValue("@inst", txtFacInst.Text.Trim());
            }
            else if (role == "staff")
            {
                cmd.Parameters.AddWithValue("@office", txtOffice.Text.Trim());
            }

            cmd.Parameters.AddWithValue("@profilePath",
                string.IsNullOrEmpty(profilePath) ? (object)DBNull.Value : profilePath);
        }

        // =============================================================
        //  RESULT CHANNEL
        // =============================================================

        private void SetResult(string type, string title, string message)
        {
            var payload = new { type = type, title = title, message = message };
            hfResult.Value = new JavaScriptSerializer().Serialize(payload);
        }

        private string DescribeDuplicate(MySqlException ex)
        {
            string msg = ex.Message ?? "";

            bool isEmail = msg.IndexOf("email", StringComparison.OrdinalIgnoreCase) >= 0;

            bool isPrimary =
                msg.IndexOf("PRIMARY", StringComparison.OrdinalIgnoreCase) >= 0 ||
                msg.IndexOf("student_id", StringComparison.OrdinalIgnoreCase) >= 0 ||
                msg.IndexOf("faculty_id", StringComparison.OrdinalIgnoreCase) >= 0 ||
                msg.IndexOf("staff_id", StringComparison.OrdinalIgnoreCase) >= 0 ||
                msg.IndexOf("user_id", StringComparison.OrdinalIgnoreCase) >= 0;

            if (isEmail && isPrimary)
                return "Both the ID Number and Email Address are already registered.";
            if (isEmail)
                return "The Email Address is already registered in the system.";
            if (isPrimary)
                return "The ID Number is already registered in the system.";

            return "A record with the same ID Number or Email already exists.";
        }

        // =============================================================
        //  FORM RESET (first load only)
        // =============================================================

        private void ClearFields()
        {
            ddlCategory.SelectedIndex = 0;
            txtID.Text = "";
            txtEmail.Text = "";
            txtFName.Text = "";
            txtMName.Text = "";
            txtLName.Text = "";
            txtExt.Text = "";
            ddlGender.SelectedIndex = 0;
            txtMobile.Text = "";
            txtInst.Text = "";
            txtCourse.Text = "";
            txtSec.Text = "";
            txtYear.Text = "";
            txtFacInst.Text = "";
            txtOffice.Text = "";
        }
    }
}