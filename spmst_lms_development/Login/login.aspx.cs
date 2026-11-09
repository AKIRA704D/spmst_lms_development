using BCrypt.Net;
using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Diagnostics;
using System.Web;
using System.Web.UI;
using spmst_lms_development.Assets.Helper;   // AuditLog

namespace spmst_lms_development.Login
{
    public partial class login : System.Web.UI.Page
    {
        private readonly string connString =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                pnlAlert.Visible = false;
                Session.Clear();
            }
        }

        protected void btnSignIn_Click(object sender, EventArgs e)
        {
            // Email: trimming leading/trailing whitespace is fine
            // (email addresses never legitimately carry spaces).
            string emailInput = txtEmail.Text.Trim();

            // Password: DO NOT trim. Whitespace may be part of the password.
            string passwordInput = txtPassword.Text;

            if (string.IsNullOrEmpty(emailInput) || string.IsNullOrEmpty(passwordInput))
            {
                DisplayError("Please enter both your email address and account password.");
                return;
            }

            try
            {
                using (MySqlConnection conn = new MySqlConnection(connString))
                {
                    // ---- Exact, case-sensitive email comparison ----
                    // MySQL's default collation (utf8mb4_general_ci) is
                    // case-insensitive. The BINARY operator forces a byte-by-
                    // byte comparison regardless of the column's collation,
                    // without altering the schema or stored data.
                    string query = @"
                        SELECT 
                            u.user_id, u.email, u.password_hash, u.role, u.is_active,
                            st.office_department, st.is_head_librarian,
                            COALESCE(st.first_name, s.first_name, f.first_name) AS first_name,
                            COALESCE(st.last_name,  s.last_name,  f.last_name)  AS last_name,
                            COALESCE(st.profile_path, s.profile_path, f.profile_path) AS profile_image
                        FROM Users u
                        LEFT JOIN Staff   st ON u.user_id = st.staff_id
                        LEFT JOIN Students s ON u.user_id = s.student_id
                        LEFT JOIN Faculty  f ON u.user_id = f.faculty_id
                        WHERE BINARY u.email = BINARY @Email LIMIT 1;";

                    using (MySqlCommand cmd = new MySqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@Email", emailInput);
                        conn.Open();

                        using (MySqlDataReader reader = cmd.ExecuteReader())
                        {
                            if (!reader.Read())
                            {
                                AuditLog.LogLogin(emailInput, false, "Unknown email");
                                DisplayError("Invalid email address or password provided. Please verify credentials.");
                                return;
                            }

                            // ---------- Account status gate ----------
                            int isActiveStatus = Convert.ToInt32(reader["is_active"]);
                            if (isActiveStatus != 1)
                            {
                                string reason;
                                switch (isActiveStatus)
                                {
                                    case 0: reason = "Account pending approval"; break;
                                    case 2: reason = "Account deactivated"; break;
                                    case 3: reason = "Account archived"; break;
                                    default: reason = "Unknown account status"; break;
                                }
                                AuditLog.LogLogin(emailInput, false, reason);

                                switch (isActiveStatus)
                                {
                                    case 0:
                                        DisplayError("Your account registration is currently pending review or approval. Make sure your account is verified and try to login again");
                                        break;
                                    case 2:
                                        DisplayError("This account has been deactivated. Please contact the administrator.");
                                        break;
                                    case 3:
                                        DisplayError("This account has been archived due to institutional policy changes.");
                                        break;
                                    default:
                                        DisplayError("Access restricted. Unable to verify account status conditions.");
                                        break;
                                }
                                return;
                            }

                            // ---------- Password verification ----------
                            string dbPasswordHash = reader["password_hash"].ToString();
                            bool isPasswordValid = false;
                            try
                            {
                                // BCrypt.Verify is case-sensitive and whitespace-sensitive
                                isPasswordValid = BCrypt.Net.BCrypt.Verify(passwordInput, dbPasswordHash);
                            }
                            catch (BCrypt.Net.BcryptAuthenticationException)
                            {
                                // Legacy plaintext fallback — string == in C# is
                                // ordinal (case-sensitive), which is what we want.
                                isPasswordValid = (passwordInput == dbPasswordHash);
                            }

                            if (!isPasswordValid)
                            {
                                AuditLog.LogLogin(emailInput, false, "Invalid password");
                                DisplayError("Invalid email address or password provided. Please verify credentials.");
                                return;
                            }

                            // ---------- Extract profile fields ----------
                            string userId = reader["user_id"].ToString();
                            string dbRole = reader["role"].ToString();
                            string dept = reader["office_department"] != DBNull.Value
                                              ? reader["office_department"].ToString()
                                              : string.Empty;
                            bool isHeadLibrarian =
                                reader["is_head_librarian"] != DBNull.Value
                                && Convert.ToInt32(reader["is_head_librarian"]) == 1;

                            string firstName = reader["first_name"] != DBNull.Value
                                               ? reader["first_name"].ToString() : "";
                            string lastName = reader["last_name"] != DBNull.Value
                                               ? reader["last_name"].ToString() : "";

                            string fullName = string.Format("{0} {1}", firstName, lastName).Trim();
                            if (string.IsNullOrEmpty(fullName)) fullName = "System User";

                            string profileImagePath = reader["profile_image"] != DBNull.Value
                                                ? reader["profile_image"].ToString() : string.Empty;

                            // ---------- Canonical role resolution ----------
                            string evaluatedRoleCode =
                                sessionHelper.ResolveRole(dbRole, dept, isHeadLibrarian);

                            if (evaluatedRoleCode == sessionHelper.RoleVisitor)
                            {
                                AuditLog.LogLogin(userId, false, "Unmapped role / department combination");
                                DisplayError("System Configuration Error: Assigned account role classification pattern remains unmapped.");
                                return;
                            }

                            // ---------- Persist session ----------
                            Session["UserID"] = userId;
                            Session["Email"] = reader["email"].ToString();
                            Session["FullName"] = fullName;
                            Session["UserRole"] = evaluatedRoleCode;  // code, NOT display name
                            Session["ProfileImagePath"] = profileImagePath;

                            // ---------- Post-login bookkeeping ----------
                            UpdateUserLastLoginTimestamp(userId);
                            AuditLog.LogLogin(userId, true);

                            // ---------- Redirect ----------
                            string targetDashboardRedirectPath =
                                sessionHelper.GetDashboardPath(evaluatedRoleCode);

                            Response.Redirect(targetDashboardRedirectPath, false);
                            Context.ApplicationInstance.CompleteRequest();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                // Log internally — do NOT leak DB/connection details to the user.
                System.Diagnostics.Trace.TraceError("Sign-in error: " + ex);

                // Show a generic error; the client-side loader will
                // disappear automatically because the response replaces
                // the old page's DOM (which held the SweetAlert modal).
                DisplayError("An unexpected error occurred during sign-in. Please try again in a moment.");
            }
        }

        private void UpdateUserLastLoginTimestamp(string userId)
        {
            try
            {
                using (MySqlConnection conn = new MySqlConnection(connString))
                {
                    string updateQuery = "UPDATE Users SET last_login = CURRENT_TIMESTAMP WHERE user_id = @UserID;";
                    using (MySqlCommand cmd = new MySqlCommand(updateQuery, conn))
                    {
                        cmd.Parameters.AddWithValue("@UserID", userId);
                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch { /* swallow — not critical to login flow */ }
        }

        private void DisplayError(string message)
        {
            lblAlertMessage.Text = HttpUtility.HtmlEncode(message);
            pnlAlert.Visible = true;
        }
    }
}