using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.UI.WebControls;
using CsvHelper;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Users.Staff.Inventory
{
    public partial class bookImport : System.Web.UI.Page
    {
        // ------------------------------------------------------------------
        // Constants
        // ------------------------------------------------------------------

        private static readonly HashSet<string> ValidStatusConditions =
            new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "Good", "Damage", "Lost", "Reserved" };

        // Resource-level columns (mapped 1:1 to Library_Resources columns).
        private static readonly string[] ResourceFields = new[]
        {
            "item_type","isbn","issn","call_number","dewey_decimal","genre","title","author",
            "section","publisher","place_of_publication","series","edition","pub_year",
            "copyright_year","pages_numeric","height_cm","width_cm","accompanying_material",
            "description","cover_path"
        };

        // ------------------------------------------------------------------
        // Page events
        // ------------------------------------------------------------------

        protected void Page_Load(object sender, EventArgs e) { }

        protected void btnImport_Click(object sender, EventArgs e)
        {
            alertPlaceholder.InnerHtml = "";
            pnlResults.Visible = false;

            // 1. Validate upload -------------------------------------------------
            if (!fuCSVImport.HasFile)
            {
                ShowAlert("warning", "No File Selected", "Please select a CSV file.");
                return;
            }
            string extension = Path.GetExtension(fuCSVImport.FileName);
            if (!extension.Equals(".csv", StringComparison.OrdinalIgnoreCase))
            {
                ShowAlert("danger", "Invalid File", "Only CSV files are allowed.");
                return;
            }

            // 2. Parse CSV -------------------------------------------------------
            List<Dictionary<string, string>> rows;
            try
            {
                rows = ParseCsv(fuCSVImport.PostedFile.InputStream);
            }
            catch (Exception ex)
            {
                ShowAlert("danger", "Could Not Read File", "The CSV file could not be parsed: " + ex.Message);
                return;
            }
            if (rows.Count == 0)
            {
                ShowAlert("warning", "Empty File", "No data rows found.");
                return;
            }

            // 3. Group rows into resource groups ---------------------------------
            List<ResourceGroup> groups = GroupRows(rows);

            // 4. Counters --------------------------------------------------------
            int resourcesCreated = 0;
            int resourcesReused = 0;
            int copiesImported = 0;
            int copiesSkipped = 0;
            int errors = 0;
            int totalCopies = rows.Count;

            DataTable resultsTable = BuildResultsTable();

            string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

            using (var conn = new MySqlConnection(connStr))
            {
                conn.Open();

                foreach (var group in groups)
                {
                    var groupPlans = new List<CopyPlan>();
                    int gImported = 0, gSkipped = 0, gErrors = 0;
                    bool gCreated = false, gReused = false;

                    string groupTitle = GetValue(group.ResourceData, "title");

                    // A resource group with no resolvable title cannot be imported at all.
                    if (string.IsNullOrEmpty(groupTitle))
                    {
                        foreach (var row in group.Rows)
                        {
                            groupPlans.Add(new CopyPlan
                            {
                                Row = row,
                                AccessionNumber = LongCodeHandler.Normalize(GetValue(row, "barcode")),
                                Status = "Error - missing title for resource group"
                            });
                            gErrors++;
                        }
                    }
                    else
                    {
                        try
                        {
                            using (var tx = conn.BeginTransaction())
                            {
                                bool created;
                                int resourceId = FindOrCreateResource(conn, tx, group, out created);

                                int nextCopyNumber = -1; // lazily resolved

                                foreach (var row in group.Rows)
                                {
                                    var plan = new CopyPlan { Row = row, ResourceId = resourceId };
                                    groupPlans.Add(plan);

                                    string barcode = LongCodeHandler.Normalize(GetValue(row, "barcode"));

                                    // Auto-generate when barcode column is empty.
                                    if (string.IsNullOrEmpty(barcode))
                                    {
                                        if (nextCopyNumber < 0)
                                            nextCopyNumber = GetNextCopyNumber(conn, tx, group, resourceId);

                                        try
                                        {
                                            barcode = LongCodeHandler.Generate(
                                                group.ResourceKey, resourceId, nextCopyNumber);
                                            nextCopyNumber++;
                                        }
                                        catch (Exception genEx)
                                        {
                                            plan.Status = "Error - " + genEx.Message;
                                            gErrors++;
                                            continue;
                                        }
                                    }

                                    plan.AccessionNumber = barcode;

                                    if (!LongCodeHandler.IsValidLength(barcode))
                                    {
                                        plan.Status = "Error - accession number exceeds "
                                                     + LongCodeHandler.MaxLength + " characters";
                                        gErrors++;
                                        continue;
                                    }

                                    if (AccessionExists(conn, tx, barcode))
                                    {
                                        plan.Status = "Skipped - duplicate accession number";
                                        gSkipped++;
                                        continue;
                                    }

                                    InsertItemCopy(conn, tx, row, resourceId, barcode);
                                    plan.Status = "Imported";
                                    gImported++;
                                }

                                // Commit rule:
                                //  - We inserted >= 1 copy  -> commit.
                                //  - We reused an existing resource (nothing created) -> commit.
                                //  - We created a resource but inserted 0 copies -> rollback (avoid orphan).
                                if (gImported > 0 || !created)
                                {
                                    tx.Commit();
                                    gCreated = created;
                                    gReused = !created;
                                }
                                else
                                {
                                    tx.Rollback();
                                    foreach (var plan in groupPlans)
                                    {
                                        if (plan.Status == "Imported")
                                            plan.Status = "Error - resource orphaned (no copies inserted)";
                                        plan.ResourceId = 0;
                                    }
                                    gImported = 0;
                                    gErrors++;
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            // Rollback happened automatically when the using scope exited
                            // without a commit.
                            gCreated = false;
                            gReused = false;
                            gImported = 0;
                            gErrors++;

                            foreach (var plan in groupPlans)
                            {
                                if (string.IsNullOrEmpty(plan.Status) || plan.Status == "Imported")
                                    plan.Status = "Error - " + ex.Message;
                                plan.ResourceId = 0;
                            }
                        }
                    }

                    // Attach this group's copy plans to the results grid.
                    foreach (var plan in groupPlans)
                        AddResultRow(resultsTable, plan, group);

                    if (gCreated) resourcesCreated++;
                    if (gReused) resourcesReused++;
                    copiesImported += gImported;
                    copiesSkipped += gSkipped;
                    errors += gErrors;
                }
            }

            // 5. Bind results ---------------------------------------------------
            gvResults.DataSource = resultsTable;
            gvResults.DataBind();

            lblImportSummary.Text = string.Format(
                "Rows: {0}  ·  Resources: {1} created / {2} reused  ·  Copies: {3} imported / {4} skipped  ·  Errors: {5}",
                totalCopies, resourcesCreated, resourcesReused, copiesImported, copiesSkipped, errors);

            int percent = totalCopies > 0
                ? (int)Math.Round(copiesImported * 100.0 / totalCopies)
                : 0;
            string barColor = (errors == 0 && copiesSkipped == 0) ? "bg-success"
                            : copiesImported == 0 ? "bg-danger"
                                                                  : "bg-warning";
            litProgressBar.Text = string.Format(
                "<div class='progress-bar {0}' role='progressbar' style='width: {1}%;' aria-valuenow='{1}' aria-valuemin='0' aria-valuemax='100'></div>",
                barColor, percent);

            pnlResults.Visible = true;

            if (errors == 0 && copiesSkipped == 0)
                ShowAlert("success", "Import Complete",
                    string.Format("Created {0} resource(s), reused {1}, imported {2} copies.",
                        resourcesCreated, resourcesReused, copiesImported));
            else if (copiesImported == 0)
                ShowAlert("danger", "Import Failed",
                    string.Format("No copies were imported. {0} error(s), {1} skipped.", errors, copiesSkipped));
            else
                ShowAlert("warning", "Import Finished With Issues",
                    string.Format("Imported {0} copies. {1} skipped, {2} error(s).",
                        copiesImported, copiesSkipped, errors));
        }

        // ------------------------------------------------------------------
        // CSV parsing and grouping
        // ------------------------------------------------------------------

        private List<Dictionary<string, string>> ParseCsv(Stream stream)
        {
            var rows = new List<Dictionary<string, string>>();

            using (var reader = new StreamReader(stream))
            using (var csv = new CsvReader(reader, CultureInfo.InvariantCulture))
            {
                csv.Read();
                csv.ReadHeader();

                if (csv.HeaderRecord == null || csv.HeaderRecord.Length == 0)
                    throw new Exception("CSV must have a header row with column names.");

                var headers = csv.HeaderRecord.ToList();
                while (csv.Read())
                {
                    var rowDict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                    foreach (var header in headers)
                    {
                        string value = csv.GetField(header)?.Trim() ?? "";
                        rowDict[header] = value;
                    }
                    rows.Add(rowDict);
                }
            }
            return rows;
        }

        /// <summary>
        /// Groups rows into resources using resource_key first, then
        /// isbn / issn / title+author+edition+pub_year as fallback.
        /// Also merges resource-level fields per group (first non-empty wins).
        /// </summary>
        private List<ResourceGroup> GroupRows(List<Dictionary<string, string>> rows)
        {
            var groups = new List<ResourceGroup>();
            var byKey = new Dictionary<string, ResourceGroup>(StringComparer.OrdinalIgnoreCase);

            foreach (var row in rows)
            {
                string rk = LongCodeHandler.Normalize(GetValue(row, "resource_key"));
                string key;
                bool isResourceKeyBased;

                if (!string.IsNullOrEmpty(rk))
                {
                    key = "RK:" + rk.ToUpperInvariant();
                    isResourceKeyBased = true;
                }
                else
                {
                    key = BuildFallbackKey(row);
                    isResourceKeyBased = false;
                }

                ResourceGroup g;
                if (!byKey.TryGetValue(key, out g))
                {
                    g = new ResourceGroup
                    {
                        GroupKey = key,
                        IsResourceKeyBased = isResourceKeyBased,
                        ResourceKey = rk
                    };
                    groups.Add(g);
                    byKey[key] = g;
                }
                g.Rows.Add(row);
            }

            foreach (var g in groups)
                g.ResourceData = MergeResourceData(g.Rows);

            return groups;
        }

        private string BuildFallbackKey(Dictionary<string, string> row)
        {
            string isbn = LongCodeHandler.Normalize(GetValue(row, "isbn"));
            if (!string.IsNullOrEmpty(isbn)) return "ISBN:" + isbn.ToLowerInvariant();

            string issn = LongCodeHandler.Normalize(GetValue(row, "issn"));
            if (!string.IsNullOrEmpty(issn)) return "ISSN:" + issn.ToLowerInvariant();

            string title = LongCodeHandler.Normalize(GetValue(row, "title")).ToLowerInvariant();
            string author = LongCodeHandler.Normalize(GetValue(row, "author")).ToLowerInvariant();
            string edition = LongCodeHandler.Normalize(GetValue(row, "edition")).ToLowerInvariant();
            string pubYear = LongCodeHandler.Normalize(GetValue(row, "pub_year")).ToLowerInvariant();

            return "TAEP:" + title + "|" + author + "|" + edition + "|" + pubYear;
        }

        /// <summary>
        /// First non-empty value wins per resource field (bibliographic inheritance).
        /// </summary>
        private Dictionary<string, string> MergeResourceData(List<Dictionary<string, string>> rows)
        {
            var merged = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (var field in ResourceFields)
            {
                string chosen = "";
                foreach (var r in rows)
                {
                    string v = GetValue(r, field);
                    if (!string.IsNullOrEmpty(v)) { chosen = v; break; }
                }
                merged[field] = chosen;
            }
            return merged;
        }

        // ------------------------------------------------------------------
        // Resource existence / creation
        // ------------------------------------------------------------------

        private int FindOrCreateResource(MySqlConnection conn, MySqlTransaction tx,
                                         ResourceGroup group, out bool created)
        {
            int? existing = FindExistingResource(conn, tx, group.ResourceData);
            if (existing.HasValue)
            {
                created = false;
                return existing.Value;
            }

            created = true;
            return InsertLibraryResource(conn, tx, group.ResourceData);
        }

        /// <summary>
        /// Priority: isbn  ->  issn  ->  title + author + edition + pub_year.
        /// Title alone is never used as an identity (requirement 21).
        /// </summary>
        private int? FindExistingResource(MySqlConnection conn, MySqlTransaction tx,
                                          Dictionary<string, string> data)
        {
            // ISBN
            string isbn = LongCodeHandler.Normalize(GetValue(data, "isbn"));
            if (!string.IsNullOrEmpty(isbn))
            {
                using (var cmd = new MySqlCommand(
                    "SELECT resource_id FROM Library_Resources WHERE LOWER(TRIM(isbn)) = @v LIMIT 1", conn, tx))
                {
                    cmd.Parameters.AddWithValue("@v", isbn.ToLowerInvariant());
                    var r = cmd.ExecuteScalar();
                    if (r != null && r != DBNull.Value) return Convert.ToInt32(r);
                }
            }

            // ISSN
            string issn = LongCodeHandler.Normalize(GetValue(data, "issn"));
            if (!string.IsNullOrEmpty(issn))
            {
                using (var cmd = new MySqlCommand(
                    "SELECT resource_id FROM Library_Resources WHERE LOWER(TRIM(issn)) = @v LIMIT 1", conn, tx))
                {
                    cmd.Parameters.AddWithValue("@v", issn.ToLowerInvariant());
                    var r = cmd.ExecuteScalar();
                    if (r != null && r != DBNull.Value) return Convert.ToInt32(r);
                }
            }

            // Title + Author + Edition + PubYear
            string title = LongCodeHandler.Normalize(GetValue(data, "title"));
            if (!string.IsNullOrEmpty(title))
            {
                string author = LongCodeHandler.Normalize(GetValue(data, "author")).ToLowerInvariant();
                string edition = LongCodeHandler.Normalize(GetValue(data, "edition")).ToLowerInvariant();
                string pubYearRaw = LongCodeHandler.Normalize(GetValue(data, "pub_year"));
                int pubYear = 0;
                if (!string.IsNullOrEmpty(pubYearRaw))
                    int.TryParse(pubYearRaw, NumberStyles.Integer, CultureInfo.InvariantCulture, out pubYear);

                const string sql = @"
                    SELECT resource_id
                    FROM Library_Resources
                    WHERE LOWER(TRIM(title))              = @title
                      AND LOWER(TRIM(IFNULL(author ,''))) = @author
                      AND LOWER(TRIM(IFNULL(edition,''))) = @edition
                      AND IFNULL(pub_year, 0)             = @pubYear
                    LIMIT 1";

                using (var cmd = new MySqlCommand(sql, conn, tx))
                {
                    cmd.Parameters.AddWithValue("@title", title.ToLowerInvariant());
                    cmd.Parameters.AddWithValue("@author", author);
                    cmd.Parameters.AddWithValue("@edition", edition);
                    cmd.Parameters.AddWithValue("@pubYear", pubYear);
                    var r = cmd.ExecuteScalar();
                    if (r != null && r != DBNull.Value) return Convert.ToInt32(r);
                }
            }

            return null;
        }

        private int InsertLibraryResource(MySqlConnection conn, MySqlTransaction tx,
                                          Dictionary<string, string> data)
        {
            const string sql = @"
                INSERT INTO Library_Resources
                    (item_type, isbn, issn, call_number, dewey_decimal, genre, title, author,
                     section, publisher, place_of_publication, series, edition, pub_year,
                     copyright_year, pages_numeric, height_cm, width_cm, accompanying_material,
                     description, cover_path)
                VALUES
                    (@item_type, @isbn, @issn, @call_number, @dewey_decimal, @genre, @title, @author,
                     @section, @publisher, @place_of_publication, @series, @edition, @pub_year,
                     @copyright_year, @pages_numeric, @height_cm, @width_cm, @accompanying_material,
                     @description, @cover_path);
                SELECT LAST_INSERT_ID();";

            using (var cmd = new MySqlCommand(sql, conn, tx))
            {
                AddParameter(cmd, "@item_type", data, "item_type");
                AddParameter(cmd, "@isbn", data, "isbn");
                AddParameter(cmd, "@issn", data, "issn");
                AddParameter(cmd, "@call_number", data, "call_number");
                AddParameter(cmd, "@dewey_decimal", data, "dewey_decimal");
                AddParameter(cmd, "@genre", data, "genre");
                AddParameter(cmd, "@title", data, "title", required: true);
                AddParameter(cmd, "@author", data, "author");
                AddParameter(cmd, "@section", data, "section");
                AddParameter(cmd, "@publisher", data, "publisher");
                AddParameter(cmd, "@place_of_publication", data, "place_of_publication");
                AddParameter(cmd, "@series", data, "series");
                AddParameter(cmd, "@edition", data, "edition");
                AddIntParameter(cmd, "@pub_year", data, "pub_year");
                AddIntParameter(cmd, "@copyright_year", data, "copyright_year");
                AddParameter(cmd, "@pages_numeric", data, "pages_numeric");
                AddDecimalParameter(cmd, "@height_cm", data, "height_cm");
                AddDecimalParameter(cmd, "@width_cm", data, "width_cm");
                AddParameter(cmd, "@accompanying_material", data, "accompanying_material");
                AddParameter(cmd, "@description", data, "description");
                AddParameter(cmd, "@cover_path", data, "cover_path");

                return Convert.ToInt32(cmd.ExecuteScalar());
            }
        }

        // ------------------------------------------------------------------
        // Item_Copies operations
        // ------------------------------------------------------------------

        private bool AccessionExists(MySqlConnection conn, MySqlTransaction tx, string accession)
        {
            using (var cmd = new MySqlCommand(
                "SELECT COUNT(*) FROM Item_Copies WHERE accession_number = @a", conn, tx))
            {
                cmd.Parameters.AddWithValue("@a", accession);
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        private void InsertItemCopy(MySqlConnection conn, MySqlTransaction tx,
                                    Dictionary<string, string> row, int resourceId, string accession)
        {
            const string sql = @"
                INSERT INTO Item_Copies
                    (accession_number, resource_id, volume_no, issue_no, binding_type,
                     campus, specific_location, status_condition, is_available, remarks)
                VALUES
                    (@accession_number, @resource_id, @volume_no, @issue_no, @binding_type,
                     @campus, @specific_location, @status_condition, @is_available, @remarks);";

            using (var cmd = new MySqlCommand(sql, conn, tx))
            {
                cmd.Parameters.AddWithValue("@accession_number", accession);
                cmd.Parameters.AddWithValue("@resource_id", resourceId);
                AddParameter(cmd, "@volume_no", row, "volume_no");
                AddParameter(cmd, "@issue_no", row, "issue_no");
                AddParameter(cmd, "@binding_type", row, "binding_type");

                string campus = GetValue(row, "campus");
                cmd.Parameters.AddWithValue("@campus",
                    string.IsNullOrEmpty(campus) ? (object)"Malita Campus" : campus);

                string specificLocation = GetValue(row, "specific_location");
                cmd.Parameters.AddWithValue("@specific_location",
                    string.IsNullOrEmpty(specificLocation) ? (object)"Circulation Desk" : specificLocation);

                string statusCondition = GetValue(row, "status_condition");
                cmd.Parameters.AddWithValue("@status_condition",
                    ValidStatusConditions.Contains(statusCondition) ? statusCondition : "Good");

                string isAvailableRaw = GetValue(row, "is_available");
                bool isAvailable = true;
                if (!string.IsNullOrEmpty(isAvailableRaw))
                {
                    isAvailable = isAvailableRaw == "1"
                        || isAvailableRaw.Equals("true", StringComparison.OrdinalIgnoreCase)
                        || isAvailableRaw.Equals("yes", StringComparison.OrdinalIgnoreCase);
                }
                cmd.Parameters.AddWithValue("@is_available", isAvailable ? 1 : 0);

                AddParameter(cmd, "@remarks", row, "remarks");

                cmd.ExecuteNonQuery();
            }
        }

        // ------------------------------------------------------------------
        // Accession auto-generation (deterministic, DB-aware)
        // ------------------------------------------------------------------

        /// <summary>
        /// Scans existing Item_Copies that look like '{prefix}-{digits}'
        /// and returns max(digits) + 1.  Never relies on CSV row count.
        /// </summary>
        private int GetNextCopyNumber(MySqlConnection conn, MySqlTransaction tx,
                                      ResourceGroup group, int resourceId)
        {
            string prefix = string.IsNullOrEmpty(group.ResourceKey)
                          ? ("LIB-" + resourceId)
                          : group.ResourceKey;

            // Regex ensures we only match '{prefix}-DIGITS' exactly
            // (so 'BK-0010-0001' is not confused with 'BK-001').
            var regex = new Regex("^" + Regex.Escape(prefix) + @"-(\d+)$",
                                  RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);

            int maxNum = 0;
            using (var cmd = new MySqlCommand(
                "SELECT accession_number FROM Item_Copies WHERE accession_number LIKE @p", conn, tx))
            {
                cmd.Parameters.AddWithValue("@p", prefix + "-%");
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        string acc = reader.GetString(0);
                        var m = regex.Match(acc);
                        if (m.Success)
                        {
                            int n;
                            if (int.TryParse(m.Groups[1].Value, NumberStyles.Integer,
                                             CultureInfo.InvariantCulture, out n) && n > maxNum)
                                maxNum = n;
                        }
                    }
                }
            }
            return maxNum + 1;
        }

        // ------------------------------------------------------------------
        // Results table helpers
        // ------------------------------------------------------------------

        private DataTable BuildResultsTable()
        {
            var t = new DataTable();
            t.Columns.Add("barcode", typeof(string));
            t.Columns.Add("resource", typeof(string));
            t.Columns.Add("title", typeof(string));
            t.Columns.Add("author", typeof(string));
            t.Columns.Add("item_type", typeof(string));
            t.Columns.Add("call_number", typeof(string));
            t.Columns.Add("status", typeof(string));
            return t;
        }

        private void AddResultRow(DataTable table, CopyPlan plan, ResourceGroup group)
        {
            var r = table.NewRow();
            r["barcode"] = plan.AccessionNumber ?? GetValue(plan.Row, "barcode");
            r["resource"] = plan.ResourceId > 0 ? plan.ResourceId.ToString(CultureInfo.InvariantCulture) : "-";
            r["title"] = GetValue(group.ResourceData, "title");
            r["author"] = GetValue(group.ResourceData, "author");
            r["item_type"] = GetValue(group.ResourceData, "item_type");
            r["call_number"] = GetValue(group.ResourceData, "call_number");
            r["status"] = plan.Status ?? "Pending";
            table.Rows.Add(r);
        }

        protected string GetStatusBadgeClass(string status)
        {
            if (string.IsNullOrEmpty(status)) return "bg-secondary";
            if (status.StartsWith("Imported", StringComparison.OrdinalIgnoreCase)) return "bg-success";
            if (status.StartsWith("Skipped", StringComparison.OrdinalIgnoreCase)) return "bg-warning text-dark";
            if (status.StartsWith("Error", StringComparison.OrdinalIgnoreCase)) return "bg-danger";
            return "bg-secondary";
        }

        // ------------------------------------------------------------------
        // Generic helpers
        // ------------------------------------------------------------------

        private string GetValue(Dictionary<string, string> row, string key)
        {
            string val;
            return row != null && row.TryGetValue(key, out val) ? (val ?? "") : "";
        }

        private void AddParameter(MySqlCommand cmd, string paramName,
                                  Dictionary<string, string> row, string column, bool required = false)
        {
            string val = GetValue(row, column);
            if (required && string.IsNullOrEmpty(val))
                throw new Exception("Required column '" + column + "' is missing or empty.");
            cmd.Parameters.AddWithValue(paramName, string.IsNullOrEmpty(val) ? (object)DBNull.Value : val);
        }

        private void AddIntParameter(MySqlCommand cmd, string paramName,
                                     Dictionary<string, string> row, string column)
        {
            string val = GetValue(row, column);
            if (string.IsNullOrEmpty(val))
            {
                cmd.Parameters.AddWithValue(paramName, DBNull.Value);
                return;
            }
            int n;
            if (int.TryParse(val, NumberStyles.Integer, CultureInfo.InvariantCulture, out n))
                cmd.Parameters.AddWithValue(paramName, n);
            else
                cmd.Parameters.AddWithValue(paramName, DBNull.Value);
        }

        private void AddDecimalParameter(MySqlCommand cmd, string paramName,
                                         Dictionary<string, string> row, string column)
        {
            string val = GetValue(row, column);
            if (string.IsNullOrEmpty(val))
            {
                cmd.Parameters.AddWithValue(paramName, DBNull.Value);
                return;
            }
            decimal d;
            if (decimal.TryParse(val, NumberStyles.Any, CultureInfo.InvariantCulture, out d))
                cmd.Parameters.AddWithValue(paramName, d);
            else
                cmd.Parameters.AddWithValue(paramName, DBNull.Value);
        }

        private void ShowAlert(string type, string title, string message)
        {
            string icon;
            if (type == "success") icon = "fa-check-circle";
            else if (type == "warning") icon = "fa-exclamation-triangle";
            else if (type == "danger") icon = "fa-times-circle";
            else icon = "fa-info-circle";

            alertPlaceholder.InnerHtml = string.Format(@"
                <div class='alert alert-{0} alert-dismissible fade show' role='alert'>
                    <i class='fas {1} me-2'></i>
                    <strong>{2}</strong> – {3}
                    <button type='button' class='btn-close' data-bs-dismiss='alert' aria-label='Close'></button>
                </div>", type, icon, title, message);
        }

        // ------------------------------------------------------------------
        // Nested types
        // ------------------------------------------------------------------

        private class ResourceGroup
        {
            public string GroupKey;
            public bool IsResourceKeyBased;
            public string ResourceKey;
            public List<Dictionary<string, string>> Rows = new List<Dictionary<string, string>>();
            public Dictionary<string, string> ResourceData; // merged, per-field first non-empty
        }

        private class CopyPlan
        {
            public Dictionary<string, string> Row;
            public string AccessionNumber;
            public int ResourceId;   // 0 = not yet assigned / rolled back
            public string Status;
        }
    }

    // ======================================================================
    // Reusable long-code handler
    // ======================================================================
    /// <summary>
    /// Central handler for accession / tracking codes.
    /// Preserves the full code, never truncates, never converts to int,
    /// and validates against the Item_Copies.accession_number VARCHAR(50) limit.
    /// </summary>
    internal static class LongCodeHandler
    {
        /// <summary>Item_Copies.accession_number is VARCHAR(50).</summary>
        public const int MaxLength = 50;

        /// <summary>
        /// Safely trims outer whitespace and collapses runs of internal
        /// whitespace to a single space. Empty / whitespace input -> string.Empty.
        /// </summary>
        public static string Normalize(string code)
        {
            if (string.IsNullOrWhiteSpace(code)) return string.Empty;
            return Regex.Replace(code.Trim(), @"\s+", " ");
        }

        /// <summary>
        /// Validates the code against the DB length limit. Does not modify.
        /// </summary>
        public static bool IsValidLength(string code)
        {
            return !string.IsNullOrEmpty(code) && code.Length <= MaxLength;
        }

        /// <summary>
        /// Deterministic code generator used only when the CSV does not
        /// supply an accession number.  Format: '{prefix}-NNNN' where prefix is
        /// the resource_key when present, otherwise 'LIB-{resourceId}'.
        /// Fails gracefully (throws) when the generated code would exceed
        /// MaxLength — never truncates.
        /// </summary>
        public static string Generate(string resourceKey, int resourceId, int copyNumber)
        {
            string prefix = string.IsNullOrEmpty(resourceKey)
                          ? ("LIB-" + resourceId)
                          : resourceKey.Trim();

            string code = prefix + "-" + copyNumber.ToString("D4", CultureInfo.InvariantCulture);

            if (code.Length > MaxLength)
                throw new InvalidOperationException(
                    "Generated accession code would exceed " + MaxLength +
                    " characters ('" + code + "'). Supply a shorter barcode or resource_key.");

            return code;
        }
    }
}