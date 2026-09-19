using System;
using System.Data;
using MySql.Data.MySqlClient;
using System.Configuration;
using System.Web.UI;

namespace spmst_lms_development.Users.Staff.Accounts
{
    public partial class userView : System.Web.UI.Page
    {
        // Connection string from Web.config (must match your project)
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                string userId = Request.QueryString["UserID"];
                string role = Request.QueryString["role"];

                if (!string.IsNullOrEmpty(userId))
                {
                    // If role not provided, fetch it from database
                    if (string.IsNullOrEmpty(role))
                    {
                        role = GetUserRole(userId);
                    }

                    LoadUserDetails(userId, role);
                    LoadBorrowingHistory(userId);
                }
            }
        }

        private string GetUserRole(string userId)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                string query = "SELECT role FROM Users WHERE user_id = @id";
                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id", userId);
                    conn.Open();
                    object result = cmd.ExecuteScalar();
                    return result != null ? result.ToString() : "";
                }
            }
        }

        private void LoadUserDetails(string userId, string role)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();
                string query = "";

                // Build role-specific query
                if (role.Equals("student", StringComparison.OrdinalIgnoreCase))
                {
                    query = @"SELECT *, CONCAT(last_name, ', ', first_name, ' ', IFNULL(middle_name, ''), ' ', IFNULL(extension_name, '')) as full_name_ext 
                              FROM Students WHERE student_id = @id";
                }
                else if (role.Equals("faculty", StringComparison.OrdinalIgnoreCase))
                {
                    query = @"SELECT *, CONCAT(last_name, ', ', first_name, ' ', IFNULL(middle_name, ''), ' ', IFNULL(extension_name, '')) as full_name_ext 
                              FROM Faculty WHERE faculty_id = @id";
                }
                else if (role.Equals("staff", StringComparison.OrdinalIgnoreCase))
                {
                    query = @"SELECT *, CONCAT(last_name, ', ', first_name) as full_name_ext 
                              FROM Staff WHERE staff_id = @id";
                }
                else
                {
                    // Unknown role – show error and exit
                    ShowErrorMessage("Invalid user role.");
                    return;
                }

                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id", userId);
                    using (MySqlDataReader dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            // Common fields
                            litFullName.Text = dr["full_name_ext"].ToString().ToUpper();
                            litAvatar.Text = dr["first_name"].ToString().Substring(0, 1).ToUpper();
                            litUserID.Text = userId;
                            litRole.Text = role.ToUpper();

                            // Personal information
                            litGender.Text = dr.HasColumn("gender") ? dr["gender"].ToString() : "N/A";
                            litContact.Text = dr.HasColumn("mobile_number") ? dr["mobile_number"].ToString() : "N/A";
                            litEmail.Text = dr.HasColumn("email") ? dr["email"].ToString() : "N/A";

                            // Role-specific information
                            if (role.ToLower() == "student")
                            {
                                phAcademicInfo.Visible = true;
                                litInstitute.Text = dr["institute"].ToString();
                                litCourse.Text = dr["course"].ToString();
                                litSection.Text = dr["section"].ToString();
                                litYear.Text = dr["year_level"].ToString();
                            }
                            else if (role.ToLower() == "faculty")
                            {
                                phAcademicInfo.Visible = true;
                                litInstitute.Text = dr["institute"].ToString();
                                litCourse.Text = "N/A";
                                litSection.Text = "N/A";
                                litYear.Text = "N/A";
                            }
                            else if (role.ToLower() == "staff")
                            {
                                phStaffHeader.Visible = true;
                                litDept.Text = dr["office_department"].ToString();
                            }
                        }
                        else
                        {
                            ShowErrorMessage("User record not found.");
                        }
                    }
                }

                // Load account status from Users table
                using (MySqlCommand cmdStatus = new MySqlCommand("SELECT is_active FROM Users WHERE user_id = @id", conn))
                {
                    cmdStatus.Parameters.AddWithValue("@id", userId);
                    object activeStatus = cmdStatus.ExecuteScalar();
                    int statusVal = activeStatus != null ? Convert.ToInt32(activeStatus) : 0;

                    if (statusVal == 1)
                    {
                        litStatus.Text = "ACTIVE";
                        statusBadge.Attributes["class"] = "text-[10px] font-bold px-2 py-0.5 rounded-full uppercase bg-green-100 text-green-700";
                    }
                    else if (statusVal == 2)
                    {
                        litStatus.Text = "DEACTIVATED";
                        statusBadge.Attributes["class"] = "text-[10px] font-bold px-2 py-0.5 rounded-full uppercase bg-red-100 text-red-700";
                    }
                    else
                    {
                        litStatus.Text = "INACTIVE";
                        statusBadge.Attributes["class"] = "text-[10px] font-bold px-2 py-0.5 rounded-full uppercase bg-yellow-100 text-yellow-700";
                    }
                }
            }
        }

        private void LoadBorrowingHistory(string userId)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                string query = @"
                    SELECT r.title AS BookTitle, r.isbn AS ISBN, t.borrow_date AS DateBorrowed, 
                           t.due_date AS DueDate, t.status AS Status 
                    FROM Transactions t 
                    INNER JOIN Item_Copies c ON t.accession_number = c.accession_number
                    INNER JOIN Library_Resources r ON c.resource_id = r.resource_id
                    WHERE t.user_id = @id 
                    ORDER BY t.borrow_date DESC LIMIT 5";

                using (MySqlCommand cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id", userId);
                    conn.Open();
                    using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
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

        protected string GetStatusClass(string status)
        {
            if (string.IsNullOrEmpty(status)) return "bg-gray-100 text-gray-600";

            switch (status.ToLower())
            {
                case "returned": return "bg-green-100 text-green-600";
                case "overdue": return "bg-red-100 text-red-600";
                case "borrowed": return "bg-blue-100 text-blue-600";
                default: return "bg-gray-100 text-gray-600";
            }
        }

        private void ShowErrorMessage(string message)
        {
            // Simple alert (can be replaced with SweetAlert if needed)
            string script = $"alert('{message.Replace("'", "\\'")}');";
            ClientScript.RegisterStartupScript(GetType(), "error", script, true);
        }
    }

    // Extension method helper for IDataReader column existence
    public static class DataReaderExtensions
    {
        public static bool HasColumn(this IDataRecord dr, string columnName)
        {
            for (int i = 0; i < dr.FieldCount; i++)
            {
                if (dr.GetName(i).Equals(columnName, StringComparison.InvariantCultureIgnoreCase))
                    return true;
            }
            return false;
        }
    }
}