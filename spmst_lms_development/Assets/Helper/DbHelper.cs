using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Web.Script.Serialization;

namespace spmst_lms_development.Assets.Helper
{
    /// <summary>
    /// Central place for connection string, null-safe readers, and JSON serialization.
    /// </summary>
    public static class DbHelper
    {
        public static string ConnStr =>
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        public static decimal SafeGetDecimal(MySqlDataReader r, string col)
            => r[col] == DBNull.Value ? 0m : Convert.ToDecimal(r[col]);

        public static int SafeGetInt(MySqlDataReader r, string col)
            => r[col] == DBNull.Value ? 0 : Convert.ToInt32(r[col]);

        public static string SafeGetString(MySqlDataReader r, string col)
            => r[col] == DBNull.Value ? string.Empty : r[col].ToString();

        public static string ToJson(object data)
            => new JavaScriptSerializer().Serialize(data);
    }
}