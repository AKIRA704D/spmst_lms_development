using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Staff.Accounts
{
    public partial class userFilter : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadInstitutes();
                RefreshDynamicFilters();
            }
        }

        protected void ddlRole_SelectedIndexChanged(object sender, EventArgs e)
        {
            LoadInstitutes();
            RefreshDynamicFilters();
        }

        protected void ddlInstitute_SelectedIndexChanged(object sender, EventArgs e)
        {
            RefreshDynamicFilters();
        }

        private void LoadInstitutes()
        {
            string role = ddlRole.SelectedValue;
            string sql = "";

            if (role == "Student")
                sql = "SELECT DISTINCT institute FROM Students WHERE institute IS NOT NULL AND institute != ''";
            else if (role == "Faculty")
                sql = "SELECT DISTINCT institute FROM Faculty WHERE institute IS NOT NULL AND institute != ''";
            else // All Patrons
                sql = "SELECT DISTINCT institute FROM Students WHERE institute IS NOT NULL AND institute != '' " +
                      "UNION SELECT DISTINCT institute FROM Faculty WHERE institute IS NOT NULL AND institute != ''";

            sql += " ORDER BY institute";

            DataTable dt = ExecuteQuery(sql);
            ddlInstitute.DataSource = dt;
            ddlInstitute.DataTextField = "institute";
            ddlInstitute.DataValueField = "institute";
            ddlInstitute.DataBind();

            ddlInstitute.Items.Insert(0, new ListItem("All Institutes", ""));
        }

        private void RefreshDynamicFilters()
        {
            string role = ddlRole.SelectedValue;
            string institute = ddlInstitute.SelectedValue;

            bool isStudent = (role == "Student");
            divProgram.Visible = isStudent;
            divYear.Visible = isStudent;

            if (isStudent && !string.IsNullOrEmpty(institute))
            {
                string sql = "SELECT DISTINCT course FROM Students WHERE institute = @inst AND course IS NOT NULL AND course != '' ORDER BY course";
                DataTable dt = ExecuteQueryWithParam(sql, "@inst", institute);

                ddlProgram.DataSource = dt;
                ddlProgram.DataTextField = "course";
                ddlProgram.DataValueField = "course";
                ddlProgram.DataBind();
                ddlProgram.Items.Insert(0, new ListItem("All Programs", ""));
            }
            else
            {
                ddlProgram.DataSource = null;
                ddlProgram.DataBind();
                ddlProgram.Items.Clear();
                ddlProgram.Items.Insert(0, new ListItem("All Programs", ""));
            }
        }

        protected void btnApply_Click(object sender, EventArgs e)
        {
            string role = ddlRole.SelectedValue;
            string inst = ddlInstitute.SelectedValue;
            string prog = divProgram.Visible ? ddlProgram.SelectedValue : "";
            string year = divYear.Visible ? ddlYear.SelectedValue : "";
            string stat = ddlStatus.SelectedValue;

            // Build query string parameters (escape single quotes)
            string queryParams = $"isFilter=1&role={Uri.EscapeDataString(role)}&inst={Uri.EscapeDataString(inst)}&prog={Uri.EscapeDataString(prog)}&year={Uri.EscapeDataString(year)}&stat={stat}";

            // Redirect parent page
            string script = $"window.parent.location.href = 'userAcc.aspx?{queryParams}';";
            ClientScript.RegisterStartupScript(GetType(), "ApplyFilters", script, true);
        }

        private DataTable ExecuteQuery(string sql)
        {
            DataTable dt = new DataTable();
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                using (MySqlCommand cmd = new MySqlCommand(sql, conn))
                {
                    conn.Open();
                    using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            return dt;
        }

        private DataTable ExecuteQueryWithParam(string sql, string paramName, string paramValue)
        {
            DataTable dt = new DataTable();
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                using (MySqlCommand cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue(paramName, paramValue);
                    conn.Open();
                    using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            return dt;
        }
    }
}