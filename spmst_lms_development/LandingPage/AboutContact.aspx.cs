using System;
using System.Configuration;
using System.Web.Services;
using System.Web.Script.Services;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.LandingPage
{
    public partial class AboutContact : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
        }

        /// <summary>
        /// Saves a contact-form submission into User_Submissions.
        /// Logged-in users are linked by user_id; guests are stored with user_id = NULL.
        /// </summary>
        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object SubmitMessage(string name, string email, string subject,
                                           string message, string type, bool isRestock)
        {
            try
            {
                // ---------- Normalise ----------
                name = (name ?? string.Empty).Trim();
                email = (email ?? string.Empty).Trim();
                subject = (subject ?? string.Empty).Trim();
                message = (message ?? string.Empty).Trim();
                type = (type ?? string.Empty).Trim();

                // ---------- Validation ----------
                if (string.IsNullOrWhiteSpace(message))
                    return new { success = false, reason = "Message is required." };

                if (message.Length > 5000)
                    return new { success = false, reason = "Message is too long (max 5000 characters)." };

                if (type != "Inquiry" && type != "Feedback" && type != "Request")
                    type = "Inquiry"; // safe default

                // ---------- Identify user via sessionHelper ----------
                bool isLoggedIn = sessionHelper.IsLoggedIn();
                string userId = isLoggedIn ? sessionHelper.UserID : null;

                // For logged-in users, prefer the session identity over form values.
                if (isLoggedIn)
                {
                    if (string.IsNullOrWhiteSpace(name))
                        name = sessionHelper.FullName;
                    if (string.IsNullOrWhiteSpace(email))
                        email = sessionHelper.Email;
                }

                // ---------- Build the stored message ----------
                // The schema has no name/email/subject columns, so contact details
                // are folded into the message body.
                string storedMessage;
                if (isLoggedIn)
                {
                    storedMessage = string.IsNullOrEmpty(subject)
                        ? message
                        : "Subject: " + subject + Environment.NewLine + Environment.NewLine + message;
                }
                else
                {
                    var header = "From (guest): " + (string.IsNullOrEmpty(name) ? "(no name)" : name);
                    if (!string.IsNullOrEmpty(email)) header += " <" + email + ">";
                    if (!string.IsNullOrEmpty(subject)) header += Environment.NewLine + "Subject: " + subject;
                    storedMessage = header + Environment.NewLine + Environment.NewLine + message;
                }

                // ---------- Insert ----------
                string connStr = ConfigurationManager
                    .ConnectionStrings["LmsDb"].ConnectionString;

                using (var conn = new MySqlConnection(connStr))
                using (var cmd = new MySqlCommand(
                    @"INSERT INTO User_Submissions
                        (user_id, type, message, is_restock_suggestion)
                      VALUES
                        (@user_id, @type, @message, @restock);", conn))
                {
                    cmd.Parameters.AddWithValue("@user_id", (object)userId ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@type", type);
                    cmd.Parameters.AddWithValue("@message", storedMessage);
                    cmd.Parameters.AddWithValue("@restock", isRestock ? 1 : 0);

                    conn.Open();
                    cmd.ExecuteNonQuery();
                }

                return new
                {
                    success = true,
                    message = isLoggedIn
                        ? "Thanks! Your message has been received."
                        : "Thanks! Your message has been received. The library team will get back to you soon."
                };
            }
            catch (MySqlException dbEx)
            {
                // If the FK fails (stale session user deleted), fall back to guest insert.
                if (dbEx.Number == 1452) // Cannot add or update a child row: FK constraint fails
                {
                    try
                    {
                        return SubmitAsGuest(subject, message, type, isRestock);
                    }
                    catch (Exception)
                    {
                        return new
                        {
                            success = false,
                            reason = "We couldn't save your message right now. Please try again in a moment."
                        };
                    }
                }

                return new
                {
                    success = false,
                    reason = "We couldn't save your message right now. Please try again in a moment."
                };
            }
            catch (Exception)
            {
                return new
                {
                    success = false,
                    reason = "Something went wrong while sending your message. Please try again."
                };
            }
        }

        /// <summary>
        /// Fallback insert for guests (user_id = NULL).
        /// </summary>
        private static object SubmitAsGuest(string subject, string message, string type, bool isRestock)
        {
            string connStr = ConfigurationManager
                .ConnectionStrings["LmsDb"].ConnectionString;

            string storedMessage = string.IsNullOrEmpty(subject)
                ? message
                : "Subject: " + subject + Environment.NewLine + Environment.NewLine + message;

            using (var conn = new MySqlConnection(connStr))
            using (var cmd = new MySqlCommand(
                @"INSERT INTO User_Submissions
                    (user_id, type, message, is_restock_suggestion)
                  VALUES
                    (NULL, @type, @message, @restock);", conn))
            {
                cmd.Parameters.AddWithValue("@type", type);
                cmd.Parameters.AddWithValue("@message", storedMessage);
                cmd.Parameters.AddWithValue("@restock", isRestock ? 1 : 0);

                conn.Open();
                cmd.ExecuteNonQuery();
            }

            return new
            {
                success = true,
                message = "Thanks! Your message has been received. The library team will get back to you soon."
            };
        }
    }
}