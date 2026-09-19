using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Web.UI;

namespace spmst_lms_development.Users.Staff.Accounts
{
    public partial class userNew : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                ClearFields();
            }
        }

        protected void BtnSave_Click(object sender, EventArgs e)
        {
            string role = ddlCategory.SelectedValue;
            string userId = txtID.Text.Trim();
            string email = txtEmail.Text.Trim();
            string fname = txtFName.Text.Trim();
            string lname = txtLName.Text.Trim();

            // Basic validation
            if (string.IsNullOrEmpty(role))
            {
                ShowSweetAlert("Validation Error", "Please select a role.", "warning");
                return;
            }
            if (string.IsNullOrEmpty(userId))
            {
                ShowSweetAlert("Validation Error", "ID Number is required.", "warning");
                return;
            }
            if (string.IsNullOrEmpty(email))
            {
                ShowSweetAlert("Validation Error", "Email Address is required.", "warning");
                return;
            }
            if (string.IsNullOrEmpty(fname) || string.IsNullOrEmpty(lname))
            {
                ShowSweetAlert("Validation Error", "First Name and Last Name are required.", "warning");
                return;
            }

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                try
                {
                    conn.Open();
                    using (MySqlTransaction trans = conn.BeginTransaction())
                    {
                        try
                        {
                            string insertPatronSql = GetPatronInsertSql(role);
                            using (MySqlCommand cmd = new MySqlCommand(insertPatronSql, conn, trans))
                            {
                                AddPatronParameters(cmd, role);
                                if (cmd.ExecuteNonQuery() != 1)
                                    throw new Exception("Failed to insert patron record.");
                            }

                            string insertUserSql = "INSERT INTO Users (user_id, email, password_hash, role, is_active) VALUES (@id, @email, NULL, @role, 0)";
                            using (MySqlCommand cmdUser = new MySqlCommand(insertUserSql, conn, trans))
                            {
                                cmdUser.Parameters.AddWithValue("@id", userId);
                                cmdUser.Parameters.AddWithValue("@email", email);
                                cmdUser.Parameters.AddWithValue("@role", role);
                                if (cmdUser.ExecuteNonQuery() != 1)
                                    throw new Exception("Failed to insert user login record.");
                            }

                            trans.Commit();

                            ShowSweetAlert("Success!", "Patron account registered successfully.", "success");
                            ClearFields();
                        }
                        catch (MySqlException ex)
                        {
                            trans.Rollback();
                            if (ex.Number == 1062) // Duplicate entry
                                ShowSweetAlert("Conflict", "ID Number or Email already exists.", "error");
                            else
                                ShowSweetAlert("Database Error", ex.Message, "error");
                        }
                        catch (Exception ex)
                        {
                            trans.Rollback();
                            ShowSweetAlert("System Error", ex.Message, "error");
                        }
                    }
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Connection Error", "Unable to connect to database.", "error");
                    System.Diagnostics.Debug.WriteLine("DB Connection Error: " + ex.Message);
                }
            }
        }

        private string GetPatronInsertSql(string role)
        {
            if (role == "student")
                return @"INSERT INTO Students 
                         (student_id, first_name, middle_name, last_name, extension_name, 
                          gender, mobile_number, email, institute, course, section, year_level) 
                         VALUES 
                         (@id, @fname, @mname, @lname, @ext, @gender, @mobile, @email, @inst, @course, @sec, @year)";
            if (role == "faculty")
                return @"INSERT INTO Faculty 
                         (faculty_id, first_name, middle_name, last_name, extension_name, 
                          gender, mobile_number, email, institute) 
                         VALUES 
                         (@id, @fname, @mname, @lname, @ext, @gender, @mobile, @email, @inst)";

            // Staff
            int isHead = (txtOffice.Text.Trim() == "Head Office") ? 1 : 0;
            return $@"INSERT INTO Staff 
                      (staff_id, first_name, last_name, email, office_department, is_head_librarian) 
                      VALUES 
                      (@id, @fname, @lname, @email, @office, {isHead})";
        }

        private void AddPatronParameters(MySqlCommand cmd, string role)
        {
            cmd.Parameters.AddWithValue("@id", txtID.Text.Trim());
            cmd.Parameters.AddWithValue("@fname", txtFName.Text.Trim());
            cmd.Parameters.AddWithValue("@lname", txtLName.Text.Trim());
            cmd.Parameters.AddWithValue("@email", txtEmail.Text.Trim());

            if (role != "staff")
            {
                cmd.Parameters.AddWithValue("@mname", txtMName.Text.Trim());
                cmd.Parameters.AddWithValue("@ext", txtExt.Text.Trim());
                cmd.Parameters.AddWithValue("@gender", ddlGender.SelectedValue);
                cmd.Parameters.AddWithValue("@mobile", txtMobile.Text.Trim());

                string institute = (role == "student") ? txtInst.Text.Trim() : txtFacInst.Text.Trim();
                cmd.Parameters.AddWithValue("@inst", institute);
            }

            if (role == "student")
            {
                cmd.Parameters.AddWithValue("@course", txtCourse.Text.Trim());
                cmd.Parameters.AddWithValue("@sec", txtSec.Text.Trim());
                cmd.Parameters.AddWithValue("@year", txtYear.Text.Trim());
            }
            else if (role == "staff")
            {
                cmd.Parameters.AddWithValue("@office", txtOffice.Text.Trim());
            }
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $@"Swal.fire({{ title: '{cleanTitle}', text: '{cleanMsg}', icon: '{icon}', confirmButtonColor: '#002447' }});";
            ScriptManager.RegisterStartupScript(this, GetType(), "alert", script, true);
        }

        private void ClearFields()
        {
            ddlCategory.SelectedIndex = 0;
            txtID.Text = "";
            txtEmail.Text = "";
            txtFName.Text = "";
            txtMName.Text = "";
            txtLName.Text = "";
            txtExt.Text = "";
            ddlGender.SelectedIndex = 0;
            txtMobile.Text = "";
            txtInst.Text = "";
            txtCourse.Text = "";
            txtSec.Text = "";
            txtYear.Text = "";
            txtFacInst.Text = "";
            txtOffice.Text = "";

            // Hide all dynamic panels
            pnlStudent.Visible = false;
            pnlFaculty.Visible = false;
            pnlStaff.Visible = false;
        }
    }
}