using System;
using System.Configuration;
using System.Net;
using System.Net.Mail;

namespace spmst_lms_development
{
    public static class EmailHelper
    {
        // Fetch SMTP settings from web.config
        private static readonly string SmtpServer = ConfigurationManager.AppSettings["SmtpServer"];
        private static readonly int SmtpPort = Convert.ToInt32(ConfigurationManager.AppSettings["SmtpPort"]);
        private static readonly string SmtpUser = ConfigurationManager.AppSettings["SmtpUser"];
        private static readonly string SmtpPass = ConfigurationManager.AppSettings["SmtpPass"];
        private static readonly bool SmtpEnableSsl = Convert.ToBoolean(ConfigurationManager.AppSettings["SmtpEnableSsl"]);

        /// <summary>
        /// Base method for sending any type of email.
        /// </summary>
        public static bool SendEmail(string toEmail, string subject, string body, bool isHtml = true)
        {
            try
            {
                using (MailMessage mail = new MailMessage())
                {
                    mail.From = new MailAddress(SmtpUser, "SPAMAST Library System");
                    mail.To.Add(toEmail);
                    mail.Subject = subject;
                    mail.Body = body;
                    mail.IsBodyHtml = isHtml;

                    using (SmtpClient smtp = new SmtpClient(SmtpServer, SmtpPort))
                    {
                        smtp.Credentials = new NetworkCredential(SmtpUser, SmtpPass);
                        smtp.EnableSsl = SmtpEnableSsl;
                        smtp.Send(mail);
                    }
                }
                return true;
            }
            catch (Exception ex)
            {
                // Optionally log the error: ex.Message
              //  System.Diagnostics.Debug.WriteLine("Email Send Error: " + ex.Message);

                System.Diagnostics.Debug.WriteLine("=== SMTP FAILURE EXCEPTION ===");
                System.Diagnostics.Debug.WriteLine(ex.ToString());
                return false;
            }
        }

        /// <summary>
        /// Pre-formatted template for sending OTPs.
        /// </summary>
        public static bool SendOtp(string toEmail, string otp)
        {
            string subject = "Your OTP - SPAMAST Library System";
            string body = $@"
                <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #ddd; border-radius: 8px; overflow: hidden;'>
                    <div style='background-color: #1d4ed8; color: white; padding: 15px; text-align: center;'>
                        <h2 style='margin: 0;'>SPAMAST Library Verification</h2>
                    </div>
                    <div style='padding: 30px; text-align: center;'>
                        <p style='color: #555; font-size: 16px;'>Your One-Time Password (OTP) is:</p>
                        <h1 style='color: #1d4ed8; font-size: 40px; letter-spacing: 5px; background: #f3f4f6; padding: 10px; border-radius: 8px; display: inline-block;'>{otp}</h1>
                        <p style='color: #888; font-size: 14px; mt-4'>Please use this code to complete your request. Do not share this code with anyone.</p>
                    </div>
                </div>";

            return SendEmail(toEmail, subject, body);
        }

        /// <summary>
        /// Pre-formatted template for general alerts/notifications.
        /// </summary>
        public static bool SendAlert(string toEmail, string title, string message)
        {
            string subject = $"Security Alert: {title}";
            string body = $@"
                <div style='font-family: Arial, sans-serif; padding: 20px; border-left: 4px solid #ef4444; background-color: #fef2f2;'>
                    <h3 style='color: #b91c1c; margin-top: 0;'>{title}</h3>
                    <p style='color: #450a0a;'>{message}</p>
                    <p style='color: #991b1b; font-size: 12px;'>If you did not perform this action, please contact the librarian immediately.</p>
                </div>";

            return SendEmail(toEmail, subject, body);
        }
    }
}