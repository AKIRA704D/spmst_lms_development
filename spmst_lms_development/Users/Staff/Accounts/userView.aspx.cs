using System;
using System.Configuration;
using System.Data;
using System.Text;
using System.Web.UI;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Users.Staff.Accounts
{
    public partial class userView : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;

            string userId = Request.QueryString["UserID"];
            if (string.IsNullOrWhiteSpace(userId)) return;

            string role = Request.QueryString["role"];
            if (string.IsNullOrEmpty(role)) role = GetUserRole(userId);

            if (string.IsNullOrEmpty(role))
            {
                ShowErrorMessage("Invalid user role.");
                return;
            }

            LoadUserDetails(userId, role);
            LoadBorrowingHistory(userId);
        }

        private string GetUserRole(string userId)
        {
            using (var conn = new MySqlConnection(connStr))
            using (var cmd = new MySqlCommand("SELECT role FROM Users WHERE user_id = @id", conn))
            {
                cmd.Parameters.AddWithValue("@id", userId);
                conn.Open();
                var result = cmd.ExecuteScalar();
                return result?.ToString() ?? "";
            }
        }

        private void LoadUserDetails(string userId, string role)
        {
            using (var conn = new MySqlConnection(connStr))
            {
                conn.Open();

                string query;
                if (role.Equals("student", StringComparison.OrdinalIgnoreCase))
                {
                    query = @"SELECT student_id AS user_id,
                     first_name, middle_name, last_name, extension_name,
                     gender, mobile_number, email,
                     institute, course, section, year_level,
                     address, profile_path
                    FROM Students WHERE student_id = @id";
                }
                else if (role.Equals("faculty", StringComparison.OrdinalIgnoreCase))
                {
                    query = @"SELECT faculty_id AS user_id,
                     first_name, middle_name, last_name, extension_name,
                     gender, mobile_number, email,
                     institute,
                     address, profile_path
                    FROM Faculty WHERE faculty_id = @id";
                }
                else if (role.Equals("staff", StringComparison.OrdinalIgnoreCase) ||
                         role.Equals("admin", StringComparison.OrdinalIgnoreCase))
                {
                    // Admins are stored in the Staff table (they share the same staff_id column).
                    query = @"SELECT staff_id AS user_id,
                     first_name, middle_name, last_name, extension_name,
                     gender, mobile_number, email,
                     office_department, is_head_librarian,
                     address, profile_path
                    FROM Staff WHERE staff_id = @id";
                }
                else
                {
                    ShowErrorMessage("Invalid user role: " + role);
                    return;
                }

                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id", userId);

                    using (var dr = cmd.ExecuteReader())
                    {
                        if (!dr.Read())
                        {
                            ShowErrorMessage("User record not found.");
                            return;
                        }

                        string first = Get(dr, "first_name");
                        string middle = Get(dr, "middle_name");
                        string last = Get(dr, "last_name");
                        string ext = Get(dr, "extension_name");

                        litFullName.Text = BuildFullName(last, first, middle, ext).ToUpper();
                        litRole.Text = role.ToUpper();
                        litUserID.Text = userId;

                        // Avatar: real photo if profile_path resolves, otherwise first+last initial.
                        string initials = BuildInitials(first, last);

                        string resolved = ResolveProfileImage(Get(dr, "profile_path"));

                        if (!string.IsNullOrEmpty(resolved))
                        {
                            string safeSrc = Server.HtmlEncode(resolved);
                            litAvatar.Text =
                                $"<img src=\"{safeSrc}\" alt=\"{initials}\" " +
                                $"class=\"w-full h-full object-cover\" " +
                                $"onerror=\"this.outerHTML='{initials}'\" />";
                        }
                        else
                        {
                            litAvatar.Text = initials;
                        }

                        // Contact block — identical columns across all three tables.
                        litGender.Text = Get(dr, "gender", "N/A");
                        litContact.Text = Get(dr, "mobile_number", "N/A");
                        litEmail.Text = Get(dr, "email", "N/A");
                        litAddress.Text = Get(dr, "address", "N/A");

                        // Role-specific blocks.
                        if (role.Equals("student", StringComparison.OrdinalIgnoreCase))
                        {
                            phAcademicInfo.Visible = true;
                            litInstitute.Text = Get(dr, "institute", "N/A");
                            litCourse.Text = Get(dr, "course", "N/A");
                            litSection.Text = Get(dr, "section", "N/A");
                            litYear.Text = Get(dr, "year_level", "N/A");
                        }
                        else if (role.Equals("faculty", StringComparison.OrdinalIgnoreCase))
                        {
                            phAcademicInfo.Visible = true;
                            litInstitute.Text = Get(dr, "institute", "N/A");
                            litCourse.Text = "—";
                            litSection.Text = "—";
                            litYear.Text = "—";
                        }
                        else // staff or admin
                        {
                            phStaffHeader.Visible = true;

                            string dept = Get(dr, "office_department", "N/A");
                            bool isHead = false;
                            object head = dr["is_head_librarian"];
                            if (head != null && head != DBNull.Value)
                                isHead = Convert.ToInt32(head) == 1;

                            litDept.Text = isHead ? dept + " · Head Librarian" : dept;
                        }
                    }
                }

                // Account status lives on the Users table, not the role table.
                using (var cmdStatus = new MySqlCommand("SELECT is_active FROM Users WHERE user_id = @id", conn))
                {
                    cmdStatus.Parameters.AddWithValue("@id", userId);
                    object activeStatus = cmdStatus.ExecuteScalar();
                    int statusVal = (activeStatus != null && activeStatus != DBNull.Value)
                        ? Convert.ToInt32(activeStatus)
                        : 0;

                    switch (statusVal)
                    {
                        case 1:
                            litStatus.Text = "ACTIVE";
                            statusBadge.Attributes["class"] =
                                "text-[10px] font-bold px-2 py-0.5 rounded-full uppercase bg-green-100 text-green-700";
                            break;
                        case 2:
                            litStatus.Text = "DEACTIVATED";
                            statusBadge.Attributes["class"] =
                                "text-[10px] font-bold px-2 py-0.5 rounded-full uppercase bg-red-100 text-red-700";
                            break;
                        default:
                            litStatus.Text = "INACTIVE";
                            statusBadge.Attributes["class"] =
                                "text-[10px] font-bold px-2 py-0.5 rounded-full uppercase bg-yellow-100 text-yellow-700";
                            break;
                    }
                }
            }
        }

        private void LoadBorrowingHistory(string userId)
        {
            using (var conn = new MySqlConnection(connStr))
            {
                const string query = @"
                    SELECT r.title AS BookTitle,
                           r.isbn  AS ISBN,
                           t.borrow_date AS DateBorrowed,
                           t.due_date    AS DueDate,
                           t.status      AS Status
                    FROM Transactions t
                    INNER JOIN Item_Copies       c ON t.accession_number = c.accession_number
                    INNER JOIN Library_Resources r ON c.resource_id     = r.resource_id
                    WHERE t.user_id = @id
                    ORDER BY t.borrow_date DESC
                    LIMIT 5";

                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id", userId);
                    conn.Open();

                    using (var da = new MySqlDataAdapter(cmd))
                    {
                        var dt = new DataTable();
                        da.Fill(dt);

                        if (dt.Rows.Count > 0)
                        {
                            rptHistory.DataSource = dt;
                            rptHistory.DataBind();
                            phNoHistory.Visible = false;
                        }
                        else
                        {
                            phNoHistory.Visible = true;
                        }
                    }
                }
            }
        }

        /// <summary>Reads a column as a trimmed string, returning a fallback for NULL/empty.</summary>
        private static string Get(IDataRecord dr, string column, string fallback = "")
        {
            int i = dr.GetOrdinal(column);
            if (dr.IsDBNull(i)) return fallback;

            string value = dr.GetValue(i).ToString().Trim();
            return string.IsNullOrEmpty(value) ? fallback : value;
        }

        /// <summary>Formats "Last, First M. Ext" — middle name collapses to an initial.</summary>
        private static string BuildFullName(string last, string first, string middle, string ext)
        {
            var sb = new StringBuilder();
            sb.Append(last);

            if (!string.IsNullOrEmpty(first))
            {
                sb.Append(", ").Append(first);

                if (!string.IsNullOrEmpty(middle))
                {
                    sb.Append(' ')
                      .Append(char.ToUpper(middle[0]))
                      .Append('.');
                }
            }

            if (!string.IsNullOrEmpty(ext))
                sb.Append(' ').Append(ext);

            return sb.ToString();
        }

        /// <summary>Two-letter placeholder from the first and last names (falls back to one or '?').</summary>
        private static string BuildInitials(string first, string last)
        {
            char f = !string.IsNullOrEmpty(first) ? char.ToUpper(first[0]) : '?';
            char l = !string.IsNullOrEmpty(last) ? char.ToUpper(last[0]) : '\0';
            return l == '\0' ? f.ToString() : new string(new[] { f, l });
        }

        /// <summary>
        /// Normalises a stored image path to an app-relative URL.
        /// Returns null if the path is empty or the file doesn't exist on disk,
        /// so the caller can fall back to initials.
        /// </summary>
        private string ResolveProfileImage(string profilePath)
        {
            if (string.IsNullOrWhiteSpace(profilePath)) return null;

            // Tolerate backslashes copied in from Windows tooling.
            string raw = profilePath.Trim().Replace('\\', '/');

            // Absolute URLs are left alone.
            if (raw.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                raw.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                return raw;
            }

            // Anything without "~/" or "/" is treated as app-root-relative.
            // This is what fixes "Assets/Covers/default-cover.jpg".
            if (!raw.StartsWith("~/") && !raw.StartsWith("/"))
                raw = "~/" + raw;

            // For app-relative paths, make sure the file actually exists.
            if (raw.StartsWith("~/"))
            {
                try
                {
                    if (!System.IO.File.Exists(Server.MapPath(raw)))
                        return null;
                }
                catch
                {
                    return null;
                }
            }

            return ResolveUrl(raw);
        }

        private void ShowErrorMessage(string message)
        {
            string script = $"alert('{message.Replace("'", "\\'")}');";
            ClientScript.RegisterStartupScript(GetType(), "error", script, true);
        }
    }
}