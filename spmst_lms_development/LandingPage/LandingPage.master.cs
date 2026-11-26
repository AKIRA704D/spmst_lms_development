using System;
using System.IO;
using spmst_lms_development.Assets.Helper;

namespace spmst_lms_development.LandingPage
{
    public partial class LandingPageMaster : System.Web.UI.MasterPage
    {
        // Computed on every access (no per-page state), backed by the cached BrandingService snapshot.
        /// <summary>Fully resolved URL for the School logo.</summary>
        protected string SchoolLogoUrl { get { return BrandingService.SchoolUrl; } }

        /// <summary>Fully resolved URL for the School Library (default department) logo.</summary>
        protected string LibraryLogoUrl { get { return BrandingService.LibraryUrl; } }

        /// <summary>Fully resolved URL for the System (LMSA) logo.</summary>
        protected string SystemLogoUrl { get { return BrandingService.SystemUrl; } }

        /// <summary>
        /// Returns "active" when the current page's file name matches the given
        /// key so the correct nav link gets highlighted in the header and offcanvas.
        /// </summary>
        protected string NavClass(string page)
        {
            string current = Path.GetFileNameWithoutExtension(Request.AppRelativeCurrentExecutionFilePath);
            return string.Equals(current, page, StringComparison.OrdinalIgnoreCase) ? "active" : string.Empty;
        }
    }
}