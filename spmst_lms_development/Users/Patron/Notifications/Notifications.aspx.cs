using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Patron.Notifications
{
    public partial class Notifications : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private string currentUserRole = "";
        private string currentUserId = "";

        protected void Page_Load(object sender, EventArgs e)
        {
            GetCurrentUserInfo();

            if (!IsPostBack)
            {
                LoadNotifications();
                SetActiveFilterButton("btnFilterAll");
            }
        }

        private void GetCurrentUserInfo()
        {
            currentUserId = Session["UserID"]?.ToString();

            if (!string.IsNullOrEmpty(currentUserId))
            {
                using (MySqlConnection conn = new MySqlConnection(connStr))
                {
                    conn.Open();
                    string query = "SELECT role FROM Users WHERE user_id = @userId";
                    MySqlCommand cmd = new MySqlCommand(query, conn);
                    cmd.Parameters.AddWithValue("@userId", currentUserId);
                    object result = cmd.ExecuteScalar();
                    if (result != null)
                        currentUserRole = result.ToString().ToLower();
                }
            }
        }

        private void LoadNotifications(string filter = "All")
        {
            if (string.IsNullOrEmpty(currentUserId))
            {
                pnlEmpty.Visible = true;
                return;
            }

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();
                string sql = BuildRoleBasedQuery();

                if (filter == "Due Date")
                    sql += " AND title LIKE '%Due%'";
                else if (filter == "Reservation")
                    sql += " AND (title LIKE '%Ready%' OR title LIKE '%Reserved%' OR title LIKE '%Reservation%')";

                sql += " ORDER BY created_at DESC";

                MySqlCommand cmd = new MySqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@userId", currentUserId);

                DataTable dt = new DataTable();
                using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                    da.Fill(dt);

                rptNotifications.DataSource = dt;
                rptNotifications.DataBind();
                pnlEmpty.Visible = (dt.Rows.Count == 0);
            }
        }

        private string BuildRoleBasedQuery()
        {
            string baseQuery = "SELECT * FROM Notifications WHERE ";

            switch (currentUserRole)
            {
                case "admin":
                    return baseQuery + "1=1";
                case "staff":
                    return baseQuery + @"(
                        user_id = @userId 
                        OR title LIKE '%Staff%'
                        OR title LIKE '%Circulation%'
                        OR title LIKE '%Library%'
                        OR title LIKE '%Operations%'
                    )";
                case "faculty":
                    return baseQuery + @"(
                        user_id = @userId 
                        OR title LIKE '%Faculty%'
                        OR title LIKE '%Department%'
                        OR title LIKE '%Research%'
                    )";
                case "student":
                default:
                    return baseQuery + @"(
                        user_id = @userId 
                        OR title LIKE '%Student%'
                        OR title LIKE '%Due%'
                        OR title LIKE '%Ready%'
                        OR title LIKE '%Reservation%'
                        OR title LIKE '%Borrow%'
                    )";
            }
        }

        protected void rptNotifications_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "View")
            {
                string notifId = e.CommandArgument.ToString();
                UpdateReadStatus(notifId);
                string currentFilter = ViewState["CurrentFilter"]?.ToString() ?? "All";
                LoadNotifications(currentFilter);
            }
        }

        private void UpdateReadStatus(string notifId)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                string sql = "UPDATE Notifications SET is_read = 1 WHERE notification_id = @id";
                MySqlCommand cmd = new MySqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@id", notifId);
                conn.Open();
                cmd.ExecuteNonQuery();
            }
        }

        protected void MarkAllRead_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(currentUserId))
                return;

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();
                string filterCondition = BuildRoleBasedQuery().Replace("SELECT * FROM Notifications WHERE ", "");
                string sql = $"UPDATE Notifications SET is_read = 1 WHERE {filterCondition}";
                MySqlCommand cmd = new MySqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@userId", currentUserId);
                int rowsAffected = cmd.ExecuteNonQuery();
                ShowSweetAlert("Success", $"{rowsAffected} notification(s) marked as read.", "success");
            }

            string currentFilter = ViewState["CurrentFilter"]?.ToString() ?? "All";
            LoadNotifications(currentFilter);
        }

        protected void Filter_Click(object sender, EventArgs e)
        {
            LinkButton clickedButton = (LinkButton)sender;
            string category = clickedButton.CommandArgument;
            ViewState["CurrentFilter"] = category;
            SetActiveFilterButton(clickedButton.ClientID);
            LoadNotifications(category);
        }

        private void SetActiveFilterButton(string activeClientId)
        {
            // Server-side: we set CSS classes manually - but we also rely on client-side JS after postback
            btnFilterAll.CssClass = "filter-pill";
            btnFilterDue.CssClass = "filter-pill";
            btnFilterRes.CssClass = "filter-pill";

            if (activeClientId.Contains("FilterAll"))
                btnFilterAll.CssClass = "filter-pill active";
            else if (activeClientId.Contains("FilterDue"))
                btnFilterDue.CssClass = "filter-pill active";
            else if (activeClientId.Contains("FilterRes"))
                btnFilterRes.CssClass = "filter-pill active";
            else
                btnFilterAll.CssClass = "filter-pill active";
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"showSweetAlert('{cleanTitle}', '{cleanMsg}', '{icon}');";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }

        // ========== UI HELPER METHODS ==========
        protected string GetBadgeClass(string title)
        {
            if (title.Contains("Due"))
                return "badge-danger";
            else if (title.Contains("Ready"))
                return "badge-success";
            else
                return "badge-info";
        }

        protected string GetIconBackground(string title)
        {
            if (title.Contains("Due"))
                return "notif-icon-danger";
            else if (title.Contains("Ready"))
                return "notif-icon-success";
            else
                return "notif-icon-info";
        }

        protected string GetIconClass(string title)
        {
            if (title.Contains("Due"))
                return "fas fa-calendar-times";
            else if (title.Contains("Ready"))
                return "fas fa-book-reader";
            else
                return "fas fa-bullhorn";
        }

        protected string GetRelativeTime(object date)
        {
            try
            {
                DateTime dt = Convert.ToDateTime(date);
                TimeSpan ts = DateTime.Now - dt;

                if (ts.TotalDays > 30)
                    return $"{(int)(ts.TotalDays / 30)} months ago";
                if (ts.TotalDays > 1)
                    return $"{(int)ts.TotalDays} days ago";
                if (ts.TotalHours > 1)
                    return $"{(int)ts.TotalHours} hours ago";
                if (ts.TotalMinutes > 1)
                    return $"{(int)ts.TotalMinutes} minutes ago";
                return "Just now";
            }
            catch
            {
                return "Recently";
            }
        }
    }
}