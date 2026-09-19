using System;
using System.Configuration;

namespace spmst_lms_development.Users.MasterPage.Components
{
    public partial class logo : System.Web.UI.Page
    {
        /// <summary>Text shown under the brand name, e.g. "v1.0.0".</summary>
        protected string AppVersionLabel { get; private set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            string version = ConfigurationManager.AppSettings["AppVersion"];
            AppVersionLabel = "v" + (string.IsNullOrWhiteSpace(version) ? "1.0.0" : version);
        }
    }
}
