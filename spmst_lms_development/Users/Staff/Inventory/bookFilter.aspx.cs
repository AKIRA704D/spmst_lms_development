using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Web.UI.WebControls;
using System.Web.UI;

namespace spmst_lms_development.Users.Staff.Inventory
{
    public partial class bookFilter : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadSections();
            }
        }

        private void LoadSections()
        {
            using (var conn = new MySqlConnection(connStr))
            {
                string sql = "SELECT DISTINCT section FROM Library_Resources WHERE section IS NOT NULL AND section <> '' ORDER BY section ASC";
                var cmd = new MySqlCommand(sql, conn);
                try
                {
                    conn.Open();
                    ddlSection.DataSource = cmd.ExecuteReader();
                    ddlSection.DataTextField = "section";
                    ddlSection.DataValueField = "section";
                    ddlSection.DataBind();
                    ddlSection.Items.Insert(0, new ListItem("All Sections", ""));
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("Error loading sections: " + ex.Message);
                    // Optionally show SweetAlert (but this is server-side, would need client script)
                }
            }
        }

        protected void Apply_Click(object sender, EventArgs e)
        {
            string section = ddlSection.SelectedValue;
            string dateFrom = txtDateFrom.Text;
            string dateTo = txtDateTo.Text;

            // Build JavaScript to call parent page functions
            string script = $@"
                window.parent.applyBookFilters('{section}', '{dateFrom}', '{dateTo}');
                window.parent.closeUniversalModal();";
            ClientScript.RegisterStartupScript(GetType(), "ApplyFilter", script, true);
        }
    }
}