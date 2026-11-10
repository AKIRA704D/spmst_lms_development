using System;
using System.IO;
using spmst_lms_development.Helpers;

namespace spmst_lms_development.LandingPage
{
    public partial class LandingPageMaster : System.Web.UI.MasterPage
    {
        /// <summary>Fully resolved URL for the primary institutional logo.</summary>
        protected string SchoolLogoUrl { get; set; }

        /// <summary>Fully resolved URL for the library brand logo.</summary>
        protected string LibraryLogoUrl { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            // LogoHelper caches per entity type in HttpRuntime.Cache for 10 minutes,
            // so both calls are cheap even when hit repeatedly.
            SchoolLogoUrl = ResolveLogoPath(LogoHelper.GetHeaderLogo("School"));
            LibraryLogoUrl = ResolveLogoPath(LogoHelper.GetHeaderLogo("Library"));
        }

        /// <summary>
        /// Returns "active" when the current page's file name matches the given
        /// key so the correct nav link gets highlighted in the header and offcanvas.
        /// </summary>
        protected string NavClass(string page)
        {
            string current = Path.GetFileNameWithoutExtension(Request.AppRelativeCurrentExecutionFilePath);
            return string.Equals(current, page, StringComparison.OrdinalIgnoreCase) ? "active" : string.Empty;
        }

        private string ResolveLogoPath(string relativePath)
        {
            if (string.IsNullOrWhiteSpace(relativePath))
                relativePath = LogoHelper.DefaultSchoolLogo;

            string clean = relativePath.Replace('\\', '/').TrimStart('~', '/');
            return ResolveUrl("~/" + clean);
        }
    }
}