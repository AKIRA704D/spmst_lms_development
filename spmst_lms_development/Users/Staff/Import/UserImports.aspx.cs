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
            new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "student", "faculty", "staff", "admin"
            };

        private static readonly string[] RequiredHeaders =
        {
            "user_id", "email", "role", "first_name", "last_name"
        };

        protected void Page_Load(object sender, EventArgs e)
        {
        }

        protected void btnImport_Click(object sender, EventArgs e)
        {
            alertPlaceholder.InnerHtml = "";
            pnlResults.Visible = false;

            // 1. Validate the upload.
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

            // 2. Read the CSV.
            List<Dictionary<string, string>> rows = new List<Dictionary<string, string>>();
            try
            {
                using (var reader = new StreamReader(fuCSVImport.PostedFile.InputStream))
                using (var csv = new CsvReader(reader, CultureInfo.InvariantCulture))
                {
                    if (!csv.Read())
                    {
                        ShowAlert("warning", "Empty File", "The CSV file has no header row.");
                        return;
                    }

                    csv.ReadHeader();

                    if (csv.HeaderRecord == null || csv.HeaderRecord.Length == 0)
                    {
                        ShowAlert("warning", "No Header", "CSV must have a header row with column names.");
                        return;
                    }

                    var headerMap = new List<KeyValuePair<string, string>>();
                    foreach (var rawHeader in csv.HeaderRecord)
                    {
                        string normalized = (rawHeader ?? "").Trim().TrimStart('\uFEFF');
                        if (normalized.Length == 0)
                            continue;

                        headerMap.Add(new KeyValuePair<string, string>(normalized, rawHeader));
                    }

                    var presentHeaders = new HashSet<string>(
                        headerMap.Select(h => h.Key),
                        StringComparer.OrdinalIgnoreCase);

                    var missingHeaders = RequiredHeaders
                        .Where(h => !presentHeaders.Contains(h))
                        .ToList();

                    if (missingHeaders.Count > 0)
                    {
                        ShowAlert(
                            "warning",
                            "Missing Required Columns",
                            "The CSV is missing required header(s): " + string.Join(", ", missingHeaders));
                        return;
                    }

                    while (csv.Read())
                    {
                        var rowDict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

                        foreach (var header in headerMap)
                        {
                            string value = "";
                            try
                            {
                                value = csv.GetField(header.Value);
                            }
                            catch
                            {
                                value = "";
                            }

                            rowDict[header.Key] = value == null ? "" : value.Trim();
                        }

                        rows.Add(rowDict);
                    }
                }
            }
            catch (Exception)
            {
                ShowAlert(
                    "danger",
                    "Could Not Read File",
                    "The CSV file could not be parsed. Please check the file format and headers, then try again.");
                return;
            }

            if (rows.Count == 0)
            {
                ShowAlert("warning", "Empty File", "No data rows found.");
                return;
            }

            // 3. Import row by row. Each row is atomic: person insert + trigger-created Users row.
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

                    // Required-field validation.
                    if (string.IsNullOrEmpty(userId) ||
                        string.IsNullOrEmpty(email) ||
                        string.IsNullOrEmpty(role))
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

                    // Gender is an ENUM('Male','Female'). Blank is allowed and becomes NULL.
                    string genderRaw = GetValue(row, "gender");
                    string normalizedGender;

                    if (!TryNormalizeGender(genderRaw, out normalizedGender))
                    {
                        resultRow["status"] = "Skipped - invalid gender (must be Male or Female)";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    row["gender"] = normalizedGender;

                    if (string.IsNullOrEmpty(firstName) || string.IsNullOrEmpty(lastName))
                    {
                        resultRow["status"] = "Skipped - missing first/last name";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    // Staff/admin role is derived by trg_staff_users from Staff.is_head_librarian.
                    bool? parsedHead = TryParseFlag(GetValue(row, "is_head_librarian"));

                    if ((role == "staff" || role == "admin") && parsedHead == null)
                    {
                        resultRow["status"] = "Skipped - invalid is_head_librarian";
                        resultsTable.Rows.Add(resultRow);
                        continue;
                    }

                    bool headFlag = parsedHead ?? false;

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

                    // Duplicate checks against the actual schema tables.
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

                    using (var tx = conn.BeginTransaction())
                    {
                        try
                        {
                            // Insert only the person record. The database trigger creates Users.
                            // CSV columns like is_active / password_hash / password are NEVER read here,
                            // so they cannot override the migration defaults.
                            InsertPersonRecord(conn, tx, row, userId, role, headFlag);

                            // Verify the trigger-created Users row and its migration defaults.
                            string verificationError = VerifyUserRecord(conn, tx, userId, email, role);

                            if (verificationError != null)
                            {
                                System.Diagnostics.Trace.TraceError(
                                    "User import verification failed. user_id='{0}', email='{1}', expected_role='{2}', problem='{3}'",
                                    userId, email, role, verificationError);

                                throw new ImportVerificationException(verificationError);
                            }

                            tx.Commit();

                            successCount++;
                            resultRow["status"] = "Imported";
                        }
                        catch (Exception ex)
                        {
                            try
                            {
                                tx.Rollback();
                            }
                            catch
                            {
                                // Preserve the original row error.
                            }

                            resultRow["status"] = GetSafeRowError(ex);
                        }
                    }

                    resultsTable.Rows.Add(resultRow);
                }
            }

            // 4. Bind results.
            gvResults.DataSource = resultsTable;
            gvResults.DataBind();

            lblImportSummary.Text = string.Format("{0} / {1} imported", successCount, totalRows);

            int percent = totalRows > 0
                ? (int)Math.Round(successCount * 100.0 / totalRows)
                : 0;

            string barColor = successCount == totalRows
                ? "bg-success"
                : (successCount == 0 ? "bg-danger" : "bg-warning");

            litProgressBar.Text =
                "<div class='progress-bar " + barColor + "' role='progressbar' style='width: " + percent + "%;' " +
                "aria-valuenow='" + percent + "' aria-valuemin='0' aria-valuemax='100'></div>";

            pnlResults.Visible = true;

            if (successCount == totalRows)
            {
                ShowAlert(
                    "success",
                    "Import Complete",
                    string.Format("Successfully imported {0} of {1} users.", successCount, totalRows));
            }
            else if (successCount == 0)
            {
                ShowAlert(
                    "danger",
                    "Import Failed",
                    string.Format("0 of {0} rows were imported. Check the results table for details.", totalRows));
            }
            else
            {
                ShowAlert(
                    "warning",
                    "Import Finished With Issues",
                    string.Format("Imported {0} of {1} rows. See the results table for skipped/errored rows.",
                                  successCount, totalRows));
            }
        }

        // ---------- Duplicate checks ----------

        private bool UserIdExists(MySqlConnection conn, string userId)
        {
            const string sql = @"
                SELECT
                    (SELECT COUNT(*) FROM Users     WHERE user_id = @id) +
                    (SELECT COUNT(*) FROM Students  WHERE student_id = @id) +
                    (SELECT COUNT(*) FROM Faculty   WHERE faculty_id = @id) +
                    (SELECT COUNT(*) FROM Staff     WHERE staff_id = @id) AS c;";

            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@id", userId);
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        private bool EmailExists(MySqlConnection conn, string email)
        {
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

        private void InsertPersonRecord(
            MySqlConnection conn,
            MySqlTransaction tx,
            Dictionary<string, string> row,
            string userId,
            string role,
            bool isHeadLibrarian)
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
                if (string.IsNullOrEmpty(office))
                    office = "Circulation Area";

                int isHead = isHeadLibrarian ? 1 : 0;

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

        // ---------- Verification (THE FIX) ----------

        /// <summary>
        /// Returns null when the trigger-created Users row matches the required migration defaults;
        /// otherwise returns a short, safe, user-facing error string.
        /// </summary>
        private string VerifyUserRecord(
            MySqlConnection conn,
            MySqlTransaction tx,
            string userId,
            string email,
            string role)
        {
            const string sql = @"
                SELECT
                    email,
                    role,
                    is_active,
                    (password_hash IS NULL) AS password_is_null
                FROM Users
                WHERE user_id = @id
                LIMIT 1;";

            using (var cmd = new MySqlCommand(sql, conn, tx))
            {
                cmd.Parameters.AddWithValue("@id", userId);

                using (var reader = cmd.ExecuteReader())
                {
                    if (!reader.Read())
                        return "Error - user account was not created";

                    string actualEmail = Convert.ToString(reader["email"]) ?? "";
                    string actualRole = Convert.ToString(reader["role"]) ?? "";
                    int isActive = Convert.ToInt32(reader["is_active"]);
                    int passwordIsNull = Convert.ToInt32(reader["password_is_null"]);

                    if (!string.Equals(actualEmail, email, StringComparison.OrdinalIgnoreCase))
                        return "Error - user account email does not match CSV";

                    if (!string.Equals(actualRole, role, StringComparison.OrdinalIgnoreCase))
                        return "Error - user account role does not match CSV";

                    if (isActive != 0)
                        return "Error - user account is_active is not 0";

                    if (passwordIsNull != 1)
                        return "Error - user account password_hash is not NULL";

                    return null;
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
            if (string.IsNullOrEmpty(status))
                return "bg-secondary";

            if (status.StartsWith("Imported", StringComparison.OrdinalIgnoreCase))
                return "bg-success";

            if (status.StartsWith("Skipped", StringComparison.OrdinalIgnoreCase))
                return "bg-warning text-dark";

            if (status.StartsWith("Error", StringComparison.OrdinalIgnoreCase))
                return "bg-danger";

            return "bg-secondary";
        }

        private static string GetValue(Dictionary<string, string> row, string key)
        {
            row.TryGetValue(key, out string val);
            return val ?? "";
        }

        private static void AddNullable(MySqlCommand cmd, string paramName, string value)
        {
            cmd.Parameters.AddWithValue(
                paramName,
                string.IsNullOrEmpty(value) ? (object)DBNull.Value : value);
        }

        private static bool TryNormalizeGender(string raw, out string normalized)
        {
            normalized = "";

            if (string.IsNullOrWhiteSpace(raw))
                return true;

            if (raw.Equals("Male", StringComparison.OrdinalIgnoreCase))
            {
                normalized = "Male";
                return true;
            }

            if (raw.Equals("Female", StringComparison.OrdinalIgnoreCase))
            {
                normalized = "Female";
                return true;
            }

            return false;
        }

        private static bool? TryParseFlag(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw))
                return false;

            if (raw == "1" ||
                raw.Equals("true", StringComparison.OrdinalIgnoreCase) ||
                raw.Equals("yes", StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            if (raw == "0" ||
                raw.Equals("false", StringComparison.OrdinalIgnoreCase) ||
                raw.Equals("no", StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            return null;
        }

        private static string GetSafeRowError(Exception ex)
        {
            var verificationEx = ex as ImportVerificationException;
            if (verificationEx != null)
                return verificationEx.SafeStatus;

            var mysqlEx = ex as MySqlException;

            if (mysqlEx != null)
            {
                System.Diagnostics.Trace.TraceError(
                    "User import database error. Number={0}, Message={1}",
                    mysqlEx.Number,
                    mysqlEx.Message);

                if (mysqlEx.Number == 1062)
                    return "Skipped - duplicate user_id or email";

                if (mysqlEx.Number == 1265 || mysqlEx.Number == 1366 || mysqlEx.Number == 1292)
                    return "Skipped - invalid data for one or more columns";

                if (mysqlEx.Number == 1452)
                    return "Error - database constraint rejected the row";

                if (mysqlEx.Number == 1146)
                    return "Error - database schema mismatch (table or trigger missing)";

                return "Error - database rejected the row";
            }

            if (ex is FormatException)
                return "Skipped - invalid CSV data";

            if (ex is InvalidOperationException)
                return "Error - import operation failed";

            return "Error - row could not be imported";
        }

        private void ShowAlert(string type, string title, string message)
        {
            string icon;
            if (type == "success") icon = "fa-check-circle";
            else if (type == "warning") icon = "fa-exclamation-triangle";
            else if (type == "danger") icon = "fa-times-circle";
            else icon = "fa-info-circle";

            alertPlaceholder.InnerHtml = string.Format(
                "<div class='alert alert-{0} alert-dismissible fade show' role='alert'>" +
                "<i class='fas {1} me-2'></i>" +
                "<strong>{2}</strong> – {3}" +
                "<button type='button' class='btn-close' data-bs-dismiss='alert' aria-label='Close'></button>" +
                "</div>",
                type, icon, title, message);
        }

        private sealed class ImportVerificationException : Exception
        {
            public string SafeStatus { get; private set; }

            public ImportVerificationException(string safeStatus)
                : base(safeStatus)
            {
                SafeStatus = safeStatus;
            }
        }
    }
}