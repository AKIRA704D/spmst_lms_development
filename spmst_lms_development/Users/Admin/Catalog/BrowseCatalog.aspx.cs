using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.IO;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Admin.Catalog
{
    public partial class BrowseCatalog : System.Web.UI.Page
    {
        private const string DefaultCover = "~/Assets/Covers/default-cover.jpg";

        private readonly string connStr =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadSections();
                LoadBooks();
            }
        }

        private void LoadSections()
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            using (MySqlCommand cmd = new MySqlCommand(
                @"SELECT DISTINCT section AS section_name
                  FROM Library_Resources
                  WHERE section IS NOT NULL AND section <> ''
                  ORDER BY section", conn))
            using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
            {
                DataTable dt = new DataTable();
                da.Fill(dt);
                rptSections.DataSource = dt;
                rptSections.DataBind();
            }
        }

        private void LoadBooks(string section = "", string search = "")
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                // Schema-aligned availability definition:
                //   "Available" copy = status_condition='Good' AND is_available=1
                string query = @"
                    SELECT
                        r.resource_id,
                        r.title,
                        r.author,
                        r.isbn,
                        r.call_number,
                        r.section,
                        r.cover_path,
                        COUNT(c.accession_number) AS total_copies,
                        SUM(CASE WHEN c.is_available = 1
                                  AND c.status_condition = 'Good'
                                 THEN 1 ELSE 0 END) AS available_copies,
                        CASE WHEN SUM(CASE WHEN c.is_available = 1
                                            AND c.status_condition = 'Good'
                                           THEN 1 ELSE 0 END) > 0
                             THEN 'Available'
                             ELSE 'On Hold'
                        END AS display_status
                    FROM Library_Resources r
                    LEFT JOIN Item_Copies c ON r.resource_id = c.resource_id
                    WHERE 1=1";

                if (!string.IsNullOrEmpty(section))
                    query += " AND r.section = @section";
                if (!string.IsNullOrEmpty(search))
                    query += " AND (r.title LIKE @search OR r.author LIKE @search OR r.isbn LIKE @search)";

                // MySQL strict-mode: every non-aggregated column must be in GROUP BY
                query += @" GROUP BY r.resource_id, r.title, r.author, r.isbn,
                                    r.call_number, r.section, r.cover_path
                            ORDER BY r.title";

                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    if (!string.IsNullOrEmpty(section))
                        cmd.Parameters.AddWithValue("@section", section);
                    if (!string.IsNullOrEmpty(search))
                        cmd.Parameters.AddWithValue("@search", "%" + search + "%");

                    DataTable dt = new DataTable();
                    using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                        da.Fill(dt);

                    rptBooks.DataSource = dt;
                    rptBooks.DataBind();
                    pnlNoResults.Visible = (dt.Rows.Count == 0);
                }
            }
        }

        protected void txtSearch_TextChanged(object sender, EventArgs e)
        {
            string currentCategory = ViewState["SelectedCategory"]?.ToString() ?? "";
            LoadBooks(currentCategory, txtSearch.Text.Trim());
        }

        protected void rptBooks_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item &&
                e.Item.ItemType != ListItemType.AlternatingItem)
                return;

            DataRowView row = (DataRowView)e.Item.DataItem;
            Image imgCover = (Image)e.Item.FindControl("imgCover");
            if (imgCover == null) return;

            string coverPath = row["cover_path"] as string;

            // Server-side validation + fallback
            imgCover.ImageUrl = ResolveCoverUrl(coverPath);

            // Client-side fallback for images that exist but fail to load
            string fallback = ResolveUrl(DefaultCover);
            imgCover.Attributes["onerror"] =
                "this.onerror=null;this.src='" + fallback + "';";
        }

        /// <summary>
        /// Resolves a stored cover_path to a valid app-relative URL.
        /// Handles: empty/null, missing files, filenames without folders,
        /// leading ~ / ~/ /, path traversal, and invalid paths.
        /// Returns ~/Assets/Covers/default-cover.jpg on any failure.
        /// </summary>
        private string ResolveCoverUrl(string coverPath)
        {
            if (string.IsNullOrWhiteSpace(coverPath))
                return DefaultCover;

            string path = coverPath.Trim().Replace("\\", "/");

            // Strip leading ~/, ~, or /
            if (path.StartsWith("~/")) path = path.Substring(2);
            else if (path.StartsWith("~")) path = path.Substring(1);
            else if (path.StartsWith("/")) path = path.Substring(1);

            // If only a bare filename is stored, place it under Covers
            if (!path.Contains("/"))
                path = "Assets/Covers/" + path;

            // Block path traversal
            if (path.Contains(".."))
                return DefaultCover;

            try
            {
                string physical = Server.MapPath("~/" + path);
                if (!string.IsNullOrEmpty(physical) && File.Exists(physical))
                    return "~/" + path;
            }
            catch
            {
                // Invalid path (bad characters, mapped path failure, etc.)
            }

            return DefaultCover;
        }

        protected void Category_Click(object sender, EventArgs e)
        {
            LinkButton btn = (LinkButton)sender;
            string selectedCategory = btn.CommandArgument;
            ViewState["SelectedCategory"] = selectedCategory;

            lnkAll.CssClass = string.IsNullOrEmpty(selectedCategory)
                ? "category-pill active"
                : "category-pill inactive";

            foreach (RepeaterItem item in rptSections.Items)
            {
                LinkButton lb = (LinkButton)item.FindControl("lnkSection");
                if (lb != null)
                {
                    lb.CssClass = (lb.CommandArgument == selectedCategory)
                        ? "category-pill active"
                        : "category-pill inactive";
                }
            }

            LoadBooks(selectedCategory, txtSearch.Text.Trim());
        }
    }
}