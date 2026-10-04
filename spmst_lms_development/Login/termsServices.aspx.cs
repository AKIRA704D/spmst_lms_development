using System;
using System.Configuration;
using System.IO;
using System.Web.UI;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Login
{
    public partial class termsServices : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadActiveTerms();
                SetUploadLinkVisibility();
            }
        }

        private void LoadActiveTerms()
        {
            string connStr = ConfigurationManager
                .ConnectionStrings["LmsDb"]?.ConnectionString;

            if (string.IsNullOrEmpty(connStr))
            {
                ShowFallback("Database connection is not configured.");
                return;
            }

            try
            {
                using (var conn = new MySqlConnection(connStr))
                {
                    conn.Open();
                    const string sql = @"SELECT file_path 
                                         FROM library_terms 
                                         WHERE is_active = 1 
                                         ORDER BY uploaded_at DESC 
                                         LIMIT 1";

                    using (var cmd = new MySqlCommand(sql, conn))
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (!reader.Read())
                        {
                            ShowFallback();   // no active row
                            return;
                        }

                        string filePath = reader["file_path"]?.ToString();
                        if (string.IsNullOrWhiteSpace(filePath))
                        {
                            ShowFallback();
                            return;
                        }

                        // Normalise to an app-relative path for ResolveUrl
                        string appRelative = filePath.StartsWith("~/")
                            ? filePath
                            : "~/" + filePath.TrimStart('/');

                        string pdfUrl = ResolveUrl(appRelative);
                        string viewerUrl = pdfUrl +
                            "#toolbar=0&navpanes=0&scrollbar=0&statusbar=0&messages=0&view=FitH";

                        // *** Use the Src property, not Attributes["src"] ***
                        pdfFrame.Src = viewerUrl;

                        // Let .pdf-iframe handle all sizing — no inline style override
                        pnlPdf.Visible = true;
                        pnlFallback.Visible = false;
                    }
                }
            }
            catch (Exception ex)
            {
                // Surface the message so you stop silently hiding bugs
                ShowFallback(ex.Message);
            }
        }

        private void ShowFallback(string reason = null)
        {
            pnlPdf.Visible = false;
            pnlFallback.Visible = true;

            if (!string.IsNullOrEmpty(reason))
            {
                // Optional: append reason to the fallback paragraph
                // If you have a control for it, set it here.
                System.Diagnostics.Debug.WriteLine("Terms load failed: " + reason);
            }
        }

        private void SetUploadLinkVisibility()
        {
            string role = Session["UserRole"]?.ToString() ?? "";
            lnkUpload.Visible = role.Equals("admin", StringComparison.OrdinalIgnoreCase);
        }
    }
}