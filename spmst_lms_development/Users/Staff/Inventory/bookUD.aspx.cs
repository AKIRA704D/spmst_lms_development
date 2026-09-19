using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Text;
using System.Web.UI;

namespace spmst_lms_development.Users.Staff.Inventory
{
    public partial class bookUD : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private string originalData = "";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                string resId = Request.QueryString["ResourceId"];
                if (!string.IsNullOrEmpty(resId))
                {
                    litResID.Text = resId;
                    LoadBookDetails(resId);
                    CaptureOriginalData();
                }
                else
                {
                    // No ID – close modal
                    ShowSweetAlert("Error", "No resource ID provided.", "error");
                    BtnExit_Click(null, null);
                }
            }
        }

        private void CaptureOriginalData()
        {
            originalData = $"{txtTitle.Text}|{txtAuthors.Text}|{txtISBN.Text}|{txtEdition.Text}|{txtPublisher.Text}|{txtPages.Text}|{txtCopyright.Text}|{txtDescription.Text}";
        }

        private string GetChanges()
        {
            var changes = new StringBuilder();
            string[] orig = originalData.Split('|');

            if (txtTitle.Text != orig[0]) changes.Append($"Title: {orig[0]} → {txtTitle.Text}; ");
            if (txtAuthors.Text != orig[1]) changes.Append($"Author: {orig[1]} → {txtAuthors.Text}; ");
            if (txtISBN.Text != orig[2]) changes.Append($"ISBN: {orig[2]} → {txtISBN.Text}; ");
            if (txtEdition.Text != orig[3]) changes.Append($"Edition: {orig[3]} → {txtEdition.Text}; ");
            if (txtPublisher.Text != orig[4]) changes.Append($"Publisher: {orig[4]} → {txtPublisher.Text}; ");
            if (txtPages.Text != orig[5]) changes.Append($"Pages: {orig[5]} → {txtPages.Text}; ");
            if (txtCopyright.Text != orig[6]) changes.Append($"Copyright Year: {orig[6]} → {txtCopyright.Text}; ");
            if (txtDescription.Text != orig[7]) changes.Append($"Description: {(orig[7].Length > 50 ? orig[7].Substring(0, 50) + "..." : orig[7])} → {(txtDescription.Text.Length > 50 ? txtDescription.Text.Substring(0, 50) + "..." : txtDescription.Text)}; ");

            return changes.ToString().TrimEnd(' ', ';');
        }

        private void LoadBookDetails(string resId)
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                string query = "SELECT title, author, isbn, edition, publisher, pages_numeric, pub_year, description FROM Library_Resources WHERE resource_id = @resId";
                var cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@resId", resId);
                try
                {
                    conn.Open();
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            txtTitle.Text = reader["title"].ToString();
                            txtAuthors.Text = reader["author"].ToString();
                            txtISBN.Text = reader["isbn"].ToString();
                            txtEdition.Text = reader["edition"].ToString();
                            txtPublisher.Text = reader["publisher"].ToString();
                            txtPages.Text = reader["pages_numeric"].ToString();
                            txtCopyright.Text = reader["pub_year"].ToString();
                            txtDescription.Text = reader["description"].ToString();
                        }
                        else
                        {
                            ShowSweetAlert("Not Found", "Resource not found in database.", "error");
                            BtnExit_Click(null, null);
                        }
                    }
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Database Error", ex.Message, "error");
                }
            }
        }

        protected void BtnUpdate_Click(object sender, EventArgs e)
        {
            string resId = litResID.Text;
            string title = txtTitle.Text.Trim();
            string author = txtAuthors.Text.Trim();
            string isbn = txtISBN.Text.Trim();
            string edition = txtEdition.Text.Trim();
            string publisher = txtPublisher.Text.Trim();
            string pages = txtPages.Text.Trim();
            string year = txtCopyright.Text.Trim();
            string description = txtDescription.Text.Trim();

            using (var conn = new MySqlConnection(_connStr))
            {
                string query = @"UPDATE Library_Resources 
                                SET title = @title, author = @author, edition = @edition, 
                                    publisher = @publisher, pages_numeric = @pages, pub_year = @year, 
                                    description = @desc 
                                WHERE resource_id = @resId";
                var cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@title", title);
                cmd.Parameters.AddWithValue("@author", author);
                cmd.Parameters.AddWithValue("@edition", edition);
                cmd.Parameters.AddWithValue("@publisher", publisher);
                cmd.Parameters.AddWithValue("@pages", pages);
                cmd.Parameters.AddWithValue("@year", year);
                cmd.Parameters.AddWithValue("@desc", description);
                cmd.Parameters.AddWithValue("@resId", resId);

                try
                {
                    conn.Open();
                    int rowsAffected = cmd.ExecuteNonQuery();
                    if (rowsAffected > 0)
                    {
                        string changes = GetChanges();
                        string successScript = $@"
                            Swal.fire({{
                                title: 'Success!',
                                text: 'Book details updated successfully!',
                                icon: 'success',
                                timer: 2000,
                                showConfirmButton: false
                            }}).then(function() {{
                                window.parent.location.reload();
                            }});
                        ";
                        ClientScript.RegisterStartupScript(GetType(), "UpdateSuccess", successScript, true);
                    }
                    else
                    {
                        ShowSweetAlert("No Changes", "No changes were made or resource not found.", "warning");
                    }
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Update Failed", ex.Message, "error");
                }
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