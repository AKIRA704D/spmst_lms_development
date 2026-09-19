using System.Web.UI;

namespace spmst_lms_development
{
    public static class AlertHelper
    {
        // Shows the processing spinner
        public static void ShowProcessing(Page page)
        {
            string script = @"
                Swal.fire({
                    title: 'Processing...',
                    allowOutsideClick: false,
                    showConfirmButton: false,
                    didOpen: () => { Swal.showLoading(); }
                });";
            ScriptManager.RegisterStartupScript(page, page.GetType(), "ProcessingAlert", script, true);
        }

        // Closes any open SweetAlert
        public static void CloseAlert(Page page)
        {
            string script = "Swal.close();";
            ScriptManager.RegisterStartupScript(page, page.GetType(), "CloseAlert", script, true);
        }

        // Shows the "Account Not Found" error
        public static void ShowError(Page page, string message)
        {
            string script = $@"
                Swal.fire({{
                    icon: 'error',
                    title: 'Error',
                    text: '{message}',
                    confirmButtonColor: '#1d4ed8'
                }});";
            ScriptManager.RegisterStartupScript(page, page.GetType(), "ErrorAlert", script, true);
        }

        // Shows the generic Success message
        public static void ShowSuccess(Page page, string title, string message)
        {
            string script = $@"
                Swal.fire({{
                    icon: 'success',
                    title: '{title}',
                    text: '{message}',
                    showConfirmButton: false,
                    timer: 2000
                }});";
            ScriptManager.RegisterStartupScript(page, page.GetType(), "SuccessAlert", script, true);
        }

        // Triggers the OTP Expired prompt via JS function execution
        public static void TriggerOtpExpired(Page page)
        {
            ScriptManager.RegisterStartupScript(page, page.GetType(), "OtpExpired", "showOtpExpired();", true);
        }
    }
}