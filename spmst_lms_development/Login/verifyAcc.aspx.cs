using BCrypt.Net;
using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development
{
    public partial class VerifyAcc : System.Web.UI.Page
    {
        private readonly string connString = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                Session.Clear();
            }
        }

        // STEP 1: Process Validation Input
        protected void btnVerifyIdentity_Click(object sender, EventArgs e)
        {
            string userId = txtUserId.Text.Trim();
            string email = txtEmail.Text.Trim().ToLower(); // Matched down-cased mapping logic sync 

            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(email))
            {
                AlertHelper.ShowError(this, "All identification data entry fields are required. Please input both your User ID and Registered Email Address.");
                return;
            }

            // Secure Email Verification Check via global helper
            if (!InputHelper.IsValidEmail(email))
            {
                AlertHelper.ShowError(this, "The email address structure provided is invalid. Please double check characters arrangement.");
                return;
            }

            if (ValidateUserEligibility(userId, email))
            {
                Session["VerifyUserId"] = userId;
                Session["VerifyEmail"] = email;

                SendOtpLogic(email);
            }
            else
            {
                AlertHelper.ShowError(this, "Verification failure: No inactive user accounts found matching that profile data structure.");
            }
        }

        private bool ValidateUserEligibility(string userId, string email)
        {
            bool eligible = false;
            using (MySqlConnection conn = new MySqlConnection(connString))
            {
                // Looking for accounts that are registered but NOT yet active (is_active = 0)
                string query = "SELECT COUNT(1) FROM Users WHERE user_id = @userId AND email = @email AND is_active = 0;";
                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@userId", userId);
                    cmd.Parameters.AddWithValue("@email", email);
                    conn.Open();
                    eligible = Convert.ToInt32(cmd.ExecuteScalar()) > 0;
                }
            }
            return eligible;
        }

        // STEP 2: Dispatch Security Codes Tracking
        private void SendOtpLogic(string email)
        {
            Random rnd = new Random();
            string otp = rnd.Next(100000, 999999).ToString();
            Session["CurrentOTP"] = otp;

            bool emailSent = EmailHelper.SendOtp(email, otp);

            if (emailSent)
            {
                pnlVerifyIdentity.Visible = false;
                pnlOtp.Visible = true;

                AlertHelper.ShowSuccess(this, "OTP Transmitted", "A 6-digit verification code has been dispatched towards your registered profile inbox.");
                ScriptManager.RegisterStartupScript(this, GetType(), "StartTimer", "startOtpTimer();", true);
            }
            else
            {
                AlertHelper.CloseAlert(this);
                AlertHelper.ShowError(this, "Mail Dispatch Malfunction: Unable to transmit system communication messages via standard SMTP configuration.");
            }
        }

        protected void btnHiddenResend_Click(object sender, EventArgs e)
        {
            if (Session["VerifyEmail"] != null)
            {
                AlertHelper.ShowProcessing(this);
                SendOtpLogic(Session["VerifyEmail"].ToString());
            }
            else
            {
                AlertHelper.ShowError(this, "Session identity data tracking expired. Please re-input parameters.");
                pnlOtp.Visible = false;
                pnlVerifyIdentity.Visible = true;
            }
        }

        // STEP 3: Evaluate User Verification Input Code Context Entries
        protected void btnVerifyOtp_Click(object sender, EventArgs e)
        {
            string inputOtp = txtOtp.Text.Trim();

            if (string.IsNullOrWhiteSpace(inputOtp))
            {
                AlertHelper.ShowError(this, "Please insert the 6-digit authentication token sequence dispatched to your screen mailbox profiles.");
                ScriptManager.RegisterStartupScript(this, GetType(), "RestartTimer", "startOtpTimer();", true);
                return;
            }

            if (Session["CurrentOTP"] != null && inputOtp == Session["CurrentOTP"].ToString())
            {
                AlertHelper.CloseAlert(this);
                pnlOtp.Visible = false;
                pnlSetupPassword.Visible = true;

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
            Session.Clear();
            Response.Redirect("login.aspx");
        }

        // STEP 4: Persist Credentials Update Base Updates Context
        protected void btnSetupPassword_Click(object sender, EventArgs e)
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

            if (Session["VerifyUserId"] != null)
            {
                string userId = Session["VerifyUserId"].ToString();
                string hashedPass = BCrypt.Net.BCrypt.HashPassword(newPass);

                using (MySqlConnection conn = new MySqlConnection(connString))
                {
                    // Sets the new password and flips the user state to Active (1)
                    string query = "UPDATE Users SET password_hash = @pass, is_active = 1, updated_at = CURRENT_TIMESTAMP WHERE user_id = @uid;";
                    using (MySqlCommand cmd = new MySqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@pass", hashedPass);
                        cmd.Parameters.AddWithValue("@uid", userId);

                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }
                }

                Session.Clear();
                AlertHelper.ShowSuccess(this, "Verification Complete!", "Your account has been fully verified and set up.");
                ScriptManager.RegisterStartupScript(this, GetType(), "Redirect", "setTimeout(function(){ window.location.href='login.aspx'; }, 2000);", true);
            }
            else
            {
                AlertHelper.ShowError(this, "Session instance timeout encountered. Processing rolled back.");
                pnlSetupPassword.Visible = false;
                pnlVerifyIdentity.Visible = true;
            }
        }
    }
}