using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Staff.Inventory
{
    public partial class bookUS : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private string originalCondition = "";
        private string originalNotes = "";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                string resourceId = Request.QueryString["ResourceId"];
                if (!string.IsNullOrEmpty(resourceId))
                {
                    LoadBookTitle(resourceId);
                    LoadAccessionNumbers(resourceId);
                }
                else
                {
                    ShowSweetAlert("Error", "No resource ID provided.", "error");
                    BtnExit_Click(null, null);
                }
            }
        }

        private void LoadBookTitle(string resourceId)
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                string query = "SELECT title FROM Library_Resources WHERE resource_id = @id";
                var cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@id", resourceId);
                conn.Open();
                txtTitle.Text = cmd.ExecuteScalar()?.ToString();
            }
        }

        private void LoadAccessionNumbers(string resourceId)
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                string query = "SELECT accession_number FROM Item_Copies WHERE resource_id = @id";
                var cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@id", resourceId);
                conn.Open();

                ddlAccession.DataSource = cmd.ExecuteReader();
                ddlAccession.DataTextField = "accession_number";
                ddlAccession.DataValueField = "accession_number";
                ddlAccession.DataBind();
                ddlAccession.Items.Insert(0, new ListItem("Select a copy...", ""));
            }
        }

        protected void ddlAccession_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(ddlAccession.SelectedValue))
            {
                ddlCondition.SelectedIndex = 0;
                txtNotes.Text = "";
                originalCondition = "";
                originalNotes = "";
                return;
            }

            using (var conn = new MySqlConnection(_connStr))
            {
                string query = "SELECT status_condition, remarks FROM Item_Copies WHERE accession_number = @acc";
                var cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@acc", ddlAccession.SelectedValue);
                conn.Open();

                using (var reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        string dbCondition = reader["status_condition"]?.ToString();
                        string dbNotes = reader["remarks"]?.ToString();

                        if (ddlCondition.Items.FindByValue(dbCondition) != null)
                            ddlCondition.SelectedValue = dbCondition;
                        else
                            ddlCondition.SelectedIndex = 0;

                        txtNotes.Text = dbNotes;
                        originalCondition = dbCondition;
                        originalNotes = dbNotes;
                    }
                }
            }
        }

        protected void BtnUpdate_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(ddlAccession.SelectedValue))
            {
                ShowSweetAlert("Validation", "Please select an accession number first.", "warning");
                return;
            }

            string accession = ddlAccession.SelectedValue;
            string newCondition = ddlCondition.SelectedValue;
            string newNotes = txtNotes.Text.Trim();
            int isAvailable = (newCondition == "Good") ? 1 : 0;

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                {
                    string sql = @"UPDATE Item_Copies 
                                   SET status_condition = @cond, 
                                       remarks = @notes,
                                       is_available = @avail
                                   WHERE accession_number = @acc";
                    var cmd = new MySqlCommand(sql, conn);
                    cmd.Parameters.AddWithValue("@cond", newCondition);
                    cmd.Parameters.AddWithValue("@notes", newNotes);
                    cmd.Parameters.AddWithValue("@avail", isAvailable);
                    cmd.Parameters.AddWithValue("@acc", accession);
                    conn.Open();

                    int rowsAffected = cmd.ExecuteNonQuery();
                    if (rowsAffected > 0)
                    {
                        string successScript = @"
                            Swal.fire({
                                title: 'Success!',
                                text: 'Stock status updated successfully!',
                                icon: 'success',
                                timer: 2000,
                                showConfirmButton: false
                            }).then(function() {
                                window.parent.location.reload();
                            });";
                        ClientScript.RegisterStartupScript(GetType(), "UpdateSuccess", successScript, true);
                    }
                    else
                    {
                        ShowSweetAlert("No Changes", "No record found for this accession number.", "warning");
                    }
                }
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Database Error", ex.Message, "error");
            }
        }

        protected void BtnExit_Click(object sender, EventArgs e)
        {
            string script = "window.parent.closeUniversalModal();";
            ClientScript.RegisterStartupScript(GetType(), "CloseModal", script, true);
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"Swal.fire({{ title: '{cleanTitle}', text: '{cleanMsg}', icon: '{icon}', confirmButtonColor: '#002447' }});";
            ClientScript.RegisterStartupScript(GetType(), Guid.NewGuid().ToString(), script, true);
        }
    }
}