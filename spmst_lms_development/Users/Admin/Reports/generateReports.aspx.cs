using System;
using System.Configuration;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Users.Admin.Reports
{
    public partial class generateReports : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // NOTE: mirrors the session/auth pattern used elsewhere in the admin area
            // (see masterpages/admin.master, which reads spmst_lms_development.sessionHelper).
            // Verify this matches your actual login/session convention.
            if (Session["UserId"] == null)
            {
                Response.Redirect("~/Login/login.aspx");
                return;
            }

            string adminId = Convert.ToString(Session["UserId"]);
            string adminEmail = GetAdminEmail(adminId);

            litAdminName.Text = Server.HtmlEncode(spmst_lms_development.sessionHelper.FullName ?? "Admin");
            litAdminEmail.Text = Server.HtmlEncode(adminEmail ?? spmst_lms_development.sessionHelper.Email ?? "");
        }

        private string GetAdminEmail(string userId)
        {
            string email = "";
            using (var conn = GetConnection())
            using (var cmd = new MySqlCommand("SELECT email FROM users WHERE user_id = @uid", conn))
            {
                cmd.Parameters.AddWithValue("@uid", userId);
                conn.Open();
                var result = cmd.ExecuteScalar();
                if (result != null)
                    email = result.ToString();
            }
            return email;
        }

        // NOTE: admin.master reads ConfigurationManager.ConnectionStrings["LmsDb"].
        // Prior project memory referenced the key "LmsDb" instead - please confirm
        // which key is actually present in Web.config and adjust if needed.
        internal static MySqlConnection GetConnection()
        {
            string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
            return new MySqlConnection(connStr);
        }
    }
}
