using ClosedXML.Excel;
using MySql.Data.MySqlClient;
using spmst_lms_development.Users.Patron;
using System;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;

namespace spmst_lms_development.Users.Staff.Accounts
{
    public partial class userUpdate : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private string currentUser = "";

        // ---- Profile photo constants (mirrors userNew) ----
        private const string ProfileFolderVirtual = "~/Assets/Profile/";
        private const int MaxPhotoBytes = 5 * 1024 * 1024;
        private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".webp" };

        // Persisted so it survives postback
        private string OriginalData
        {
            get { return ViewState["OriginalData"]?.ToString() ?? ""; }
            set { ViewState["OriginalData"] = value; }
        }

        // The profile_path currently stored in the DB for this patron
        private string CurrentProfilePath
        {
            get { return ViewState["CurrentProfilePath"]?.ToString() ?? ""; }
            set { ViewState["CurrentProfilePath"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            currentUser = Session["UserID"]?.ToString() ?? "SYSTEM";

            // Guarantee multipart for the photo upload
            form1.Enctype = "multipart/form-data";

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

                            txtMName.Text = dr["middle_name"].ToString();
                            txtExt.Text = dr["extension_name"].ToString();

                            string gender = dr["gender"].ToString();
                            if (!string.IsNullOrEmpty(gender))
                            {
                                var li = ddlGender.Items.FindByValue(gender);
                                if (li != null)
                                {
                                    ddlGender.ClearSelection();
                                    li.Selected = true;
                                }
                            }

                            txtMobile.Text = FormatMobile(dr["mobile_number"].ToString());

                            // Address
                            txtAddress.Text = dr["address"] != DBNull.Value ? dr["address"].ToString() : "";

                            // ---------- PROFILE PHOTO ----------
                            // Raw value from DB (may be stale / may point to a missing file).
                            string profilePath = (dr["profile_path"] != DBNull.Value)
                                ? dr["profile_path"].ToString()
                                : "";
                            CurrentProfilePath = profilePath ?? "";

                            // Use the same resolution strategy as userView.
                            string resolved = ResolveProfileImage(profilePath);

                            if (!string.IsNullOrEmpty(resolved))
                            {
                                profilePreview.Src = resolved;
                                profilePreview.Style["display"] = "block";
                                profilePlaceholder.Style["display"] = "none";
                            }
                            else
                            {
                                profilePreview.Style["display"] = "none";
                                profilePlaceholder.Style["display"] = "block";
                            }

                            // Show Remove whenever the DB has a path — even if the
                            // physical file is missing, the user may want to clear it.
                            btnRemovePhoto.Style["display"] =
                                string.IsNullOrEmpty(CurrentProfilePath) ? "none" : "inline-block";
                            // --------------------------------------

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

        // =============================================================
        //  PROFILE PHOTO HELPERS
        // =============================================================

        /// <summary>
        /// Normalises a stored DB path into a "~/"-prefixed virtual path.
        /// Used only for physical file IO (save/delete/compare), NOT for display.
        /// </summary>
        private string NormalizeProfilePath(string raw)
        {
            if (string.IsNullOrEmpty(raw)) return "";
            string p = raw.Trim().Replace('\\', '/');
            if (p.StartsWith("~/")) return p;
            if (p.StartsWith("/")) return "~" + p;
            return "~/" + p;
        }

        /// <summary>
        /// Same resolution strategy as userView.aspx.cs:
        ///   1. Trim + normalise slashes.
        ///   2. Pass absolute URLs through untouched.
        ///   3. Prepend "~/" if the path is app-relative but has no prefix.
        ///   4. Verify the physical file exists via Server.MapPath + File.Exists.
        ///   5. Return ResolveUrl(...) if the file exists, else null.
        /// Returns null for NULL/empty/whitespace or a missing physical file.
        /// </summary>
        private string ResolveProfileImage(string profilePath)
        {
            if (string.IsNullOrWhiteSpace(profilePath)) return null;

            string raw = profilePath.Trim().Replace('\\', '/');

            if (raw.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                raw.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
                return raw;

            if (!raw.StartsWith("~/") && !raw.StartsWith("/"))
                raw = "~/" + raw;

            try
            {
                if (!File.Exists(Server.MapPath(raw)))
                    return null;
            }
            catch
            {
                return null;
            }

            return ResolveUrl(raw);
        }

        private string SaveProfilePhoto(string userId)
        {
            HttpPostedFile file = null;

            try
            {
                if (fuProfile != null && fuProfile.HasFile)
                    file = fuProfile.PostedFile;
            }
            catch { /* fall through */ }

            if (file == null || file.ContentLength <= 0)
            {
                if (Request.Files.Count > 0)
                {
                    file = Request.Files["fuProfile"];
                    if (file == null && fuProfile != null)
                        file = Request.Files[fuProfile.UniqueID];
                }
            }

            if (file == null || file.ContentLength <= 0)
                return null;

            string originalName = file.FileName ?? string.Empty;
            string ext = (Path.GetExtension(originalName) ?? string.Empty).ToLowerInvariant();

            if (!AllowedExtensions.Contains(ext))
                throw new Exception("Invalid image format. Allowed: JPG, JPEG, PNG, GIF, WEBP.");

            if (file.ContentLength > MaxPhotoBytes)
                throw new Exception("Profile photo must be 5 MB or smaller.");

            string physicalFolder = Server.MapPath(ProfileFolderVirtual);
            if (!Directory.Exists(physicalFolder))
                Directory.CreateDirectory(physicalFolder);

            string safeId = string.Join("_", (userId ?? "user").Split(Path.GetInvalidFileNameChars()));
            if (string.IsNullOrEmpty(safeId)) safeId = "user";

            string fileName = $"{safeId}_{DateTime.Now:yyyyMMddHHmmssfff}{ext}";
            string physicalPath = Path.Combine(physicalFolder, fileName);

            file.SaveAs(physicalPath);

            return ProfileFolderVirtual + fileName;
        }

        private void DeleteProfilePhoto(string virtualPath)
        {
            if (string.IsNullOrEmpty(virtualPath)) return;
            try
            {
                string virt = NormalizeProfilePath(virtualPath);
                string physical = Server.MapPath(virt);
                if (File.Exists(physical)) File.Delete(physical);
            }
            catch { /* best-effort */ }
        }

        // =============================================================
        //  UPDATE
        // =============================================================

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

            // ---------- Determine the photo action ----------
            string existingProfilePath = CurrentProfilePath ?? "";
            string finalProfilePath = existingProfilePath;   // default = keep unchanged
            string newSavedFile = null;                      // physical file we created (if any)

            bool newFileSelected = (fuProfile != null && fuProfile.HasFile);
            bool removeRequested = string.Equals(hfRemovePhoto.Value, "1", StringComparison.Ordinal);

            if (newFileSelected)
            {
                try
                {
                    newSavedFile = SaveProfilePhoto(userId);
                    if (string.IsNullOrEmpty(newSavedFile))
                    {
                        ShowPopup("The selected file could not be read. Please try again.");
                        return;
                    }
                    finalProfilePath = newSavedFile;
                }
                catch (Exception ex)
                {
                    ShowPopup(ex.Message);
                    return;
                }
            }
            else if (removeRequested)
            {
                finalProfilePath = null;
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
                                          section=@sec, year_level=@year, address=@address, profile_path=@profilePath
                                          WHERE student_id=@id";
                        }
                        else if (role == "faculty")
                        {
                            updateSql = @"UPDATE Faculty SET first_name=@fname, middle_name=@mname, last_name=@lname, extension_name=@ext,
                                          gender=@gender, mobile_number=@mobile, email=@email, institute=@inst, address=@address,
                                          profile_path=@profilePath
                                          WHERE faculty_id=@id";
                        }
                        else
                        {
                            updateSql = @"UPDATE Staff SET first_name=@fname, middle_name=@mname, last_name=@lname, extension_name=@ext,
                                          gender=@gender, mobile_number=@mobile, email=@email, office_department=@office,
                                          is_head_librarian=@head, address=@address, profile_path=@profilePath
                                          WHERE staff_id=@id";
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

                            cmd.Parameters.AddWithValue("@profilePath",
                                string.IsNullOrEmpty(finalProfilePath) ? (object)DBNull.Value : finalProfilePath);

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

                        // ---- Post-commit: clean up the OLD physical photo ----
                        if (!string.IsNullOrEmpty(existingProfilePath))
                        {
                            string oldVirt = NormalizeProfilePath(existingProfilePath);
                            string newVirt = string.IsNullOrEmpty(finalProfilePath)
                                ? ""
                                : NormalizeProfilePath(finalProfilePath);

                            if (newFileSelected)
                            {
                                if (!string.Equals(oldVirt, newVirt, StringComparison.OrdinalIgnoreCase))
                                    DeleteProfilePhoto(existingProfilePath);
                            }
                            else if (removeRequested)
                            {
                                DeleteProfilePhoto(existingProfilePath);
                            }
                        }

                        // Keep server-side state in sync (for repeat saves without reload)
                        CurrentProfilePath = finalProfilePath ?? "";

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

                        // If the DB update failed, remove the NEW file we just saved
                        // (the OLD file stays untouched)
                        if (!string.IsNullOrEmpty(newSavedFile))
                            DeleteProfilePhoto(newSavedFile);

                        ShowPopup("Update Failed: " + ex.Message);
                    }
                }
            }
        }

        private void ShowPopup(string message)
        {
            string cleanMsg = message.Replace("\\", "\\\\").Replace("'", "\\'").Replace("\r", "").Replace("\n", "\\n");
            string script = $"window.parent.Swal.fire({{ icon: 'error', title: 'Update Notice', text: '{cleanMsg}', confirmButtonColor: '#002447' }});";
            ScriptManager.RegisterStartupScript(this, GetType(), "alert", script, true);
        }

        private void ShowErrorAndClose(string message)
        {
            string cleanMsg = message.Replace("\\", "\\\\").Replace("'", "\\'").Replace("\r", "").Replace("\n", "\\n");
            string script = $@"
                Swal.fire({{ icon: 'error', title: 'Error', text: '{cleanMsg}', confirmButtonColor: '#002447' }}).then(function() {{
                    window.parent.closeUniversalModal();
                }});";
            ScriptManager.RegisterStartupScript(this, GetType(), "closeError", script, true);
        }
    }
}