using MySql.Data.MySqlClient;
using spmst_lms_development.Assets.Helper.Reservations;
using System;
using System.Configuration;
using System.Data;
using System.Globalization;
using System.Web.UI;
using System.Web.UI.WebControls;
using static spmst_lms_development.Assets.Helper.Reservations.ReservationNotificationService;

namespace spmst_lms_development.Users.Staff.Reservation
{
    public partial class Reservations : System.Web.UI.Page
    {
        private readonly string _connStr =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadData();
                LoadExpiringSoon();
            }
        }

        /* ================================================================
         * MAIN TABLE
         * ================================================================ */
        private void LoadData()
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("transaction_id");
            dt.Columns.Add("user_id");
            dt.Columns.Add("patron_name");
            dt.Columns.Add("title");
            dt.Columns.Add("call_number");
            dt.Columns.Add("accession_number");
            dt.Columns.Add("cover_url");
            dt.Columns.Add("display_status");
            dt.Columns.Add("status_css");
            dt.Columns.Add("expiry_display");
            dt.Columns.Add("action_visible", typeof(bool));
            dt.Columns.Add("action_css");
            dt.Columns.Add("action_text");
            dt.Columns.Add("action_icon");
            dt.Columns.Add("row_css");

            string search = (txtSearchPatron.Text ?? string.Empty).Trim();

            string sql = @"
                SELECT
                    t.transaction_id,
                    t.user_id,
                    t.accession_number,
                    t.status,
                    t.updated_at,
                    t.remarks,
                    r.title,
                    r.call_number,
                    r.cover_path,
                    DATE_ADD(t.updated_at, INTERVAL 1 HOUR) AS expiry_at,
                    CASE
                        WHEN t.status = 'Ready'
                             AND t.updated_at <= NOW() - INTERVAL 1 HOUR THEN 1
                        WHEN t.status = 'Cancelled'
                             AND t.remarks LIKE 'Auto-cancelled: reservation expired%' THEN 1
                        ELSE 0
                    END AS is_expired,
                    COALESCE(
                        CONCAT(s.first_name,  ' ', s.last_name),
                        CONCAT(f.first_name,  ' ', f.last_name),
                        CONCAT(st.first_name, ' ', st.last_name)
                    ) AS patron_name
                FROM Transactions t
                INNER JOIN Item_Copies        c  ON t.accession_number = c.accession_number
                INNER JOIN Library_Resources  r  ON c.resource_id      = r.resource_id
                LEFT  JOIN Students           s  ON t.user_id          = s.student_id
                LEFT  JOIN Faculty            f  ON t.user_id          = f.faculty_id
                LEFT  JOIN Staff              st ON t.user_id          = st.staff_id
                WHERE t.status IN ('Reserved', 'Ready', 'Cancelled')
                  AND (t.status <> 'Cancelled'
                       OR t.updated_at >= NOW() - INTERVAL 24 HOUR)
                  AND t.return_date IS NULL";

            if (search.Length > 0)
            {
                sql += @" AND (
                            t.user_id         LIKE @search
                         OR s.last_name       LIKE @search
                         OR f.last_name       LIKE @search
                         OR st.last_name      LIKE @search
                         OR r.title           LIKE @search )";
            }

            sql += @"
                ORDER BY
                    CASE
                        WHEN t.status = 'Reserved' THEN 0
                        WHEN t.status = 'Ready'    THEN 1
                        WHEN t.status = 'Cancelled'
                             AND t.remarks LIKE 'Auto-cancelled: reservation expired%' THEN 2
                        ELSE 3
                    END,
                    t.updated_at DESC";

            using (var conn = new MySqlConnection(_connStr))
            using (var cmd = new MySqlCommand(sql, conn))
            {
                if (search.Length > 0)
                    cmd.Parameters.AddWithValue("@search", "%" + search + "%");

                conn.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        string rawStatus = Convert.ToString(reader["status"]);
                        bool isExpired = Convert.ToInt32(reader["is_expired"]) == 1;
                        DateTime updatedAt = Convert.ToDateTime(reader["updated_at"]);
                        DateTime? expiryAt = reader["expiry_at"] == DBNull.Value
                            ? (DateTime?)null
                            : Convert.ToDateTime(reader["expiry_at"]);

                        string displayStatus, statusCss, actionCss, actionText, actionIcon, rowCss;
                        bool actionVisible;
                        string expiryDisplay;

                        if (isExpired)
                        {
                            displayStatus = "Expired";
                            statusCss = "status-expired";
                            actionCss = "btn-action btn-action-muted";
                            actionText = "Expired";
                            actionIcon = "fas fa-ban";
                            actionVisible = false;
                            rowCss = "expired-row";
                            expiryDisplay = expiryAt.HasValue
                                ? "Expired at " + expiryAt.Value.ToString("MMM d, yyyy, h:mm tt", CultureInfo.InvariantCulture)
                                : "Expired at " + updatedAt.AddHours(1).ToString("MMM d, yyyy, h:mm tt", CultureInfo.InvariantCulture);
                        }
                        else if (string.Equals(rawStatus, "Cancelled", StringComparison.OrdinalIgnoreCase))
                        {
                            displayStatus = "Cancelled";
                            statusCss = "status-cancelled";
                            actionCss = "btn-action btn-action-muted";
                            actionText = "Cancelled";
                            actionIcon = "fas fa-ban";
                            actionVisible = false;
                            rowCss = "";
                            expiryDisplay = "\u2014";
                        }
                        else if (string.Equals(rawStatus, "Ready", StringComparison.OrdinalIgnoreCase))
                        {
                            displayStatus = "Ready";
                            statusCss = "status-ready";
                            actionCss = "btn-action btn-action-muted";
                            actionText = "Notified";
                            actionIcon = "fas fa-check-circle";
                            actionVisible = false;
                            rowCss = "";
                            expiryDisplay = expiryAt.HasValue
                                ? "Valid until " + expiryAt.Value.ToString("MMM d, yyyy, h:mm tt", CultureInfo.InvariantCulture)
                                : "\u2014";
                        }
                        else /* Reserved */
                        {
                            displayStatus = "Reserved";
                            statusCss = "status-reserved";
                            actionCss = "btn-action btn-action-ready";
                            actionText = "Mark Ready & Notify";
                            actionIcon = "fas fa-bell-concierge";
                            actionVisible = true;
                            rowCss = "";
                            expiryDisplay = "Waiting for staff";
                        }

                        dt.Rows.Add(
                            Convert.ToInt32(reader["transaction_id"]).ToString(CultureInfo.InvariantCulture),
                            Convert.ToString(reader["user_id"]),
                            reader["patron_name"] == DBNull.Value ? "Unknown Patron" : Convert.ToString(reader["patron_name"]),
                            Convert.ToString(reader["title"]),
                            reader["call_number"] == DBNull.Value ? "\u2014" : Convert.ToString(reader["call_number"]),
                            Convert.ToString(reader["accession_number"]),
                            ResolveCoverUrl(reader["cover_path"]),
                            displayStatus,
                            statusCss,
                            expiryDisplay,
                            actionVisible,
                            actionCss,
                            actionText,
                            actionIcon,
                            rowCss
                        );
                    }
                }
            }

            rptReservations.DataSource = dt;
            rptReservations.DataBind();

            litTotalHolds.Text = dt.Rows.Count.ToString(CultureInfo.InvariantCulture);
            pnlEmptyReservations.Visible = dt.Rows.Count == 0;
        }

        /* ================================================================
         * EXPIRING SOON (Ready, > 0s and <= 1200s remaining)
         * ================================================================ */
        private void LoadExpiringSoon()
        {
            const string sql = @"
                SELECT
                    r.title,
                    r.cover_path,
                    t.accession_number,
                    t.user_id,
                    COALESCE(
                        CONCAT(s.first_name,  ' ', s.last_name),
                        CONCAT(f.first_name,  ' ', f.last_name),
                        CONCAT(st.first_name, ' ', st.last_name)
                    ) AS patron_name,
                    TIMESTAMPDIFF(SECOND, NOW(), DATE_ADD(t.updated_at, INTERVAL 1 HOUR)) AS seconds_left,
                    DATE_ADD(t.updated_at, INTERVAL 1 HOUR) AS expiry_at
                FROM Transactions t
                INNER JOIN Item_Copies       c  ON t.accession_number = c.accession_number
                INNER JOIN Library_Resources r  ON c.resource_id      = r.resource_id
                LEFT  JOIN Students          s  ON t.user_id          = s.student_id
                LEFT  JOIN Faculty           f  ON t.user_id          = f.faculty_id
                LEFT  JOIN Staff             st ON t.user_id          = st.staff_id
                WHERE t.status = 'Ready'
                  AND t.return_date IS NULL
                  AND TIMESTAMPDIFF(SECOND, NOW(), DATE_ADD(t.updated_at, INTERVAL 1 HOUR)) > 0
                  AND TIMESTAMPDIFF(SECOND, NOW(), DATE_ADD(t.updated_at, INTERVAL 1 HOUR)) <= 1200
                ORDER BY t.updated_at ASC";

            DataTable dt = new DataTable();
            using (var conn = new MySqlConnection(_connStr))
            using (var da = new MySqlDataAdapter(sql, conn))
            {
                da.Fill(dt);
            }

            dt.Columns.Add("cover_url", typeof(string));
            dt.Columns.Add("expiry_display", typeof(string));
            dt.Columns.Add("expiry_ticks", typeof(long));

            foreach (DataRow row in dt.Rows)
            {
                row["cover_url"] = ResolveCoverUrl(row["cover_path"]);

                if (row["expiry_at"] != DBNull.Value)
                {
                    DateTime expiry = Convert.ToDateTime(row["expiry_at"]);
                    row["expiry_display"] = expiry.ToString("MMM d, yyyy, h:mm tt", CultureInfo.InvariantCulture);
                    row["expiry_ticks"] = expiry.Ticks;
                }
                else
                {
                    row["expiry_display"] = "\u2014";
                    row["expiry_ticks"] = 0L;
                }
            }

            rptExpiring.DataSource = dt;
            rptExpiring.DataBind();

            litExpiringCount.Text = dt.Rows.Count.ToString(CultureInfo.InvariantCulture);
            phNoExpiring.Visible = dt.Rows.Count == 0;
        }

        /* ================================================================
         * MARK READY & NOTIFY
         * ================================================================ */
        protected void HandleAction_Click(object sender, EventArgs e)
        {
            var btn = (LinkButton)sender;
            int txnId;
            if (!int.TryParse(Convert.ToString(btn.CommandArgument), out txnId))
            {
                ShowSweetAlert("Error", "Invalid transaction.", "error");
                return;
            }

            bool transitioned = false;
            string errMsg = null;

            using (var conn = new MySqlConnection(_connStr))
            {
                conn.Open();
                using (var trans = conn.BeginTransaction())
                {
                    try
                    {
                        /* 1. Ensure status is Reserved (idempotent, no duplicate notifications). */
                        const string updateSql = @"
                            UPDATE Transactions
                               SET status = 'Ready'
                             WHERE transaction_id = @tid
                               AND status = 'Reserved'
                               AND return_date IS NULL";

                        using (var cmd = new MySqlCommand(updateSql, conn, trans))
                        {
                            cmd.Parameters.AddWithValue("@tid", txnId);
                            if (cmd.ExecuteNonQuery() == 1)
                                transitioned = true;
                        }

                        if (!transitioned)
                        {
                            trans.Rollback();
                            ShowSweetAlert("Info",
                                "This reservation may have already been processed or has expired.",
                                "info");
                            LoadData();
                            LoadExpiringSoon();
                            return;
                        }

                        trans.Commit();
                    }
                    catch (Exception ex)
                    {
                        try { trans.Rollback(); } catch { }
                        errMsg = ex.Message;
                    }
                }
            }

            if (!string.IsNullOrEmpty(errMsg))
            {
                ShowSweetAlert("Error", errMsg, "error");
                LoadData();
                LoadExpiringSoon();
                return;
            }

            /* 2. Fire the existing notification service (SMS + Email + In-App). */
            ReservationNotificationResult nr = null;
            try
            {
                nr = ReservationNotificationService.SendReservationReadyNotifications(txnId);
            }
            catch
            {
                /* Notification failures must not break the UI flow. */
            }

            if (nr != null)
            {
                bool anyOk = nr.Sms.Status == "Success"
                          || nr.Email.Status == "Success"
                          || nr.Push.Status == "Success";

                string summary = string.Format(
                    "SMS: {0} | Email: {1} | In-App: {2}",
                    nr.Sms.Status, nr.Email.Status, nr.Push.Status);

                ShowSweetAlert(anyOk ? "Success" : "Warning",
                    "Book marked as Ready. " + summary,
                    anyOk ? "success" : "warning");
            }
            else
            {
                ShowSweetAlert("Success", "Book marked as Ready.", "success");
            }

            LoadData();
            LoadExpiringSoon();
        }

        protected void FilterReservations(object sender, EventArgs e)
        {
            LoadData();
        }

        /* ================================================================
         * Helpers
         * ================================================================ */
        private void ShowSweetAlert(string title, string message, string icon)
        {
            string script = string.Format(
                "showSweetAlert({0},{1},{2});",
                JsString(title), JsString(message), JsString(icon));

            ScriptManager.RegisterStartupScript(this, GetType(),
                Guid.NewGuid().ToString(), script, true);
        }

        private static string JsString(string value)
        {
            return System.Web.HttpUtility.JavaScriptStringEncode(value ?? string.Empty, true);
        }

        private string ResolveCoverUrl(object coverObj)
        {
            string defaultUrl = ResolveUrl("~/Assets/Covers/default-cover.jpg");

            string raw = coverObj == null || coverObj == DBNull.Value
                ? string.Empty : coverObj.ToString().Trim();
            if (string.IsNullOrWhiteSpace(raw)) return defaultUrl;

            if (raw.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                raw.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
                return raw;

            string normalized = raw.Replace('\\', '/').Trim();
            if (normalized.Contains("..")) return defaultUrl;

            int assetsIndex = normalized.IndexOf("Assets/", StringComparison.OrdinalIgnoreCase);

            string appRelative;
            if (assetsIndex >= 0) appRelative = "~/" + normalized.Substring(assetsIndex);
            else if (normalized.StartsWith("~/", StringComparison.Ordinal)) appRelative = normalized;
            else if (normalized.StartsWith("/", StringComparison.Ordinal)) appRelative = "~" + normalized;
            else if (!normalized.Contains("/")) appRelative = "~/Assets/Covers/" + normalized;
            else appRelative = "~/" + normalized.TrimStart('/');

            try
            {
                string physical = Server.MapPath(appRelative);
                if (!string.IsNullOrEmpty(physical) && System.IO.File.Exists(physical))
                    return ResolveUrl(appRelative);
            }
            catch { }

            return defaultUrl;
        }

        protected string GetCountdownClass(object secondsLeft)
        {
            int secs;
            if (secondsLeft == null || secondsLeft == DBNull.Value ||
                !int.TryParse(secondsLeft.ToString(), out secs))
                return "countdown-warn";

            if (secs <= 0) return "countdown-done";
            if (secs <= 300) return "countdown-urgent";
            return "countdown-warn";
        }

        protected string FormatTimeLeft(object secondsLeft)
        {
            int secs;
            if (secondsLeft == null || secondsLeft == DBNull.Value ||
                !int.TryParse(secondsLeft.ToString(), out secs))
                return "\u2014";

            if (secs <= 0) return "Expiring now";
            int m = secs / 60;
            int s = secs % 60;
            return m + ":" + (s < 10 ? "0" : "") + s + " left";
        }
    }
}