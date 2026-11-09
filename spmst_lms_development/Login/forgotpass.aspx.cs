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
    public partial class ForgotPass : System.Web.UI.Page
    {
        private readonly string connString =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        private const int OtpServerExpirySeconds = 90;
        private const int MaxOtpAttempts = 3;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                Session.Clear();
                Session["OtpFailedAttempts"] = 0;
            }
        }

        /* ---------------- STEP 1 : find account ---------------- */
        protected void btnFindAccount_Click(object sender, EventArgs e)
        {
            string userId = (txtUserId.Text ?? string.Empty).Trim();
            string email = (txtEmail.Text ?? string.Empty).Trim().ToLowerInvariant();

            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(email))
            {
                AlertHelper.ShowError(this, "All identification data entry fields are required. Please input both your User ID and Registered Email Address.");
                return;
            }

            if (!InputHelper.IsValidEmail(email))
            {
                AlertHelper.ShowError(this, "The email address structure provided is invalid. Please double check characters arrangement.");
                return;
            }

            try
            {
                AuditLog.LogCredentialValidationInitiated(userId, "forgot-password");

                if (ValidateUserExists(userId, email))
                {
                    AuditLog.LogCredentialValidationSuccess(userId, "forgot-password");
                    Session["ResetUserId"] = userId;
                    Session["ResetEmail"] = email;
                    SendOtpLogic(email); // This is where it might hang on SMTP
                }
                else
                {
                    AuditLog.LogCredentialValidationFailed(userId, "forgot-password", "No matching active account");
                    AlertHelper.ShowError(this, "Verification failure: No active user records match the specified User ID number and email structure pairings.");
                }
            }
            catch (Exception ex)
            {
                // If the database fails or SMTP crashes, close the loader and show an error!
                AuditLog.LogCredentialValidationFailed(userId, "forgot-password", "System Exception: " + ex.Message);
                AlertHelper.ShowError(this, "A system error occurred. Please try again later.");
            }
        }

        private bool ValidateUserExists(string userId, string email)
        {
            using (MySqlConnection conn = new MySqlConnection(connString))
            {
                const string query =
                    "SELECT COUNT(1) FROM Users " +
                    "WHERE user_id = @userId AND email = @email AND is_active = 1;";
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
                int code = 100000 + (int)(raw % 900000);
                return code.ToString("D6");
            }
        }

        private void SendOtpLogic(string email)
        {
            string otp = GenerateSecureOtp();
            Session["CurrentOTP"] = otp;
            Session["OtpIssuedAt"] = DateTime.UtcNow;
            Session["OtpExpiry"] = DateTime.UtcNow.AddSeconds(OtpServerExpirySeconds);
            Session["OtpFailedAttempts"] = 0;
            Session["OtpVerified"] = false;

            bool emailSent = EmailHelper.SendOtp(email, otp);

            if (emailSent)
            {
                pnlFindAccount.Visible = false;
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
                    "communication messages via standard SMTP network configurations.");
            }
        }

        protected void btnHiddenResend_Click(object sender, EventArgs e)
        {
            if (Session["ResetEmail"] != null)
            {
                SendOtpLogic(Session["ResetEmail"].ToString());
            }
            else
            {
                AlertHelper.ShowError(this,
                    "Session identity data tracking expired. Please re-input parameters.");
                pnlOtp.Visible = false;
                pnlFindAccount.Visible = true;
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
                Session["CurrentOTP"] = null;
                Session["OtpExpiry"] = null;
                Session["OtpVerified"] = true;
                Session["OtpFailedAttempts"] = 0;

                pnlOtp.Visible = false;
                pnlResetPassword.Visible = true;

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
            pnlResetPassword.Visible = false;
            pnlFindAccount.Visible = true;
        }

        protected void btnCancel_Click(object sender, EventArgs e)
        {
            ScriptManager.RegisterStartupScript(this, GetType(),
                "StopTimer_" + Guid.NewGuid().ToString("N"),
                "stopOtpTimer();", true);
            Session.Clear();
            Response.Redirect("login.aspx");
        }

        /* ---------------- STEP 4 : reset password ---------------- */
        protected void btnResetPassword_Click(object sender, EventArgs e)
        {
            string newPass = txtNewPass.Text ?? string.Empty;
            string confPass = txtConfirmPass.Text ?? string.Empty;

            if (Session["ResetUserId"] == null ||
                !(Session["OtpVerified"] is bool verified && verified))
            {
                AlertHelper.ShowError(this,
                    "Session instance timeout encountered during execution. " +
                    "Please restart the process.");
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

            string userId = Session["ResetUserId"].ToString();
            AuditLog.LogPasswordResetInitiated(userId);

            try
            {
                string hashedPass = BCrypt.Net.BCrypt.HashPassword(newPass);

                using (MySqlConnection conn = new MySqlConnection(connString))
                {
                    // NOTE: intentionally does NOT touch is_active — preserves
                    // existing activation status during password reset.
                    const string query =
                        "UPDATE Users SET password_hash = @pass, " +
                        "updated_at = CURRENT_TIMESTAMP " +
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

                AuditLog.LogPasswordResetSuccess(userId);
                Session.Clear();

                AlertHelper.ShowSuccess(this,
                    "Password Successfully Reset!",
                    "Your password has been successfully updated.",
                    "login.aspx", 2000);
            }
            catch (Exception ex)
            {
                AuditLog.LogPasswordResetFailed(userId, ex.Message);
                AlertHelper.ShowError(this,
                    "An error occurred while resetting your password. " +
                    "Please try again.");
            }
        }
    }
}