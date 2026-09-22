using MySql.Data.MySqlClient;
using spmst_lms_development.Assets.Helper;
using System;
using System.Data;

namespace spmst_lms_development.Assets.Helper.Handlers
{
    public class PatronAnalyticsHelper
    {
        private readonly string _connStr = DbHelper.ConnStr;

        public DataTable GetTopPrograms(int limit = 4)
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                const string sql = @"
                    SELECT course,
                           COUNT(*) AS Count,
                           ROUND(COUNT(*) * 100 / (SELECT NULLIF(COUNT(*),0) FROM Students), 0) AS Percentage
                    FROM Students
                    WHERE course IS NOT NULL AND course <> ''
                    GROUP BY course
                    ORDER BY Count DESC
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

        public DataTable GetTopInstitutes(int limit = 4)
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                const string sql = @"
                    SELECT institute,
                           COUNT(*) AS Count,
                           ROUND(COUNT(*) * 100 /
                               (SELECT NULLIF(COUNT(*),0) FROM (
                                   SELECT institute FROM Students WHERE institute IS NOT NULL AND institute <> ''
                                   UNION ALL
                                   SELECT institute FROM Faculty  WHERE institute IS NOT NULL AND institute <> ''
                               ) AS allInst), 0) AS Percentage
                    FROM (
                        SELECT institute FROM Students WHERE institute IS NOT NULL AND institute <> ''
                        UNION ALL
                        SELECT institute FROM Faculty  WHERE institute IS NOT NULL AND institute <> ''
                    ) AS Combined
                    GROUP BY institute
                    ORDER BY Count DESC
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

        /// <summary>Returns { patron:[faculty,student], gender:[male,female] }.</summary>
        public object GetDistribution()
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                const string sql = @"
                    SELECT
                        SUM(CASE WHEN role = 'faculty' THEN 1 ELSE 0 END) AS TotalFaculty,
                        SUM(CASE WHEN role = 'student' THEN 1 ELSE 0 END) AS TotalStudents,
                        SUM(CASE WHEN gender = 'Male'   THEN 1 ELSE 0 END) AS TotalMale,
                        SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) AS TotalFemale
                    FROM (
                        SELECT 'student' AS role, gender FROM Students
                        UNION ALL
                        SELECT 'faculty' AS role, gender FROM Faculty
                    ) AS Combined";
                conn.Open();
                using (var cmd = new MySqlCommand(sql, conn))
                using (var r = cmd.ExecuteReader())
                {
                    if (r.Read())
                    {
                        return new
                        {
                            patron = new[]
                            {
                                DbHelper.SafeGetInt(r, "TotalFaculty"),
                                DbHelper.SafeGetInt(r, "TotalStudents")
                            },
                            gender = new[]
                            {
                                DbHelper.SafeGetInt(r, "TotalMale"),
                                DbHelper.SafeGetInt(r, "TotalFemale")
                            }
                        };
                    }
                }
            }
            return new { patron = new[] { 0, 0 }, gender = new[] { 0, 0 } };
        }

        public DataTable GetPenalties(string searchTerm = "")
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                string sql = @"
                    SELECT
                        t.borrow_date                                          AS PenaltyDate,
                        COALESCE(
                            CONCAT_WS(' ', s.first_name,  s.last_name),
                            CONCAT_WS(' ', f.first_name,  f.last_name),
                            CONCAT_WS(' ', st.first_name, st.last_name),
                            t.user_id
                        )                                                      AS FullName,
                        t.user_id                                              AS PatronID,
                        COALESCE(s.course, f.institute, st.office_department, 'N/A') AS Program,
                        r.title                                                AS BookTitle,
                        CASE
                            WHEN t.is_damaged = 1 THEN 'Damage'
                            WHEN t.is_lost    = 1 THEN 'Lost'
                            ELSE 'Overdue'
                        END                                                    AS PenaltyType,
                        t.fine_amount                                          AS Amount,
                        t.fine_status                                          AS Status
                    FROM Transactions t
                    INNER JOIN Users            u  ON t.user_id          = u.user_id
                    LEFT  JOIN Students         s  ON t.user_id          = s.student_id
                    LEFT  JOIN Faculty          f  ON t.user_id          = f.faculty_id
                    LEFT  JOIN Staff            st ON t.user_id          = st.staff_id
                    INNER JOIN Item_Copies      c  ON t.accession_number = c.accession_number
                    INNER JOIN Library_Resources r ON c.resource_id      = r.resource_id
                    WHERE t.fine_amount > 0";
                if (!string.IsNullOrEmpty(searchTerm))
                {
                    sql += @" AND (s.first_name LIKE @s OR s.last_name LIKE @s
                              OR f.first_name  LIKE @s OR f.last_name LIKE @s
                              OR st.first_name LIKE @s OR st.last_name LIKE @s
                              OR t.user_id    LIKE @s)";
                }
                sql += " ORDER BY t.borrow_date DESC";

                using (var cmd = new MySqlCommand(sql, conn))
                {
                    if (!string.IsNullOrEmpty(searchTerm))
                        cmd.Parameters.AddWithValue("@s", "%" + searchTerm + "%");
                    var dt = new DataTable();
                    conn.Open();
                    new MySqlDataAdapter(cmd).Fill(dt);
                    return dt;
                }
            }
        }
    }
}