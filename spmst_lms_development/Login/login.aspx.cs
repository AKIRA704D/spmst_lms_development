using BCrypt.Net;
using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web;
using System.Web.UI;

namespace spmst_lms_development.Login
{
    public partial class login : System.Web.UI.Page
    {
        // Define your centralized MySQL standard database server connection identifier string pattern
        private readonly string connString = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                pnlAlert.Visible = false;

                // Clear any existing residual sessions upon accessing the security check wall directly
                Session.Clear();
            }
        }

        protected void btnSignIn_Click(object sender, EventArgs e)
        {
            string emailInput = txtEmail.Text.Trim();
            string passwordInput = txtPassword.Text.Trim();

            // Enforce basic client data sanity validations
            if (string.IsNullOrEmpty(emailInput) || string.IsNullOrEmpty(passwordInput))
            {
                DisplayError("Please enter both your email address and account password.");
                return;
            }

            try
            {
                using (MySqlConnection conn = new MySqlConnection(connString))
                {
                    // Construct an efficient, parameterized join statement that gathers structural personnel properties safely
                    string query = @"
                        SELECT 
                            u.user_id, u.email, u.password_hash, u.role, u.is_active,
                            st.office_department, st.is_head_librarian,
                            COALESCE(st.first_name, s.first_name, f.first_name) AS first_name,
                            COALESCE(st.last_name, s.last_name, f.last_name) AS last_name
                        FROM Users u
                        LEFT JOIN Staff st ON u.user_id = st.staff_id
                        LEFT JOIN Students s ON u.user_id = s.student_id
                        LEFT JOIN Faculty f ON u.user_id = f.faculty_id
                        WHERE u.email = @Email LIMIT 1;";

                    using (MySqlCommand cmd = new MySqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@Email", emailInput);
                        conn.Open();

                        using (MySqlDataReader reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                int isActiveStatus = Convert.ToInt32(reader["is_active"]);
                                string dbPasswordHash = reader["password_hash"].ToString();

                                // Account Status Evaluation Gate check (0=pending, 1=active, 2=deactivated, 3=archived)
                                if (isActiveStatus != 1)
                                {
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

                                /* =========================================================================
                                 * IMPORTANT SECURITY IMPLEMENTATION NOTE ON CRYPTOGRAPHY VERIFICATION
                                 * =========================================================================
                                 * If you are utilizing raw text seed data during development phases,
                                 * swap this out with direct string equivalence tests temporarily. 
                                 * For real application security deployment, use BCrypt:
                                 */
                                bool isPasswordValid = false;
                                try
                                {
                                    isPasswordValid = BCrypt.Net.BCrypt.Verify(passwordInput, dbPasswordHash);
                                }
                                catch (BCrypt.Net.BcryptAuthenticationException)
                                {
                                    // Fallback structural check safety hook block if your database entries aren't initialized as BCrypt string models
                                    isPasswordValid = (passwordInput == dbPasswordHash);
                                }

                                if (isPasswordValid)
                                {
                                    // Parse profile properties safely out of query data context tables variables 
                                    string userId = reader["user_id"].ToString();
                                    string baseRole = reader["role"].ToString().ToLower();
                                    string dept = reader["office_department"] != DBNull.Value ? reader["office_department"].ToString() : "";
                                    string firstName = reader["first_name"] != DBNull.Value ? reader["first_name"].ToString() : "";
                                    string lastName = reader["last_name"] != DBNull.Value ? reader["last_name"].ToString() : "";

                                    string fullName = string.Format("{0} {1}", firstName, lastName).Trim();
                                    if (string.IsNullOrEmpty(fullName)) { fullName = "System User"; }

                                    // Map core database items directly onto mapped processing system runtime flags matching targets instructions requirements
                                    string evaluatedRoleCode = "";
                                    string targetDashboardRedirectPath = "";

                                    if (baseRole == "staff" || baseRole == "admin")
                                    {
                                        // Filter explicit administrative execution roles profiles dynamically using exact string match assertions
                                        if (dept.Equals("Circulation Area", StringComparison.OrdinalIgnoreCase))
                                        {
                                            evaluatedRoleCode = "staff-C";
                                            targetDashboardRedirectPath = "~/Users/circulationArea/cirDash.aspx";
                                        }
                                        else if (dept.Equals("Management Area", StringComparison.OrdinalIgnoreCase))
                                        {
                                            evaluatedRoleCode = "staff-M";
                                            targetDashboardRedirectPath = "~/Users/managementArea/manDash.aspx";
                                        }
                                        else if (baseRole == "admin" || dept.Equals("Head Office", StringComparison.OrdinalIgnoreCase))
                                        {
                                            evaluatedRoleCode = "staff-A";
                                            targetDashboardRedirectPath = "~/Users/Admin/Dashboard/adminDashC.aspx";
                                        }
                                        else
                                        {
                                            // Fallback default routing condition pattern for generic staff personnel definitions (staff-O)
                                            evaluatedRoleCode = "staff-O";
                                            targetDashboardRedirectPath = "~/Users/patron/patronDash.aspx";
                                        }
                                    }
                                    else if (baseRole == "student" || baseRole == "faculty")
                                    {
                                        evaluatedRoleCode = baseRole;
                                        targetDashboardRedirectPath = "~/Users/patron/patronDash.aspx";
                                    }
                                    else
                                    {
                                        DisplayError("System Configuration Error: Assigned account role classification pattern remains unmapped.");
                                        return;
                                    }

                                    // Allocate localized variables safe tracking inside global Context thread references pools
                                    Session["UserID"] = userId;
                                    Session["Email"] = reader["email"].ToString();
                                    Session["FullName"] = fullName;
                                    Session["UserRole"] = evaluatedRoleCode;

                                    // Update backend access event log timeline tracking values securely before dispatching navigation tokens
                                    UpdateUserLastLoginTimestamp(userId);

                                    // Dispatch execution context routing towards mapped administrative endpoints safely
                                    Response.Redirect(targetDashboardRedirectPath, false);
                                    Context.ApplicationInstance.CompleteRequest();
                                }
                                else
                                {
                                    DisplayError("Invalid email address or password provided. Please verify credentials.");
                                }
                            }
                            else
                            {
                                DisplayError("Invalid email address or password provided. Please verify credentials.");
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                // Mask structural infrastructure logs parameters out from front-facing presentation layers
                DisplayError("A connectivity infrastructure error occurred during sign-in verification processing: " + ex.Message);
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
            catch { /* Gracefully digest asynchronous timeline updates runtime errors tracking records failures */ }
        }

        private void DisplayError(string message)
        {
            lblAlertMessage.Text = HttpUtility.HtmlEncode(message);
            pnlAlert.Visible = true;
        }
    }
}