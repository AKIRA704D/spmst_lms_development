using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

#pragma warning disable IDE1006, CA1707, SA1300

namespace spmst_lms_development.Users.Staff.Accounts
{
    public partial class UserAcc : System.Web.UI.Page
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private string currentUser = "";

        // Applied to every "active users" list query; archived users must
        // only ever surface through the dedicated Archived view.
        private const string ArchivedExclusion = " AND u.is_active <> 3 ";

        protected void Page_Load(object sender, EventArgs e)
        {
            currentUser = Session["UserID"]?.ToString() ?? "SYSTEM";

            if (!IsPostBack)
            {
                if (Request.QueryString["isFilter"] == "1")
                {
                    string role = Request.QueryString["role"];
                    if (role == "Student") ViewState["CurrentFilter"] = "student";
                    else if (role == "Faculty") ViewState["CurrentFilter"] = "faculty";
                    else ViewState["CurrentFilter"] = "all";
                    BindFilteredPatrons();
                }
                else
                {
                    if (ViewState["CurrentFilter"] == null)
                        ViewState["CurrentFilter"] = "all";
                    LoadPatrons(ViewState["CurrentFilter"].ToString());
                }
                SetActiveTab();
                this.DataBind();
            }
        }

        private void SetActiveTab()
        {
            string currentFilter = ViewState["CurrentFilter"]?.ToString() ?? "all";

            tabAll.Attributes["class"] = "nav-link";
            tabFaculty.Attributes["class"] = "nav-link";
            tabStudent.Attributes["class"] = "nav-link";
            tabStaff.Attributes["class"] = "nav-link";
            tabArchived.Attributes["class"] = "btn btn-sm btn-outline-dark";

            switch (currentFilter.ToLower())
            {
                case "faculty": tabFaculty.Attributes["class"] = "nav-link active"; break;
                case "student": tabStudent.Attributes["class"] = "nav-link active"; break;
                case "staff": tabStaff.Attributes["class"] = "nav-link active"; break;
                case "archived": tabArchived.Attributes["class"] = "btn btn-sm btn-dark"; break;
                default: tabAll.Attributes["class"] = "nav-link active"; break;
            }
        }

        private void BindFilteredPatrons()
        {
            string role = Request.QueryString["role"];
            string inst = Request.QueryString["inst"]?.Replace("'", "''");
            string prog = Request.QueryString["prog"]?.Replace("'", "''");
            string year = Request.QueryString["year"]?.Replace("'", "''");
            string stat = Request.QueryString["stat"];

            string sql;

            if (role == "Student")
            {
                sql = @"SELECT s.student_id as user_id, CONCAT(s.first_name, ' ', s.last_name) as full_name,
                        s.extension_name as ext_name, s.gender, s.institute, s.course, '' as section, s.year_level,
                        u.role as display_role, CAST(u.is_active AS SIGNED) as is_active, '' as office_dept,
                        u.archived_at
                        FROM Students s INNER JOIN Users u ON s.student_id = u.user_id
                        WHERE 1=1 " + ArchivedExclusion;
                if (!string.IsNullOrEmpty(inst)) sql += " AND s.institute = '" + inst + "'";
                if (!string.IsNullOrEmpty(prog)) sql += " AND s.course = '" + prog + "'";
                if (!string.IsNullOrEmpty(year)) sql += " AND s.year_level = '" + year + "'";
            }
            else if (role == "Faculty")
            {
                sql = @"SELECT f.faculty_id as user_id, CONCAT(f.first_name, ' ', f.last_name) as full_name,
                        f.extension_name as ext_name, f.gender, f.institute, '' as course, '' as section, '' as year_level,
                        u.role as display_role, CAST(u.is_active AS SIGNED) as is_active, '' as office_dept,
                        u.archived_at
                        FROM Faculty f INNER JOIN Users u ON f.faculty_id = u.user_id
                        WHERE 1=1 " + ArchivedExclusion;
                if (!string.IsNullOrEmpty(inst)) sql += " AND f.institute = '" + inst + "'";
            }
            else
            {
                sql = @"SELECT u.user_id, u.role as display_role, CAST(u.is_active AS SIGNED) as is_active,
                        COALESCE(CONCAT(s.first_name, ' ', s.last_name), CONCAT(f.first_name, ' ', f.last_name)) as full_name,
                        COALESCE(s.extension_name, f.extension_name, '') as ext_name,
                        COALESCE(s.gender, f.gender, '') as gender,
                        COALESCE(s.institute, f.institute, '') as institute,
                        COALESCE(s.course, '') as course,
                        '' as section,
                        COALESCE(s.year_level, '') as year_level, '' as office_dept, u.archived_at
                        FROM Users u
                        LEFT JOIN Students s ON u.user_id = s.student_id
                        LEFT JOIN Faculty  f ON u.user_id = f.faculty_id
                        WHERE u.role IN ('Student', 'Faculty') " + ArchivedExclusion;
                if (!string.IsNullOrEmpty(inst)) sql += " AND (s.institute = '" + inst + "' OR f.institute = '" + inst + "')";
            }

            if (!string.IsNullOrEmpty(stat) && int.TryParse(stat, out int statInt) && statInt >= 0 && statInt <= 3)
                sql += " AND u.is_active = " + statInt;

            DataTable dt = ExecuteQuery(sql);
            rptPatrons.DataSource = dt;
            rptPatrons.DataBind();
        }

        protected void FilterTab_Click(object sender, EventArgs e)
        {
            System.Web.UI.HtmlControls.HtmlButton btn = (System.Web.UI.HtmlControls.HtmlButton)sender;
            string filter = btn.ID.Replace("tab", "").ToLower();
            ViewState["CurrentFilter"] = filter;
            SetActiveTab();
            LoadPatrons(filter, txtSearch.Text.Trim());
        }

        // -----------------------------------------------------------------
        //  Deactivate / Reactivate (unchanged)
        // -----------------------------------------------------------------
        protected void HandleAccountAction(object sender, CommandEventArgs e)
        {
            ToggleAccountStatus(e.CommandArgument.ToString());
        }

        private void ToggleAccountStatus(string userId)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                try
                {
                    conn.Open();
                    string checkSql = "SELECT CAST(is_active AS SIGNED) FROM Users WHERE user_id = @id";
                    int currentStatus = 0;
                    using (MySqlCommand checkCmd = new MySqlCommand(checkSql, conn))
                    {
                        checkCmd.Parameters.AddWithValue("@id", userId);
                        object result = checkCmd.ExecuteScalar();
                        if (result != null && result != DBNull.Value)
                            currentStatus = Convert.ToInt32(result);
                        else
                        {
                            ShowSweetAlert("Error: User ID not found.", "error");
                            return;
                        }
                    }

                    if (currentStatus == 3)
                    {
                        ShowSweetAlert("This account is archived and cannot be toggled.", "error");
                        return;
                    }

                    int newStatus = (currentStatus == 2) ? 1 : 2;
                    string updateSql = "UPDATE Users SET is_active = @status WHERE user_id = @id AND is_active <> 3";
                    using (MySqlCommand updateCmd = new MySqlCommand(updateSql, conn))
                    {
                        updateCmd.Parameters.Add("@status", MySqlDbType.Int32).Value = newStatus;
                        updateCmd.Parameters.Add("@id", MySqlDbType.VarChar).Value = userId;
                        if (updateCmd.ExecuteNonQuery() > 0)
                            ShowSweetAlert(newStatus == 1
                                ? "Account re-activated successfully."
                                : "Account deactivated successfully.", "success");
                        else
                            ShowSweetAlert("Account could not be updated (it may have been archived concurrently).", "error");
                    }

                    string filter = ViewState["CurrentFilter"]?.ToString() ?? "all";
                    LoadPatrons(filter, txtSearch.Text.Trim());
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Trace.TraceError("ToggleAccountStatus failed: " + ex);
                    ShowSweetAlert("An error occurred while updating the account. Please try again.", "error");
                }
            }
        }

        // =================================================================
        //  ARCHIVAL (phase 1) — validate + confirmation
        // =================================================================
        protected void HandleDeleteAccount(object sender, CommandEventArgs e)
        {
            string userId = Convert.ToString(e.CommandArgument);
            if (string.IsNullOrWhiteSpace(userId))
            {
                ShowSweetAlert("Invalid account identifier.", "error");
                return;
            }

            if (string.Equals(userId, currentUser, StringComparison.OrdinalIgnoreCase))
            {
                ShowSweetAlert("You cannot archive your own account.", "error");
                return;
            }

            string blockingReason;
            try
            {
                using (MySqlConnection conn = new MySqlConnection(connStr))
                {
                    conn.Open();
                    blockingReason = GetArchiveBlockingReason(conn, null, userId);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.TraceError("Archive pre-check failed: " + ex);
                ShowSweetAlert("Could not validate this account. Please try again.", "error");
                return;
            }

            if (!string.IsNullOrEmpty(blockingReason))
            {
                ShowSweetAlert(blockingReason, "error");
                return;
            }

            ViewState["PendingArchiveUserId"] = userId;

            string script = @"
                (function () {
                    Swal.fire({
                        title: 'Archive this account?',
                        html: 'The account will be <b>archived</b>, not permanently deleted.<br/>' +
                              'Historical transactions, fines and payments will be preserved.',
                        icon: 'question',
                        showCancelButton: true,
                        confirmButtonText: 'Yes, archive it',
                        cancelButtonText: 'Cancel',
                        confirmButtonColor: '#dc3545'
                    }).then(function (r) {
                        if (r.isConfirmed) {
                            var b = document.getElementById('" + btnConfirmArchive.ClientID + @"');
                            if (b) b.click();
                        }
                    });
                })();";
            ScriptManager.RegisterStartupScript(this, GetType(), "confirmArchive", script, true);
        }

        // =================================================================
        //  ARCHIVAL (phase 2) — lock, revalidate, commit
        // =================================================================
        protected void btnConfirmArchive_Click(object sender, EventArgs e)
        {
            string userId = ViewState["PendingArchiveUserId"]?.ToString();
            ViewState.Remove("PendingArchiveUserId");

            if (string.IsNullOrEmpty(userId))
            {
                ShowSweetAlert("The archive request has expired. Please try again.", "error");
                return;
            }

            if (string.Equals(userId, currentUser, StringComparison.OrdinalIgnoreCase))
            {
                ShowSweetAlert("You cannot archive your own account.", "error");
                return;
            }

            try
            {
                using (MySqlConnection conn = new MySqlConnection(connStr))
                {
                    conn.Open();
                    using (MySqlTransaction trans = conn.BeginTransaction())
                    {
                        try
                        {
                            int isActive;
                            using (MySqlCommand lockCmd = new MySqlCommand(
                                "SELECT CAST(is_active AS SIGNED) FROM Users WHERE user_id = @id FOR UPDATE",
                                conn, trans))
                            {
                                lockCmd.Parameters.Add("@id", MySqlDbType.VarChar).Value = userId;
                                object r = lockCmd.ExecuteScalar();
                                if (r == null || r == DBNull.Value)
                                {
                                    trans.Rollback();
                                    ShowSweetAlert("Account no longer exists.", "error");
                                    return;
                                }
                                isActive = Convert.ToInt32(r);
                            }

                            if (isActive == 3)
                            {
                                trans.Rollback();
                                ShowSweetAlert("This account is already archived.", "info");
                                return;
                            }

                            string reason = GetArchiveBlockingReason(conn, trans, userId);
                            if (!string.IsNullOrEmpty(reason))
                            {
                                trans.Rollback();
                                ShowSweetAlert(reason, "error");
                                return;
                            }

                            const string archiveSql = @"
                                UPDATE Users
                                   SET is_active       = 3,
                                       archived_at     = COALESCE(archived_at, CURRENT_TIMESTAMP),
                                       archived_reason = COALESCE(archived_reason,
                                            'Account archived by librarian through User Account Management.')
                                 WHERE user_id = @id
                                   AND is_active <> 3";
                            int affected;
                            using (MySqlCommand archiveCmd = new MySqlCommand(archiveSql, conn, trans))
                            {
                                archiveCmd.Parameters.Add("@id", MySqlDbType.VarChar).Value = userId;
                                affected = archiveCmd.ExecuteNonQuery();
                            }

                            if (affected == 0)
                            {
                                trans.Rollback();
                                ShowSweetAlert("The account could not be archived (it may have been modified concurrently). Please refresh and try again.", "warning");
                                return;
                            }

                            trans.Commit();
                            ShowSweetAlert("User account archived successfully. Historical library records have been preserved.", "success");

                            LoadPatrons(ViewState["CurrentFilter"]?.ToString() ?? "all", txtSearch.Text.Trim());
                        }
                        catch (Exception ex)
                        {
                            try { trans.Rollback(); } catch { }
                            System.Diagnostics.Trace.TraceError("Archive transaction failed for " + userId + ": " + ex);
                            ShowSweetAlert("An error occurred while archiving the account. Please try again or contact the administrator.", "error");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.TraceError("Archive connection failed: " + ex);
                ShowSweetAlert("A database connection error occurred while archiving the account.", "error");
            }
        }

        // =================================================================
        //  RESTORE — reverse of archive; only for is_active = 3
        // =================================================================
        protected void HandleRestoreAccount(object sender, CommandEventArgs e)
        {
            string userId = Convert.ToString(e.CommandArgument);
            if (string.IsNullOrWhiteSpace(userId))
            {
                ShowSweetAlert("Invalid account identifier.", "error");
                return;
            }

            if (string.Equals(userId, currentUser, StringComparison.OrdinalIgnoreCase))
            {
                ShowSweetAlert("You cannot restore your own account.", "error");
                return;
            }

            try
            {
                using (MySqlConnection conn = new MySqlConnection(connStr))
                {
                    conn.Open();
                    int isActive;
                    using (MySqlCommand lockCmd = new MySqlCommand(
                        "SELECT CAST(is_active AS SIGNED) FROM Users WHERE user_id = @id FOR UPDATE",
                        conn))
                    {
                        lockCmd.Parameters.Add("@id", MySqlDbType.VarChar).Value = userId;
                        object r = lockCmd.ExecuteScalar();
                        if (r == null || r == DBNull.Value)
                        {
                            ShowSweetAlert("Account no longer exists.", "error");
                            return;
                        }
                        isActive = Convert.ToInt32(r);
                    }

                    if (isActive != 3)
                    {
                        ShowSweetAlert("This account is not archived.", "info");
                        return;
                    }

                    const string restoreSql = @"
                        UPDATE Users
                           SET is_active       = 1,
                               archived_at     = NULL,
                               archived_reason = NULL
                         WHERE user_id  = @id
                           AND is_active = 3";
                    int affected;
                    using (MySqlCommand restoreCmd = new MySqlCommand(restoreSql, conn))
                    {
                        restoreCmd.Parameters.Add("@id", MySqlDbType.VarChar).Value = userId;
                        affected = restoreCmd.ExecuteNonQuery();
                    }

                    if (affected == 0)
                    {
                        ShowSweetAlert("The account could not be restored (it may have been modified concurrently).", "warning");
                        return;
                    }

                    ShowSweetAlert("User account restored successfully.", "success");
                    LoadPatrons(ViewState["CurrentFilter"]?.ToString() ?? "all", txtSearch.Text.Trim());
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.TraceError("RestoreAccount failed: " + ex);
                ShowSweetAlert("An error occurred while restoring the account.", "error");
            }
        }

        private string GetArchiveBlockingReason(MySqlConnection conn, MySqlTransaction trans, string userId)
        {
            const string activeLoanSql = @"
                SELECT COUNT(*) FROM Transactions
                 WHERE user_id = @id AND status = 'Borrowed'";
            if (CountRows(conn, trans, activeLoanSql, userId) > 0)
                return "Deletion blocked: This user still has unreturned library items. Please process all outstanding returns first.";

            const string finesSql = @"
                SELECT COUNT(*) FROM Penalties
                 WHERE user_id = @id
                   AND (fine_amount - amount_paid) > 0";
            if (CountRows(conn, trans, finesSql, userId) > 0)
                return "Deletion blocked: This user has outstanding fines. Please settle all unpaid balances first.";

            const string pendingSql = @"
                SELECT
                  (SELECT COUNT(*) FROM Transactions
                    WHERE user_id = @id
                      AND status IN ('Reserved','Ready','Renewal'))
                + (SELECT COUNT(*) FROM Renewals r
                     INNER JOIN Transactions t ON r.transaction_id = t.transaction_id
                    WHERE t.user_id = @id
                      AND r.status = 'Pending')";
            if (CountRows(conn, trans, pendingSql, userId) > 0)
                return "Deletion blocked: This user has pending reservations or renewal requests. Please resolve all pending requests before proceeding.";

            return string.Empty;
        }

        private static long CountRows(MySqlConnection conn, MySqlTransaction trans, string sql, string userId)
        {
            using (MySqlCommand cmd = new MySqlCommand(sql, conn))
            {
                if (trans != null) cmd.Transaction = trans;
                cmd.Parameters.Add("@id", MySqlDbType.VarChar).Value = userId;
                object result = cmd.ExecuteScalar();
                return (result == null || result == DBNull.Value) ? 0L : Convert.ToInt64(result);
            }
        }

        // =================================================================
        //  LIST LOADING
        // =================================================================
        private void LoadPatrons(string filter, string searchTerm = "")
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                string sql;
                bool hasSearch = !string.IsNullOrEmpty(searchTerm);

                switch (filter.ToLower())
                {
                    case "student":
                        string studentSearch = hasSearch ? " AND (s.student_id LIKE @search OR s.first_name LIKE @search OR s.last_name LIKE @search OR s.course LIKE @search)" : "";
                        sql = $@"SELECT s.student_id as user_id, CONCAT(s.first_name, ' ', s.last_name) as full_name,
                                s.extension_name as ext_name, s.gender, s.institute, s.course, s.section, s.year_level,
                                u.role as display_role, CAST(u.is_active AS SIGNED) as is_active, '' as office_dept,
                                u.archived_at
                                FROM Students s INNER JOIN Users u ON s.student_id = u.user_id
                                WHERE 1=1 {ArchivedExclusion} {studentSearch}";
                        break;

                    case "faculty":
                        string facultySearch = hasSearch ? " AND (f.faculty_id LIKE @search OR f.first_name LIKE @search OR f.last_name LIKE @search)" : "";
                        sql = $@"SELECT f.faculty_id as user_id, CONCAT(f.first_name, ' ', f.last_name) as full_name,
                                f.extension_name as ext_name, f.gender, f.institute, '' as course, '' as section, '' as year_level,
                                u.role as display_role, CAST(u.is_active AS SIGNED) as is_active, '' as office_dept,
                                u.archived_at
                                FROM Faculty f INNER JOIN Users u ON f.faculty_id = u.user_id
                                WHERE 1=1 {ArchivedExclusion} {facultySearch}";
                        break;

                    case "staff":
                        string staffSearch = hasSearch ? " AND (st.staff_id LIKE @search OR st.first_name LIKE @search OR st.last_name LIKE @search OR st.office_department LIKE @search)" : "";
                        sql = $@"SELECT st.staff_id as user_id, CONCAT(st.first_name, ' ', st.last_name) as full_name,
                                st.extension_name as ext_name, st.gender, 'Library' as institute, '' as course, '' as section, '' as year_level,
                                u.role as display_role, CAST(u.is_active AS SIGNED) as is_active, st.office_department as office_dept,
                                u.archived_at
                                FROM Staff st INNER JOIN Users u ON st.staff_id = u.user_id
                                WHERE 1=1 {ArchivedExclusion} {staffSearch}";
                        break;

                    case "archived":
                        // All roles: student + faculty + staff (+ any orphaned
                        // user_id whose person row is gone). Includes search.
                        string archivedSearch = hasSearch
                            ? " AND (u.user_id LIKE @search " +
                              " OR s.first_name LIKE @search OR s.last_name LIKE @search " +
                              " OR f.first_name LIKE @search OR f.last_name LIKE @search " +
                              " OR st.first_name LIKE @search OR st.last_name LIKE @search)"
                            : "";
                        sql = $@"SELECT u.user_id,
                                       u.role as display_role,
                                       CAST(u.is_active AS SIGNED) as is_active,
                                       COALESCE(CONCAT(s.first_name, ' ', s.last_name),
                                                CONCAT(f.first_name, ' ', f.last_name),
                                                CONCAT(st.first_name, ' ', st.last_name),
                                                u.user_id) as full_name,
                                       COALESCE(s.extension_name, f.extension_name, st.extension_name, '') as ext_name,
                                       COALESCE(s.gender, f.gender, st.gender, '') as gender,
                                       COALESCE(s.institute, f.institute, 'Library') as institute,
                                       '' as course,
                                       '' as section,
                                       '' as year_level,
                                       COALESCE(st.office_department, '') as office_dept,
                                       u.archived_at
                                  FROM Users u
                                  LEFT JOIN Students s  ON u.user_id = s.student_id
                                  LEFT JOIN Faculty  f  ON u.user_id = f.faculty_id
                                  LEFT JOIN Staff    st ON u.user_id = st.staff_id
                                 WHERE u.is_active = 3 {archivedSearch}
                                 ORDER BY u.archived_at DESC, u.user_id";
                        break;

                    default:
                        string allSearch = hasSearch ? " AND (u.user_id LIKE @search OR s.first_name LIKE @search OR s.last_name LIKE @search OR f.first_name LIKE @search OR f.last_name LIKE @search OR s.course LIKE @search)" : "";
                        sql = $@"SELECT u.user_id, u.role as display_role, CAST(u.is_active AS SIGNED) as is_active,
                              COALESCE(CONCAT(s.first_name, ' ', s.last_name), CONCAT(f.first_name, ' ', f.last_name)) as full_name,
                              COALESCE(s.extension_name, f.extension_name, '') as ext_name,
                              COALESCE(s.gender, f.gender, '') as gender,
                              COALESCE(s.institute, f.institute) as institute,
                              COALESCE(s.course, '') as course,
                              COALESCE(s.year_level, '') as year_level,
                              '' as office_dept, u.archived_at
                              FROM Users u
                              LEFT JOIN Students s ON u.user_id = s.student_id
                              LEFT JOIN Faculty  f ON u.user_id = f.faculty_id
                              WHERE u.role IN ('Student', 'Faculty') {ArchivedExclusion} {allSearch}";
                        break;
                }

                try
                {
                    conn.Open();
                    using (MySqlCommand cmd = new MySqlCommand(sql, conn))
                    {
                        if (hasSearch)
                            cmd.Parameters.AddWithValue("@search", "%" + searchTerm + "%");
                        MySqlDataAdapter da = new MySqlDataAdapter(cmd);
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        rptPatrons.DataSource = dt;
                        rptPatrons.DataBind();
                        lblNoData.Visible = (dt.Rows.Count == 0);
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Trace.TraceError("LoadPatrons failed: " + ex);
                    ShowSweetAlert("An error occurred while loading the patron list.", "error");
                }
            }
        }

        private DataTable ExecuteQuery(string sql)
        {
            DataTable dt = new DataTable();
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                using (MySqlCommand cmd = new MySqlCommand(sql, conn))
                {
                    conn.Open();
                    using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                        da.Fill(dt);
                }
            }
            return dt;
        }

        // -----------------------------------------------------------------
        //  Data-binding helpers for the "Archived: …" label inside
        //  rptPatrons. Both methods must be null-safe because they are
        //  called for EVERY row — including non-archived rows where
        //  archived_at is DBNull.
        // -----------------------------------------------------------------
        protected bool IsArchivedVisible(object isActive, object archivedAt)
        {
            try
            {
                if (Convert.IsDBNull(isActive) || isActive == null) return false;
                if (Convert.ToInt32(isActive) != 3) return false;
                return archivedAt != null && !Convert.IsDBNull(archivedAt);
            }
            catch
            {
                return false;
            }
        }

        protected string GetArchivedMeta(object isActive, object archivedAt)
        {
            try
            {
                if (Convert.IsDBNull(isActive) || isActive == null) return string.Empty;
                if (Convert.ToInt32(isActive) != 3) return string.Empty;
                if (archivedAt == null || Convert.IsDBNull(archivedAt)) return string.Empty;

                return "<span class=\"archived-meta\">Archived: " +
                       Convert.ToDateTime(archivedAt).ToString("yyyy-MM-dd HH:mm") +
                       "</span>";
            }
            catch
            {
                return string.Empty;
            }
        }

        private void ShowSweetAlert(string message, string icon)
        {
            string cleanMsg = (message ?? string.Empty).Replace("\\", "\\\\").Replace("'", "\\'");
            string script = $"showSwal('Notification', '{cleanMsg}', '{icon}');";
            ScriptManager.RegisterStartupScript(this, GetType(), "swal", script, true);
        }

        protected void txtSearch_TextChanged(object sender, EventArgs e)
        {
            LoadPatrons(ViewState["CurrentFilter"]?.ToString() ?? "all", txtSearch.Text.Trim());
        }

        protected void btnRefreshTable_Click(object sender, EventArgs e)
        {
            LoadPatrons(ViewState["CurrentFilter"]?.ToString() ?? "all", txtSearch.Text.Trim());
            upMain.Update();
        }
    }
}