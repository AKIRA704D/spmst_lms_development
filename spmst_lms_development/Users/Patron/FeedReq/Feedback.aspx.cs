using DocumentFormat.OpenXml.Office.SpreadSheetML.Y2023.MsForms;
using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.UI;

namespace spmst_lms_development.Users.Patron.FeedReq
{
    public partial class Feedback : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadRecentActivity();
            }
        }

        protected void btnTabFeedback_Click(object sender, EventArgs e)
        {
            mvForms.ActiveViewIndex = 0;
            btnTabFeedback.CssClass = "tab-btn active";
            btnTabRequest.CssClass = "tab-btn inactive";
        }

        protected void btnTabRequest_Click(object sender, EventArgs e)
        {
            mvForms.ActiveViewIndex = 1;
            btnTabFeedback.CssClass = "tab-btn inactive";
            btnTabRequest.CssClass = "tab-btn active";
        }

        protected void btnSubmitFeedback_Click(object sender, EventArgs e)
        {
            string userId = Session["UserID"]?.ToString();
            if (string.IsNullOrEmpty(userId))
            {
                ShowSweetAlert("Session Error", "User not logged in. Please log in again.", "error");
                return;
            }

            string category = ddlCategory.SelectedValue;
            string message = txtMessage.Text.Trim();

            if (string.IsNullOrEmpty(category) || string.IsNullOrEmpty(message))
            {
                ShowSweetAlert("Incomplete", "Please select a category and enter your message.", "warning");
                return;
            }

            string formattedMessage = $"[{ddlCategory.SelectedItem.Text}] {message}";

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                string query = "INSERT INTO User_Submissions (user_id, type, message) VALUES (@userId, 'Feedback', @message)";
                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@userId", userId);
                    cmd.Parameters.AddWithValue("@message", formattedMessage);
                    try
                    {
                        conn.Open();
                        cmd.ExecuteNonQuery();
                        ShowSweetAlert("Success", "Your feedback has been submitted successfully!", "success");
                        ddlCategory.SelectedIndex = 0;
                        txtMessage.Text = "";
                        LoadRecentActivity();
                    }
                    catch (Exception ex)
                    {
                        ShowSweetAlert("Database Error", ex.Message, "error");
                    }
                }
            }
        }

        protected void btnSubmitRequest_Click(object sender, EventArgs e)
        {
            string userId = Session["UserID"]?.ToString();
            if (string.IsNullOrEmpty(userId))
            {
                ShowSweetAlert("Session Error", "User not logged in. Please log in again.", "error");
                return;
            }

            string title = txtReqTitle.Text.Trim();
            string author = txtReqAuthor.Text.Trim();
            string year = txtReqYear.Text.Trim();

            if (string.IsNullOrEmpty(title) || string.IsNullOrEmpty(author))
            {
                ShowSweetAlert("Incomplete", "Please provide at least the Book Title and Author.", "warning");
                return;
            }

            string formattedMessage = $"[Book Request] Title: {title} | Author: {author} | Year: {(string.IsNullOrEmpty(year) ? "N/A" : year)}";

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                string query = "INSERT INTO User_Submissions (user_id, type, message) VALUES (@userId, 'Request', @message)";
                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@userId", userId);
                    cmd.Parameters.AddWithValue("@message", formattedMessage);
                    try
                    {
                        conn.Open();
                        cmd.ExecuteNonQuery();
                        ShowSweetAlert("Success", "Your book request has been submitted!", "success");
                        txtReqTitle.Text = "";
                        txtReqAuthor.Text = "";
                        txtReqYear.Text = "";
                        LoadRecentActivity();
                    }
                    catch (Exception ex)
                    {
                        ShowSweetAlert("Database Error", ex.Message, "error");
                    }
                }
            }
        }

        private void LoadRecentActivity()
        {
            string userId = Session["UserID"]?.ToString();
            if (string.IsNullOrEmpty(userId)) return;

            DataTable dt = new DataTable();
            dt.Columns.Add("CategoryTitle");
            dt.Columns.Add("TimeAgo");

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                string query = @"
                    SELECT type, message, created_at 
                    FROM User_Submissions 
                    WHERE user_id = @userId 
                    ORDER BY created_at DESC LIMIT 4";
                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@userId", userId);
                    conn.Open();
                    using (MySqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            string rawMessage = reader["message"].ToString();
                            DateTime createdAt = Convert.ToDateTime(reader["created_at"]);
                            string categoryTitle = reader["type"].ToString() + " Submission";
                            if (rawMessage.StartsWith("[") && rawMessage.Contains("]"))
                            {
                                int endBracket = rawMessage.IndexOf("]");
                                categoryTitle = rawMessage.Substring(1, endBracket - 1);
                            }
                            dt.Rows.Add(categoryTitle, GetTimeAgo(createdAt));
                        }
                    }
                }
            }
            rptRecentActivity.DataSource = dt;
            rptRecentActivity.DataBind();
        }

        private string GetTimeAgo(DateTime dt)
        {
            TimeSpan span = DateTime.Now - dt;
            if (span.Days > 365) return $"{span.Days / 365} year{(span.Days / 365 == 1 ? "" : "s")} ago";
            if (span.Days > 30) return $"{span.Days / 30} month{(span.Days / 30 == 1 ? "" : "s")} ago";
            if (span.Days > 0) return $"{span.Days} day{(span.Days == 1 ? "" : "s")} ago";
            if (span.Hours > 0) return $"{span.Hours} hour{(span.Hours == 1 ? "" : "s")} ago";
            if (span.Minutes > 0) return $"{span.Minutes} minute{(span.Minutes == 1 ? "" : "s")} ago";
            return "Just now";
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"showSweetAlert('{cleanTitle}', '{cleanMsg}', '{icon}');";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }
    }
}
