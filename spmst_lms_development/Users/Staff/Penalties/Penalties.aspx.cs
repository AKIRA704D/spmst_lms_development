using MySql.Data.MySqlClient;
using spmst_lms_development.Assets.Helper;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Web.Services;

namespace spmst_lms_development.Users.Staff.Penalties
{
    public partial class Penalties : System.Web.UI.Page
    {
        private static readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        [WebMethod]
        public static List<PenaltyService.PenaltyRecord> GetPenalties()
        {
            return PenaltyService.GetPenalties();
        }

        public class PenaltyRecord
        {
            public string TransactionID { get; set; }
            public string UserID { get; set; }
            public string PatronName { get; set; }
            public string Book { get; set; }
            public string AccessionNumber { get; set; }
            public string Reason { get; set; }
            public decimal Amount { get; set; }
            public decimal Balance { get; set; }
            public string Status { get; set; }
        }
    }
}