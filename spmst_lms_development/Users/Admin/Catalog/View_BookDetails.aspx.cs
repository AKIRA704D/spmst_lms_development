using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.IO;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Admin.Catalog
{
    public partial class View_BookDetails : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                string resourceId = Request.QueryString["ResourceID"];
                if (!string.IsNullOrEmpty(resourceId))
                    LoadBookData(resourceId);
            }
        }

        private void LoadBookData(string id)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();
                // Main resource
                string resourceQuery = "SELECT * FROM Library_Resources WHERE resource_id = @id";
                MySqlCommand cmdRes = new MySqlCommand(resourceQuery, conn);
                cmdRes.Parameters.AddWithValue("@id", id);
                using (MySqlDataReader dr = cmdRes.ExecuteReader())
                {
                    if (dr.Read())
                    {
                        litTitle.Text = dr["title"].ToString();
                        litAuthor.Text = dr["author"].ToString();
                        litISBN.Text = dr["isbn"].ToString();
                        litEdition.Text = dr["edition"] != DBNull.Value ? dr["edition"].ToString() : "N/A";
                        litCallNum.Text = dr["call_number"].ToString();
                        litPublisher.Text = dr["publisher"].ToString();
                        litYear.Text = dr["copyright_year"].ToString();
                        litPages.Text = dr["pages_numeric"].ToString();
                        litDescription.Text = !string.IsNullOrEmpty(dr["description"].ToString()) ? dr["description"].ToString() : "No description available.";

                        string coverPath = dr["cover_path"]?.ToString();
                        if (!string.IsNullOrEmpty(coverPath) && File.Exists(Server.MapPath("~/" + coverPath)))
                            imgCover.ImageUrl = "~/" + coverPath;
                        else
                            imgCover.ImageUrl = "~/Assets/Covers/default-cover.jpg";
                    }
                }

                // Copies with availability
                string copiesQuery = @"
                                        SELECT c.accession_number, c.status_condition, c.is_available,
                                               CASE 
                                                   WHEN c.status_condition IN ('Damage', 'Damaged', 'Lost') THEN 'Not Available'
                                                   WHEN c.status_condition = 'Good' THEN
                                                       CASE 
                                                           WHEN c.is_available = 1 THEN 'Available'
                                                           WHEN c.is_available = 0 THEN 
                                                               CASE 
                                                                   WHEN MAX(t.status) = 'Borrowed' THEN 'Borrowed'
                                                                   WHEN MAX(t.status) IN ('Reserved', 'Ready') THEN 'Reserved'
                                                                   ELSE 'Not Available'
                                                               END
                                                       END
                                                   ELSE 'Not Available'
                                               END AS availability_reason
                                        FROM Item_Copies c
                                        LEFT JOIN Transactions t ON c.accession_number = t.accession_number 
                                            AND t.status IN ('Borrowed', 'Reserved', 'Ready')
                                        WHERE c.resource_id = @id
                                        GROUP BY c.accession_number";
                MySqlCommand cmdCopies = new MySqlCommand(copiesQuery, conn);
                cmdCopies.Parameters.AddWithValue("@id", id);
                DataTable dtCopies = new DataTable();
                using (MySqlDataAdapter da = new MySqlDataAdapter(cmdCopies))
                    da.Fill(dtCopies);

                if (dtCopies.Rows.Count > 0)
                {
                    rptCopies.DataSource = dtCopies;
                    rptCopies.DataBind();
                    pnlNoCopies.Visible = false;

                    var available = dtCopies.AsEnumerable()
                        .FirstOrDefault(row => row["status_condition"].ToString().Equals("Good", StringComparison.OrdinalIgnoreCase)
                                             && Convert.ToInt32(row["is_available"]) == 1);
                    if (available != null)
                        litAccession.Text = available["accession_number"].ToString();
                    else
                        litAccession.Text = "Out of Stock";
                }
                else
                {
                    rptCopies.Visible = false;
                    pnlNoCopies.Visible = true;
                    litAccession.Text = "Out of Stock";
                }
            }
        }

        // ========== UI HELPER METHODS (called from .aspx) ==========
        protected string GetStatusClass(string status)
        {
            if (string.IsNullOrEmpty(status)) return "status-default";
            switch (status.ToLower())
            {
                case "available": return "status-available";
                case "reserved": return "status-reserved";
                case "borrowed": return "status-borrowed";
                default: return "status-damaged";
            }
        }

        protected string GetConditionClass(string condition)
        {
            if (string.IsNullOrEmpty(condition)) return "text-secondary fw-semibold";
            switch (condition.ToLower())
            {
                case "good": return "text-success fw-semibold";
                case "damage": case "damaged": return "text-warning fw-semibold";
                case "lost": return "text-danger fw-semibold";
                default: return "text-secondary fw-semibold";
            }
        }
    }
}