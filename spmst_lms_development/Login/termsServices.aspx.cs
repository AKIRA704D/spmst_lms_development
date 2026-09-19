using System;
using System.IO;
using System.Web.UI;

namespace spmst_lms_development.Login
{
    public partial class termsServices : System.Web.UI.Page
    {
        private readonly string PdfPath = "~/Assets/Terms/terms.pdf";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                string physicalPath = Server.MapPath(PdfPath);
                if (File.Exists(physicalPath))
                {
                    pnlPdf.Visible = true;
                    pnlFallback.Visible = false;
                    pdfFrame.Attributes["src"] = ResolveUrl(PdfPath) + "#toolbar=0&view=FitW";
                }
                else
                {
                    pnlPdf.Visible = false;
                    pnlFallback.Visible = true;
                }

                string userRole = Session["UserRole"]?.ToString() ?? "";
                lnkUpload.Visible = userRole.Equals("admin", StringComparison.OrdinalIgnoreCase);
            }
        }
    }
}