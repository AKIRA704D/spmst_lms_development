using ClosedXML.Excel;
using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Text.RegularExpressions;
using System.Web.UI;

namespace spmst_lms_development.Users.Staff.Accounts
{
    public partial class userUpdate : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private string currentUser = "";

        // Persisted so it survives postback (needed by GetChanges)
        private string OriginalData
        {
            get { return ViewState["OriginalData"]?.ToString() ?? ""; }
            set { ViewState["OriginalData"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            currentUser = Session["UserID"]?.ToString() ?? "SYSTEM";

            if (!IsPostBack)
            {
                string userId = Request.QueryString["UserID"];
                if (string.IsNullOrEmpty(userId))
                {
                    ShowErrorAndClose("No user ID provided.");
                    return;
                }

                LoadPatronData(userId);
                CaptureOriginalData();
            }
        }

        private void CaptureOriginalData()
        {
            OriginalData = string.Join("|", new[]
            {
                txtFName.Text, txtLName.Text, txtEmail.Text, txtMName.Text, txtExt.Text,
                ddlGender.SelectedValue, txtMobile.Text, txtInst.Text, txtCourse.Text,
                txtSec.Text, txtYear.Text, txtFacInst.Text, txtOffice.Text,
                txtAddress.Text, chkHeadLibrarian.Checked ? "1" : "0"
            });
        }

        private string GetChanges(string role)
        {
            var changes = new System.Text.StringBuilder();
            string[] orig = OriginalData.Split('|');
            if (orig.Length < 15) return "";

            if (txtFName.Text != orig[0]) changes.Append($"First Name: {orig[0]} → {txtFName.Text}; ");
            if (txtLName.Text != orig[1]) changes.Append($"Last Name: {orig[1]} → {txtLName.Text}; ");
            if (txtEmail.Text != orig[2]) changes.Append($"Email: {orig[2]} → {txtEmail.Text}; ");
            if (txtMName.Text != orig[3]) changes.Append($"Middle Name: {orig[3]} → {txtMName.Text}; ");
            if (txtExt.Text != orig[4]) changes.Append($"Extension: {orig[4]} → {txtExt.Text}; ");
            if (ddlGender.SelectedValue != orig[5]) changes.Append($"Gender: {orig[5]} → {ddlGender.SelectedValue}; ");
            if (txtMobile.Text != orig[6]) changes.Append($"Mobile: {orig[6]} → {txtMobile.Text}; ");
            if (txtAddress.Text != orig[13]) changes.Append($"Address: {orig[13]} → {txtAddress.Text}; ");

            if (role == "student")
            {
                if (txtInst.Text != orig[7]) changes.Append($"Institute: {orig[7]} → {txtInst.Text}; ");
                if (txtCourse.Text != orig[8]) changes.Append($"Course: {orig[8]} → {txtCourse.Text}; ");
                if (txtSec.Text != orig[9]) changes.Append($"Section: {orig[9]} → {txtSec.Text}; ");
                if (txtYear.Text != orig[10]) changes.Append($"Year: {orig[10]} → {txtYear.Text}; ");
            }
            else if (role == "faculty")
            {
                if (txtFacInst.Text != orig[11]) changes.Append($"Institute: {orig[11]} → {txtFacInst.Text}; ");
            }
            else if (role == "staff" || role == "admin")
            {
                if (txtOffice.Text != orig[12]) changes.Append($"Office: {orig[12]} → {txtOffice.Text}; ");
                string headNow = chkHeadLibrarian.Checked ? "1" : "0";
                if (headNow != orig[14])
                    changes.Append($"Head Librarian: {(orig[14] == "1" ? "Yes" : "No")} → {(headNow == "1" ? "Yes" : "No")}; ");
            }

            return changes.ToString().TrimEnd(' ', ';');
        }

        private void LoadPatronData(string userId)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();
                string role = GetUserRole(conn, userId);
                if (string.IsNullOrEmpty(role)) return;

                txtRoleDisplay.Text = role.ToUpper();
                ViewState["CurrentRole"] = role;

                string sql;
                if (role == "student")
                    sql = "SELECT * FROM Students WHERE student_id = @id";
                else if (role == "faculty")
                    sql = "SELECT * FROM Faculty WHERE faculty_id = @id";
                else
                    sql = "SELECT * FROM Staff WHERE staff_id = @id";

                using (MySqlCommand cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@id", userId);
                    using (MySqlDataReader dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            txtID.Text = userId;
                            txtFName.Text = dr["first_name"].ToString();
                            txtLName.Text = dr["last_name"].ToString();
                            txtEmail.Text = dr["email"].ToString();

                            // ---- Personal fields exist on ALL three tables ----
                            txtMName.Text = dr["middle_name"].ToString();
                            txtExt.Text = dr["extension_name"].ToString();

                            string gender = dr["gender"].ToString();
                            if (!string.IsNullOrEmpty(gender))
                            {
                                var li = ddlGender.Items.FindByValue(gender);
                                if (li != null) ddlGender.ClearSelection();
                                if (li != null) li.Selected = true;
                            }

                            txtMobile.Text = FormatMobile(dr["mobile_number"].ToString());

                            // ---- Address exists on all three tables ----
                            txtAddress.Text = dr["address"].ToString();

                            if (role == "student")
                            {
                                pnlStudent.Visible = true;
                                txtInst.Text = dr["institute"].ToString();
                                txtCourse.Text = dr["course"].ToString();
                                txtSec.Text = dr["section"].ToString();
                                txtYear.Text = dr["year_level"].ToString();
                            }
                            else if (role == "faculty")
                            {
                                pnlFaculty.Visible = true;
                                txtFacInst.Text = dr["institute"].ToString();
                            }
                            else if (role == "staff" || role == "admin")
                            {
                                pnlStaff.Visible = true;
                                txtOffice.Text = dr["office_department"].ToString();
                                chkHeadLibrarian.Checked =
                                    dr["is_head_librarian"] != DBNull.Value &&
                                    Convert.ToInt32(dr["is_head_librarian"]) == 1;
                            }
                        }
                    }
                }
            }
        }

        private string FormatMobile(string raw)
        {
            string digits = Regex.Replace(raw ?? "", @"[^\d]", "");
            if (digits.Length <= 4) return digits;
            if (digits.Length <= 7) return digits.Substring(0, 4) + "-" + digits.Substring(4);
            if (digits.Length <= 11)
                return digits.Substring(0, 4) + "-" + digits.Substring(4, 3) + "-" + digits.Substring(7);
            return digits;
        }

        private string GetUserRole(MySqlConnection conn, string userId)
        {
            using (MySqlCommand cmd = new MySqlCommand("SELECT role FROM Users WHERE user_id = @id", conn))
            {
                cmd.Parameters.AddWithValue("@id", userId);
                object result = cmd.ExecuteScalar();
                return result?.ToString().ToLower() ?? "";
            }
        }

        protected void BtnUpdate_Click(object sender, EventArgs e)
        {
            string userId = txtID.Text.Trim();
            string email = txtEmail.Text.Trim();
            string fname = txtFName.Text.Trim();
            string lname = txtLName.Text.Trim();
            string role = ViewState["CurrentRole"]?.ToString() ?? "";

            if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(fname) || string.IsNullOrEmpty(lname))
            {
                ShowPopup("Please fill in all required fields.");
                return;
            }

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();
                using (MySqlTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        string updateSql;
                        if (role == "student")
                        {
                            updateSql = @"UPDATE Students SET first_name=@fname, middle_name=@mname, last_name=@lname, extension_name=@ext,
                                          gender=@gender, mobile_number=@mobile, email=@email, institute=@inst, course=@course,
                                          section=@sec, year_level=@year, address=@address WHERE student_id=@id";
                        }
                        else if (role == "faculty")
                        {
                            updateSql = @"UPDATE Faculty SET first_name=@fname, middle_name=@mname, last_name=@lname, extension_name=@ext,
                                          gender=@gender, mobile_number=@mobile, email=@email, institute=@inst, address=@address WHERE faculty_id=@id";
                        }
                        else
                        {
                            updateSql = @"UPDATE Staff SET first_name=@fname, middle_name=@mname, last_name=@lname, extension_name=@ext,
                                          gender=@gender, mobile_number=@mobile, email=@email, office_department=@office,
                                          is_head_librarian=@head, address=@address WHERE staff_id=@id";
                        }

                        using (MySqlCommand cmd = new MySqlCommand(updateSql, conn, trans))
                        {
                            cmd.Parameters.AddWithValue("@id", userId);
                            cmd.Parameters.AddWithValue("@fname", fname);
                            cmd.Parameters.AddWithValue("@lname", lname);
                            cmd.Parameters.AddWithValue("@email", email);
                            cmd.Parameters.AddWithValue("@mname", txtMName.Text.Trim());
                            cmd.Parameters.AddWithValue("@ext", txtExt.Text.Trim());
                            cmd.Parameters.AddWithValue("@gender", ddlGender.SelectedValue);
                            string rawMobile = Regex.Replace(txtMobile.Text.Trim(), @"[^\d]", "");
                            cmd.Parameters.AddWithValue("@mobile", rawMobile);
                            cmd.Parameters.AddWithValue("@address", txtAddress.Text.Trim());

                            if (role == "student")
                            {
                                cmd.Parameters.AddWithValue("@inst", txtInst.Text.Trim());
                                cmd.Parameters.AddWithValue("@course", txtCourse.Text.Trim());
                                cmd.Parameters.AddWithValue("@sec", txtSec.Text.Trim());
                                cmd.Parameters.AddWithValue("@year", txtYear.Text.Trim());
                            }
                            else if (role == "faculty")
                            {
                                cmd.Parameters.AddWithValue("@inst", txtFacInst.Text.Trim());
                            }
                            else if (role == "staff" || role == "admin")
                            {
                                cmd.Parameters.AddWithValue("@office", txtOffice.Text.Trim());
                                cmd.Parameters.AddWithValue("@head", chkHeadLibrarian.Checked ? 1 : 0);
                            }

                            if (cmd.ExecuteNonQuery() != 1)
                                throw new Exception("Role table update failed.");
                        }

                        using (MySqlCommand cmdUser = new MySqlCommand("UPDATE Users SET email = @email WHERE user_id = @id", conn, trans))
                        {
                            cmdUser.Parameters.AddWithValue("@email", email);
                            cmdUser.Parameters.AddWithValue("@id", userId);
                            if (cmdUser.ExecuteNonQuery() != 1)
                                throw new Exception("Users table update failed.");
                        }

                        trans.Commit();

                        // (Optional) capture change summary for logging:
                        string changes = GetChanges(role);

                        string successScript = $@"
                            window.parent.Swal.fire({{
                                icon: 'success',
                                title: 'Updated Successfully',
                                text: 'The account details have been updated.',
                                timer: 2000,
                                showConfirmButton: false
                            }}).then(function() {{
                                window.parent.refreshParentTable();
                                window.parent.closeUniversalModal();
                            }});";

                        ScriptManager.RegisterStartupScript(this, GetType(), "successUpdate", successScript, true);
                    }
                    catch (Exception ex)
                    {
                        trans.Rollback();
                        ShowPopup("Update Failed: " + ex.Message);
                    }
                }
            }
        }

        private void ShowPopup(string message)
        {
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"window.parent.Swal.fire({{ icon: 'error', title: 'Update Notice', text: '{cleanMsg}', confirmButtonColor: '#002447' }});";
            ScriptManager.RegisterStartupScript(this, GetType(), "alert", script, true);
        }

        private void ShowErrorAndClose(string message)
        {
            string script = $@"
                Swal.fire({{ icon: 'error', title: 'Error', text: '{message}', confirmButtonColor: '#002447' }}).then(function() {{
                    window.parent.closeUniversalModal();
                }});";
            ScriptManager.RegisterStartupScript(this, GetType(), "closeError", script, true);
        }
    }
}