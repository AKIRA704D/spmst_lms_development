using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.IO;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Staff.Inventory
{
    public partial class bookInventory : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadStats();
                LoadInventory();
            }
        }

        protected void Filter_Changed(object sender, EventArgs e)
        {
            LoadInventory();
        }

        private void LoadStats()
        {
            try
            {
                using (var conn = new MySqlConnection(_connStr))
                {
                    string statsQuery = @"
                        SELECT 
                            (SELECT COUNT(*) FROM item_copies) as GrandTotal,
                            (SELECT COUNT(*) FROM item_copies WHERE is_available = 1) as TotalAvailable,
                            (SELECT COUNT(*) FROM item_copies WHERE status_condition = 'Damage') as TotalDamaged,
                            (SELECT COUNT(*) FROM item_copies WHERE status_condition = 'Lost') as TotalLost";
                    var cmd = new MySqlCommand(statsQuery, conn);
                    conn.Open();
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            litTotalBooks.Text = reader["GrandTotal"].ToString();
                            litAvailable.Text = reader["TotalAvailable"].ToString();
                            litDamage.Text = reader["TotalDamaged"].ToString();
                            litLost.Text = reader["TotalLost"].ToString();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Error", "Failed to load statistics: " + ex.Message, "error");
            }
        }

        private void LoadInventory()
        {
            string search = txtSearch.Text.Trim();
            string filterSection = Request.QueryString["section"];
            string dateFrom = Request.QueryString["from"];
            string dateTo = Request.QueryString["to"];

            using (var conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT r.*, 
                           COUNT(c.accession_number) as TotalCopies,
                           SUM(CASE WHEN c.is_available = 1 THEN 1 ELSE 0 END) as AvailableCopies
                    FROM Library_Resources r
                    LEFT JOIN Item_Copies c ON r.resource_id = c.resource_id
                    WHERE (r.title LIKE @search OR r.author LIKE @search OR r.isbn LIKE @search)";

                if (!string.IsNullOrEmpty(filterSection))
                    query += " AND r.section = @section";
                if (!string.IsNullOrEmpty(dateFrom) && !string.IsNullOrEmpty(dateTo))
                    query += " AND DATE(c.created_at) BETWEEN @df AND @dt";

                query += " GROUP BY r.resource_id ORDER BY r.title ASC";

                var cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@search", "%" + search + "%");
                cmd.Parameters.AddWithValue("@section", filterSection ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("@df", dateFrom ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("@dt", dateTo ?? (object)DBNull.Value);

                var dt = new DataTable();
                new MySqlDataAdapter(cmd).Fill(dt);
                rptInventory.DataSource = dt;
                rptInventory.DataBind();

                lblNoData.Visible = dt.Rows.Count == 0;
            }
        }

        protected void rptInventory_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                var row = (DataRowView)e.Item.DataItem;
                string resourceId = row["resource_id"].ToString();

                Image imgCover = (Image)e.Item.FindControl("imgCover");
                if (imgCover != null)
                {
                    string path = row["cover_path"]?.ToString();
                    if (!string.IsNullOrEmpty(path) && File.Exists(Server.MapPath("~/" + path)))
                    {
                        imgCover.ImageUrl = "~/" + path;
                        imgCover.Visible = true;
                    }
                    else
                    {
                        imgCover.Visible = false;
                    }
                }

                Repeater rptCopies = (Repeater)e.Item.FindControl("rptCopies");
                if (rptCopies != null)
                {
                    using (var conn = new MySqlConnection(_connStr))
                    {
                        string copyQuery = "SELECT accession_number, is_available, status_condition FROM Item_Copies WHERE resource_id = @resId";
                        var cmd = new MySqlCommand(copyQuery, conn);
                        cmd.Parameters.AddWithValue("@resId", resourceId);
                        var dtCopies = new DataTable();
                        new MySqlDataAdapter(cmd).Fill(dtCopies);
                        rptCopies.DataSource = dtCopies;
                        rptCopies.DataBind();
                    }
                }
            }
        }

        protected void btnRefreshTable_Click(object sender, EventArgs e)
        {
            LoadStats();
            LoadInventory();
            ShowSweetAlert("Refreshed", "Inventory data has been refreshed.", "success");
        }

        // ===== bookInventory.aspx.cs — add these members to the class =====

        /// <summary>
        /// Permanently deletes the selected resource together with all of its copies.
        /// </summary>
        protected void btnDeleteResource_Click(object sender, EventArgs e)
        {
            int resourceId;
            if (!int.TryParse(hfDeleteResourceId.Value, out resourceId) || resourceId <= 0)
            {
                ShowSweetAlert("Invalid Resource", "The selected resource could not be identified.", "error");
                return;
            }

            string coverPath = null;

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                {
                    conn.Open();

                    // 1. Verify the resource exists and grab its cover path (needed for file cleanup).
                    using (var cmd = new MySqlCommand(
                        "SELECT cover_path FROM Library_Resources WHERE resource_id = @resId", conn))
                    {
                        cmd.Parameters.AddWithValue("@resId", resourceId);
                        object result = cmd.ExecuteScalar();

                        if (result == null)
                        {
                            LoadStats();
                            LoadInventory();
                            ShowSweetAlert("Not Found", "This resource no longer exists in the inventory.", "warning");
                            return;
                        }

                        coverPath = result == DBNull.Value ? null : result.ToString();
                    }

                    // 2. Delete copies + resource inside a single transaction.
                    using (var tran = conn.BeginTransaction())
                    {
                        try
                        {
                            using (var cmd = new MySqlCommand(
                                "DELETE FROM Item_Copies WHERE resource_id = @resId", conn, tran))
                            {
                                cmd.Parameters.AddWithValue("@resId", resourceId);
                                cmd.ExecuteNonQuery();
                            }

                            using (var cmd = new MySqlCommand(
                                "DELETE FROM Library_Resources WHERE resource_id = @resId", conn, tran))
                            {
                                cmd.Parameters.AddWithValue("@resId", resourceId);
                                cmd.ExecuteNonQuery();
                            }

                            tran.Commit();
                        }
                        catch
                        {
                            tran.Rollback();
                            throw;
                        }
                    }
                }

                // 3. Remove the orphaned cover image (non-critical).
                DeleteCoverFile(coverPath);

                LoadStats();
                LoadInventory();
                ShowSweetAlert("Deleted", "The resource and all of its copies have been removed.", "success");
            }
            catch (MySqlException ex)
            {
                // 1451 = ER_ROW_IS_REFERENCED_2 (foreign key constraint on a circulation record)
                if (ex.Number == 1451)
                {
                    ShowSweetAlert("Cannot Delete",
                        "This resource is linked to existing circulation records (borrowings, reservations or fines). " +
                        "Archive or clear those records before deleting it.", "error");
                }
                else
                {
                    ShowSweetAlert("Error", "Failed to delete the resource: " + ex.Message, "error");
                }
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Error", "Failed to delete the resource: " + ex.Message, "error");
            }
            finally
            {
                hfDeleteResourceId.Value = string.Empty;
            }
        }

        /// <summary>
        /// Deletes the physical cover image for a resource, ignoring any I/O problems.
        /// </summary>
        private void DeleteCoverFile(string coverPath)
        {
            if (string.IsNullOrEmpty(coverPath)) return;

            try
            {
                string relative = coverPath.Replace("~/", string.Empty)
                                           .Replace("\\", "/")
                                           .TrimStart('/');
                string physical = Server.MapPath("~/" + relative);

                if (File.Exists(physical))
                {
                    File.Delete(physical);
                }
            }
            catch
            {
                // Cover cleanup is best-effort — never fail the delete because of it.
            }
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"Swal.fire({{ title: '{cleanTitle}', text: '{cleanMsg}', icon: '{icon}', confirmButtonColor: '#002447' }});";
            ScriptManager.RegisterStartupScript(this, GetType(), "alert", script, true);
        }
    }
}