using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Patron.Reservations
{
    public partial class ToPickUp : System.Web.UI.Page
    {
        private readonly string connStr =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            string userId = Session["UserID"]?.ToString();

            if (string.IsNullOrEmpty(userId))
            {
                Response.Redirect("~/Login/login.aspx");
                return;
            }

            if (!IsPostBack)
            {
                LoadReservations();
            }
        }

        private void LoadReservations()
        {
            string userId = Session["UserID"]?.ToString();

            if (string.IsNullOrEmpty(userId))
            {
                Response.Redirect("~/Login/login.aspx");
                return;
            }

            int readyCount = 0;
            int processingCount = 0;

            try
            {
                using (MySqlConnection conn = new MySqlConnection(connStr))
                {
                    string query = @"
                        SELECT
                            t.transaction_id      AS TransactionID,
                            t.accession_number    AS AccessionNumber,
                            lr.title              AS Title,
                            lr.author             AS Author,
                            lr.cover_path         AS CoverPath,
                            t.borrow_date         AS ReservedDate,
                            t.status              AS Status,
                            t.remarks             AS Remarks,
                            DATE_ADD(t.updated_at, INTERVAL 1 HOUR) AS ExpiryAt,
                            CASE
                                WHEN t.status = 'Ready'
                                     AND t.updated_at <= NOW() - INTERVAL 1 HOUR
                                THEN 1
                                ELSE 0
                            END AS IsExpiredNow
                        FROM Transactions t
                        INNER JOIN Item_Copies ic
                            ON t.accession_number = ic.accession_number
                        INNER JOIN Library_Resources lr
                            ON ic.resource_id = lr.resource_id
                        WHERE t.user_id = @UserId
                          AND (
                                t.status IN ('Reserved', 'Ready')
                                OR (
                                    t.status = 'Cancelled'
                                    AND t.remarks LIKE 'Auto-cancelled: reservation expired%'
                                )
                          )
                        ORDER BY
                            CASE
                                WHEN t.status = 'Ready' THEN 0
                                WHEN t.status = 'Reserved' THEN 1
                                ELSE 2
                            END,
                            t.updated_at DESC";

                    using (MySqlCommand cmd = new MySqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@UserId", userId);

                        using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                        {
                            DataTable dt = new DataTable();
                            da.Fill(dt);

                            AddDisplayColumns(dt);

                            foreach (DataRow row in dt.Rows)
                            {
                                string status = Convert.ToString(row["Status"]);
                                bool isCancelled = string.Equals(
                                    status, "Cancelled", StringComparison.OrdinalIgnoreCase);
                                bool isReady = string.Equals(
                                    status, "Ready", StringComparison.OrdinalIgnoreCase);
                                bool isReserved = string.Equals(
                                    status, "Reserved", StringComparison.OrdinalIgnoreCase);

                                bool isExpiredNow =
                                    row["IsExpiredNow"] != DBNull.Value &&
                                    Convert.ToInt32(row["IsExpiredNow"]) == 1;

                                bool isExpired = isCancelled || (isReady && isExpiredNow);

                                DateTime? expiryAt = null;
                                if (row["ExpiryAt"] != DBNull.Value)
                                {
                                    expiryAt = Convert.ToDateTime(row["ExpiryAt"]);
                                }

                                row["DisplayAuthor"] = FormatAuthor(row["Author"]);
                                row["CoverUrl"] = ResolveCoverUrl(row["CoverPath"]);
                                row["CoverFallbackUrl"] =
                                    ResolveUrl("~/Assets/Covers/default-cover.jpg");

                                row["ReservedDateDisplay"] =
                                    row["ReservedDate"] == DBNull.Value
                                        ? "—"
                                        : Convert.ToDateTime(row["ReservedDate"])
                                            .ToString("MMM d, yyyy", CultureInfo.InvariantCulture);

                                row["IsExpired"] = isExpired;
                                row["CancelVisible"] = !isExpired && (isReady || isReserved);

                                string statusText = "Processing";
                                string statusCss = "status-processing";
                                string expiryDisplay = "Not ready yet";

                                if (isCancelled)
                                {
                                    statusText = "Reservation Expired";
                                    statusCss = "status-expired";
                                    expiryDisplay = "Expired";
                                }
                                else if (isReady)
                                {
                                    if (isExpired)
                                    {
                                        statusText = "Reservation Expired";
                                        statusCss = "status-expired";
                                        expiryDisplay = expiryAt.HasValue
                                            ? "Expired at " + expiryAt.Value.ToString(
                                                "MMM d, yyyy, h:mm tt", CultureInfo.InvariantCulture)
                                            : "Expired";
                                    }
                                    else
                                    {
                                        statusText = "Ready for Pickup";
                                        statusCss = "status-ready";
                                        expiryDisplay = expiryAt.HasValue
                                            ? "Valid until " + expiryAt.Value.ToString(
                                                "MMM d, yyyy, h:mm tt", CultureInfo.InvariantCulture)
                                            : "Valid for 1 hour after ready";
                                    }
                                }
                                else if (isReserved)
                                {
                                    statusText = "Processing";
                                    statusCss = "status-processing";
                                    expiryDisplay = "Not ready yet";
                                }

                                row["StatusText"] = statusText;
                                row["StatusCss"] = statusCss;
                                row["ExpiryDisplay"] = expiryDisplay;
                                row["RowCss"] = "reservation-card" +
                                    (isExpired ? " reservation-expired" : string.Empty);

                                if (isReady && !isExpired)
                                {
                                    readyCount++;
                                }
                                else if (isReserved)
                                {
                                    processingCount++;
                                }
                            }

                            litReadyCount.Text = readyCount.ToString();
                            litProcessingCount.Text = processingCount.ToString();

                            rptReservations.DataSource = dt;
                            rptReservations.DataBind();

                            rptReservations.Visible = dt.Rows.Count > 0;
                            pnlEmpty.Visible = dt.Rows.Count == 0;
                        }
                    }
                }
            }
            catch
            {
                litReadyCount.Text = "0";
                litProcessingCount.Text = "0";
                rptReservations.Visible = false;
                pnlEmpty.Visible = true;

                ShowSweetAlert(
                    "Error",
                    "Unable to load reservations right now. Please try again.",
                    "error");
            }
        }

        private void AddDisplayColumns(DataTable dt)
        {
            dt.Columns.Add("DisplayAuthor", typeof(string));
            dt.Columns.Add("CoverUrl", typeof(string));
            dt.Columns.Add("CoverFallbackUrl", typeof(string));
            dt.Columns.Add("ReservedDateDisplay", typeof(string));
            dt.Columns.Add("ExpiryDisplay", typeof(string));
            dt.Columns.Add("StatusText", typeof(string));
            dt.Columns.Add("StatusCss", typeof(string));
            dt.Columns.Add("RowCss", typeof(string));
            dt.Columns.Add("IsExpired", typeof(bool));
            dt.Columns.Add("CancelVisible", typeof(bool));
        }

        protected void rptReservations_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (!string.Equals(
                e.CommandName, "CancelReservation", StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            string userId = Session["UserID"]?.ToString();

            if (string.IsNullOrEmpty(userId))
            {
                Response.Redirect("~/Login/login.aspx");
                return;
            }

            int transactionId;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out transactionId))
            {
                ShowSweetAlert(
                    "Unable to Cancel",
                    "Invalid reservation request.",
                    "error");

                return;
            }

            try
            {
                using (MySqlConnection conn = new MySqlConnection(connStr))
                {
                    conn.Open();

                    using (MySqlTransaction trans = conn.BeginTransaction())
                    {
                        string status = null;
                        string title = null;
                        bool expired = false;
                        bool found = false;

                        string checkSql = @"
                            SELECT
                                t.status,
                                lr.title,
                                CASE
                                    WHEN t.status = 'Ready'
                                         AND t.updated_at <= NOW() - INTERVAL 1 HOUR
                                    THEN 1
                                    ELSE 0
                                END AS IsExpired
                            FROM Transactions t
                            INNER JOIN Item_Copies ic
                                ON t.accession_number = ic.accession_number
                            INNER JOIN Library_Resources lr
                                ON ic.resource_id = lr.resource_id
                            WHERE t.transaction_id = @TxnId
                              AND t.user_id = @UserId
                            FOR UPDATE";

                        using (MySqlCommand checkCmd = new MySqlCommand(checkSql, conn, trans))
                        {
                            checkCmd.Parameters.AddWithValue("@TxnId", transactionId);
                            checkCmd.Parameters.AddWithValue("@UserId", userId);

                            using (MySqlDataReader reader = checkCmd.ExecuteReader())
                            {
                                if (reader.Read())
                                {
                                    found = true;
                                    status = Convert.ToString(reader["status"]);
                                    title = Convert.ToString(reader["title"]);
                                    expired = Convert.ToInt32(reader["IsExpired"]) == 1;
                                }
                            }
                        }

                        if (!found)
                        {
                            trans.Rollback();
                            LoadReservations();
                            ShowSweetAlert(
                                "Unable to Cancel",
                                "This reservation was not found for your account.",
                                "error");

                            return;
                        }

                        if (string.Equals(
                            status, "Cancelled", StringComparison.OrdinalIgnoreCase))
                        {
                            trans.Rollback();
                            LoadReservations();
                            ShowSweetAlert(
                                "Already Cancelled",
                                "This reservation has already been cancelled.",
                                "info");

                            return;
                        }

                        bool isReady = string.Equals(
                            status, "Ready", StringComparison.OrdinalIgnoreCase);
                        bool isReserved = string.Equals(
                            status, "Reserved", StringComparison.OrdinalIgnoreCase);

                        if (!isReady && !isReserved)
                        {
                            trans.Rollback();
                            LoadReservations();
                            ShowSweetAlert(
                                "Unable to Cancel",
                                "This reservation can no longer be cancelled.",
                                "error");

                            return;
                        }

                        if (isReady && expired)
                        {
                            trans.Rollback();
                            LoadReservations();
                            ShowSweetAlert(
                                "Reservation Expired",
                                "This reservation has expired and can no longer be cancelled.",
                                "warning");

                            return;
                        }

                        string updateSql = @"
                            UPDATE Transactions
                            SET status = 'Cancelled',
                                remarks = 'Cancelled by patron'
                            WHERE transaction_id = @TxnId
                              AND user_id = @UserId
                              AND status IN ('Reserved', 'Ready')
                              AND (
                                    status <> 'Ready'
                                    OR updated_at > NOW() - INTERVAL 1 HOUR
                                  )";

                        using (MySqlCommand updateCmd = new MySqlCommand(updateSql, conn, trans))
                        {
                            updateCmd.Parameters.AddWithValue("@TxnId", transactionId);
                            updateCmd.Parameters.AddWithValue("@UserId", userId);

                            int affected = updateCmd.ExecuteNonQuery();

                            if (affected == 0)
                            {
                                trans.Rollback();
                                LoadReservations();
                                ShowSweetAlert(
                                    "Unable to Cancel",
                                    "The reservation could not be cancelled. It may have expired or already been cancelled.",
                                    "error");

                                return;
                            }
                        }

                        trans.Commit();

                        LoadReservations();

                        ShowSweetAlert(
                            "Cancelled",
                            "Your reservation for '" + title + "' has been cancelled.",
                            "success");
                    }
                }
            }
            catch
            {
                ShowSweetAlert(
                    "Error",
                    "Unable to cancel the reservation right now. Please try again.",
                    "error");
            }
        }

        private string FormatAuthor(object authorObj)
        {
            string raw = authorObj == null || authorObj == DBNull.Value
                ? string.Empty
                : authorObj.ToString();

            if (string.IsNullOrWhiteSpace(raw))
            {
                return "Unknown Author";
            }

            raw = raw.Replace("\r", " ").Replace("\n", ";").Trim();

            string first = raw;
            bool multiple = false;

            string[] semicolonParts = raw
                .Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(p => p.Trim())
                .Where(p => p.Length > 0)
                .ToArray();

            if (semicolonParts.Length > 1)
            {
                multiple = true;
                first = semicolonParts[0];
            }
            else
            {
                string[] andParts = Regex
                    .Split(raw, @"\s+(?:and|&)\s+", RegexOptions.IgnoreCase)
                    .Select(p => p.Trim())
                    .Where(p => p.Length > 0)
                    .ToArray();

                if (andParts.Length > 1)
                {
                    multiple = true;
                    first = andParts[0];
                }
                else
                {
                    string[] commaParts = raw
                        .Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                        .Select(p => p.Trim())
                        .Where(p => p.Length > 0)
                        .ToArray();

                    if (commaParts.Length > 1)
                    {
                        multiple = true;
                        first = commaParts[0];
                    }
                }
            }

            first = first.Trim().Trim(',', ';').Trim();

            if (first.EndsWith(" et al.", StringComparison.OrdinalIgnoreCase))
            {
                first = first.Substring(0, first.Length - 8).Trim();
            }

            if (string.IsNullOrWhiteSpace(first) ||
                first.Equals("et al.", StringComparison.OrdinalIgnoreCase))
            {
                return "Unknown Author";
            }

            return multiple ? first + " et al." : first;
        }

        private string ResolveCoverUrl(object coverObj)
        {
            string defaultAppRelative = "~/Assets/Covers/default-cover.jpg";
            string defaultUrl = ResolveUrl(defaultAppRelative);

            string raw = coverObj == null || coverObj == DBNull.Value
                ? string.Empty
                : coverObj.ToString().Trim();

            if (string.IsNullOrWhiteSpace(raw))
            {
                return defaultUrl;
            }

            if (raw.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                raw.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                return raw;
            }

            string normalized = raw.Replace('\\', '/').Trim();

            if (normalized.Contains(".."))
            {
                return defaultUrl;
            }

            int assetsIndex = normalized.IndexOf(
                "Assets/", StringComparison.OrdinalIgnoreCase);

            string appRelative;

            if (assetsIndex >= 0)
            {
                appRelative = "~/" + normalized.Substring(assetsIndex);
            }
            else if (normalized.StartsWith("~/", StringComparison.Ordinal))
            {
                appRelative = normalized;
            }
            else if (normalized.StartsWith("/", StringComparison.Ordinal))
            {
                appRelative = "~" + normalized;
            }
            else if (!normalized.Contains("/"))
            {
                appRelative = "~/Assets/Covers/" + normalized;
            }
            else
            {
                appRelative = "~/" + normalized.TrimStart('/');
            }

            try
            {
                string physicalPath = Server.MapPath(appRelative);

                if (!string.IsNullOrEmpty(physicalPath) &&
                    System.IO.File.Exists(physicalPath))
                {
                    return ResolveUrl(appRelative);
                }
            }
            catch
            {
                // Fall through to the default cover.
            }

            return defaultUrl;
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string script =
                "showSweetAlert(" +
                JsString(title) + "," +
                JsString(message) + "," +
                JsString(icon) +
                ");";

            ScriptManager.RegisterStartupScript(
                this,
                GetType(),
                Guid.NewGuid().ToString(),
                script,
                true);
        }

        private static string JsString(string value)
        {
            return System.Web.HttpUtility.JavaScriptStringEncode(
                value ?? string.Empty,
                true);
        }
    }
}