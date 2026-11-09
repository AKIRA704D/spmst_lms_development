using spmst_lms_development.Assets.Helper;
using System.Collections.Generic;
using System.Web.Services;

namespace spmst_lms_development.Users.Staff.Penalties
{
    public partial class Penalties : System.Web.UI.Page
    {
        [WebMethod]
        public static List<PenaltyService.PenaltyRecord> GetPenalties()
        {
            return PenaltyService.GetPenalties();
        }
    }
}