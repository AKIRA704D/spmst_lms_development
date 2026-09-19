using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.IO;
using System.Web.UI;

namespace spmst_lms_development.Users.Admin.Catalog
{
    public partial class Reserved_Book : System.Web.UI.Page
    {
        public int CurrentStep { get; set; } = 1;
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                string bookId = Request.QueryString["BookID"];
                if (!string.IsNullOrEmpty(bookId))
                {
                    LoadBookDetails(bookId);
                    UpdateProgressBar();
                }
            }
        }

        private void LoadBookDetails(string bookId)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();
                // Book details
                string bookQuery = "SELECT title, author, section, cover_path FROM Library_Resources WHERE resource_id = @id";
                MySqlCommand cmd = new MySqlCommand(bookQuery, conn);
                cmd.Parameters.AddWithValue("@id", bookId);
                using (MySqlDataReader dr = cmd.ExecuteReader())
                {
                    if (dr.Read())
                    {
                        litTitle.Text = dr["title"].ToString();
                        litAuthor.Text = dr["author"].ToString();
                        litSection.Text = dr["section"].ToString();

                        string coverPath = dr["cover_path"]?.ToString();
                        if (!string.IsNullOrEmpty(coverPath) && File.Exists(Server.MapPath("~/" + coverPath)))
                            imgCover.ImageUrl = "~/" + coverPath;
                        else
                            imgCover.ImageUrl = "~/Assets/Covers/default-cover.jpg";
                    }
                }

                // Available locations
                string locQuery = @"SELECT MIN(accession_number) as first_copy,
                                           CONCAT(campus, ' (', specific_location, ')') as display_text
                                    FROM Item_Copies
                                    WHERE resource_id = @id AND is_available = 1
                                    GROUP BY campus, specific_location";
                MySqlCommand cmdLoc = new MySqlCommand(locQuery, conn);
                cmdLoc.Parameters.AddWithValue("@id", bookId);
                DataTable dt = new DataTable();
                using (MySqlDataAdapter da = new MySqlDataAdapter(cmdLoc))
                    da.Fill(dt);
                rblLocations.DataSource = dt;
                rblLocations.DataTextField = "display_text";
                rblLocations.DataValueField = "first_copy";
                rblLocations.DataBind();
                if (rblLocations.Items.Count > 0) rblLocations.SelectedIndex = 0;
            }
        }

        protected void Next_Click(object sender, EventArgs e)
        {
            CurrentStep = 2;
            pnlStep1.Visible = false;
            pnlStep2.Visible = true;
            UpdateProgressBar();
            upReservation.Update();
        }

        protected void Back_Click(object sender, EventArgs e)
        {
            CurrentStep = 1;
            pnlStep1.Visible = true;
            pnlStep2.Visible = false;
            UpdateProgressBar();
            upReservation.Update();
        }

        protected void Confirm_Click(object sender, EventArgs e)
        {
            if (!chkTerms.Checked)
            {
                ShowSweetAlert("Terms Required", "Please agree to the pickup terms.", "warning");
                return;
            }
            if (string.IsNullOrEmpty(rblLocations.SelectedValue))
            {
                ShowSweetAlert("Location Required", "Please select a pickup location.", "warning");
                return;
            }

            string userId = Session["UserID"]?.ToString();
            string selectedAccession = rblLocations.SelectedValue;
            DateTime deadline = new DateTime(DateTime.Now.Year, DateTime.Now.Month, DateTime.Now.Day, 17, 0, 0);

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();
                using (MySqlTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        // Insert transaction
                        string ins = "INSERT INTO Transactions (user_id, accession_number, borrow_date, due_date, status) VALUES (@uid, @acc, @bd, @dd, 'Reserved')";
                        MySqlCommand cmd = new MySqlCommand(ins, conn, trans);
                        cmd.Parameters.AddWithValue("@uid", userId);
                        cmd.Parameters.AddWithValue("@acc", selectedAccession);
                        cmd.Parameters.AddWithValue("@bd", DateTime.Now);
                        cmd.Parameters.AddWithValue("@dd", deadline);
                        cmd.ExecuteNonQuery();

                        // Mark copy as unavailable
                        string upd = "UPDATE Item_Copies SET is_available = 0 WHERE accession_number = @acc";
                        MySqlCommand cmdUpd = new MySqlCommand(upd, conn, trans);
                        cmdUpd.Parameters.AddWithValue("@acc", selectedAccession);
                        cmdUpd.ExecuteNonQuery();

                        trans.Commit();

                        litDeadline.Text = "Today by 5:00 PM";
                        pnlStep2.Visible = false;
                        pnlStep3.Visible = true;
                        // phHeader.Visible = false; // REMOVED – no such control in Bootstrap version
                        upReservation.Update();
                    }
                    catch (Exception ex)
                    {
                        trans.Rollback();
                        ShowSweetAlert("Error", ex.Message, "error");
                    }
                }
            }
        }

        protected void Cancel_Click(object sender, EventArgs e)
        {
            string script = "window.parent.closeUniversalModal();";
            ScriptManager.RegisterStartupScript(this, GetType(), "Close", script, true);
        }

        private void UpdateProgressBar()
        {
            // Not used in Bootstrap version, kept for compatibility
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"Swal.fire({{ title: '{cleanTitle}', text: '{cleanMsg}', icon: '{icon}', confirmButtonColor: '#0d6efd' }});";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }
    }
}