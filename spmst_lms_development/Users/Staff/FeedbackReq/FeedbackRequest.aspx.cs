using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Staff.FeedbackReq
{
    public partial class FeedbackRequest : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        public class SubmissionItem
        {
            public string UserId { get; set; }
            public string PatronName { get; set; }
            public string DisplayName { get; set; }
            public string Role { get; set; }
            public string Type { get; set; }
            public string CategoryTitle { get; set; }
            public string CleanMessage { get; set; }
            public string FormattedDate { get; set; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                if (ViewState["CurrentFilter"] == null)
                    ViewState["CurrentFilter"] = "all";
                LoadSubmissions(ViewState["CurrentFilter"].ToString());
                CheckUserPermissions();
            }
            SetActiveTab();
        }

        private void CheckUserPermissions()
        {
            string userRole = Session["UserRole"]?.ToString() ?? "";
            string userDept = Session["UserDept"]?.ToString() ?? "";
            bool canSubmit = userRole.ToLower() == "admin" ||
                (userRole.ToLower() == "staff" && (userDept == "Circulation Area" || userDept == "Management Area" || userDept == "Head Office"));
            btnSubmitFeedback.Visible = canSubmit;
        }

        private void SetActiveTab()
        {
            string filter = ViewState["CurrentFilter"]?.ToString() ?? "all";
            tabAll.CssClass = "nav-link";
            tabFeedback.CssClass = "nav-link";
            tabRequest.CssClass = "nav-link";
            if (filter == "all") tabAll.CssClass = "nav-link active";
            else if (filter == "feedback") tabFeedback.CssClass = "nav-link active";
            else if (filter == "request") tabRequest.CssClass = "nav-link active";
        }

        protected void tabAll_Click(object sender, EventArgs e)
        {
            ViewState["CurrentFilter"] = "all";
            LoadSubmissions("all", txtSearch.Text.Trim());
            SetActiveTab();
            upTable.Update();
        }

        protected void tabFeedback_Click(object sender, EventArgs e)
        {
            ViewState["CurrentFilter"] = "feedback";
            LoadSubmissions("feedback", txtSearch.Text.Trim());
            SetActiveTab();
            upTable.Update();
        }

        protected void tabRequest_Click(object sender, EventArgs e)
        {
            ViewState["CurrentFilter"] = "request";
            LoadSubmissions("request", txtSearch.Text.Trim());
            SetActiveTab();
            upTable.Update();
        }

        protected void txtSearch_TextChanged(object sender, EventArgs e)
        {
            LoadSubmissions(ViewState["CurrentFilter"]?.ToString() ?? "all", txtSearch.Text.Trim());
        }

        protected void btnSubmitFeedback_Click(object sender, EventArgs e)
        {
            Response.Redirect("~/userpages/feedback/Feedback.aspx");
        }

        protected void btnExport_Click(object sender, EventArgs e)
        {
            try
            {
                DataTable dt = GetExportDataTable(ViewState["CurrentFilter"]?.ToString() ?? "all", txtSearch.Text.Trim());
                if (dt.Rows.Count > 0)
                {
                    StringBuilder csv = new StringBuilder();
                    // Headers
                    string[] headers = { "Date Submitted", "Patron Name", "User ID", "Role", "Type", "Category", "Message" };
                    csv.AppendLine(string.Join(",", headers.Select(h => $"\"{h}\"")));

                    // Rows
                    foreach (DataRow row in dt.Rows)
                    {
                        // Convert each item to string and escape double quotes
                        string[] fields = row.ItemArray.Select(item => $"\"{item.ToString().Replace("\"", "\"\"")}\"").ToArray();
                        csv.AppendLine(string.Join(",", fields));
                    }

                    Response.Clear();
                    Response.ContentType = "text/csv";
                    Response.AddHeader("content-disposition", $"attachment;filename=FeedbackRequests_{DateTime.Now:yyyyMMdd_HHmmss}.csv");
                    Response.Write(csv.ToString());
                    Response.End();
                }
                else
                {
                    ShowSweetAlert("No Data", "No submissions found to export.", "warning");
                }
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Export Error", ex.Message, "error");
            }
        }

        private DataTable GetExportDataTable(string filter, string searchTerm)
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("Date Submitted", typeof(string));
            dt.Columns.Add("Patron Name", typeof(string));
            dt.Columns.Add("User ID", typeof(string));
            dt.Columns.Add("Role", typeof(string));
            dt.Columns.Add("Type", typeof(string));
            dt.Columns.Add("Category", typeof(string));
            dt.Columns.Add("Message", typeof(string));

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                string sql = @"
                    SELECT us.user_id, us.type, us.message, us.created_at, u.role,
                           COALESCE(CONCAT(s.first_name, ' ', s.last_name), CONCAT(f.first_name, ' ', f.last_name), CONCAT(st.first_name, ' ', st.last_name)) AS patron_name
                    FROM User_Submissions us
                    INNER JOIN Users u ON us.user_id = u.user_id
                    LEFT JOIN Students s ON us.user_id = s.student_id
                    LEFT JOIN Faculty f ON us.user_id = f.faculty_id
                    LEFT JOIN Staff st ON us.user_id = st.staff_id
                    WHERE 1=1 ";
                if (filter == "feedback") sql += " AND us.type = 'Feedback' ";
                else if (filter == "request") sql += " AND us.type = 'Request' ";
                if (!string.IsNullOrEmpty(searchTerm))
                    sql += " AND (us.user_id LIKE @search OR patron_name LIKE @search) ";
                sql += " ORDER BY us.created_at DESC";

                using (MySqlCommand cmd = new MySqlCommand(sql, conn))
                {
                    if (!string.IsNullOrEmpty(searchTerm))
                        cmd.Parameters.AddWithValue("@search", "%" + searchTerm + "%");
                    conn.Open();
                    using (MySqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            string rawMessage = reader["message"].ToString();
                            DateTime createdAt = Convert.ToDateTime(reader["created_at"]);
                            string type = reader["type"].ToString();
                            string categoryTitle = type;
                            string cleanMessage = rawMessage;
                            if (rawMessage.StartsWith("[") && rawMessage.Contains("]"))
                            {
                                int endBracket = rawMessage.IndexOf("]");
                                categoryTitle = rawMessage.Substring(1, endBracket - 1);
                                cleanMessage = rawMessage.Substring(endBracket + 1).Trim();
                            }
                            string patronName = reader["patron_name"]?.ToString();
                            dt.Rows.Add(
                                createdAt.ToString("MMM dd, yyyy - hh:mm tt"),
                                string.IsNullOrEmpty(patronName) ? reader["user_id"].ToString() : patronName,
                                reader["user_id"].ToString(),
                                reader["role"].ToString(),
                                type,
                                categoryTitle,
                                cleanMessage
                            );
                        }
                    }
                }
            }
            return dt;
        }

        private void LoadSubmissions(string filter, string searchTerm = "")
        {
            List<SubmissionItem> submissions = new List<SubmissionItem>();
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                string sql = @"
                    SELECT us.user_id, us.type, us.message, us.created_at, u.role,
                           COALESCE(CONCAT(s.first_name, ' ', s.last_name), CONCAT(f.first_name, ' ', f.last_name), CONCAT(st.first_name, ' ', st.last_name)) AS patron_name
                    FROM User_Submissions us
                    INNER JOIN Users u ON us.user_id = u.user_id
                    LEFT JOIN Students s ON us.user_id = s.student_id
                    LEFT JOIN Faculty f ON us.user_id = f.faculty_id
                    LEFT JOIN Staff st ON us.user_id = st.staff_id
                    WHERE 1=1 ";
                if (filter == "feedback") sql += " AND us.type = 'Feedback' ";
                else if (filter == "request") sql += " AND us.type = 'Request' ";
                if (!string.IsNullOrEmpty(searchTerm))
                    sql += " AND (us.user_id LIKE @search OR patron_name LIKE @search) ";
                sql += " ORDER BY us.created_at DESC";

                using (MySqlCommand cmd = new MySqlCommand(sql, conn))
                {
                    if (!string.IsNullOrEmpty(searchTerm))
                        cmd.Parameters.AddWithValue("@search", "%" + searchTerm + "%");
                    conn.Open();
                    using (MySqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            string rawMessage = reader["message"].ToString();
                            DateTime createdAt = Convert.ToDateTime(reader["created_at"]);
                            string type = reader["type"].ToString();
                            string categoryTitle = type;
                            string cleanMessage = rawMessage;
                            if (rawMessage.StartsWith("[") && rawMessage.Contains("]"))
                            {
                                int endBracket = rawMessage.IndexOf("]");
                                categoryTitle = rawMessage.Substring(1, endBracket - 1);
                                cleanMessage = rawMessage.Substring(endBracket + 1).Trim();
                            }
                            string rawName = reader["patron_name"]?.ToString();
                            string displayName = string.IsNullOrEmpty(rawName) ? reader["user_id"].ToString() : CultureInfo.CurrentCulture.TextInfo.ToTitleCase(rawName.ToLower());
                            submissions.Add(new SubmissionItem
                            {
                                UserId = reader["user_id"].ToString(),
                                PatronName = string.IsNullOrEmpty(rawName) ? "" : displayName,
                                DisplayName = displayName,
                                Role = reader["role"].ToString(),
                                Type = type,
                                CategoryTitle = categoryTitle,
                                CleanMessage = cleanMessage.Length > 100 ? cleanMessage.Substring(0, 100) + "..." : cleanMessage,
                                FormattedDate = createdAt.ToString("MMM dd, yyyy - hh:mm tt")
                            });
                        }
                    }
                }
            }
            rptSubmissions.DataSource = submissions;
            rptSubmissions.DataBind();
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