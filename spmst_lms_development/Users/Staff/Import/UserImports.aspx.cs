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
    public partial class UserImports : System.Web.UI.Page
    {
        // Matches the Users.role ENUM.
        private static readonly HashSet<string> ValidRoles =
            new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "student", "faculty", "staff", "admin" };

        // Matches the gender ENUM used across the person tables.
        private static readonly HashSet<string> ValidGenders =
            new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "Male", "Female" };

        protected void Page_Load(object sender, EventArgs e)
        {
        }

        protected void btnImport_Click(object sender, EventArgs e)
        {
            alertPlaceholder.InnerHtml = "";
            pnlResults.Visible = false;

            // 1. Validate the upload
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

            // 2. Read the CSV
            List<Dictionary<string, string>> rows = new List<Dictionary<string, string>>();
            try
            {
                using (var reader = new StreamReader(fuCSVImport.PostedFile.InputStream))
                using (var csv = new CsvReader(reader, CultureInfo.InvariantCulture))
                {
                    csv.Read();
                    csv.ReadHeader();

                    if (csv.HeaderRecord == null || csv.HeaderRecord.Length == 0)
                    {
                        ShowAlert("warning", "No Header", "CSV must have a header row with column names.");
                        return;
                    }

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

            // 3. Import row by row (each in its own transaction)
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
                    string email = GetValue(row, "email");
                    string role = GetValue(row, "role").ToLowerInvariant();
                    string firstName = GetValue(row, "first_name");
                    string lastName = GetValue(row, "last_name");

                    DataRow resultRow = resultsTable.NewRow();
                    resultRow["user_id"] = userId;
                    resultRow["email"] = email;
                    resultRow["name"] = (firstName + " " + lastName).Trim();
                    resultRow["role"] = role;

                    // Required-field validation
                    if (string.IsNullOrEmpty(userId) || string.IsNullOrEmpty(email) || string.IsNullOrEmpty(role))
                    {
                        resultRow["status"] = "Skipped - missing user_id/email/role";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    if (!ValidRoles.Contains(role))
                    {
                        resultRow["status"] = "Skipped - invalid role";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    // Role must agree with the head-librarian flag (the trigger derives Users.role from it)
                    string headRaw = GetValue(row, "is_head_librarian");
                    bool headFlag = headRaw == "1"
                        || headRaw.Equals("true", StringComparison.OrdinalIgnoreCase)
                        || headRaw.Equals("yes", StringComparison.OrdinalIgnoreCase);

                    if (role == "admin" && !headFlag)
                    {
                        resultRow["status"] = "Skipped - admin requires is_head_librarian = 1";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }
                    if (role == "staff" && headFlag)
                    {
                        resultRow["status"] = "Skipped - head librarian must use role admin";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    if (string.IsNullOrEmpty(firstName) || string.IsNullOrEmpty(lastName))

                        if (string.IsNullOrEmpty(firstName) || string.IsNullOrEmpty(lastName))
                    {
                        resultRow["status"] = "Skipped - missing first/last name";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    // Duplicate checks
                    if (UserIdExists(conn, userId))
                    {
                        resultRow["status"] = "Skipped - duplicate user_id";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    if (EmailExists(conn, email))
                    {
                        resultRow["status"] = "Skipped - duplicate email";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    MySqlTransaction tx = conn.BeginTransaction();
                    try
                    {
                        // Insert the role-specific person record first,
                        InsertPersonRecord(conn, tx, row, userId, role);                    
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
                ShowAlert("success", "Import Complete", $"Successfully imported {successCount} of {totalRows} users.");
            else if (successCount == 0)
                ShowAlert("danger", "Import Failed", $"0 of {totalRows} rows were imported. Check the results table for details.");
            else
                ShowAlert("warning", "Import Finished With Issues", $"Imported {successCount} of {totalRows} rows. See the results table for skipped/errored rows.");
        }

        // ---------- Duplicate checks ----------

        private bool UserIdExists(MySqlConnection conn, string userId)
        {
            using (var cmd = new MySqlCommand("SELECT COUNT(*) FROM Users WHERE user_id = @id", conn))
            {
                cmd.Parameters.AddWithValue("@id", userId);
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        private bool EmailExists(MySqlConnection conn, string email)
        {
            // All three person tables and Users have UNIQUE email constraints,
            // so we check all four to avoid a partial insert + rollback cycle.
            const string sql = @"
                SELECT
                    (SELECT COUNT(*) FROM Users     WHERE email = @email) +
                    (SELECT COUNT(*) FROM Students  WHERE email = @email) +
                    (SELECT COUNT(*) FROM Faculty   WHERE email = @email) +
                    (SELECT COUNT(*) FROM Staff     WHERE email = @email) AS c;";

            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@email", email);
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        // ---------- Inserts ----------

        private void InsertPersonRecord(MySqlConnection conn, MySqlTransaction tx,
                                        Dictionary<string, string> row, string userId, string role)
        {
            string firstName = GetValue(row, "first_name");
            string middleName = GetValue(row, "middle_name");
            string lastName = GetValue(row, "last_name");
            string extensionName = GetValue(row, "extension_name");
            string gender = GetValue(row, "gender");
            string mobileNumber = GetValue(row, "mobile_number");
            string email = GetValue(row, "email");
            string address = GetValue(row, "address");
            string profilePath = GetValue(row, "profile_path");

            if (!string.IsNullOrEmpty(gender) && !ValidGenders.Contains(gender))
                gender = ""; // silently drop invalid ENUM values

            if (role == "student")
            {
                const string sql = @"
                    INSERT INTO Students
                        (student_id, first_name, middle_name, last_name, extension_name, gender,
                         mobile_number, email, institute, course, section, year_level, address, profile_path)
                    VALUES
                        (@id, @first_name, @middle_name, @last_name, @extension_name, @gender,
                         @mobile_number, @email, @institute, @course, @section, @year_level, @address, @profile_path);";

                using (var cmd = new MySqlCommand(sql, conn, tx))
                {
                    cmd.Parameters.AddWithValue("@id", userId);
                    AddNullable(cmd, "@first_name", firstName);
                    AddNullable(cmd, "@middle_name", middleName);
                    AddNullable(cmd, "@last_name", lastName);
                    AddNullable(cmd, "@extension_name", extensionName);
                    AddNullable(cmd, "@gender", gender);
                    AddNullable(cmd, "@mobile_number", mobileNumber);
                    AddNullable(cmd, "@email", email);
                    AddNullable(cmd, "@institute", GetValue(row, "institute"));
                    AddNullable(cmd, "@course", GetValue(row, "course"));
                    AddNullable(cmd, "@section", GetValue(row, "section"));
                    AddNullable(cmd, "@year_level", GetValue(row, "year_level"));
                    AddNullable(cmd, "@address", address);
                    AddNullable(cmd, "@profile_path", profilePath);
                    cmd.ExecuteNonQuery();
                }
            }
            else if (role == "faculty")
            {
                const string sql = @"
                    INSERT INTO Faculty
                        (faculty_id, first_name, middle_name, last_name, extension_name, gender,
                         mobile_number, email, institute, address, profile_path)
                    VALUES
                        (@id, @first_name, @middle_name, @last_name, @extension_name, @gender,
                         @mobile_number, @email, @institute, @address, @profile_path);";

                using (var cmd = new MySqlCommand(sql, conn, tx))
                {
                    cmd.Parameters.AddWithValue("@id", userId);
                    AddNullable(cmd, "@first_name", firstName);
                    AddNullable(cmd, "@middle_name", middleName);
                    AddNullable(cmd, "@last_name", lastName);
                    AddNullable(cmd, "@extension_name", extensionName);
                    AddNullable(cmd, "@gender", gender);
                    AddNullable(cmd, "@mobile_number", mobileNumber);
                    AddNullable(cmd, "@email", email);
                    AddNullable(cmd, "@institute", GetValue(row, "institute"));
                    AddNullable(cmd, "@address", address);
                    AddNullable(cmd, "@profile_path", profilePath);
                    cmd.ExecuteNonQuery();
                }
            }
            else // staff or admin -> Staff table
            {
                const string sql = @"
                    INSERT INTO Staff
                        (staff_id, first_name, middle_name, last_name, extension_name, gender,
                         mobile_number, email, office_department, is_head_librarian, address, profile_path)
                    VALUES
                        (@id, @first_name, @middle_name, @last_name, @extension_name, @gender,
                         @mobile_number, @email, @office_department, @is_head_librarian, @address, @profile_path);";

                string office = GetValue(row, "office_department");
                if (string.IsNullOrEmpty(office)) office = "Circulation Area";

                int isHead = 0;
                string headRaw = GetValue(row, "is_head_librarian");
                if (headRaw == "1"
                    || headRaw.Equals("true", StringComparison.OrdinalIgnoreCase)
                    || headRaw.Equals("yes", StringComparison.OrdinalIgnoreCase))
                    isHead = 1;

                using (var cmd = new MySqlCommand(sql, conn, tx))
                {
                    cmd.Parameters.AddWithValue("@id", userId);
                    AddNullable(cmd, "@first_name", firstName);
                    AddNullable(cmd, "@middle_name", middleName);
                    AddNullable(cmd, "@last_name", lastName);
                    AddNullable(cmd, "@extension_name", extensionName);
                    AddNullable(cmd, "@gender", gender);
                    AddNullable(cmd, "@mobile_number", mobileNumber);
                    AddNullable(cmd, "@email", email);
                    AddNullable(cmd, "@office_department", office);
                    cmd.Parameters.AddWithValue("@is_head_librarian", isHead);
                    AddNullable(cmd, "@address", address);
                    AddNullable(cmd, "@profile_path", profilePath);
                    cmd.ExecuteNonQuery();
                }
            }
        }

       

        // ---------- Helpers ----------

        private DataTable BuildResultsTable()
        {
            var table = new DataTable();
            table.Columns.Add("user_id", typeof(string));
            table.Columns.Add("email", typeof(string));
            table.Columns.Add("name", typeof(string));
            table.Columns.Add("role", typeof(string));
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

        private static string GetValue(Dictionary<string, string> row, string key)
        {
            row.TryGetValue(key, out string val);
            return val ?? "";
        }

        private static void AddNullable(MySqlCommand cmd, string paramName, string value)
        {
            cmd.Parameters.AddWithValue(paramName,
                string.IsNullOrEmpty(value) ? (object)DBNull.Value : value);
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