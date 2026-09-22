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

namespace spmst_lms_development.Users.Staff.Import
{
    public partial class TransactionImports : System.Web.UI.Page
    {
        // Allowed enum values (must match Transactions table in SPAMAST_LMSv2).
        private static readonly HashSet<string> ValidFineStatus =
            new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "Unpaid", "Partial", "Paid" };

        private static readonly HashSet<string> ValidLoanStatus =
            new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { "Borrowed", "Returned", "Overdue", "Reserved", "Ready", "Cancelled" };

        // Accepted date formats for CSV parsing.
        private static readonly string[] DateFormats =
        {
            "yyyy-MM-dd", "yyyy/MM/dd", "MM/dd/yyyy", "M/d/yyyy",
            "dd/MM/yyyy", "d/M/yyyy", "yyyy-MM-dd HH:mm:ss"
        };

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

            // 3. Import row by row, each in its own transaction.
            int totalRows = rows.Count;
            int successCount = 0;
            DataTable resultsTable = BuildResultsTable();

            string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();

                foreach (var row in rows)
                {
                    string userId = GetValue(row, "user_id");
                    string accessionNumber = GetValue(row, "accession_number");
                    string borrowDate = GetValue(row, "borrow_date");
                    string dueDate = GetValue(row, "due_date");
                    string returnDate = GetValue(row, "return_date");
                    string loanStatus = GetValue(row, "status");

                    DataRow resultRow = resultsTable.NewRow();
                    resultRow["user_id"] = userId;
                    resultRow["accession_number"] = accessionNumber;
                    resultRow["borrow_date"] = borrowDate;
                    resultRow["due_date"] = dueDate;
                    resultRow["return_date"] = returnDate;
                    resultRow["status"] = loanStatus;

                    // Required-field validation
                    if (string.IsNullOrEmpty(userId) || string.IsNullOrEmpty(accessionNumber)
                        || string.IsNullOrEmpty(borrowDate) || string.IsNullOrEmpty(dueDate))
                    {
                        resultRow["result"] = "Skipped - missing user_id / accession / dates";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    // Foreign-key pre-checks (gives friendlier messages than raw FK errors).
                    if (!UserExists(conn, userId))
                    {
                        resultRow["result"] = "Skipped - user_id not found";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }
                    if (!ItemCopyExists(conn, accessionNumber))
                    {
                        resultRow["result"] = "Skipped - accession_number not found";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    MySqlTransaction tx = conn.BeginTransaction();
                    try
                    {
                        InsertTransaction(conn, tx, row);
                        tx.Commit();

                        successCount++;
                        resultRow["result"] = "Imported";
                    }
                    catch (Exception ex)
                    {
                        try { tx.Rollback(); } catch { /* ignore */ }
                        resultRow["result"] = "Error - " + ex.Message;
                    }

                    resultsTable.Rows.Add(resultRow);
                }
            }

            // 4. Bind results
            gvResults.DataSource = resultsTable;
            gvResults.DataBind();

            lblImportSummary.Text = $"{successCount} / {totalRows} imported";
            int percent = totalRows > 0 ? (int)Math.Round(successCount * 100.0 / totalRows) : 0;
            string barColor = successCount == totalRows ? "bg-success"
                            : (successCount == 0 ? "bg-danger" : "bg-warning");
            litProgressBar.Text =
                $"<div class='progress-bar {barColor}' role='progressbar' style='width: {percent}%;' " +
                $"aria-valuenow='{percent}' aria-valuemin='0' aria-valuemax='100'></div>";

            pnlResults.Visible = true;

            if (successCount == totalRows)
                ShowAlert("success", "Import Complete", $"Successfully imported {successCount} of {totalRows} rows.");
            else if (successCount == 0)
                ShowAlert("danger", "Import Failed", $"0 of {totalRows} rows were imported. Check the results table for details.");
            else
                ShowAlert("warning", "Import Finished With Issues", $"Imported {successCount} of {totalRows} rows. See the results table for skipped/errored rows.");
        }

        // ---- DB helpers ----

        private bool UserExists(MySqlConnection conn, string userId)
        {
            using (var cmd = new MySqlCommand("SELECT COUNT(*) FROM Users WHERE user_id = @uid", conn))
            {
                cmd.Parameters.AddWithValue("@uid", userId);
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        private bool ItemCopyExists(MySqlConnection conn, string accessionNumber)
        {
            using (var cmd = new MySqlCommand("SELECT COUNT(*) FROM Item_Copies WHERE accession_number = @acc", conn))
            {
                cmd.Parameters.AddWithValue("@acc", accessionNumber);
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        private void InsertTransaction(MySqlConnection conn, MySqlTransaction tx, Dictionary<string, string> row)
        {
            const string sql = @"
                INSERT INTO Transactions
                    (user_id, accession_number, borrow_date, due_date, return_date,
                     fine_amount, amount_paid, balance, fine_status, paid_date,
                     status, is_damaged, is_lost, remarks)
                VALUES
                    (@user_id, @accession_number, @borrow_date, @due_date, @return_date,
                     @fine_amount, @amount_paid, @balance, @fine_status, @paid_date,
                     @status, @is_damaged, @is_lost, @remarks);";

            using (var cmd = new MySqlCommand(sql, conn, tx))
            {
                cmd.Parameters.AddWithValue("@user_id", GetValue(row, "user_id"));
                cmd.Parameters.AddWithValue("@accession_number", GetValue(row, "accession_number"));
                cmd.Parameters.AddWithValue("@borrow_date", ParseRequiredDate(row, "borrow_date"));
                cmd.Parameters.AddWithValue("@due_date", ParseRequiredDate(row, "due_date"));
                cmd.Parameters.AddWithValue("@return_date", ParseOptionalDate(row, "return_date"));

                decimal fineAmount = ParseDecimalOrDefault(row, "fine_amount", 0m);
                decimal amountPaid = ParseDecimalOrDefault(row, "amount_paid", 0m);
                decimal balance = ParseDecimalOrDefault(row, "balance", fineAmount - amountPaid);
                if (balance < 0) balance = 0m;

                cmd.Parameters.AddWithValue("@fine_amount", fineAmount);
                cmd.Parameters.AddWithValue("@amount_paid", amountPaid);
                cmd.Parameters.AddWithValue("@balance", balance);

                string fineStatus = GetValue(row, "fine_status");
                cmd.Parameters.AddWithValue("@fine_status",
                    ValidFineStatus.Contains(fineStatus) ? fineStatus : "Unpaid");

                cmd.Parameters.AddWithValue("@paid_date", ParseOptionalDate(row, "paid_date"));

                string status = GetValue(row, "status");
                cmd.Parameters.AddWithValue("@status",
                    ValidLoanStatus.Contains(status) ? status : "Borrowed");

                cmd.Parameters.AddWithValue("@is_damaged", ParseBoolToInt(row, "is_damaged"));
                cmd.Parameters.AddWithValue("@is_lost", ParseBoolToInt(row, "is_lost"));

                AddParameter(cmd, "@remarks", row, "remarks");

                cmd.ExecuteNonQuery();
            }
        }

        // ---- Helper methods ----

        private DataTable BuildResultsTable()
        {
            var table = new DataTable();
            table.Columns.Add("user_id", typeof(string));
            table.Columns.Add("accession_number", typeof(string));
            table.Columns.Add("borrow_date", typeof(string));
            table.Columns.Add("due_date", typeof(string));
            table.Columns.Add("return_date", typeof(string));
            table.Columns.Add("status", typeof(string));
            table.Columns.Add("result", typeof(string));
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

        private object ParseRequiredDate(Dictionary<string, string> row, string column)
        {
            string val = GetValue(row, column);
            if (string.IsNullOrEmpty(val))
                throw new Exception($"Required date column '{column}' is missing or empty.");
            if (TryParseDate(val, out DateTime dt))
                return dt.Date;
            throw new Exception($"Invalid date value in '{column}': '{val}'.");
        }

        private object ParseOptionalDate(Dictionary<string, string> row, string column)
        {
            string val = GetValue(row, column);
            if (string.IsNullOrEmpty(val))
                return DBNull.Value;
            if (TryParseDate(val, out DateTime dt))
                return dt;
            return DBNull.Value;
        }

        private bool TryParseDate(string val, out DateTime dt)
        {
            if (DateTime.TryParseExact(val, DateFormats, CultureInfo.InvariantCulture,
                    DateTimeStyles.None, out dt))
                return true;
            return DateTime.TryParse(val, CultureInfo.InvariantCulture,
                    DateTimeStyles.None, out dt);
        }

        private decimal ParseDecimalOrDefault(Dictionary<string, string> row, string column, decimal fallback)
        {
            string val = GetValue(row, column);
            if (string.IsNullOrEmpty(val)) return fallback;
            if (decimal.TryParse(val, NumberStyles.Any, CultureInfo.InvariantCulture, out decimal d))
                return d;
            return fallback;
        }

        private int ParseBoolToInt(Dictionary<string, string> row, string column)
        {
            string val = GetValue(row, column);
            if (string.IsNullOrEmpty(val)) return 0;
            if (val == "1") return 1;
            if (val.Equals("true", StringComparison.OrdinalIgnoreCase)) return 1;
            if (val.Equals("yes", StringComparison.OrdinalIgnoreCase)) return 1;
            return 0;
        }

        private void ShowAlert(string type, string title, string message)
        {
            string icon;
            if (type == "success") icon = "fa-check-circle";
            else if (type == "warning") icon = "fa-exclamation-triangle";
            else if (type == "danger") icon = "fa-times-circle";
            else icon = "fa-info-circle";

            alertPlaceholder.InnerHtml = $@"
                <div class='alert alert-{type} alert-dismissible fade show' role='alert'>
                    <i class='fas {icon} me-2'></i>
                    <strong>{title}</strong> – {message}
                    <button type='button' class='btn-close' data-bs-dismiss='alert' aria-label='Close'></button>
                </div>";
        }
    }
}