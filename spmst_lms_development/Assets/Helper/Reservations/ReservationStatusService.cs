using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Hosting;

namespace spmst_lms_development.Assets.Helper.Reservations
{
    /// <summary>
    /// Returns the current reservation snapshot for a single patron.
    /// Used by ToPickUp.aspx AJAX polling. All queries are parameterized
    /// and scoped to the supplied user id.
    /// </summary>
    public class ReservationStatusService
    {
        private readonly string _connStr =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        public ReservationStatusPayload GetPatronStatuses(string userId)
        {
            if (string.IsNullOrWhiteSpace(userId))
                throw new ArgumentException("userId is required.", "userId");

            var payload = new ReservationStatusPayload
            {
                Success = true,
                Reservations = new List<ReservationStatusDto>()
            };

            using (var conn = new MySqlConnection(_connStr))
            {
                const string query = @"
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
                                AND t.updated_at >= NOW() - INTERVAL 7 DAY
                            )
                      )
                    ORDER BY
                        CASE
                            WHEN t.status = 'Ready'    THEN 0
                            WHEN t.status = 'Reserved' THEN 1
                            ELSE 2
                        END,
                        t.updated_at DESC";

                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@UserId", userId);
                    conn.Open();

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            string rawStatus = Convert.ToString(reader["Status"]);
                            bool isCancelled = string.Equals(rawStatus, "Cancelled", StringComparison.OrdinalIgnoreCase);
                            bool isReady = string.Equals(rawStatus, "Ready", StringComparison.OrdinalIgnoreCase);
                            bool isReserved = string.Equals(rawStatus, "Reserved", StringComparison.OrdinalIgnoreCase);
                            bool isExpiredNow = reader["IsExpiredNow"] != DBNull.Value
                                                 && Convert.ToInt32(reader["IsExpiredNow"]) == 1;
                            bool isExpired = isCancelled || (isReady && isExpiredNow);

                            DateTime? expiryAt = null;
                            if (reader["ExpiryAt"] != DBNull.Value)
                                expiryAt = Convert.ToDateTime(reader["ExpiryAt"]);

                            var dto = new ReservationStatusDto
                            {
                                TransactionId = Convert.ToInt32(reader["TransactionID"]),
                                Title = Convert.ToString(reader["Title"]),
                                Author = FormatAuthor(reader["Author"]),
                                CoverUrl = ResolveCoverUrl(reader["CoverPath"]),
                                CoverFallbackUrl = VirtualPathUtility.ToAbsolute("~/Assets/Covers/default-cover.jpg"),
                                ReservedDateDisplay = reader["ReservedDate"] == DBNull.Value
                                    ? "\u2014"
                                    : Convert.ToDateTime(reader["ReservedDate"])
                                             .ToString("MMM d, yyyy", CultureInfo.InvariantCulture)
                            };

                            if (isCancelled)
                            {
                                dto.Status = "Cancelled";
                                dto.StatusText = "Reservation Expired";
                                dto.StatusCss = "status-expired";
                                dto.ExpiryDisplay = "Expired";
                                dto.IsExpired = true;
                                dto.CancelVisible = false;
                                dto.RowCss = "reservation-card reservation-expired";
                            }
                            else if (isReady)
                            {
                                if (isExpired)
                                {
                                    dto.Status = "Ready";
                                    dto.StatusText = "Reservation Expired";
                                    dto.StatusCss = "status-expired";
                                    dto.ExpiryDisplay = expiryAt.HasValue
                                        ? "Expired at " + expiryAt.Value.ToString("MMM d, yyyy, h:mm tt", CultureInfo.InvariantCulture)
                                        : "Expired";
                                    dto.IsExpired = true;
                                    dto.CancelVisible = false;
                                    dto.RowCss = "reservation-card reservation-expired";
                                }
                                else
                                {
                                    dto.Status = "Ready";
                                    dto.StatusText = "Ready for Pickup";
                                    dto.StatusCss = "status-ready";
                                    dto.ExpiryDisplay = expiryAt.HasValue
                                        ? "Valid until " + expiryAt.Value.ToString("MMM d, yyyy, h:mm tt", CultureInfo.InvariantCulture)
                                        : "Valid for 1 hour after ready";
                                    dto.IsExpired = false;
                                    dto.CancelVisible = true;
                                    dto.RowCss = "reservation-card";
                                }
                            }
                            else if (isReserved)
                            {
                                dto.Status = "Reserved";
                                dto.StatusText = "Processing";
                                dto.StatusCss = "status-processing";
                                dto.ExpiryDisplay = "Not ready yet";
                                dto.IsExpired = false;
                                dto.CancelVisible = true;
                                dto.RowCss = "reservation-card";
                            }

                            if (isReady && !isExpired) payload.ReadyCount++;
                            else if (isReserved) payload.ProcessingCount++;

                            payload.Reservations.Add(dto);
                        }
                    }
                }
            }

            return payload;
        }

        /* ------------------------------------------------------------------ */
        /* Helpers (mirrors ToPickUp.aspx.cs formatting so JSON matches HTML) */
        /* ------------------------------------------------------------------ */

        private static string FormatAuthor(object authorObj)
        {
            string raw = authorObj == null || authorObj == DBNull.Value
                ? string.Empty
                : authorObj.ToString();

            if (string.IsNullOrWhiteSpace(raw)) return "Unknown Author";

            raw = raw.Replace("\r", " ").Replace("\n", ";").Trim();

            string first = raw;
            bool multiple = false;

            string[] semi = raw.Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries)
                               .Select(p => p.Trim()).Where(p => p.Length > 0).ToArray();
            if (semi.Length > 1) { multiple = true; first = semi[0]; }
            else
            {
                string[] andParts = Regex.Split(raw, @"\s+(?:and|&)\s+", RegexOptions.IgnoreCase)
                                          .Select(p => p.Trim()).Where(p => p.Length > 0).ToArray();
                if (andParts.Length > 1) { multiple = true; first = andParts[0]; }
                else
                {
                    string[] comma = raw.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                                        .Select(p => p.Trim()).Where(p => p.Length > 0).ToArray();
                    if (comma.Length > 1) { multiple = true; first = comma[0]; }
                }
            }

            first = first.Trim().Trim(',', ';').Trim();
            if (first.EndsWith(" et al.", StringComparison.OrdinalIgnoreCase))
                first = first.Substring(0, first.Length - 8).Trim();

            if (string.IsNullOrWhiteSpace(first) ||
                first.Equals("et al.", StringComparison.OrdinalIgnoreCase))
                return "Unknown Author";

            return multiple ? first + " et al." : first;
        }

        private static string ResolveCoverUrl(object coverObj)
        {
            string defaultUrl = VirtualPathUtility.ToAbsolute("~/Assets/Covers/default-cover.jpg");

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
                string physicalPath = HostingEnvironment.MapPath(appRelative);
                if (!string.IsNullOrEmpty(physicalPath) && File.Exists(physicalPath))
                    return VirtualPathUtility.ToAbsolute(appRelative);
            }
            catch { /* fall through */ }

            return defaultUrl;
        }
    }

    public class ReservationStatusPayload
    {
        public bool Success { get; set; }
        public int ReadyCount { get; set; }
        public int ProcessingCount { get; set; }
        public List<ReservationStatusDto> Reservations { get; set; }
    }

    public class ReservationStatusDto
    {
        public int TransactionId { get; set; }
        public string Title { get; set; }
        public string Author { get; set; }
        public string CoverUrl { get; set; }
        public string CoverFallbackUrl { get; set; }
        public string ReservedDateDisplay { get; set; }
        public string Status { get; set; } // Reserved | Ready | Cancelled
        public string StatusText { get; set; }
        public string StatusCss { get; set; }
        public string ExpiryDisplay { get; set; }
        public bool IsExpired { get; set; }
        public bool CancelVisible { get; set; }
        public string RowCss { get; set; }
    }
}