using System;
using System.Configuration;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Assets.Helper.Notifications
{
    /// <summary>
    /// Resolves a patron's contact details (mobile, email, full name)
    /// by walking the Students -> Faculty -> Staff tables.
    /// Mobile lookups delegate to ReservationSmsService to avoid
    /// duplicating the existing query.
    /// </summary>
    public static class PatronContactResolver
    {
        private static string ConnStr
        {
            get { return ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString; }
        }

        // table|id_column
        private static readonly string[] PersonTables =
        {
            "Students|student_id",
            "Faculty|faculty_id",
            "Staff|staff_id"
        };

        public static string GetMobileNumber(string userId)
        {
            // Reuse the already-implemented resolver.
            return ReservationSmsService.GetMobileNumber(userId);
        }

        public static string GetEmail(string userId)
        {
            if (string.IsNullOrWhiteSpace(userId)) return null;
            return QuerySingle(userId, "email");
        }

        public static string GetFullName(string userId)
        {
            if (string.IsNullOrWhiteSpace(userId)) return null;

            using (var conn = new MySqlConnection(ConnStr))
            {
                conn.Open();
                foreach (var entry in PersonTables)
                {
                    var parts = entry.Split('|');
                    string sql = string.Format(
                        "SELECT CONCAT(first_name,' ',last_name) FROM `{0}` WHERE `{1}` = @uid LIMIT 1",
                        parts[0], parts[1]);

                    using (var cmd = new MySqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@uid", userId);
                        object o = cmd.ExecuteScalar();
                        if (o != null && o != DBNull.Value && !string.IsNullOrWhiteSpace(o.ToString()))
                            return o.ToString().Trim();
                    }
                }
            }
            return null;
        }

        private static string QuerySingle(string userId, string column)
        {
            using (var conn = new MySqlConnection(ConnStr))
            {
                conn.Open();
                foreach (var entry in PersonTables)
                {
                    var parts = entry.Split('|');
                    string sql = string.Format(
                        "SELECT `{0}` FROM `{1}` WHERE `{2}` = @uid LIMIT 1",
                        column, parts[0], parts[1]);

                    using (var cmd = new MySqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@uid", userId);
                        object o = cmd.ExecuteScalar();
                        if (o != null && o != DBNull.Value && !string.IsNullOrWhiteSpace(o.ToString()))
                            return o.ToString().Trim();
                    }
                }
            }
            return null;
        }
    }
}