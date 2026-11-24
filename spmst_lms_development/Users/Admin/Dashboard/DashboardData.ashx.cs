using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.SessionState;
using ClosedXML.Excel;
using MySql.Data.MySqlClient;
using spmst_lms_development.Assets.Helper;
using spmst_lms_development.Assets.Helper.Handlers;

namespace spmst_lms_development.Users.Admin.Dashboard
{
    /// <summary>
    /// Data endpoint for the Admin Dashboard (Circulation / Patrons / Attendance tabs).
    ///
    /// SECURITY MODEL
    ///   1. The caller must have a server-side login session            -> else HTTP 401
    ///   2. Every action belongs to exactly one dashboard tab, and the
    ///      session role must be allowed to view that tab
    ///      (DashboardAccess.CanAccess)                                -> else HTTP 403
    ///   3. Denied requests return a generic message and NO data.
    ///   4. The role is read from the session only - never from the request.
    ///   5. All SQL is parameterised; every client value is validated/whitelisted.
    ///
    /// Pagination is server-side (LIMIT/OFFSET), 10 rows per page, exactly like the
    /// Landing Page "Home" catalog: the response carries { items, page, pageSize, total, totalPages }.
    /// </summary>
    public class DashboardData : IHttpHandler, IRequiresSessionState
    {
        public bool IsReusable { get { return false; } }

        private const int PageSize = 10;
        private const string Unassigned = "(Unassigned)";
        private const string Unspecified = "Unspecified";

        // Existing analytic result caps (kept so the analytics keep their original meaning).
        private const int TrendingCap = 10;
        private const int OverdueCap = 15;

        // Occupancy capacities (same values the original Attendance page used).
        private const int CapTotal = 100;
        private const int CapStudy = 80;
        private const int CapResearch = 20;

        // -----------------------------------------------------------------
        // Unified patron directory. ONE row per person (no double counting),
        // classified by the profile table the person actually lives in.
        // Staff have no institute/program column, so - exactly like the existing
        // Circulation charts (COALESCE(institute, office_department)) - their
        // office/department is used as their "institute".
        // -----------------------------------------------------------------
        private const string PatronDir = @"
            (SELECT s.student_id AS uid, 'Student' AS ptype,
                    NULLIF(TRIM(s.institute), '') AS institute,
                    NULLIF(TRIM(s.course), '')    AS program,
                    s.gender AS gender,
                    NULLIF(TRIM(s.year_level), '') AS year_level,
                    CONCAT_WS(' ', s.first_name, NULLIF(s.middle_name, ''), s.last_name, NULLIF(s.extension_name, '')) AS full_name
               FROM students s
             UNION ALL
             SELECT f.faculty_id, 'Faculty',
                    NULLIF(TRIM(f.institute), ''), NULL, f.gender, NULL,
                    CONCAT_WS(' ', f.first_name, NULLIF(f.middle_name, ''), f.last_name, NULLIF(f.extension_name, ''))
               FROM faculty f
              WHERE f.faculty_id NOT IN (SELECT student_id FROM students)
             UNION ALL
             SELECT st.staff_id, 'Staff',
                    NULLIF(TRIM(st.office_department), ''), NULL, st.gender, NULL,
                    CONCAT_WS(' ', st.first_name, NULLIF(st.middle_name, ''), st.last_name, NULLIF(st.extension_name, ''))
               FROM staff st
              WHERE st.staff_id NOT IN (SELECT student_id FROM students)
                AND st.staff_id NOT IN (SELECT faculty_id FROM faculty)
            ) d";

        // =================================================================
        // ENTRY POINT
        // =================================================================
        public void ProcessRequest(HttpContext context)
        {
            string action = (context.Request.QueryString["action"] ?? string.Empty).Trim().ToLowerInvariant();
            bool isExport = action == "export";

            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
            context.Response.TrySkipIisCustomErrors = true;
            if (!isExport) context.Response.ContentType = "application/json";

            // ---- 1. Authentication ----
            if (!sessionHelper.IsLoggedIn())
            {
                Deny(context, 401, "Your session has expired. Please sign in again.", isExport);
                return;
            }

            // ---- 2. Authorization: action -> tab -> role ----
            DashTab tab;
            if (!TryGetTab(action, out tab))
            {
                Deny(context, 400, "Unknown request.", isExport);
                return;
            }
            if (!DashboardAccess.CanAccess(sessionHelper.UserRole, tab))
            {
                // Generic message, no data, nothing about what exists.
                Deny(context, 403, "You do not have permission to view this data.", isExport);
                return;
            }

            try
            {
                if (isExport) { ExportAttendance(context); return; }

                object result;
                switch (action)
                {
                    // ----- Circulation -----
                    case "trends": result = GetTrends(context); break;
                    case "topbooks": result = GetTopBooks(context); break;
                    case "analytics": result = GetAnalyticsPage(context); break;
                    case "peakchart": result = GetPeakChart(); break;

                    // ----- Patrons -----
                    case "patronfilters": result = GetPatronFilters(context); break;
                    case "patronoverview": result = GetPatronOverview(context); break;
                    case "penalties": result = GetPenalties(context); break;

                    // ----- Attendance -----
                    case "occupancy": result = GetOccupancy(context); break;
                    case "attendance": result = GetAttendancePage(context); break;

                    default:
                        Deny(context, 400, "Unknown request.", false);
                        return;
                }

                WriteJson(context, new { success = true, data = result });
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.TraceError("DashboardData[" + action + "]: " + ex);
                try
                {
                    context.Response.StatusCode = 500;
                    if (!isExport)
                    {
                        WriteJson(context, new { success = false, message = "The data could not be loaded. Please try again." });
                    }
                    else
                    {
                        context.Response.ContentType = "text/plain";
                        context.Response.Write("The export could not be created. Please try again.");
                    }
                }
                catch (HttpException) { /* response already started; nothing more can be sent */ }
            }
        }

        private static bool TryGetTab(string action, out DashTab tab)
        {
            switch (action)
            {
                case "trends":
                case "topbooks":
                case "analytics":
                case "peakchart":
                    tab = DashTab.Circulation; return true;

                case "patronfilters":
                case "patronoverview":
                case "penalties":
                    tab = DashTab.Patrons; return true;

                case "occupancy":
                case "attendance":
                case "export":
                    tab = DashTab.Attendance; return true;
            }
            tab = DashTab.Circulation;
            return false;
        }

        private static void Deny(HttpContext context, int status, string message, bool plainText)
        {
            context.Response.StatusCode = status;
            if (plainText)
            {
                context.Response.ContentType = "text/plain";
                context.Response.Write(message);
            }
            else
            {
                context.Response.ContentType = "application/json";
                WriteJson(context, new { success = false, message = message });
            }
        }

        // =================================================================
        // CIRCULATION
        // =================================================================

        /// <summary>Library Trends Overview data (all charts + penalty totals) for a date range.</summary>
        private object GetTrends(HttpContext ctx)
        {
            DateTime to = ParseDate(ctx, "to") ?? DateTime.Today;
            DateTime from = ParseDate(ctx, "from") ?? to.AddDays(-30);
            if (from > to) { DateTime tmp = from; from = to; to = tmp; }

            using (var conn = new MySqlConnection(DbHelper.ConnStr))
            {
                conn.Open();

                var section = LabelCount(conn, @"
                    SELECT COALESCE(NULLIF(lr.section, ''), 'Unclassified') AS label, COUNT(t.transaction_id) AS cnt
                      FROM transactions t
                      JOIN item_copies ic ON t.accession_number = ic.accession_number
                      JOIN library_resources lr ON ic.resource_id = lr.resource_id
                     WHERE t.borrow_date BETWEEN @start AND @end
                     GROUP BY label
                     ORDER BY cnt DESC, label
                     LIMIT 10", from, to);

                var subject = LabelCount(conn, @"
                    SELECT COALESCE(NULLIF(lr.dewey_decimal, ''), 'Unclassified') AS label, COUNT(t.transaction_id) AS cnt
                      FROM transactions t
                      JOIN item_copies ic ON t.accession_number = ic.accession_number
                      JOIN library_resources lr ON ic.resource_id = lr.resource_id
                     WHERE t.borrow_date BETWEEN @start AND @end
                     GROUP BY label
                     ORDER BY cnt DESC, label
                     LIMIT 10", from, to);

                var inst = Stacked(conn, "institute", "COALESCE(s.institute, f.institute, st.office_department)", from, to);
                var prog = Stacked(conn, "program", "COALESCE(s.course, f.institute, st.office_department)", from, to);

                decimal damageAmt = 0, lostAmt = 0, overdueAmt = 0, totalFine = 0, totalPaid = 0;
                int damageCnt = 0, lostCnt = 0, overdueCnt = 0;

                using (var cmd = new MySqlCommand(@"
                    SELECT
                        IFNULL(SUM(CASE WHEN p.penalty_type LIKE '%Damaged%' THEN p.fine_amount ELSE 0 END), 0) AS DamageAmount,
                        COUNT(CASE WHEN p.penalty_type LIKE '%Damaged%' THEN 1 END)                              AS DamageCount,
                        IFNULL(SUM(CASE WHEN p.penalty_type LIKE '%Lost%'    THEN p.fine_amount ELSE 0 END), 0) AS LostAmount,
                        COUNT(CASE WHEN p.penalty_type LIKE '%Lost%'    THEN 1 END)                              AS LostCount,
                        IFNULL(SUM(CASE WHEN p.penalty_type LIKE '%Overdue%' THEN p.fine_amount ELSE 0 END), 0) AS OverdueAmount,
                        COUNT(CASE WHEN p.penalty_type LIKE '%Overdue%' THEN 1 END)                              AS OverdueCount,
                        IFNULL(SUM(p.fine_amount), 0)                                                            AS TotalFine,
                        IFNULL(SUM(p.amount_paid), 0)                                                            AS TotalPaid
                      FROM penalties p
                      JOIN transactions t ON p.transaction_id = t.transaction_id
                     WHERE t.borrow_date BETWEEN @start AND @end", conn))
                {
                    cmd.CommandTimeout = 60;
                    cmd.Parameters.AddWithValue("@start", from.Date);
                    cmd.Parameters.AddWithValue("@end", to.Date);
                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            damageAmt = DbHelper.SafeGetDecimal(r, "DamageAmount");
                            damageCnt = DbHelper.SafeGetInt(r, "DamageCount");
                            lostAmt = DbHelper.SafeGetDecimal(r, "LostAmount");
                            lostCnt = DbHelper.SafeGetInt(r, "LostCount");
                            overdueAmt = DbHelper.SafeGetDecimal(r, "OverdueAmount");
                            overdueCnt = DbHelper.SafeGetInt(r, "OverdueCount");
                            totalFine = DbHelper.SafeGetDecimal(r, "TotalFine");
                            totalPaid = DbHelper.SafeGetDecimal(r, "TotalPaid");
                        }
                    }
                }

                decimal balance = totalFine - totalPaid;
                if (balance < 0) balance = 0;

                return new
                {
                    from = from.ToString("yyyy-MM-dd"),
                    to = to.ToString("yyyy-MM-dd"),
                    section = section,
                    subject = subject,
                    penalty = new
                    {
                        amounts = new[] { damageAmt, lostAmt, overdueAmt },
                        counts = new[] { damageCnt, lostCnt, overdueCnt }
                    },
                    institutes = inst,
                    programs = prog,
                    totals = new
                    {
                        penalties = totalFine.ToString("N2", CultureInfo.InvariantCulture),
                        paid = totalPaid.ToString("N2", CultureInfo.InvariantCulture),
                        balance = balance.ToString("N2", CultureInfo.InvariantCulture)
                    }
                };
            }
        }

        private static object LabelCount(MySqlConnection conn, string sql, DateTime from, DateTime to)
        {
            var labels = new List<string>();
            var values = new List<int>();
            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 60;
                cmd.Parameters.AddWithValue("@start", from.Date);
                cmd.Parameters.AddWithValue("@end", to.Date);
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        labels.Add(Convert.ToString(r["label"]));
                        values.Add(Convert.ToInt32(r["cnt"]));
                    }
                }
            }
            return new { labels = labels, values = values };
        }

        private static object Stacked(MySqlConnection conn, string alias, string labelExpr, DateTime from, DateTime to)
        {
            string sql = @"
                SELECT " + labelExpr + @" AS lbl,
                    SUM(CASE WHEN t.status = 'Borrowed' THEN 1 ELSE 0 END) AS Borrowed,
                    SUM(CASE WHEN t.status = 'Returned' THEN 1 ELSE 0 END) AS Returned,
                    SUM(CASE WHEN t.status IN ('Reserved','Ready') THEN 1 ELSE 0 END) AS Reserved,
                    SUM(CASE WHEN u.role = 'student' AND t.status = 'Borrowed' THEN 1 ELSE 0 END) AS StudentBorrowed,
                    SUM(CASE WHEN u.role = 'faculty' AND t.status = 'Borrowed' THEN 1 ELSE 0 END) AS FacultyBorrowed,
                    SUM(CASE WHEN u.role = 'staff'   AND t.status = 'Borrowed' THEN 1 ELSE 0 END) AS StaffBorrowed
                  FROM transactions t
                  JOIN users u ON t.user_id = u.user_id
                  LEFT JOIN students s ON u.user_id = s.student_id
                  LEFT JOIN faculty  f ON u.user_id = f.faculty_id
                  LEFT JOIN staff   st ON u.user_id = st.staff_id
                 WHERE t.borrow_date BETWEEN @start AND @end
                 GROUP BY lbl
                 ORDER BY lbl";

            var labels = new List<string>();
            var borrowed = new List<int>();
            var returned = new List<int>();
            var reserved = new List<int>();
            var roles = new List<object>();

            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 60;
                cmd.Parameters.AddWithValue("@start", from.Date);
                cmd.Parameters.AddWithValue("@end", to.Date);
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        string lbl = r["lbl"] == DBNull.Value ? "" : Convert.ToString(r["lbl"]);
                        labels.Add(string.IsNullOrWhiteSpace(lbl) ? "Unknown" : lbl);
                        borrowed.Add(Convert.ToInt32(r["Borrowed"]));
                        returned.Add(Convert.ToInt32(r["Returned"]));
                        reserved.Add(Convert.ToInt32(r["Reserved"]));
                        roles.Add(new
                        {
                            student = Convert.ToInt32(r["StudentBorrowed"]),
                            faculty = Convert.ToInt32(r["FacultyBorrowed"]),
                            staff = Convert.ToInt32(r["StaffBorrowed"])
                        });
                    }
                }
            }
            return new { labels = labels, borrowed = borrowed, returned = returned, reserved = reserved, borrowedRoles = roles };
        }

        /// <summary>
        /// Top Borrowed Books. limit is clamped to 5..20. A single aggregate query (no per-row
        /// sub-selects). Books with zero checkouts are only used as filler to reach the 5-row minimum.
        /// </summary>
        private object GetTopBooks(HttpContext ctx)
        {
            int limit = IntParam(ctx, "limit", 5, 5, 20);

            const string sql = @"
                SELECT lr.resource_id, lr.cover_path, lr.title, lr.author, lr.section AS category,
                       COALESCE(SUM(CASE WHEN t.status IN ('Borrowed','Returned') THEN 1 ELSE 0 END), 0) AS checkouts,
                       COALESCE(SUM(CASE WHEN t.status IN ('Reserved','Ready')    THEN 1 ELSE 0 END), 0) AS waiting
                  FROM library_resources lr
                  LEFT JOIN item_copies ic  ON ic.resource_id = lr.resource_id
                  LEFT JOIN transactions t  ON t.accession_number = ic.accession_number
                 GROUP BY lr.resource_id, lr.cover_path, lr.title, lr.author, lr.section
                 ORDER BY checkouts DESC, lr.title ASC, lr.resource_id ASC
                 LIMIT @lim";

            string fallbackLogo = VirtualPathUtility.ToAbsolute("~/" + LogoHelper.GetVerifiedLogo("School"));
            var items = new List<object>();
            var seen = new HashSet<int>();

            using (var conn = new MySqlConnection(DbHelper.ConnStr))
            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 60;
                cmd.Parameters.AddWithValue("@lim", limit);
                conn.Open();
                using (var r = cmd.ExecuteReader())
                {
                    int rank = 0;
                    while (r.Read())
                    {
                        int id = Convert.ToInt32(r["resource_id"]);
                        if (!seen.Add(id)) continue;           // never show the same book twice

                        int checkouts = Convert.ToInt32(r["checkouts"]);
                        rank++;
                        if (checkouts == 0 && rank > 5) break; // zero-checkout rows only fill up to 5

                        items.Add(new
                        {
                            rank = rank,
                            id = id,
                            title = Convert.ToString(r["title"]),
                            author = r["author"] == DBNull.Value ? "" : Convert.ToString(r["author"]),
                            category = r["category"] == DBNull.Value ? "" : Convert.ToString(r["category"]),
                            checkouts = checkouts,
                            waiting = Convert.ToInt32(r["waiting"]),
                            cover = ResolveCoverUrl(r["cover_path"] == DBNull.Value ? null : Convert.ToString(r["cover_path"]))
                        });
                    }
                }
            }

            return new { items = items, limit = limit, count = items.Count, fallbackLogo = fallbackLogo };
        }

        /// <summary>Returns an absolute URL for an existing cover file, or null (client shows the school logo).</summary>
        private static string ResolveCoverUrl(string coverPath)
        {
            if (string.IsNullOrWhiteSpace(coverPath)) return null;

            string path = coverPath.Trim().Replace("\\", "/");
            if (path.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                path.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
                return path; // remote cover; the <img> falls back to the logo if it fails to load

            if (path.StartsWith("~/")) path = path.Substring(2);
            else if (path.StartsWith("~")) path = path.Substring(1);
            else if (path.StartsWith("/")) path = path.Substring(1);

            if (!path.Contains("/")) path = "Assets/Covers/" + path;
            if (path.Contains("..")) return null;

            try
            {
                string physical = System.Web.Hosting.HostingEnvironment.MapPath("~/" + path);
                if (!string.IsNullOrEmpty(physical) && File.Exists(physical) && new FileInfo(physical).Length > 0)
                    return VirtualPathUtility.ToAbsolute("~/" + path);
            }
            catch { }
            return null;
        }

        // ---------------- Descriptive & Diagnostic analytics (paged) ----------------

        private object GetAnalyticsPage(HttpContext ctx)
        {
            string kind = (ctx.Request.QueryString["kind"] ?? "").Trim().ToLowerInvariant();
            int page = IntParam(ctx, "page", 1, 1, int.MaxValue);

            string sql;
            int cap = 0;

            switch (kind)
            {
                case "trending":
                    cap = TrendingCap;
                    sql = @"
                        SELECT lr.title AS Title, lr.author AS Author, COALESCE(lr.isbn, lr.issn) AS Isbn,
                               lr.section AS Section, COUNT(t.transaction_id) AS Borrows,
                               IFNULL(MAX(t.borrow_date), 'Never') AS LastBorrowed,
                               CASE WHEN COUNT(t.transaction_id) >= 20 THEN 'High Demand'
                                    WHEN COUNT(t.transaction_id) >= 10 THEN 'Moderate Demand'
                                    ELSE 'Rising Popularity' END AS Reason,
                               CASE WHEN COUNT(t.transaction_id) >= 20 THEN 'This book is in extremely high demand - likely a core textbook or popular title.'
                                    WHEN COUNT(t.transaction_id) >= 10 THEN 'Consistently borrowed; may be required reading or a frequently referenced work.'
                                    WHEN MAX(t.borrow_date) > DATE_SUB(NOW(), INTERVAL 1 MONTH) THEN 'Recently gained popularity - possibly due to new course adoption or current events.'
                                    ELSE 'Steady interest - a reliable resource for users.' END AS Explanation
                          FROM library_resources lr
                         INNER JOIN item_copies ic ON lr.resource_id = ic.resource_id
                         INNER JOIN transactions t ON ic.accession_number = t.accession_number
                         WHERE t.status NOT IN ('Cancelled')
                         GROUP BY lr.resource_id, lr.title, lr.author, lr.isbn, lr.issn, lr.section
                         ORDER BY Borrows DESC, lr.title ASC, lr.resource_id ASC";
                    break;

                case "lowcirc":
                    sql = @"
                        SELECT lr.title AS Title, lr.section AS Category, COUNT(t.transaction_id) AS Borrows,
                               IFNULL(MAX(t.borrow_date), 'Never') AS LastBorrowed,
                               CASE WHEN COUNT(t.transaction_id) = 0 THEN 'No Curriculum Match'
                                    WHEN MAX(t.borrow_date) < DATE_SUB(NOW(), INTERVAL 1 YEAR) THEN 'Outdated Content'
                                    ELSE 'Niche Subject' END AS Reason,
                               CASE WHEN COUNT(t.transaction_id) = 0 THEN 'This book has never been borrowed; it may not align with current course offerings.'
                                    WHEN MAX(t.borrow_date) < DATE_SUB(NOW(), INTERVAL 1 YEAR) THEN 'The content may be obsolete or replaced by newer editions.'
                                    ELSE 'This item covers a highly specific topic with a limited target audience.' END AS Explanation
                          FROM library_resources lr
                          LEFT JOIN item_copies ic ON lr.resource_id = ic.resource_id
                          LEFT JOIN transactions t ON ic.accession_number = t.accession_number
                         GROUP BY lr.resource_id, lr.title, lr.section
                        HAVING Borrows < 5
                         ORDER BY Borrows ASC, lr.title ASC, lr.resource_id ASC";
                    break;

                case "overdue":
                    cap = OverdueCap;
                    sql = @"
                        SELECT Title, Author, Isbn, Section, OverdueCount, AvgDaysOverdue, LastOverdueDate, TotalBorrows,
                               CASE WHEN OverdueCount >= 5 AND TotalBorrows >= 10 THEN 'High Demand + Overdue'
                                    WHEN AvgDaysOverdue > 10 THEN 'Extended Loan Period'
                                    WHEN OverdueCount >= 3 AND AvgDaysOverdue > 5 THEN 'Moderate Overdue Risk'
                                    ELSE 'Low Overdue Rate' END AS Reason,
                               CASE WHEN OverdueCount >= 5 AND TotalBorrows >= 10 THEN 'This book is very popular; many users borrow it and often return late.'
                                    WHEN AvgDaysOverdue > 10 THEN 'Users keep this book for an extended period, exceeding the loan period.'
                                    WHEN OverdueCount >= 3 AND AvgDaysOverdue > 5 THEN 'Frequent but moderate overdue; may need shorter loan period or reminders.'
                                    ELSE 'Overdue is uncommon for this book; current loan periods seem appropriate.' END AS Explanation
                          FROM (
                                SELECT lr.resource_id, lr.title AS Title, lr.author AS Author, COALESCE(lr.isbn, lr.issn) AS Isbn,
                                       lr.section AS Section, COUNT(t.transaction_id) AS OverdueCount,
                                       ROUND(AVG(CASE WHEN t.return_date IS NULL THEN DATEDIFF(CURDATE(), t.due_date)
                                                      ELSE DATEDIFF(t.return_date, t.due_date) END), 0) AS AvgDaysOverdue,
                                       MAX(t.due_date) AS LastOverdueDate,
                                       (SELECT COUNT(*) FROM transactions t2
                                          INNER JOIN item_copies ic2 ON t2.accession_number = ic2.accession_number
                                         WHERE ic2.resource_id = lr.resource_id AND t2.status <> 'Cancelled') AS TotalBorrows
                                  FROM library_resources lr
                                 INNER JOIN item_copies ic ON lr.resource_id = ic.resource_id
                                 INNER JOIN transactions t ON ic.accession_number = t.accession_number
                                 WHERE t.status <> 'Cancelled'
                                   AND ((t.status = 'Borrowed' AND t.due_date < CURDATE())
                                     OR (t.return_date IS NOT NULL AND t.return_date > t.due_date))
                                 GROUP BY lr.resource_id, lr.title, lr.author, lr.isbn, lr.issn, lr.section
                                HAVING OverdueCount > 0
                          ) AS OverdueData
                         ORDER BY OverdueCount DESC, AvgDaysOverdue DESC, Title ASC, resource_id ASC";
                    break;

                case "peakentries":
                    sql = @"SELECT HOUR(time_in) AS Hr, COUNT(*) AS Cnt
                              FROM library_attendance
                             WHERE time_in IS NOT NULL AND time_in >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                             GROUP BY HOUR(time_in)
                             ORDER BY Hr";
                    break;

                case "peakexits":
                    sql = @"SELECT HOUR(time_out) AS Hr, COUNT(*) AS Cnt
                              FROM library_attendance
                             WHERE time_out IS NOT NULL AND time_out >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                             GROUP BY HOUR(time_out)
                             ORDER BY Hr";
                    break;

                default:
                    throw new ArgumentException("Unknown analytics kind.");
            }

            using (var conn = new MySqlConnection(DbHelper.ConnStr))
            {
                conn.Open();
                DataTable dt;
                int total;
                PagedQuery(conn, sql, null, page, cap, out dt, out total);
                return BuildPage(RowsToList(dt), page, total);
            }
        }

        /// <summary>Peak-hour chart arrays (24 buckets) and headline insights.</summary>
        private object GetPeakChart()
        {
            int[] entries = new int[24];
            int[] exits = new int[24];

            using (var conn = new MySqlConnection(DbHelper.ConnStr))
            {
                conn.Open();
                FillHours(conn, @"SELECT HOUR(time_in) AS Hr, COUNT(*) AS Cnt FROM library_attendance
                                   WHERE time_in IS NOT NULL AND time_in >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                                   GROUP BY HOUR(time_in)", entries);
                FillHours(conn, @"SELECT HOUR(time_out) AS Hr, COUNT(*) AS Cnt FROM library_attendance
                                   WHERE time_out IS NOT NULL AND time_out >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                                   GROUP BY HOUR(time_out)", exits);
            }

            int peakIn = 0, peakOut = 0, totalIn = 0, totalOut = 0;
            for (int i = 0; i < 24; i++)
            {
                if (entries[i] > entries[peakIn]) peakIn = i;
                if (exits[i] > exits[peakOut]) peakOut = i;
                totalIn += entries[i];
                totalOut += exits[i];
            }

            var labels = new List<string>();
            for (int i = 0; i < 24; i++) labels.Add(i.ToString("00") + ":00");

            return new
            {
                labels = labels,
                entries = entries,
                exits = exits,
                hasData = (totalIn + totalOut) > 0,
                peakEntryHour = peakIn,
                peakEntryCount = entries[peakIn],
                peakExitHour = peakOut,
                peakExitCount = exits[peakOut],
                totalEntries = totalIn,
                totalExits = totalOut
            };
        }

        private static void FillHours(MySqlConnection conn, string sql, int[] target)
        {
            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 60;
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        int h = Convert.ToInt32(r["Hr"]);
                        if (h >= 0 && h < 24) target[h] = Convert.ToInt32(r["Cnt"]);
                    }
                }
            }
        }

        // =================================================================
        // PATRONS
        // =================================================================

        private class PatronFilter
        {
            public string Institute = "";
            public string Program = "";
            public string PType = "";
            public string Gender = "";

            public static PatronFilter From(HttpContext ctx)
            {
                var f = new PatronFilter();
                f.Institute = Clean(ctx.Request.QueryString["institute"], 50);
                f.Program = Clean(ctx.Request.QueryString["program"], 50);
                string pt = Clean(ctx.Request.QueryString["ptype"], 10);
                string g = Clean(ctx.Request.QueryString["gender"], 15);

                f.PType = pt == "Student" || pt == "Faculty" || pt == "Staff" ? pt : "";
                f.Gender = g == "Male" || g == "Female" || g == Unspecified ? g : "";
                return f;
            }

            public bool Any { get { return Institute != "" || Program != "" || PType != "" || Gender != ""; } }

            /// <summary>Appends " AND ..." conditions. 'skip' names a facet to leave out (for facet option lists).</summary>
            public void Apply(StringBuilder sql, MySqlCommand cmd, string skip)
            {
                if (skip != "institute" && Institute != "")
                {
                    if (Institute == Unassigned) sql.Append(" AND d.institute IS NULL");
                    else { sql.Append(" AND d.institute = @fInst"); cmd.Parameters.AddWithValue("@fInst", Institute); }
                }
                if (skip != "program" && Program != "")
                {
                    sql.Append(" AND d.program = @fProg"); cmd.Parameters.AddWithValue("@fProg", Program);
                }
                if (skip != "ptype" && PType != "")
                {
                    sql.Append(" AND d.ptype = @fType"); cmd.Parameters.AddWithValue("@fType", PType);
                }
                if (skip != "gender" && Gender != "")
                {
                    if (Gender == Unspecified) sql.Append(" AND d.gender IS NULL");
                    else { sql.Append(" AND d.gender = @fGender"); cmd.Parameters.AddWithValue("@fGender", Gender); }
                }
            }

            public PatronFilter Clone()
            {
                return new PatronFilter { Institute = Institute, Program = Program, PType = PType, Gender = Gender };
            }
        }

        private static int CountPatrons(MySqlConnection conn, PatronFilter f)
        {
            var sql = new StringBuilder("SELECT COUNT(*) FROM " + PatronDir + " WHERE 1=1");
            using (var cmd = new MySqlCommand("", conn))
            {
                f.Apply(sql, cmd, null);
                cmd.CommandText = sql.ToString();
                cmd.CommandTimeout = 60;
                return Convert.ToInt32(cmd.ExecuteScalar());
            }
        }

        /// <summary>
        /// Drops selections that cannot be combined with the one the user just changed
        /// (e.g. a program that does not belong to the newly chosen institute).
        /// </summary>
        private static PatronFilter Resolve(MySqlConnection conn, PatronFilter f, string changed)
        {
            var cur = f.Clone();
            string[] dropOrder = { "program", "institute", "ptype", "gender" };
            int guard = 0;
            while (cur.Any && CountPatrons(conn, cur) == 0 && guard++ < 4)
            {
                bool dropped = false;
                foreach (string facet in dropOrder)
                {
                    if (facet == changed) continue;
                    if (facet == "program" && cur.Program != "") { cur.Program = ""; dropped = true; break; }
                    if (facet == "institute" && cur.Institute != "") { cur.Institute = ""; dropped = true; break; }
                    if (facet == "ptype" && cur.PType != "") { cur.PType = ""; dropped = true; break; }
                    if (facet == "gender" && cur.Gender != "") { cur.Gender = ""; dropped = true; break; }
                }
                if (!dropped) break;
            }
            return cur;
        }

        /// <summary>
        /// Dropdown options for all four filters. Each list is computed from the patrons that
        /// match the OTHER three filters, so incompatible choices never appear, and any stale
        /// selection is cleared and reported back in 'selected'.
        /// </summary>
        private object GetPatronFilters(HttpContext ctx)
        {
            var f = PatronFilter.From(ctx);
            string changed = Clean(ctx.Request.QueryString["changed"], 12);

            using (var conn = new MySqlConnection(DbHelper.ConnStr))
            {
                conn.Open();
                f = Resolve(conn, f, changed);

                var institutes = Facet(conn, f, "institute", "COALESCE(d.institute, '" + Unassigned + "')");
                var programs = Facet(conn, f, "program", "d.program", "d.program IS NOT NULL");
                var types = Facet(conn, f, "ptype", "d.ptype");
                var genders = Facet(conn, f, "gender", "COALESCE(d.gender, '" + Unspecified + "')");

                return new
                {
                    selected = new { institute = f.Institute, program = f.Program, ptype = f.PType, gender = f.Gender },
                    institutes = institutes,
                    programs = programs,
                    ptypes = types,
                    genders = genders
                };
            }
        }

        private static List<object> Facet(MySqlConnection conn, PatronFilter f, string facet, string valueExpr, string extraWhere = null)
        {
            var sql = new StringBuilder("SELECT " + valueExpr + " AS v, COUNT(*) AS c FROM " + PatronDir + " WHERE 1=1");
            if (extraWhere != null) sql.Append(" AND " + extraWhere);

            var list = new List<object>();
            using (var cmd = new MySqlCommand("", conn))
            {
                f.Apply(sql, cmd, facet);
                sql.Append(" GROUP BY v ORDER BY v");
                cmd.CommandText = sql.ToString();
                cmd.CommandTimeout = 60;
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                        list.Add(new { value = Convert.ToString(r["v"]), count = Convert.ToInt32(r["c"]) });
                }
            }
            return list;
        }

        /// <summary>Top Programs, Top Institutes, Patron Distribution and Gender Distribution for the active filters.</summary>
        private object GetPatronOverview(HttpContext ctx)
        {
            var f = PatronFilter.From(ctx);

            using (var conn = new MySqlConnection(DbHelper.ConnStr))
            {
                conn.Open();

                int total = CountPatrons(conn, f);

                var instRows = TopList(conn, f, "d.institute", 4);
                var progRows = TopList(conn, f, "d.program", 4);

                int faculty = 0, student = 0, staff = 0, male = 0, female = 0, unspecified = 0;
                var sql = new StringBuilder(@"
                    SELECT COALESCE(SUM(d.ptype = 'Faculty'), 0) AS fac, COALESCE(SUM(d.ptype = 'Student'), 0) AS stu,
                           COALESCE(SUM(d.ptype = 'Staff'), 0)   AS stf, COALESCE(SUM(d.gender = 'Male'), 0)   AS mal,
                           COALESCE(SUM(d.gender = 'Female'), 0) AS fem, COALESCE(SUM(d.gender IS NULL), 0)    AS uns
                      FROM " + PatronDir + " WHERE 1=1");
                using (var cmd = new MySqlCommand("", conn))
                {
                    f.Apply(sql, cmd, null);
                    cmd.CommandText = sql.ToString();
                    cmd.CommandTimeout = 60;
                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            faculty = Convert.ToInt32(r["fac"]); student = Convert.ToInt32(r["stu"]); staff = Convert.ToInt32(r["stf"]);
                            male = Convert.ToInt32(r["mal"]); female = Convert.ToInt32(r["fem"]); unspecified = Convert.ToInt32(r["uns"]);
                        }
                    }
                }

                return new
                {
                    total = total,
                    institutes = instRows,
                    programs = progRows,
                    patron = new { faculty = faculty, student = student, staff = staff },
                    gender = new { male = male, female = female, unspecified = unspecified }
                };
            }
        }

        /// <summary>Counts per value of 'col' for the active filters; percentage is relative to the filtered rows that HAVE a value.</summary>
        private static List<object> TopList(MySqlConnection conn, PatronFilter f, string col, int limit)
        {
            var sql = new StringBuilder("SELECT " + col + " AS name, COUNT(*) AS cnt FROM " + PatronDir + " WHERE " + col + " IS NOT NULL");
            var rows = new List<KeyValuePair<string, int>>();
            int baseTotal = 0;

            using (var cmd = new MySqlCommand("", conn))
            {
                f.Apply(sql, cmd, null);
                sql.Append(" GROUP BY " + col + " ORDER BY cnt DESC, name ASC");
                cmd.CommandText = sql.ToString();
                cmd.CommandTimeout = 60;
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        int c = Convert.ToInt32(r["cnt"]);
                        baseTotal += c;
                        rows.Add(new KeyValuePair<string, int>(Convert.ToString(r["name"]), c));
                    }
                }
            }

            var list = new List<object>();
            for (int i = 0; i < rows.Count && i < limit; i++)
            {
                int pct = baseTotal > 0 ? (int)Math.Round(rows[i].Value * 100.0 / baseTotal, MidpointRounding.AwayFromZero) : 0;
                list.Add(new { name = rows[i].Key, count = rows[i].Value, percentage = pct });
            }
            return list;
        }

        /// <summary>Penalty Tracking table - 10 rows per page, honours the Patrons filters and the search box.</summary>
        private object GetPenalties(HttpContext ctx)
        {
            var f = PatronFilter.From(ctx);
            string q = Clean(ctx.Request.QueryString["q"], 60);
            int page = IntParam(ctx, "page", 1, 1, int.MaxValue);

            var where = new StringBuilder(" WHERE p.fine_amount > 0");
            using (var conn = new MySqlConnection(DbHelper.ConnStr))
            using (var cmd = new MySqlCommand("", conn))
            {
                f.Apply(where, cmd, null);
                if (q != "")
                {
                    where.Append(" AND (d.full_name LIKE @q OR p.user_id LIKE @q)");
                    cmd.Parameters.AddWithValue("@q", "%" + EscapeLike(q) + "%");
                }

                string from = @"
                    FROM penalties p
                    JOIN transactions t ON p.transaction_id = t.transaction_id
                    LEFT JOIN " + PatronDir + @" ON d.uid = p.user_id
                    LEFT JOIN item_copies c ON p.accession_number = c.accession_number
                    LEFT JOIN library_resources r ON c.resource_id = r.resource_id";

                conn.Open();
                cmd.CommandTimeout = 60;

                cmd.CommandText = "SELECT COUNT(*) " + from + where;
                int total = Convert.ToInt32(cmd.ExecuteScalar());

                int pages = Math.Max(1, (int)Math.Ceiling(total / (double)PageSize));
                if (page > pages) page = pages;

                cmd.CommandText = @"
                    SELECT t.borrow_date AS PenaltyDate, COALESCE(d.full_name, p.user_id) AS FullName, p.user_id AS PatronID,
                           COALESCE(d.program, d.institute, 'N/A') AS Program, r.title AS BookTitle,
                           p.penalty_type AS PenaltyType, p.fine_amount AS Amount, p.fine_status AS Status"
                    + from + where + @"
                    ORDER BY p.created_at DESC, p.penalty_id DESC
                    LIMIT @pgLim OFFSET @pgOff";
                cmd.Parameters.AddWithValue("@pgLim", PageSize);
                cmd.Parameters.AddWithValue("@pgOff", (page - 1) * PageSize);

                var dt = new DataTable();
                new MySqlDataAdapter(cmd).Fill(dt);
                return BuildPage(RowsToList(dt), page, total);
            }
        }

        // =================================================================
        // ATTENDANCE (shared date for occupancy, table and export)
        // =================================================================

        /// <summary>The selected date, or the DATABASE's "today" when none/invalid (so browser time zones never matter).</summary>
        private static DateTime ResolveDate(HttpContext ctx, MySqlConnection conn)
        {
            DateTime? d = ParseDate(ctx, "date");
            if (d.HasValue) return d.Value.Date;

            using (var cmd = new MySqlCommand("SELECT CURDATE()", conn))
            {
                object o = cmd.ExecuteScalar();
                return Convert.ToDateTime(o).Date;
            }
        }

        private static string NormalizeRole(string raw)
        {
            string r = Clean(raw, 10);
            return r == "Faculty" || r == "Student" || r == "Staff" ? r : "";
        }

        private const string AttendanceFrom = @"
            FROM library_attendance la
            LEFT JOIN " + PatronDir + @" ON d.uid = la.user_id
            LEFT JOIN users u ON u.user_id = la.user_id";

        private static string AttendanceWhere(MySqlCommand cmd, DateTime date, string role, string q)
        {
            var w = new StringBuilder(" WHERE la.time_in >= @dayStart AND la.time_in < @dayEnd");
            cmd.Parameters.AddWithValue("@dayStart", date.Date);
            cmd.Parameters.AddWithValue("@dayEnd", date.Date.AddDays(1));
            if (role != "")
            {
                w.Append(" AND d.ptype = @role");
                cmd.Parameters.AddWithValue("@role", role);
            }
            if (q != "")
            {
                w.Append(" AND (d.full_name LIKE @q OR la.user_id LIKE @q)");
                cmd.Parameters.AddWithValue("@q", "%" + EscapeLike(q) + "%");
            }
            return w.ToString();
        }

        private const string AttendanceSelect = @"
            SELECT la.attendance_id AS Id,
                   COALESCE(d.full_name, la.user_id)          AS FullName,
                   la.user_id                                  AS UserID,
                   COALESCE(d.ptype, 'Unclassified')           AS Role,
                   COALESCE(d.institute, 'N/A')                AS Institute,
                   COALESCE(d.program, 'N/A')                  AS Program,
                   COALESCE(la.purpose, '-')                   AS Purpose,
                   COALESCE(d.year_level, '-')                 AS Year,
                   la.time_in                                  AS Login,
                   la.time_out                                 AS Logout,
                   CASE WHEN la.attendance_status = 'Entry' THEN 'IN' ELSE 'OUT' END AS Status";

        /// <summary>Attendance table: newest first across the WHOLE dataset, then paged (10 per page).</summary>
        private object GetAttendancePage(HttpContext ctx)
        {
            int page = IntParam(ctx, "page", 1, 1, int.MaxValue);
            string role = NormalizeRole(ctx.Request.QueryString["role"]);
            string q = Clean(ctx.Request.QueryString["q"], 60);

            using (var conn = new MySqlConnection(DbHelper.ConnStr))
            using (var cmd = new MySqlCommand("", conn))
            {
                conn.Open();
                cmd.CommandTimeout = 60;
                DateTime date = ResolveDate(ctx, conn);
                string where = AttendanceWhere(cmd, date, role, q);

                cmd.CommandText = "SELECT COUNT(*) " + AttendanceFrom + where;
                int total = Convert.ToInt32(cmd.ExecuteScalar());

                int pages = Math.Max(1, (int)Math.Ceiling(total / (double)PageSize));
                if (page > pages) page = pages;

                cmd.CommandText = AttendanceSelect + AttendanceFrom + where
                                + " ORDER BY la.time_in DESC, la.attendance_id DESC LIMIT @pgLim OFFSET @pgOff";
                cmd.Parameters.AddWithValue("@pgLim", PageSize);
                cmd.Parameters.AddWithValue("@pgOff", (page - 1) * PageSize);

                var dt = new DataTable();
                new MySqlDataAdapter(cmd).Fill(dt);

                var items = RowsToList(dt);
                return new
                {
                    date = date.ToString("yyyy-MM-dd"),
                    items = items,
                    page = page,
                    pageSize = PageSize,
                    total = total,
                    totalPages = pages
                };
            }
        }

        private class OccupancyResult
        {
            public DateTime Date;
            public int Visits, UniqueVisitors, StillInside;
            public int PeakTotal, PeakStudy, PeakResearch;
            public double AvgFacultyMin, AvgStudentMin;
            public int FacultyVisits, StudentVisits, StaffVisits;
        }

        /// <summary>Occupancy statistics for the selected date (computed from the same rows the table shows).</summary>
        private static OccupancyResult ComputeOccupancy(MySqlConnection conn, DateTime date)
        {
            var res = new OccupancyResult { Date = date };
            var sessions = new List<Session>();
            var users = new HashSet<string>();
            double facSum = 0, stuSum = 0; int facN = 0, stuN = 0;

            using (var cmd = new MySqlCommand(@"
                SELECT la.user_id, la.time_in, la.time_out, la.purpose, la.attendance_status, d.ptype
                  FROM library_attendance la
                  LEFT JOIN " + PatronDir + @" ON d.uid = la.user_id
                 WHERE la.time_in >= @dayStart AND la.time_in < @dayEnd", conn))
            {
                cmd.CommandTimeout = 60;
                cmd.Parameters.AddWithValue("@dayStart", date.Date);
                cmd.Parameters.AddWithValue("@dayEnd", date.Date.AddDays(1));
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        DateTime tin = Convert.ToDateTime(r["time_in"]);
                        DateTime? tout = r["time_out"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(r["time_out"]);
                        string purpose = r["purpose"] == DBNull.Value ? "" : Convert.ToString(r["purpose"]).Trim();
                        string ptype = r["ptype"] == DBNull.Value ? "" : Convert.ToString(r["ptype"]);

                        sessions.Add(new Session { In = tin, Out = tout, Purpose = purpose });
                        users.Add(Convert.ToString(r["user_id"]));
                        res.Visits++;

                        if (ptype == "Faculty") res.FacultyVisits++;
                        else if (ptype == "Student") res.StudentVisits++;
                        else if (ptype == "Staff") res.StaffVisits++;

                        string status = r["attendance_status"] == DBNull.Value ? "" : Convert.ToString(r["attendance_status"]);
                        if (!tout.HasValue && status == "Entry") res.StillInside++;

                        if (tout.HasValue && tout.Value >= tin)
                        {
                            double mins = (tout.Value - tin).TotalMinutes;
                            if (ptype == "Faculty") { facSum += mins; facN++; }
                            else if (ptype == "Student") { stuSum += mins; stuN++; }
                        }
                    }
                }
            }

            res.UniqueVisitors = users.Count;
            res.AvgFacultyMin = facN > 0 ? facSum / facN : 0;
            res.AvgStudentMin = stuN > 0 ? stuSum / stuN : 0;
            res.PeakTotal = Peak(sessions, null);
            res.PeakStudy = Peak(sessions, "Study");
            res.PeakResearch = Peak(sessions, "Research");
            return res;
        }

        private class Session
        {
            public DateTime In;
            public DateTime? Out;
            public string Purpose;
        }

        /// <summary>Highest number of people inside at the same moment (sweep line). purpose == null means everyone.</summary>
        private static int Peak(List<Session> sessions, string purpose)
        {
            var events = new List<KeyValuePair<DateTime, int>>();
            foreach (var s in sessions)
            {
                if (purpose != null && !string.Equals(s.Purpose, purpose, StringComparison.OrdinalIgnoreCase)) continue;
                events.Add(new KeyValuePair<DateTime, int>(s.In, +1));
                if (s.Out.HasValue && s.Out.Value >= s.In)
                    events.Add(new KeyValuePair<DateTime, int>(s.Out.Value, -1));
            }
            // same instant: exits are processed before entries
            events.Sort((a, b) => a.Key != b.Key ? a.Key.CompareTo(b.Key) : a.Value.CompareTo(b.Value));

            int cur = 0, peak = 0;
            foreach (var e in events)
            {
                cur += e.Value;
                if (cur > peak) peak = cur;
            }
            return peak;
        }

        private object GetOccupancy(HttpContext ctx)
        {
            using (var conn = new MySqlConnection(DbHelper.ConnStr))
            {
                conn.Open();
                DateTime date = ResolveDate(ctx, conn);
                OccupancyResult o = ComputeOccupancy(conn, date);

                return new
                {
                    date = date.ToString("yyyy-MM-dd"),
                    visits = o.Visits,
                    uniqueVisitors = o.UniqueVisitors,
                    stillInside = o.StillInside,
                    total = new { value = o.PeakTotal, capacity = CapTotal },
                    study = new { value = o.PeakStudy, capacity = CapStudy },
                    research = new { value = o.PeakResearch, capacity = CapResearch },
                    avgFacultyMinutes = Math.Round(o.AvgFacultyMin, 1),
                    avgStudentMinutes = Math.Round(o.AvgStudentMin, 1)
                };
            }
        }

        /// <summary>Excel export of BOTH datasets (Occupancy Overview + Attendance) for the one selected date.</summary>
        private void ExportAttendance(HttpContext ctx)
        {
            string role = NormalizeRole(ctx.Request.QueryString["role"]);
            string q = Clean(ctx.Request.QueryString["q"], 60);

            using (var conn = new MySqlConnection(DbHelper.ConnStr))
            using (var cmd = new MySqlCommand("", conn))
            {
                conn.Open();
                cmd.CommandTimeout = 60;
                DateTime date = ResolveDate(ctx, conn);

                OccupancyResult o = ComputeOccupancy(conn, date);

                string where = AttendanceWhere(cmd, date, role, q);
                cmd.CommandText = AttendanceSelect + AttendanceFrom + where
                                + " ORDER BY la.time_in DESC, la.attendance_id DESC";
                var dt = new DataTable();
                new MySqlDataAdapter(cmd).Fill(dt);

                using (var wb = new XLWorkbook())
                {
                    // ---- Sheet 1: Occupancy Overview ----
                    var ws1 = wb.Worksheets.Add("Occupancy Overview");
                    ws1.Cell(1, 1).Value = "Library Occupancy Overview";
                    ws1.Cell(1, 1).Style.Font.Bold = true; ws1.Cell(1, 1).Style.Font.FontSize = 14;
                    ws1.Cell(2, 1).Value = "Date";
                    ws1.Cell(2, 2).Value = date.Date;
                    ws1.Cell(2, 2).Style.DateFormat.Format = "yyyy-mm-dd";
                    ws1.Cell(2, 2).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Left;

                    int rr = 4;
                    string[] heads = { "Measure", "Value", "Capacity", "Notes" };
                    for (int c = 0; c < heads.Length; c++) ws1.Cell(rr, c + 1).Value = heads[c];
                    StyleHeader(ws1.Range(rr, 1, rr, heads.Length));
                    rr++;

                    AddRow(ws1, ref rr, "Total visits (check-ins)", o.Visits, null, "All attendance records with a time-in on this date");
                    AddRow(ws1, ref rr, "Unique visitors", o.UniqueVisitors, null, "Distinct patron IDs");
                    AddRow(ws1, ref rr, "Peak total occupancy", o.PeakTotal, CapTotal, "Highest number inside at the same time");
                    AddRow(ws1, ref rr, "Peak General Area (Study)", o.PeakStudy, CapStudy, "Purpose = Study");
                    AddRow(ws1, ref rr, "Peak Virtual Room (Research)", o.PeakResearch, CapResearch, "Purpose = Research");
                    AddRow(ws1, ref rr, "Still inside (no time-out)", o.StillInside, null, "Status Entry and no time-out recorded");
                    AddRow(ws1, ref rr, "Faculty visits", o.FacultyVisits, null, "");
                    AddRow(ws1, ref rr, "Student visits", o.StudentVisits, null, "");
                    AddRow(ws1, ref rr, "Staff visits", o.StaffVisits, null, "");
                    AddRow(ws1, ref rr, "Avg. stay - Faculty (minutes)", Math.Round(o.AvgFacultyMin, 1), null, "Completed visits only");
                    AddRow(ws1, ref rr, "Avg. stay - Student (minutes)", Math.Round(o.AvgStudentMin, 1), null, "Completed visits only");
                    ws1.Columns().AdjustToContents();

                    // ---- Sheet 2: Attendance ----
                    var ws2 = wb.Worksheets.Add("Attendance");
                    string[] cols = { "Patron ID", "Name", "Patron Type", "Institute", "Program", "Purpose", "Year Level", "Time In", "Time Out", "Status" };
                    for (int c = 0; c < cols.Length; c++) ws2.Cell(1, c + 1).Value = cols[c];
                    StyleHeader(ws2.Range(1, 1, 1, cols.Length));

                    int row = 2;
                    foreach (DataRow dr in dt.Rows)
                    {
                        ws2.Cell(row, 1).Value = Convert.ToString(dr["UserID"]);
                        ws2.Cell(row, 2).Value = Convert.ToString(dr["FullName"]);
                        ws2.Cell(row, 3).Value = Convert.ToString(dr["Role"]);
                        ws2.Cell(row, 4).Value = Convert.ToString(dr["Institute"]);
                        ws2.Cell(row, 5).Value = Convert.ToString(dr["Program"]);
                        ws2.Cell(row, 6).Value = Convert.ToString(dr["Purpose"]);
                        ws2.Cell(row, 7).Value = Convert.ToString(dr["Year"]);

                        ws2.Cell(row, 8).Value = Convert.ToDateTime(dr["Login"]);
                        ws2.Cell(row, 8).Style.DateFormat.Format = "yyyy-mm-dd hh:mm:ss AM/PM";
                        if (dr["Logout"] != DBNull.Value)
                        {
                            ws2.Cell(row, 9).Value = Convert.ToDateTime(dr["Logout"]);
                            ws2.Cell(row, 9).Style.DateFormat.Format = "yyyy-mm-dd hh:mm:ss AM/PM";
                        }
                        else ws2.Cell(row, 9).Value = "-";
                        ws2.Cell(row, 10).Value = Convert.ToString(dr["Status"]);
                        row++;
                    }
                    ws2.SheetView.FreezeRows(1);
                    ws2.Columns().AdjustToContents();

                    // note about active filters on the attendance sheet
                    if (role != "" || q != "")
                    {
                        ws1.Cell(rr + 1, 1).Value = "Attendance sheet filters";
                        ws1.Cell(rr + 1, 2).Value = (role != "" ? "Patron type = " + role : "") + (role != "" && q != "" ? "; " : "") + (q != "" ? "Search = \"" + q + "\"" : "");
                    }

                    string fileName = "LMSA_Occupancy_Attendance_" + date.ToString("yyyy-MM-dd") + ".xlsx";
                    ctx.Response.Clear();
                    ctx.Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                    ctx.Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");

                    using (var ms = new MemoryStream())
                    {
                        wb.SaveAs(ms);
                        ms.WriteTo(ctx.Response.OutputStream);
                    }
                    ctx.Response.Flush();
                    if (ctx.ApplicationInstance != null) ctx.ApplicationInstance.CompleteRequest();
                }
            }
        }

        private static void AddRow(IXLWorksheet ws, ref int row, string measure, double value, int? capacity, string note)
        {
            ws.Cell(row, 1).Value = measure;
            ws.Cell(row, 2).Value = value;
            if (capacity.HasValue) ws.Cell(row, 3).Value = capacity.Value;
            ws.Cell(row, 4).Value = note;
            row++;
        }

        private static void StyleHeader(IXLRange range)
        {
            range.Style.Font.Bold = true;
            range.Style.Font.FontColor = XLColor.White;
            range.Style.Fill.BackgroundColor = XLColor.FromHtml("#14532d");
        }

        // =================================================================
        // SHARED HELPERS
        // =================================================================

        /// <summary>
        /// Runs a query that has no LIMIT, returning one page. 'cap' (0 = none) limits the total
        /// rows available across all pages, preserving the original "top N" meaning of an analytic.
        /// </summary>
        private static void PagedQuery(MySqlConnection conn, string sql, Dictionary<string, object> prms,
                                       int page, int cap, out DataTable dt, out int total)
        {
            using (var countCmd = new MySqlCommand("SELECT COUNT(*) FROM (" + sql + ") AS q", conn))
            {
                countCmd.CommandTimeout = 60;
                AddParams(countCmd, prms);
                total = Convert.ToInt32(countCmd.ExecuteScalar());
            }
            if (cap > 0 && total > cap) total = cap;

            int pages = Math.Max(1, (int)Math.Ceiling(total / (double)PageSize));
            if (page > pages) page = pages;
            int offset = (page - 1) * PageSize;
            int take = Math.Max(0, Math.Min(PageSize, total - offset));

            dt = new DataTable();
            if (take == 0) return;

            using (var cmd = new MySqlCommand(sql + " LIMIT @pgLim OFFSET @pgOff", conn))
            {
                cmd.CommandTimeout = 60;
                AddParams(cmd, prms);
                cmd.Parameters.AddWithValue("@pgLim", take);
                cmd.Parameters.AddWithValue("@pgOff", offset);
                new MySqlDataAdapter(cmd).Fill(dt);
            }
        }

        private static void AddParams(MySqlCommand cmd, Dictionary<string, object> prms)
        {
            if (prms == null) return;
            foreach (var kv in prms) cmd.Parameters.AddWithValue(kv.Key, kv.Value);
        }

        private static object BuildPage(List<Dictionary<string, object>> items, int page, int total)
        {
            int pages = Math.Max(1, (int)Math.Ceiling(total / (double)PageSize));
            if (page > pages) page = pages;
            return new { items = items, page = page, pageSize = PageSize, total = total, totalPages = pages };
        }

        private static List<Dictionary<string, object>> RowsToList(DataTable dt)
        {
            var list = new List<Dictionary<string, object>>();
            foreach (DataRow row in dt.Rows)
            {
                var d = new Dictionary<string, object>();
                foreach (DataColumn col in dt.Columns)
                {
                    object v = row[col];
                    if (v == DBNull.Value) d[col.ColumnName] = null;
                    else if (v is DateTime)
                    {
                        DateTime dtv = (DateTime)v;
                        // dates stay plain strings so no time-zone conversion can ever happen in the browser
                        d[col.ColumnName] = dtv.ToString("yyyy-MM-ddTHH:mm:ss", CultureInfo.InvariantCulture);
                    }
                    else if (v is decimal) d[col.ColumnName] = Convert.ToDouble(v);
                    else if (v is MySql.Data.Types.MySqlDateTime)
                    {
                        var m = (MySql.Data.Types.MySqlDateTime)v;
                        d[col.ColumnName] = m.IsValidDateTime ? m.GetDateTime().ToString("yyyy-MM-ddTHH:mm:ss", CultureInfo.InvariantCulture) : null;
                    }
                    else d[col.ColumnName] = v;
                }
                list.Add(d);
            }
            return list;
        }

        private static DateTime? ParseDate(HttpContext ctx, string key)
        {
            string raw = ctx.Request.QueryString[key];
            DateTime d;
            if (!string.IsNullOrWhiteSpace(raw) &&
                DateTime.TryParseExact(raw.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out d))
                return d.Date;
            return null;
        }

        private static int IntParam(HttpContext ctx, string key, int fallback, int min, int max)
        {
            int v;
            if (!int.TryParse(ctx.Request.QueryString[key], out v)) v = fallback;
            if (v < min) v = min;
            if (v > max) v = max;
            return v;
        }

        private static string Clean(string raw, int maxLen)
        {
            if (string.IsNullOrWhiteSpace(raw)) return "";
            string s = raw.Trim();
            return s.Length > maxLen ? s.Substring(0, maxLen) : s;
        }

        private static string EscapeLike(string s)
        {
            return s.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_");
        }

        private static void WriteJson(HttpContext ctx, object payload)
        {
            var ser = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
            ctx.Response.Write(ser.Serialize(payload));
        }
    }
}
