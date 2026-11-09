using BCrypt.Net;
using MySql.Data.MySqlClient;
using spmst_lms_development.Assets.Helper;
using System;
using System.Configuration;
using System.Security.Cryptography;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development
{
    public partial class VerifyAcc : System.Web.UI.Page
    {
        private readonly string connString =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        private const int OtpServerExpirySeconds = 90; // slightly larger than the JS 60s display
        private const int MaxOtpAttempts = 3;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                Session.Clear();
                Session["OtpFailedAttempts"] = 0;
            }
        }

        /* ---------------- STEP 1 : validate identity ---------------- */
        protected void btnVerifyIdentity_Click(object sender, EventArgs e)
        {
            string userId = (txtUserId.Text ?? string.Empty).Trim();
            string email = (txtEmail.Text ?? string.Empty).Trim().ToLowerInvariant();

            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(email))
            {
                AuditLog.LogCredentialValidationFailed(userId,
                    "verify-account", "Missing user id or email");
                AlertHelper.ShowError(this,
                    "All identification data entry fields are required. " +
                    "Please input both your User ID and Registered Email Address.");
                return;
            }

            if (!InputHelper.IsValidEmail(email))
            {
                AuditLog.LogCredentialValidationFailed(userId,
                    "verify-account", "Invalid email format");
                AlertHelper.ShowError(this,
                    "The email address structure provided is invalid. " +
                    "Please double check characters arrangement.");
                return;
            }

            AuditLog.LogCredentialValidationInitiated(userId, "verify-account");

            if (ValidateUserEligibility(userId, email))
            {
                AuditLog.LogCredentialValidationSuccess(userId, "verify-account");
                Session["VerifyUserId"] = userId;
                Session["VerifyEmail"] = email;
                SendOtpLogic(email);
            }
            else
            {
                AuditLog.LogCredentialValidationFailed(userId,
                    "verify-account", "No matching inactive account");
                AlertHelper.ShowError(this,
                    "Verification failure: No inactive user accounts found matching " +
                    "that profile data structure.");
            }
        }

        private bool ValidateUserEligibility(string userId, string email)
        {
            using (MySqlConnection conn = new MySqlConnection(connString))
            {
                const string query =
                    "SELECT COUNT(1) FROM Users " +
                    "WHERE user_id = @userId AND email = @email AND is_active = 0;";
                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@userId", userId);
                    cmd.Parameters.AddWithValue("@email", email);
                    conn.Open();
                    return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
                }
            }
        }

        /* ---------------- STEP 2 : send OTP ---------------- */
        private static string GenerateSecureOtp()
        {
            using (var rng = RandomNumberGenerator.Create())
            {
                byte[] bytes = new byte[4];
                rng.GetBytes(bytes);
                uint raw = BitConverter.ToUInt32(bytes, 0);
                int code = 100000 + (int)(raw % 900000); // 100000..999999
                return code.ToString("D6");
            }
        }

        private void SendOtpLogic(string email)
        {
            // The client already shows the "Verifying Account..." loader before the
            // postback; that stays visible during SMTP. Here we simply refresh the
            // session OTP state.
            string otp = GenerateSecureOtp();
            Session["CurrentOTP"] = otp;
            Session["OtpIssuedAt"] = DateTime.UtcNow;
            Session["OtpExpiry"] = DateTime.UtcNow.AddSeconds(OtpServerExpirySeconds);
            Session["OtpFailedAttempts"] = 0;
            Session["OtpVerified"] = false;

            bool emailSent = EmailHelper.SendOtp(email, otp);

            if (emailSent)
            {
                pnlVerifyIdentity.Visible = false;
                pnlOtp.Visible = true;

                AlertHelper.ShowSuccess(this,
                    "OTP Transmitted",
                    "A 6-digit verification code has been dispatched towards " +
                    "your registered profile inbox.");
                ScriptManager.RegisterStartupScript(this, GetType(),
                    "StartTimer_" + Guid.NewGuid().ToString("N"),
                    "startOtpTimer();", true);
            }
            else
            {
                Session["CurrentOTP"] = null;
                Session["OtpExpiry"] = null;
                AlertHelper.ShowError(this,
                    "Mail Dispatch Malfunction: Unable to transmit system " +
                    "communication messages via standard SMTP configuration.");
            }
        }

        protected void btnHiddenResend_Click(object sender, EventArgs e)
        {
            if (Session["VerifyEmail"] != null && Session["VerifyUserId"] != null)
            {
                SendOtpLogic(Session["VerifyEmail"].ToString());
            }
            else
            {
                AlertHelper.ShowError(this,
                    "Session identity data tracking expired. Please re-input parameters.");
                pnlOtp.Visible = false;
                pnlVerifyIdentity.Visible = true;
            }
        }

        /* ---------------- STEP 3 : verify OTP ---------------- */
        protected void btnVerifyOtp_Click(object sender, EventArgs e)
        {
            string inputOtp = (txtOtp.Text ?? string.Empty).Trim();

            if (string.IsNullOrWhiteSpace(inputOtp) || inputOtp.Length != 6)
            {
                AlertHelper.ShowError(this,
                    "Please insert the 6-digit authentication token sequence " +
                    "dispatched to your screen mailbox profiles.");
                ScriptManager.RegisterStartupScript(this, GetType(),
                    "RestartTimer_" + Guid.NewGuid().ToString("N"),
                    "startOtpTimer();", true);
                return;
            }

            // Server-side expiration check (never trust the JS countdown alone)
            DateTime? expiry = null;
            if (Session["OtpExpiry"] is DateTime exp) { expiry = exp; }
            if (expiry.HasValue && DateTime.UtcNow > expiry.Value)
            {
                Session["CurrentOTP"] = null;
                Session["OtpExpiry"] = null;
                Session["OtpVerified"] = false;
                AlertHelper.ShowError(this,
                    "The verification code has expired. Please request a new one.");
                ResetOtpView();
                return;
            }

            if (Session["CurrentOTP"] != null &&
                inputOtp == Session["CurrentOTP"].ToString())
            {
                // Invalidate OTP after successful use
                Session["CurrentOTP"] = null;
                Session["OtpExpiry"] = null;
                Session["OtpVerified"] = true;
                Session["OtpFailedAttempts"] = 0;

                pnlOtp.Visible = false;
                pnlSetupPassword.Visible = true;

                AlertHelper.CloseAlert(this);
                ScriptManager.RegisterStartupScript(this, GetType(),
                    "StopTimer_" + Guid.NewGuid().ToString("N"),
                    "stopOtpTimer();", true);
            }
            else
            {
                int failedAttempts = Session["OtpFailedAttempts"] != null
                                     ? (int)Session["OtpFailedAttempts"] : 0;
                failedAttempts++;
                Session["OtpFailedAttempts"] = failedAttempts;

                if (failedAttempts >= MaxOtpAttempts)
                {
                    Session["OtpFailedAttempts"] = null;
                    Session["CurrentOTP"] = null;
                    Session["OtpExpiry"] = null;
                    Session["OtpVerified"] = false;

                    AlertHelper.ShowError(this,
                        "Too many incorrect attempts. For security, your " +
                        "verification session has been reset. Please check your " +
                        "credentials and try again.");
                    ResetOtpView();
                    ScriptManager.RegisterStartupScript(this, GetType(),
                        "StopTimer_" + Guid.NewGuid().ToString("N"),
                        "stopOtpTimer();", true);
                }
                else
                {
                    int remaining = MaxOtpAttempts - failedAttempts;
                    AlertHelper.ShowError(this,
                        "Invalid token sequence match. Verification failed. " +
                        "You have " + remaining + " attempt(s) remaining.");
                    ScriptManager.RegisterStartupScript(this, GetType(),
                        "RestartTimer_" + Guid.NewGuid().ToString("N"),
                        "startOtpTimer();", true);
                }
            }
        }

        private void ResetOtpView()
        {
            pnlOtp.Visible = false;
            pnlSetupPassword.Visible = false;
            pnlVerifyIdentity.Visible = true;
        }

        protected void btnCancel_Click(object sender, EventArgs e)
        {
            Session.Clear();
            Response.Redirect("login.aspx");
        }

        /* ---------------- STEP 4 : create password and activate ---------------- */
        protected void btnSetupPassword_Click(object sender, EventArgs e)
        {
            string newPass = txtNewPass.Text ?? string.Empty;
            string confPass = txtConfirmPass.Text ?? string.Empty;

            if (Session["VerifyUserId"] == null ||
                !(Session["OtpVerified"] is bool verified && verified))
            {
                AlertHelper.ShowError(this,
                    "Session instance timeout encountered or verification " +
                    "incomplete. Please restart the process.");
                ResetOtpView();
                return;
            }

            if (string.IsNullOrWhiteSpace(newPass) || string.IsNullOrWhiteSpace(confPass))
            {
                AlertHelper.ShowError(this,
                    "Password fields cannot be empty.");
                return;
            }

            if (newPass != confPass)
            {
                AlertHelper.ShowError(this,
                    "Input synchronization mismatch: The two password " +
                    "entries do not match.");
                return;
            }

            string userId = Session["VerifyUserId"].ToString();
            AuditLog.LogPasswordCreateInitiated(userId);

            try
            {
                string hashedPass = BCrypt.Net.BCrypt.HashPassword(newPass);

                using (MySqlConnection conn = new MySqlConnection(connString))
                {
                    const string query =
                        "UPDATE Users SET password_hash = @pass, " +
                        "is_active = 1, updated_at = CURRENT_TIMESTAMP " +
                        "WHERE user_id = @uid;";
                    using (MySqlCommand cmd = new MySqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@pass", hashedPass);
                        cmd.Parameters.AddWithValue("@uid", userId);
                        conn.Open();
                        int affected = cmd.ExecuteNonQuery();
                        if (affected == 0)
                        {
                            throw new InvalidOperationException(
                                "No user record was updated.");
                        }
                    }
                }

                AuditLog.LogPasswordCreate(userId, true);
                Session.Clear();

                AlertHelper.ShowSuccess(this,
                    "Account Verified!",
                    "Your account has been successfully verified and activated.",
                    "login.aspx", 2000);
            }
            catch (Exception ex)
            {
                AuditLog.LogPasswordCreate(userId, false, ex.Message);
                AlertHelper.ShowError(this,
                    "An error occurred while creating your password. " +
                    "Please try again.");
            }
        }
    }
}