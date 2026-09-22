using MySql.Data.MySqlClient;
using spmst_lms_development.Assets.Helper;
using System;
using System.Data;

namespace spmst_lms_development.Assets.Helper.Handlers
{
    public class AttendanceHelper
    {
        private readonly string _connStr = DbHelper.ConnStr;

        public class OccupancyStats
        {
            public int Total;
            public int StudyArea;
            public int ResearchArea;
        }

        public class StayDurationStats
        {
            public double FacultyAvg;
            public double StudentAvg;
        }

        public OccupancyStats GetOccupancyStats()
        {
            var s = new OccupancyStats();
            using (var conn = new MySqlConnection(_connStr))
            {
                const string sql = @"
                    SELECT
                        COUNT(*)                                              AS Total,
                        SUM(CASE WHEN purpose = 'Study'    THEN 1 ELSE 0 END) AS StudyArea,
                        SUM(CASE WHEN purpose = 'Research' THEN 1 ELSE 0 END) AS ResearchArea
                    FROM Library_Attendance
                    WHERE attendance_status = 'Entry' AND time_out IS NULL";
                conn.Open();
                using (var cmd = new MySqlCommand(sql, conn))
                using (var r = cmd.ExecuteReader())
                {
                    if (r.Read())
                    {
                        s.Total = DbHelper.SafeGetInt(r, "Total");
                        s.StudyArea = DbHelper.SafeGetInt(r, "StudyArea");
                        s.ResearchArea = DbHelper.SafeGetInt(r, "ResearchArea");
                    }
                }
            }
            return s;
        }

        public StayDurationStats GetStayDurationStats()
        {
            var s = new StayDurationStats();
            using (var conn = new MySqlConnection(_connStr))
            {
                const string sql = @"
                    SELECT
                        AVG(CASE WHEN u.role = 'faculty'
                                 THEN TIMESTAMPDIFF(MINUTE, la.time_in, la.time_out) END) AS FacultyAvg,
                        AVG(CASE WHEN u.role = 'student'
                                 THEN TIMESTAMPDIFF(MINUTE, la.time_in, la.time_out) END) AS StudentAvg
                    FROM Library_Attendance la
                    INNER JOIN Users u ON la.user_id = u.user_id
                    WHERE la.time_out IS NOT NULL";
                conn.Open();
                using (var cmd = new MySqlCommand(sql, conn))
                using (var r = cmd.ExecuteReader())
                {
                    if (r.Read())
                    {
                        s.FacultyAvg = r["FacultyAvg"] == DBNull.Value ? 0 : Convert.ToDouble(r["FacultyAvg"]);
                        s.StudentAvg = r["StudentAvg"] == DBNull.Value ? 0 : Convert.ToDouble(r["StudentAvg"]);
                    }
                }
            }
            return s;
        }

        /// <summary>roleFilter = "All" | "Faculty" | "Student".</summary>
        public DataTable GetAttendance(string roleFilter, string searchTerm)
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                string sql = @"
                    SELECT
                        COALESCE(
                            CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name, s.extension_name),
                            CONCAT_WS(' ', f.first_name, f.middle_name, f.last_name, f.extension_name),
                            CONCAT_WS(' ', st.first_name, st.middle_name, st.last_name, st.extension_name),
                            u.user_id
                        )                                                     AS FullName,
                        la.user_id                                            AS UserID,
                        u.role                                                AS Role,
                        COALESCE(s.institute, f.institute, st.office_department, 'N/A') AS Institute,
                        COALESCE(s.course, 'N/A')                             AS Program,
                        la.purpose                                            AS Purpose,
                        COALESCE(s.year_level, '-')                           AS Year,
                        la.time_in                                            AS Login,
                        la.time_out                                           AS Logout,
                        CASE WHEN la.attendance_status = 'Entry' THEN 'IN' ELSE 'OUT' END AS Status
                    FROM Library_Attendance la
                    INNER JOIN Users u ON la.user_id = u.user_id
                    LEFT JOIN Students s ON la.user_id = s.student_id
                    LEFT JOIN Faculty  f ON la.user_id = f.faculty_id
                    LEFT JOIN Staff    st ON la.user_id = st.staff_id
                    WHERE 1=1";

                if (roleFilter == "Faculty") sql += " AND u.role = 'faculty'";
                else if (roleFilter == "Student") sql += " AND u.role = 'student'";

                if (!string.IsNullOrEmpty(searchTerm))
                {
                    sql += @" AND (s.first_name LIKE @search OR s.last_name  LIKE @search
                              OR f.first_name  LIKE @search OR f.last_name  LIKE @search
                              OR st.first_name LIKE @search OR st.last_name LIKE @search
                              OR la.user_id    LIKE @search)";
                }
                sql += " ORDER BY la.time_in DESC";

                using (var cmd = new MySqlCommand(sql, conn))
                {
                    if (!string.IsNullOrEmpty(searchTerm))
                        cmd.Parameters.AddWithValue("@search", "%" + searchTerm + "%");
                    var dt = new DataTable();
                    conn.Open();
                    new MySqlDataAdapter(cmd).Fill(dt);
                    return dt;
                }
            }
        }

        public class ManagementKpis
        {
            public int FacultyVisits;
            public int StudentVisits;
            public int CurrentlyInside;
            public int TodayVisits;
            public int TotalFaculty;
            public int TotalStudents;
            public int TotalPrograms;
            public int TotalInstitutes;
        }

        /// <summary>Aggregate KPIs for the management dashboard KPI cards.</summary>
        public ManagementKpis GetManagementKpis()
        {
            var k = new ManagementKpis();
            using (var conn = new MySqlConnection(_connStr))
            {
                const string sql = @"
            SELECT
                (SELECT COUNT(*) FROM Library_Attendance la
                    INNER JOIN Users u ON la.user_id = u.user_id
                    WHERE u.role = 'faculty')                                       AS FacultyVisits,
                (SELECT COUNT(*) FROM Library_Attendance la
                    INNER JOIN Users u ON la.user_id = u.user_id
                    WHERE u.role = 'student')                                       AS StudentVisits,
                (SELECT COUNT(*) FROM Library_Attendance
                    WHERE attendance_status = 'Entry' AND time_out IS NULL)         AS CurrentlyInside,
                (SELECT COUNT(*) FROM Library_Attendance
                    WHERE DATE(time_in) = CURDATE())                                AS TodayVisits,
                (SELECT COUNT(*) FROM Faculty)                                      AS TotalFaculty,
                (SELECT COUNT(*) FROM Students)                                     AS TotalStudents,
                (SELECT COUNT(DISTINCT course) FROM Students
                    WHERE course IS NOT NULL AND course <> '')                      AS TotalPrograms,
                (SELECT COUNT(*) FROM (
                    SELECT institute FROM Students
                        WHERE institute IS NOT NULL AND institute <> ''
                    UNION
                    SELECT institute FROM Faculty
                        WHERE institute IS NOT NULL AND institute <> ''
                ) AS inst)                                                          AS TotalInstitutes";
                conn.Open();
                using (var cmd = new MySqlCommand(sql, conn))
                using (var r = cmd.ExecuteReader())
                {
                    if (r.Read())
                    {
                        k.FacultyVisits = DbHelper.SafeGetInt(r, "FacultyVisits");
                        k.StudentVisits = DbHelper.SafeGetInt(r, "StudentVisits");
                        k.CurrentlyInside = DbHelper.SafeGetInt(r, "CurrentlyInside");
                        k.TodayVisits = DbHelper.SafeGetInt(r, "TodayVisits");
                        k.TotalFaculty = DbHelper.SafeGetInt(r, "TotalFaculty");
                        k.TotalStudents = DbHelper.SafeGetInt(r, "TotalStudents");
                        k.TotalPrograms = DbHelper.SafeGetInt(r, "TotalPrograms");
                        k.TotalInstitutes = DbHelper.SafeGetInt(r, "TotalInstitutes");
                    }
                }
            }
            return k;
        }
    }
}