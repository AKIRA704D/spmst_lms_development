using MySql.Data.MySqlClient;
using spmst_lms_development.Assets.Helper;
using System;
using System.Collections.Generic;
using System.Data;

namespace spmst_lms_development.Assets.Helper.Handlers
{
    public class CirculationHelper
    {
        private readonly string _connStr = DbHelper.ConnStr;

        public class DashboardStats
        {
            public int FacultyVisits;
            public int Circulated;
            public int OverdueCount;
            public decimal PendingTotal;
            public int ActivePatrons;
            public int DamageCount;
            public int LostCount;
            public decimal Collected;
        }

        public class PenaltyBreakdown
        {
            public decimal DamageAmt, LostAmt, OverdueAmt;
            public int DamageCount, LostCount, OverdueCount;
            public decimal TotalFine, TotalPaid, Balance;
        }

        public DashboardStats GetDashboardStats()
        {
            var s = new DashboardStats();
            using (var conn = new MySqlConnection(_connStr))
            {
                const string sql = @"
                    SELECT
                        (SELECT COUNT(*) FROM Library_Attendance la
                            INNER JOIN Users u ON la.user_id = u.user_id
                            WHERE u.role = 'faculty')                       AS FacultyVisits,
                        (SELECT COUNT(*) FROM Transactions WHERE status = 'Borrowed') AS Circulated,
                        (SELECT COUNT(*) FROM Transactions WHERE status = 'Overdue')  AS OverdueCount,
                        (SELECT IFNULL(SUM(balance), 0) FROM Transactions)         AS PendingTotal,
                        (SELECT COUNT(DISTINCT user_id) FROM Library_Attendance)   AS ActivePatrons,
                        (SELECT COUNT(*) FROM Item_Copies WHERE status_condition = 'Damage') AS DamageCount,
                        (SELECT COUNT(*) FROM Item_Copies WHERE status_condition = 'Lost')   AS LostCount,
                        (SELECT IFNULL(SUM(amount_paid), 0) FROM Transactions)     AS Collected";
                conn.Open();
                using (var cmd = new MySqlCommand(sql, conn))
                using (var r = cmd.ExecuteReader())
                {
                    if (r.Read())
                    {
                        s.FacultyVisits = DbHelper.SafeGetInt(r, "FacultyVisits");
                        s.Circulated = DbHelper.SafeGetInt(r, "Circulated");
                        s.OverdueCount = DbHelper.SafeGetInt(r, "OverdueCount");
                        s.PendingTotal = DbHelper.SafeGetDecimal(r, "PendingTotal");
                        s.ActivePatrons = DbHelper.SafeGetInt(r, "ActivePatrons");
                        s.DamageCount = DbHelper.SafeGetInt(r, "DamageCount");
                        s.LostCount = DbHelper.SafeGetInt(r, "LostCount");
                        s.Collected = DbHelper.SafeGetDecimal(r, "Collected");
                    }
                }
            }
            return s;
        }

        public string GetSectionJson(string start, string end) => GetJsonData(@"
            SELECT lr.section, COUNT(t.transaction_id) AS count
            FROM Transactions t
            JOIN Item_Copies       ic ON t.accession_number = ic.accession_number
            JOIN Library_Resources lr ON ic.resource_id    = lr.resource_id
            WHERE t.borrow_date BETWEEN @start AND @end
            GROUP BY lr.section
            ORDER BY count DESC
            LIMIT 10", start, end);

        public string GetSubjectJson(string start, string end) => GetJsonData(@"
            SELECT lr.dewey_decimal, COUNT(t.transaction_id) AS count
            FROM Transactions t
            JOIN Item_Copies       ic ON t.accession_number = ic.accession_number
            JOIN Library_Resources lr ON ic.resource_id    = lr.resource_id
            WHERE t.borrow_date BETWEEN @start AND @end
            GROUP BY lr.dewey_decimal
            ORDER BY count DESC
            LIMIT 10", start, end);

        public string GetInstituteJson(string start, string end) => GetStackedJson(@"
            SELECT
                COALESCE(s.institute, f.institute, st.office_department) AS institute,
                SUM(CASE WHEN t.status IN ('Borrowed','Overdue')  THEN 1 ELSE 0 END) AS Borrowed,
                SUM(CASE WHEN t.status = 'Returned'                THEN 1 ELSE 0 END) AS Returned,
                SUM(CASE WHEN t.status IN ('Reserved','Ready')     THEN 1 ELSE 0 END) AS Reserved,
                SUM(CASE WHEN u.role='student' AND t.status IN ('Borrowed','Overdue') THEN 1 ELSE 0 END) AS StudentBorrowed,
                SUM(CASE WHEN u.role='faculty' AND t.status IN ('Borrowed','Overdue') THEN 1 ELSE 0 END) AS FacultyBorrowed,
                SUM(CASE WHEN u.role='staff'   AND t.status IN ('Borrowed','Overdue') THEN 1 ELSE 0 END) AS StaffBorrowed
            FROM Transactions t
            INNER JOIN Users   u  ON t.user_id = u.user_id
            LEFT  JOIN Students s ON t.user_id = s.student_id
            LEFT  JOIN Faculty  f ON t.user_id = f.faculty_id
            LEFT  JOIN Staff    st ON t.user_id = st.staff_id
            WHERE t.borrow_date BETWEEN @start AND @end
            GROUP BY institute", "institute", start, end);

        public string GetProgramJson(string start, string end) => GetStackedJson(@"
            SELECT
                COALESCE(s.course, f.institute, st.office_department) AS program,
                SUM(CASE WHEN t.status IN ('Borrowed','Overdue')  THEN 1 ELSE 0 END) AS Borrowed,
                SUM(CASE WHEN t.status = 'Returned'                THEN 1 ELSE 0 END) AS Returned,
                SUM(CASE WHEN t.status IN ('Reserved','Ready')     THEN 1 ELSE 0 END) AS Reserved,
                SUM(CASE WHEN u.role='student' AND t.status IN ('Borrowed','Overdue') THEN 1 ELSE 0 END) AS StudentBorrowed,
                SUM(CASE WHEN u.role='faculty' AND t.status IN ('Borrowed','Overdue') THEN 1 ELSE 0 END) AS FacultyBorrowed,
                SUM(CASE WHEN u.role='staff'   AND t.status IN ('Borrowed','Overdue') THEN 1 ELSE 0 END) AS StaffBorrowed
            FROM Transactions t
            INNER JOIN Users   u  ON t.user_id = u.user_id
            LEFT  JOIN Students s ON t.user_id = s.student_id
            LEFT  JOIN Faculty  f ON t.user_id = f.faculty_id
            LEFT  JOIN Staff    st ON t.user_id = st.staff_id
            WHERE t.borrow_date BETWEEN @start AND @end
            GROUP BY program", "program", start, end);

        public PenaltyBreakdown GetPenaltyBreakdown(string start, string end)
        {
            var p = new PenaltyBreakdown();
            using (var conn = new MySqlConnection(_connStr))
            {
                const string sql = @"
                    SELECT
                        SUM(CASE WHEN t.is_damaged = 1 THEN 100 ELSE 0 END) AS DamageAmount,
                        SUM(CASE WHEN t.is_damaged = 1 THEN 1   ELSE 0 END) AS DamageCount,
                        SUM(CASE WHEN t.is_lost    = 1 THEN 600 ELSE 0 END) AS LostAmount,
                        SUM(CASE WHEN t.is_lost    = 1 THEN 1   ELSE 0 END) AS LostCount,
                        SUM(CASE
                            WHEN t.return_date IS NULL THEN
                                CASE WHEN t.due_date < CURDATE() THEN DATEDIFF(CURDATE(), t.due_date) * 5 ELSE 0 END
                            ELSE
                                CASE WHEN t.return_date > t.due_date THEN DATEDIFF(t.return_date, t.due_date) * 5 ELSE 0 END
                        END) AS OverdueAmount,
                        SUM(CASE
                            WHEN t.return_date IS NULL THEN
                                CASE WHEN t.due_date < CURDATE() THEN 1 ELSE 0 END
                            ELSE
                                CASE WHEN t.return_date > t.due_date THEN 1 ELSE 0 END
                        END) AS OverdueCount,
                        SUM(
                            CASE WHEN t.is_damaged = 1 THEN 100 ELSE 0 END
                          + CASE WHEN t.is_lost    = 1 THEN 600 ELSE 0 END
                          + CASE
                                WHEN t.return_date IS NULL THEN
                                    CASE WHEN t.due_date < CURDATE() THEN DATEDIFF(CURDATE(), t.due_date) * 5 ELSE 0 END
                                ELSE
                                    CASE WHEN t.return_date > t.due_date THEN DATEDIFF(t.return_date, t.due_date) * 5 ELSE 0 END
                            END
                        ) AS TotalComputedFine,
                        IFNULL(SUM(t.amount_paid), 0) AS TotalPaid
                    FROM Transactions t
                    WHERE t.borrow_date BETWEEN @start AND @end";
                conn.Open();
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@start", start);
                    cmd.Parameters.AddWithValue("@end", end);
                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            p.DamageAmt = DbHelper.SafeGetDecimal(r, "DamageAmount");
                            p.LostAmt = DbHelper.SafeGetDecimal(r, "LostAmount");
                            p.OverdueAmt = DbHelper.SafeGetDecimal(r, "OverdueAmount");
                            p.DamageCount = DbHelper.SafeGetInt(r, "DamageCount");
                            p.LostCount = DbHelper.SafeGetInt(r, "LostCount");
                            p.OverdueCount = DbHelper.SafeGetInt(r, "OverdueCount");
                            p.TotalFine = DbHelper.SafeGetDecimal(r, "TotalComputedFine");
                            p.TotalPaid = DbHelper.SafeGetDecimal(r, "TotalPaid");
                            p.Balance = p.TotalFine - p.TotalPaid;
                            if (p.Balance < 0) p.Balance = 0;
                        }
                    }
                }
            }
            return p;
        }

        public DataTable GetTopBorrowedBooks(int limit = 5)
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                const string sql = @"
                    SELECT lr.resource_id, lr.cover_path, lr.title, lr.author,
                           lr.section AS Category,
                        (SELECT COUNT(*) FROM Transactions t
                            INNER JOIN Item_Copies ic ON t.accession_number = ic.accession_number
                            WHERE ic.resource_id = lr.resource_id
                              AND t.status IN ('Borrowed','Returned'))            AS Checkouts,
                        (SELECT COUNT(*) FROM Transactions t
                            INNER JOIN Item_Copies ic ON t.accession_number = ic.accession_number
                            WHERE ic.resource_id = lr.resource_id
                              AND t.status IN ('Reserved','Ready'))               AS Waiting
                    FROM Library_Resources lr
                    ORDER BY Checkouts DESC
                    LIMIT @limit";
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@limit", limit);
                    var dt = new DataTable();
                    conn.Open();
                    new MySqlDataAdapter(cmd).Fill(dt);
                    return dt;
                }
            }
        }

        // -------- private helpers --------

        private string GetJsonData(string query, string start, string end)
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                var dt = new DataTable();
                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@start", start);
                    cmd.Parameters.AddWithValue("@end", end);
                    conn.Open();
                    new MySqlDataAdapter(cmd).Fill(dt);
                }
                var labels = new List<string>();
                var values = new List<int>();
                foreach (DataRow row in dt.Rows)
                {
                    labels.Add(row[0]?.ToString() ?? "");
                    values.Add(row[1] == DBNull.Value ? 0 : Convert.ToInt32(row[1]));
                }
                return DbHelper.ToJson(new { labels, values });
            }
        }

        private string GetStackedJson(string query, string labelField, string start, string end)
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                var dt = new DataTable();
                using (var cmd = new MySqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@start", start);
                    cmd.Parameters.AddWithValue("@end", end);
                    conn.Open();
                    new MySqlDataAdapter(cmd).Fill(dt);
                }
                var labels = new List<string>();
                var borrowed = new List<int>();
                var returned = new List<int>();
                var reserved = new List<int>();
                var borrowedRoles = new List<object>();
                foreach (DataRow row in dt.Rows)
                {
                    labels.Add(row[labelField]?.ToString() ?? "Unknown");
                    borrowed.Add(Convert.ToInt32(row["Borrowed"]));
                    returned.Add(Convert.ToInt32(row["Returned"]));
                    reserved.Add(Convert.ToInt32(row["Reserved"]));
                    borrowedRoles.Add(new
                    {
                        student = Convert.ToInt32(row["StudentBorrowed"]),
                        faculty = Convert.ToInt32(row["FacultyBorrowed"]),
                        staff = Convert.ToInt32(row["StaffBorrowed"])
                    });
                }
                return DbHelper.ToJson(new { labels, borrowed, returned, reserved, borrowedRoles });
            }
        }
    }
}