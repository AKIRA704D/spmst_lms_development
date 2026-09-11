using BCrypt.Net;
using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development
{
    public partial class ForgotPass : System.Web.UI.Page
    {
        private readonly string connString = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                Session.Clear();
            }
        }

        // STEP 1: Process User Identifiers Lookup & Validate Empty Inputs
        protected void btnFindAccount_Click(object sender, EventArgs e)
        {
            string userId = txtUserId.Text.Trim();
            string email = txtEmail.Text.Trim().ToLower();

            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(email))
            {
                AlertHelper.ShowError(this, "All identification data entry fields are required. Please input both your User ID and Registered Email Address.");
                return;
            }


            // Secure Email Verification Check via global helper
            if (string.IsNullOrWhiteSpace(userId) || !InputHelper.IsValidEmail(email))
            {
                AlertHelper.ShowError(this, "The email address structure provided is invalid. Please double check characters arrangement.");
                return;
            }

            if (ValidateUserExists(userId, email))
            {
                Session["ResetUserId"] = userId;
                Session["ResetEmail"] = email;

                SendOtpLogic(email);
            }
            else
            {
                AlertHelper.ShowError(this, "Verification failure: No active user records match the specified User ID number and email structure pairings.");
            }
        }

        private bool ValidateUserExists(string userId, string email)
        {
            bool exists = false;
            using (MySqlConnection conn = new MySqlConnection(connString))
            {
                string query = "SELECT COUNT(1) FROM Users WHERE user_id = @userId AND email = @email AND is_active = 1;";
                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@userId", userId);
                    cmd.Parameters.AddWithValue("@email", email);
                    conn.Open();
                    exists = Convert.ToInt32(cmd.ExecuteScalar()) > 0;
                }
            }
            return exists;
        }

        // STEP 2: Dispatch Security Codes Tracking (Delegated to EmailHelper)
        private void SendOtpLogic(string email)
        {
            Random rnd = new Random();
            string otp = rnd.Next(100000, 999999).ToString();
            Session["CurrentOTP"] = otp;

            bool emailSent = EmailHelper.SendOtp(email, otp);

            if (emailSent)
            {
                pnlFindAccount.Visible = false;
                pnlOtp.Visible = true;

                // Shows a clean, non-blocking success toast or alert
                AlertHelper.ShowSuccess(this, "OTP Transmitted", "A 6-digit verification code has been dispatched towards your registered profile inbox.");

                ScriptManager.RegisterStartupScript(this, GetType(), "StartTimer", "startOtpTimer();", true);
            }
            else
            {
                AlertHelper.CloseAlert(this);
                AlertHelper.ShowError(this, "Mail Dispatch Malfunction: Unable to transmit system communication messages via standard SMTP network configurations.");
            }
        }

        protected void btnHiddenResend_Click(object sender, EventArgs e)
        {
            if (Session["ResetEmail"] != null)
            {
                AlertHelper.ShowProcessing(this);
                SendOtpLogic(Session["ResetEmail"].ToString());
            }
            else
            {
                AlertHelper.ShowError(this, "Session identity data tracking expired. Please re-input parameters.");
                pnlOtp.Visible = false;
                pnlFindAccount.Visible = true;
            }
        }

        // STEP 3: Evaluate User Verification Input Code Context Entries (Solely Responsible for Checking Match)
        protected void btnVerifyOtp_Click(object sender, EventArgs e)
        {
            string inputOtp = txtOtp.Text.Trim();

            if (string.IsNullOrWhiteSpace(inputOtp))
            {
                AlertHelper.ShowError(this, "Please insert the 6-digit authentication token sequence dispatched to your screen mailbox profiles.");
                ScriptManager.RegisterStartupScript(this, GetType(), "RestartTimer", "startOtpTimer();", true);
                return;
            }

            // Checks the current OTP in session then proceeds directly to password reset panel
            if (Session["CurrentOTP"] != null && inputOtp == Session["CurrentOTP"].ToString())
            {
                AlertHelper.CloseAlert(this);
                pnlOtp.Visible = false;
                pnlResetPassword.Visible = true;

                ScriptManager.RegisterStartupScript(this, GetType(), "StopTimer", "stopOtpTimer();", true);
            }
            else
            {
                // 1. Tracks the sequential failed attempt counters
                int failedAttempts = Session["OtpFailedAttempts"] != null ? (int)Session["OtpFailedAttempts"] : 0;
                failedAttempts++;
                Session["OtpFailedAttempts"] = failedAttempts;

                int maxAttempts = 3;

                if (failedAttempts >= maxAttempts)
                {
                    // 2. Wipe current context variables to preserve registration state security
                    Session["OtpFailedAttempts"] = null;
                    Session["CurrentOTP"] = null;

                    // 3. Output the kickback redirection notification alert 
                    AlertHelper.ShowError(this, "Too many incorrect attempts. For security, your verification session has been reset. Please check your credentials and try again.");

                    // 4. Reset views directly back to the original identification panels
                    pnlOtp.Visible = false;

                    if (pnlOtp.Parent.FindControl("pnlFindAccount") != null)
                    {
                        ((Panel)pnlOtp.Parent.FindControl("pnlFindAccount")).Visible = true;
                    }
                    else if (pnlOtp.Parent.FindControl("pnlVerifyIdentity") != null)
                    {
                        ((Panel)pnlOtp.Parent.FindControl("pnlVerifyIdentity")).Visible = true;
                    }

                    // 5. Terminate the active frontend timer since we are exiting the OTP workspace
                    ScriptManager.RegisterStartupScript(this, GetType(), "StopTimer", "stopOtpTimer();", true);
                }
                else
                {
                    // 6. Normal attempt warning: Calculate remaining attempts and restart the countdown
                    int remainingAttempts = maxAttempts - failedAttempts;
                    AlertHelper.ShowError(this, $"Invalid token sequence match. Verification failed. You have {remainingAttempts} attempt(s) remaining.");

                    ScriptManager.RegisterStartupScript(this, GetType(), "RestartTimer", "startOtpTimer();", true);
                }
            }
        }

        protected void btnCancel_Click(object sender, EventArgs e)
        {
            ScriptManager.RegisterStartupScript(this, GetType(), "StopTimer", "stopOtpTimer();", true);
            Session.Clear();
            Response.Redirect("login.aspx");
        }

        // STEP 4: Persist Hashed Verification Token String Values Overwrites Updates
        protected void btnResetPassword_Click(object sender, EventArgs e)
        {
            string newPass = txtNewPass.Text;
            string confPass = txtConfirmPass.Text;

            if (string.IsNullOrWhiteSpace(newPass) || string.IsNullOrWhiteSpace(confPass))
            {
                AlertHelper.ShowError(this, "Credential input profiles cannot accommodate null or empty password space strings values configurations.");
                return;
            }

            if (newPass != confPass)
            {
                AlertHelper.ShowError(this, "Input synchronization mismatch: Defined credential password entry targets do not match.");
                return;
            }

            if (Session["ResetUserId"] != null)
            {
                string userId = Session["ResetUserId"].ToString();
                string hashedPass = BCrypt.Net.BCrypt.HashPassword(newPass);

                using (MySqlConnection conn = new MySqlConnection(connString))
                {
                    string query = "UPDATE Users SET password_hash = @pass, updated_at = CURRENT_TIMESTAMP WHERE user_id = @uid;";
                    using (MySqlCommand cmd = new MySqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@pass", hashedPass);
                        cmd.Parameters.AddWithValue("@uid", userId);

                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }
                }

                Session.Clear();
                AlertHelper.ShowSuccess(this, "Password Reset", "Your library profile password mapping was successfully refreshed.");
                ScriptManager.RegisterStartupScript(this, GetType(), "Redirect", "setTimeout(function(){ window.location.href='login.aspx'; }, 2000);", true);
            }
            else
            {
                AlertHelper.ShowError(this, "Session instance timeout encountered during execution context transformations. Processing rolled back.");
                pnlResetPassword.Visible = false;
                pnlFindAccount.Visible = true;
            }
        }
    }
}