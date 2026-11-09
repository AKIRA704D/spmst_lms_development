using System;
using System.Web;
using System.Web.UI;

namespace spmst_lms_development
{
    /// <summary>
    /// Safe server-side helper for SweetAlert2 dialogs.
    /// All dynamic strings are JavaScript-encoded to prevent injection.
    /// Uses centralized theme colors and the reusable ProcessIndicator
    /// JS utility when available.
    /// </summary>
    public static class AlertHelper
    {
        // Fallback color for the SweetAlert2 confirm button if theme CSS
        // is unavailable; matches --sp-green-700 from spamast-theme.css.
        private const string FallbackGreen = "#14532d";

        private static string Js(string s)
        {
            return HttpUtility.JavaScriptStringEncode(s ?? string.Empty);
        }

        private static string UniqueKey(string prefix)
        {
            return prefix + "_" + Guid.NewGuid().ToString("N");
        }

        /// <summary>
        /// Displays a SweetAlert2 loading modal. Supports optional title/message.
        /// Existing callers using ShowProcessing(page) continue to work.
        /// </summary>
        public static void ShowProcessing(Page page,
                                          string title = "Processing...",
                                          string message = "Please wait...")
        {
            if (page == null) { return; }
            string script = $@"
                if (window.ProcessIndicator) {{
                    ProcessIndicator.showLoading('{Js(title)}', '{Js(message)}');
                }} else if (window.Swal) {{
                    Swal.fire({{
                        title: '{Js(title)}',
                        html: '{Js(message)}',
                        allowOutsideClick: false,
                        allowEscapeKey: false,
                        showConfirmButton: false,
                        didOpen: function () {{ Swal.showLoading(); }}
                    }});
                }}";
            ScriptManager.RegisterStartupScript(
                page, page.GetType(), UniqueKey("ProcessingAlert"), script, true);
        }

        /// <summary>
        /// Closes any currently open loader. Only closes the *loading* dialog;
        /// it never closes a final success/error dialog.
        /// </summary>
        public static void CloseAlert(Page page)
        {
            if (page == null) { return; }
            string script = @"
                if (window.ProcessIndicator) {
                    ProcessIndicator.hideLoading();
                } else if (window.Swal) {
                    Swal.close();
                }";
            ScriptManager.RegisterStartupScript(
                page, page.GetType(), UniqueKey("CloseAlert"), script, true);
        }

        /// <summary>
        /// Displays an error dialog (replaces any open loader).
        /// </summary>
        public static void ShowError(Page page, string message, string title = "Error")
        {
            if (page == null) { return; }
            string script = $@"
                if (window.ProcessIndicator) {{
                    ProcessIndicator.showError('{Js(title)}', '{Js(message)}');
                }} else if (window.Swal) {{
                    Swal.fire({{
                        icon: 'error',
                        title: '{Js(title)}',
                        html: '{Js(message)}',
                        confirmButtonColor: '{FallbackGreen}'
                    }});
                }}";
            ScriptManager.RegisterStartupScript(
                page, page.GetType(), UniqueKey("ErrorAlert"), script, true);
        }

        /// <summary>
        /// Displays a success dialog (replaces any open loader).
        /// Optional redirectUrl will navigate the browser after redirectDelayMs.
        /// </summary>
        public static void ShowSuccess(Page page,
                                       string title,
                                       string message,
                                       string redirectUrl = null,
                                       int redirectDelayMs = 2000)
        {
            if (page == null) { return; }

            string script = $@"
                if (window.ProcessIndicator) {{
                    ProcessIndicator.showSuccess(
                        '{Js(title)}', '{Js(message)}',
                        {{ timer: {redirectDelayMs}, showConfirmButton: false }});
                }} else if (window.Swal) {{
                    Swal.fire({{
                        icon: 'success',
                        title: '{Js(title)}',
                        html: '{Js(message)}',
                        showConfirmButton: false,
                        timer: {redirectDelayMs}
                    }});
                }}";

            if (!string.IsNullOrEmpty(redirectUrl))
            {
                script += $" setTimeout(function(){{ window.location.href = '{Js(redirectUrl)}'; }}, {redirectDelayMs}); ";
            }

            ScriptManager.RegisterStartupScript(
                page, page.GetType(), UniqueKey("SuccessAlert"), script, true);
        }

        /// <summary>
        /// Invokes the page's showOtpExpired() JavaScript function, if defined.
        /// </summary>
        public static void TriggerOtpExpired(Page page)
        {
            if (page == null) { return; }
            string script = "if (typeof showOtpExpired === 'function') { showOtpExpired(); }";
            ScriptManager.RegisterStartupScript(
                page, page.GetType(), UniqueKey("OtpExpired"), script, true);
        }
    }
}