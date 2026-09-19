using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Web.UI.WebControls;
using CsvHelper;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Users.Staff.Inventory
{
    public partial class bookImport : System.Web.UI.Page
    {
        // Valid values for item_copies.status_condition (matches the DB enum).
        private static readonly HashSet<string> ValidStatusConditions =
            new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "Good", "Damage", "Lost", "Reserved" };

        protected void Page_Load(object sender, EventArgs e)
        {
        }

        protected void btnImport_Click(object sender, EventArgs e)
        {
            alertPlaceholder.InnerHtml = "";
            pnlResults.Visible = false;

            // 1. Validate file upload
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

            // 2. Read CSV data
            List<Dictionary<string, string>> rows = new List<Dictionary<string, string>>();

            try
            {
                using (var reader = new StreamReader(fuCSVImport.PostedFile.InputStream))
                using (var csv = new CsvReader(reader, CultureInfo.InvariantCulture))
                {
                    csv.Read();
                    csv.ReadHeader();
                    if (csv.HeaderRecord != null && csv.HeaderRecord.Length > 0)
                    {
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
                    else
                    {
                        ShowAlert("warning", "No Header", "CSV must have a header row with column names.");
                        return;
                    }
                }
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

            // 3. Import row by row, each in its own transaction so one bad row
            //    doesn't abort the whole batch.
            int totalRows = rows.Count;
            int successCount = 0;
            DataTable resultsTable = BuildResultsTable();

            string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();

                foreach (var row in rows)
                {
                    string barcode = GetValue(row, "barcode");
                    string title = GetValue(row, "title");
                    string author = GetValue(row, "author");
                    string itemType = GetValue(row, "item_type");
                    string callNumber = GetValue(row, "call_number");

                    DataRow resultRow = resultsTable.NewRow();
                    resultRow["barcode"] = barcode;
                    resultRow["title"] = title;
                    resultRow["author"] = author;
                    resultRow["item_type"] = itemType;
                    resultRow["call_number"] = callNumber;

                    // Required-field validation
                    if (string.IsNullOrEmpty(title) || string.IsNullOrEmpty(barcode))
                    {
                        resultRow["status"] = "Skipped - missing title/barcode";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    // Duplicate barcode check (accession_number is the primary key)
                    if (BarcodeExists(conn, barcode))
                    {
                        resultRow["status"] = "Skipped - duplicate barcode";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    MySqlTransaction tx = conn.BeginTransaction();
                    try
                    {
                        int resourceId = InsertLibraryResource(conn, tx, row);
                        InsertItemCopy(conn, tx, row, resourceId, barcode);
                        tx.Commit();

                        successCount++;
                        resultRow["status"] = "Imported";
                    }
                    catch (Exception ex)
                    {
                        tx.Rollback();
                        resultRow["status"] = "Error - " + ex.Message;
                    }

                    resultsTable.Rows.Add(resultRow);
                }
            }

            // 4. Bind results
            gvResults.DataSource = resultsTable;
            gvResults.DataBind();

            lblImportSummary.Text = $"{successCount} / {totalRows} imported";
            int percent = totalRows > 0 ? (int)Math.Round(successCount * 100.0 / totalRows) : 0;
            string barColor = successCount == totalRows ? "bg-success" : (successCount == 0 ? "bg-danger" : "bg-warning");
            litProgressBar.Text = $"<div class='progress-bar {barColor}' role='progressbar' style='width: {percent}%;' aria-valuenow='{percent}' aria-valuemin='0' aria-valuemax='100'></div>";

            pnlResults.Visible = true;

            if (successCount == totalRows)
            {
                ShowAlert("success", "Import Complete", $"Successfully imported {successCount} of {totalRows} rows.");
            }
            else if (successCount == 0)
            {
                ShowAlert("danger", "Import Failed", $"0 of {totalRows} rows were imported. Check the results table for details.");
            }
            else
            {
                ShowAlert("warning", "Import Finished With Issues", $"Imported {successCount} of {totalRows} rows. See the results table for skipped/errored rows.");
            }
        }

        // ---- DB helpers ----

        private bool BarcodeExists(MySqlConnection conn, string barcode)
        {
            using (var cmd = new MySqlCommand("SELECT COUNT(*) FROM item_copies WHERE accession_number = @barcode", conn))
            {
                cmd.Parameters.AddWithValue("@barcode", barcode);
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        private int InsertLibraryResource(MySqlConnection conn, MySqlTransaction tx, Dictionary<string, string> row)
        {
            const string sql = @"
                INSERT INTO library_resources
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
                AddParameter(cmd, "@item_type", row, "item_type");
                AddParameter(cmd, "@isbn", row, "isbn");
                AddParameter(cmd, "@issn", row, "issn");
                AddParameter(cmd, "@call_number", row, "call_number");
                AddParameter(cmd, "@dewey_decimal", row, "dewey_decimal");
                AddParameter(cmd, "@genre", row, "genre");
                AddParameter(cmd, "@title", row, "title", required: true);
                AddParameter(cmd, "@author", row, "author");
                AddParameter(cmd, "@section", row, "section");
                AddParameter(cmd, "@publisher", row, "publisher");
                AddParameter(cmd, "@place_of_publication", row, "place_of_publication");
                AddParameter(cmd, "@series", row, "series");
                AddParameter(cmd, "@edition", row, "edition");
                AddIntParameter(cmd, "@pub_year", row, "pub_year");
                AddIntParameter(cmd, "@copyright_year", row, "copyright_year");
                AddParameter(cmd, "@pages_numeric", row, "pages_numeric");
                AddDecimalParameter(cmd, "@height_cm", row, "height_cm");
                AddDecimalParameter(cmd, "@width_cm", row, "width_cm");
                AddParameter(cmd, "@accompanying_material", row, "accompanying_material");
                AddParameter(cmd, "@description", row, "description");
                AddParameter(cmd, "@cover_path", row, "cover_path");

                return Convert.ToInt32(cmd.ExecuteScalar());
            }
        }

        private void InsertItemCopy(MySqlConnection conn, MySqlTransaction tx, Dictionary<string, string> row, int resourceId, string barcode)
        {
            const string sql = @"
                INSERT INTO item_copies
                    (accession_number, resource_id, volume_no, issue_no, binding_type,
                     campus, specific_location, status_condition, is_available, remarks)
                VALUES
                    (@accession_number, @resource_id, @volume_no, @issue_no, @binding_type,
                     @campus, @specific_location, @status_condition, @is_available, @remarks);";

            using (var cmd = new MySqlCommand(sql, conn, tx))
            {
                cmd.Parameters.AddWithValue("@accession_number", barcode);
                cmd.Parameters.AddWithValue("@resource_id", resourceId);
                AddParameter(cmd, "@volume_no", row, "volume_no");
                AddParameter(cmd, "@issue_no", row, "issue_no");
                AddParameter(cmd, "@binding_type", row, "binding_type");

                string campus = GetValue(row, "campus");
                cmd.Parameters.AddWithValue("@campus", string.IsNullOrEmpty(campus) ? "Malita Campus" : (object)campus);

                string specificLocation = GetValue(row, "specific_location");
                cmd.Parameters.AddWithValue("@specific_location", string.IsNullOrEmpty(specificLocation) ? "Circulation Desk" : (object)specificLocation);

                string statusCondition = GetValue(row, "status_condition");
                cmd.Parameters.AddWithValue("@status_condition", ValidStatusConditions.Contains(statusCondition) ? statusCondition : "Good");

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

        // ---- Helper methods ----

        private DataTable BuildResultsTable()
        {
            var table = new DataTable();
            table.Columns.Add("barcode", typeof(string));
            table.Columns.Add("title", typeof(string));
            table.Columns.Add("author", typeof(string));
            table.Columns.Add("item_type", typeof(string));
            table.Columns.Add("call_number", typeof(string));
            table.Columns.Add("status", typeof(string));
            return table;
        }

        protected string GetStatusBadgeClass(string status)
        {
            if (string.IsNullOrEmpty(status)) return "bg-secondary";
            if (status.StartsWith("Imported", StringComparison.OrdinalIgnoreCase)) return "bg-success";
            if (status.StartsWith("Skipped", StringComparison.OrdinalIgnoreCase)) return "bg-warning text-dark";
            if (status.StartsWith("Error", StringComparison.OrdinalIgnoreCase)) return "bg-danger";
            return "bg-secondary";
        }

        private string GetValue(Dictionary<string, string> row, string key)
        {
            row.TryGetValue(key, out string val);
            return val ?? "";
        }

        private void AddParameter(MySqlCommand cmd, string paramName, Dictionary<string, string> row, string column, bool required = false)
        {
            string val = GetValue(row, column);
            if (required && string.IsNullOrEmpty(val))
                throw new Exception($"Required column '{column}' is missing or empty.");
            cmd.Parameters.AddWithValue(paramName, string.IsNullOrEmpty(val) ? DBNull.Value : (object)val);
        }

        private void AddIntParameter(MySqlCommand cmd, string paramName, Dictionary<string, string> row, string column)
        {
            string val = GetValue(row, column);
            if (string.IsNullOrEmpty(val))
                cmd.Parameters.AddWithValue(paramName, DBNull.Value);
            else if (int.TryParse(val, out int intVal))
                cmd.Parameters.AddWithValue(paramName, intVal);
            else
                cmd.Parameters.AddWithValue(paramName, DBNull.Value);
        }

        private void AddDecimalParameter(MySqlCommand cmd, string paramName, Dictionary<string, string> row, string column)
        {
            string val = GetValue(row, column);
            if (string.IsNullOrEmpty(val))
                cmd.Parameters.AddWithValue(paramName, DBNull.Value);
            else if (decimal.TryParse(val, NumberStyles.Any, CultureInfo.InvariantCulture, out decimal decVal))
                cmd.Parameters.AddWithValue(paramName, decVal);
            else
                cmd.Parameters.AddWithValue(paramName, DBNull.Value);
        }

        private void ShowAlert(string type, string title, string message)
        {
            string icon;
            if (type == "success")
                icon = "fa-check-circle";
            else if (type == "warning")
                icon = "fa-exclamation-triangle";
            else if (type == "danger")
                icon = "fa-times-circle";
            else
                icon = "fa-info-circle";

            alertPlaceholder.InnerHtml = $@"
                <div class='alert alert-{type} alert-dismissible fade show' role='alert'>
                    <i class='fas {icon} me-2'></i>
                    <strong>{title}</strong> – {message}
                    <button type='button' class='btn-close' data-bs-dismiss='alert' aria-label='Close'></button>
                </div>";
        }
    }
}
