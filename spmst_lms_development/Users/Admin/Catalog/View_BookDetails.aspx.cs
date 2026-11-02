using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.IO;

namespace spmst_lms_development.Users.Admin.Catalog
{
    public partial class View_BookDetails : System.Web.UI.Page
    {
        private readonly string connStr =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;

            string resourceId = Request.QueryString["ResourceID"];
            if (!string.IsNullOrEmpty(resourceId))
            {
                LoadBookData(resourceId);
            }
            else
            {
                litTitle.Text = "No book selected";
                litAccession.Text = "N/A";
                rptCopies.Visible = false;
                pnlNoCopies.Visible = true;
            }
        }

        private void LoadBookData(string id)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();

                // ---------- 1. Main resource ----------
                string resourceQuery = "SELECT * FROM Library_Resources WHERE resource_id = @id";
                using (MySqlCommand cmdRes = new MySqlCommand(resourceQuery, conn))
                {
                    cmdRes.Parameters.AddWithValue("@id", id);
                    using (MySqlDataReader dr = cmdRes.ExecuteReader())
                    {
                        if (!dr.Read())
                        {
                            litTitle.Text = "Book not found";
                            litAccession.Text = "N/A";
                            rptCopies.Visible = false;
                            pnlNoCopies.Visible = true;
                            return;
                        }

                        litTitle.Text = SafeString(dr["title"]);
                        litAuthor.Text = SafeString(dr["author"], "Unknown Author");
                        litISBN.Text = SafeString(dr["isbn"], "N/A");
                        litEdition.Text = SafeString(dr["edition"], "N/A");
                        litCallNum.Text = SafeString(dr["call_number"], "N/A");
                        litPublisher.Text = SafeString(dr["publisher"], "N/A");
                        litYear.Text = SafeString(dr["copyright_year"], "N/A");
                        litPages.Text = SafeString(dr["pages_numeric"], "N/A");
                        litDescription.Text = SafeString(dr["description"], "No description available.");

                        // Cover — normalize, validate via Server.MapPath, fall back
                        imgCover.ImageUrl = ResolveCoverUrl(dr["cover_path"] as string);
                    }
                }

                // ---------- 2. Copies with accurate availability ----------
                // Schema-aware: Item_Copies.status_condition ENUM('Good','Damage','Lost','Combination','Reserved')
                //               Transactions.status ENUM(... 'Borrowed','Renewal','Renewed', 'Reserved','Ready', ...)
                string copiesQuery = @"
                    SELECT
                        c.accession_number,
                        c.status_condition,
                        c.is_available,
                        CASE
                            WHEN c.status_condition IN ('Damage','Lost','Combination') THEN 'Not Available'
                            WHEN c.status_condition = 'Reserved' THEN 'Reserved'
                            WHEN c.is_available = 0 AND EXISTS (
                                SELECT 1 FROM Transactions t
                                WHERE t.accession_number = c.accession_number
                                  AND t.status IN ('Borrowed','Renewal','Renewed')
                            ) THEN 'Borrowed'
                            WHEN c.is_available = 0 AND EXISTS (
                                SELECT 1 FROM Transactions t
                                WHERE t.accession_number = c.accession_number
                                  AND t.status IN ('Reserved','Ready')
                            ) THEN 'Reserved'
                            WHEN c.is_available = 1 AND c.status_condition = 'Good' THEN 'Available'
                            ELSE 'Not Available'
                        END AS availability_reason
                    FROM Item_Copies c
                    WHERE c.resource_id = @id
                    ORDER BY c.accession_number";

                using (MySqlCommand cmdCopies = new MySqlCommand(copiesQuery, conn))
                {
                    cmdCopies.Parameters.AddWithValue("@id", id);
                    DataTable dtCopies = new DataTable();
                    using (MySqlDataAdapter da = new MySqlDataAdapter(cmdCopies))
                        da.Fill(dtCopies);

                    if (dtCopies.Rows.Count > 0)
                    {
                        rptCopies.DataSource = dtCopies;
                        rptCopies.DataBind();
                        rptCopies.Visible = true;
                        pnlNoCopies.Visible = false;

                        // Primary accession = first available copy (if any)
                        string primaryAcc = null;
                        foreach (DataRow row in dtCopies.Rows)
                        {
                            if (string.Equals(row["availability_reason"].ToString(),
                                              "Available", StringComparison.OrdinalIgnoreCase))
                            {
                                primaryAcc = row["accession_number"].ToString();
                                break;
                            }
                        }
                        litAccession.Text = primaryAcc ?? "Out of Stock";
                    }
                    else
                    {
                        rptCopies.Visible = false;
                        pnlNoCopies.Visible = true;
                        litAccession.Text = "Out of Stock";
                    }
                }
            }
        }

        /// <summary>
        /// Resolves a DB-stored cover path to a browser-safe application-relative URL.
        /// Falls back to ~/Assets/Covers/default-cover.jpg when path is null/empty,
        /// invalid, or when the physical file does not exist.
        /// Handles paths that may already contain a leading "~/" or "/" and backslashes.
        /// </summary>
        private string ResolveCoverUrl(string coverPath)
        {
            const string fallback = "~/Assets/Covers/default-cover.jpg";
            if (string.IsNullOrWhiteSpace(coverPath)) return fallback;

            // Normalize: strip leading ~ or /, convert backslashes
            string normalized = coverPath.Trim()
                                         .TrimStart('~', '/', '\\')
                                         .Replace("\\", "/");

            if (string.IsNullOrEmpty(normalized)) return fallback;

            try
            {
                string physical = Server.MapPath("~/" + normalized);
                if (File.Exists(physical))
                    return "~/" + normalized;
            }
            catch
            {
                // Ignore path resolution errors → use fallback
            }
            return fallback;
        }

        private static string SafeString(object value, string fallback = "")
        {
            if (value == null || value == DBNull.Value) return fallback;
            string s = value.ToString();
            return string.IsNullOrWhiteSpace(s) ? fallback : s;
        }

        // =============================================================
        // UI HELPERS — bound to Eval() so DB values drive presentation
        // =============================================================
        protected string GetCopyCardClass(object availabilityReasonObj)
        {
            string reason = availabilityReasonObj == null ? string.Empty : availabilityReasonObj.ToString();
            return string.Equals(reason, "Available", StringComparison.OrdinalIgnoreCase)
                ? "copy-card available"
                : "copy-card unavailable";
        }

        protected string GetStatusClass(object statusObj)
        {
            string status = statusObj == null ? string.Empty : statusObj.ToString().ToLowerInvariant();
            switch (status)
            {
                case "available": return "status-badge status-available";
                case "reserved": return "status-badge status-reserved";
                case "borrowed": return "status-badge status-borrowed";
                default: return "status-badge status-damaged";
            }
        }

        protected string GetConditionClass(object conditionObj)
        {
            string condition = conditionObj == null ? string.Empty : conditionObj.ToString().ToLowerInvariant();
            switch (condition)
            {
                case "good": return "condition-badge condition-good";
                case "damage":
                case "damaged": return "condition-badge condition-damaged";
                case "lost": return "condition-badge condition-lost";
                case "combination": return "condition-badge condition-lost";
                case "reserved": return "condition-badge condition-reserved";
                default: return "condition-badge condition-default";
            }
        }
    }
}