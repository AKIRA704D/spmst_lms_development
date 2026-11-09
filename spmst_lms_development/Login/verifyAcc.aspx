<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="VerifyAcc.aspx.cs" Inherits="spmst_lms_development.VerifyAcc" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verify Account - SPAMAST Library</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <link href="<%= ResolveUrl("~/Assets/Themes/spamast-theme.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Assets/Themes/verify-account.css") %>" rel="stylesheet" />

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="<%= ResolveUrl("~/Assets/Script/process-indicator.js") %>"></script>
</head>
<body style="--sp-bg-img: url('<%= ResolveUrl("~/Assets/Logo/lmsa_bg.jpg") %>');">
    <form id="form1" runat="server">
        <asp:ScriptManager ID="ScriptManager1" runat="server"></asp:ScriptManager>

        <header class="sticky-header">
            <div class="header-brand d-flex align-items-center">
                <img src="<%= ResolveUrl("~/Assets/Logo/lmsa_logo.png") %>"
                     alt="LMSA Logo" class="header-logo me-2" />
                <div>
                    <strong>SPAMAST LIBRARY</strong>
                    <span>LMSA v2.0 Platform</span>
                </div>
            </div>
            <a href="login.aspx" class="btn-back">
                <i class="fa-solid fa-arrow-left"></i><span>Back</span>
            </a>
        </header>

        <div class="page-container">
            <div class="auth-card">
                <div class="blue-panel">
                    <i class="fa-solid fa-user-shield animated-lock"></i>
                    <div>
                        <h3>Account Setup</h3>
                        <p class="mt-1">Verify your assigned institutional parameters to unlock your structural library credentials profile access.</p>
                    </div>
                </div>

                <div class="form-panel">
                    <asp:UpdatePanel ID="updMain" runat="server">
                        <ContentTemplate>

                            <asp:Panel ID="pnlVerifyIdentity" runat="server" Visible="true">
                                <h3>Verify Identity</h3>
                                <p>Provide your user assignment metrics to continue.</p>

                                <div class="mb-3">
                                    <label class="form-label">User ID / ID Number</label>
                                    <asp:TextBox ID="txtUserId" runat="server" CssClass="form-control"
                                                 placeholder="e.g. 2024-0001"></asp:TextBox>
                                </div>
                                <div class="mb-4">
                                    <label class="form-label">Registered Email Address</label>
                                    <asp:TextBox ID="txtEmail" runat="server" TextMode="Email"
                                                 CssClass="form-control" data-format="lowercase"
                                                 placeholder="username@lmsa.edu.ph"></asp:TextBox>
                                </div>

                                <asp:Button ID="btnVerifyIdentity" runat="server"
                                            Text="Verify Identity" CssClass="btn btn-primary"
                                            OnClick="btnVerifyIdentity_Click"
                                            OnClientClick="return InputHelper.validateSubmission('txtUserId', 'txtEmail', 'Verifying Account...', 'Please wait while we validate your account information.', this);" />
                            </asp:Panel>

                            <asp:Panel ID="pnlOtp" runat="server" Visible="false" CssClass="text-center">
                                <h3>Verification Required</h3>
                                <p>A 6-digit verification code was successfully processed and dispatched towards your registered profile inbox address.</p>

                                <div class="timer-text" id="divTimer">Time remaining: <span id="timeDisplay">60</span>s</div>

                                <div class="mb-3 mt-2">
                                    <asp:TextBox ID="txtOtp" runat="server" CssClass="form-control text-center"
                                                 placeholder="******" MaxLength="6" data-format="numeric"
                                                 Style="letter-spacing:8px; font-size:22px; font-weight:700; max-width:260px; margin:0 auto;"></asp:TextBox>
                                </div>

                                <div class="d-flex gap-2 justify-content-center mt-4">
                                    <asp:Button ID="btnVerifyOtp" runat="server"
                                                Text="Verify OTP" CssClass="btn btn-primary w-auto px-4 mt-0"
                                                OnClick="btnVerifyOtp_Click"
                                                OnClientClick="return InputHelper.validateOtpSubmission('txtOtp', 'Verifying OTP...', 'Please wait while we verify your authentication code.', this);" />
                                    <asp:Button ID="btnCancel" runat="server"
                                                Text="Cancel" CssClass="btn btn-secondary w-auto px-4"
                                                OnClick="btnCancel_Click" CausesValidation="false" />
                                </div>

                                <asp:Button ID="btnHiddenResend" runat="server" OnClick="btnHiddenResend_Click" style="display:none;" />
                            </asp:Panel>

                            <asp:Panel ID="pnlSetupPassword" runat="server" Visible="false">
                                <h3 class="text-center">Create Password</h3>
                                <p class="text-muted text-center">Set up your highly secured alphanumeric credentials.</p>

                                <div class="mb-3 position-relative">
                                    <label class="form-label">New Password</label>
                                    <asp:TextBox ID="txtNewPass" runat="server" TextMode="Password"
                                                 CssClass="form-control" placeholder="••••••••"></asp:TextBox>
                                    <i class="fa-solid fa-eye toggle-password-icon"
                                       onclick="InputHelper.togglePassword('txtNewPass', this)"></i>
                                </div>

                                <div class="mb-3 position-relative">
                                    <label class="form-label">Confirm New Password</label>
                                    <asp:TextBox ID="txtConfirmPass" runat="server" TextMode="Password"
                                                 CssClass="form-control" placeholder="••••••••"></asp:TextBox>
                                    <i class="fa-solid fa-eye toggle-password-icon"
                                       onclick="InputHelper.togglePassword('txtConfirmPass', this)"></i>
                                </div>

                                <div class="mt-4">
                                    <asp:Button ID="btnSetupPassword" runat="server"
                                                Text="Complete Setup" CssClass="btn btn-primary w-100"
                                                OnClick="btnSetupPassword_Click"
                                                OnClientClick="return InputHelper.validatePasswordSubmission('txtNewPass', 'txtConfirmPass', 'Creating Your Account...', 'Please wait while we securely create your password and activate your account.', this);" />
                                </div>
                            </asp:Panel>

                        </ContentTemplate>
                    </asp:UpdatePanel>
                </div>
            </div>
        </div>
    </form>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <script>
        var timerInterval;
        window.__piSubmitInFlight = false;

        function piShowLoading(title, message) {
            if (window.ProcessIndicator && ProcessIndicator.showLoading) {
                ProcessIndicator.showLoading(title, message);
            } else if (window.Swal) {
                Swal.fire({
                    title: title, html: message,
                    allowOutsideClick: false, allowEscapeKey: false,
                    showConfirmButton: false,
                    didOpen: function () { Swal.showLoading(); }
                });
            }
        }

        function piShowError(title, message) {
            if (window.ProcessIndicator && ProcessIndicator.showError) {
                ProcessIndicator.showError(title, message);
            } else if (window.Swal) {
                Swal.fire({ icon: "error", title: title, html: message, confirmButtonColor: "#14532d" });
            }
        }

        function piDisableButton(button) {
            if (!button) return;
            try {
                button.dataset.piOriginalDisabled = button.disabled ? "1" : "0";
                button.disabled = true;
                button.classList.add("pi-loading");
            } catch (e) { }
        }

        var InputHelper = {
            forceLowerCase: function (el) {
                el.addEventListener('input', function () { this.value = this.value.toLowerCase(); });
            },
            forceNumeric: function (el) {
                el.addEventListener('input', function () { this.value = this.value.replace(/[^0-9]/g, ''); });
            },
            togglePassword: function (inputId, iconElement) {
                var input = document.getElementById(inputId);
                if (!input) input = document.querySelector('[id$="' + inputId + '"]');
                if (!input) return;
                if (input.type === 'password') {
                    input.type = 'text';
                    iconElement.classList.remove('fa-eye');
                    iconElement.classList.add('fa-eye-slash');
                } else {
                    input.type = 'password';
                    iconElement.classList.remove('fa-eye-slash');
                    iconElement.classList.add('fa-eye');
                }
            },

            validateSubmission: function (userSelector, emailSelector, loadingTitle, loadingMessage, button) {
                if (window.__piSubmitInFlight) { return true; }

                var userEl = document.getElementById(userSelector);
                var emailEl = document.getElementById(emailSelector);

                if (!userEl) userEl = document.querySelector('[id$="' + userSelector + '"]');
                if (!emailEl) emailEl = document.querySelector('[id$="' + emailSelector + '"]');

                if (!userEl) userEl = document.querySelector('[name$="' + userSelector + '"]');
                if (!emailEl) emailEl = document.querySelector('[name$="' + emailSelector + '"]');

                var uv = userEl ? (userEl.value || '').trim() : '';
                var ev = emailEl ? (emailEl.value || '').trim() : '';

                if (!uv || !ev) {
                    piShowError('Missing Information', 'Please enter both your User ID and Registered Email Address.');
                    return false;
                }
                if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(ev)) {
                    piShowError('Invalid Email', 'The email address format is invalid.');
                    return false;
                }

                window.__piSubmitInFlight = true;
                piShowLoading(loadingTitle, loadingMessage);

                if (button) {
                    setTimeout(function () { piDisableButton(button); }, 10);
                }

                return true;
            },

            validateOtpSubmission: function (otpSelector, loadingTitle, loadingMessage, button) {
                if (window.__piSubmitInFlight) { return true; }
                var otpEl = document.getElementById(otpSelector) || document.querySelector('[id$="' + otpSelector + '"]');
                var v = otpEl ? (otpEl.value || '').trim() : '';
                if (!/^\d{6}$/.test(v)) {
                    piShowError('Invalid OTP', 'Please enter the 6-digit verification code.');
                    return false;
                }
                window.__piSubmitInFlight = true;
                piShowLoading(loadingTitle, loadingMessage);

                if (button) {
                    setTimeout(function () { piDisableButton(button); }, 10);
                }

                return true;
            },

            validatePasswordSubmission: function (newId, confirmId, loadingTitle, loadingMessage, button) {
                if (window.__piSubmitInFlight) { return true; }
                var nEl = document.getElementById(newId) || document.querySelector('[id$="' + newId + '"]');
                var cEl = document.getElementById(confirmId) || document.querySelector('[id$="' + confirmId + '"]');
                var nv = nEl ? (nEl.value || '') : '';
                var cv = cEl ? (cEl.value || '') : '';
                if (!nv || !cv) {
                    piShowError('Missing Password', 'Please enter both password fields.');
                    return false;
                }
                if (nv !== cv) {
                    piShowError('Password Mismatch', 'The two password fields do not match.');
                    return false;
                }
                window.__piSubmitInFlight = true;
                piShowLoading(loadingTitle, loadingMessage);

                if (button) {
                    setTimeout(function () { piDisableButton(button); }, 10);
                }

                return true;
            }
        }; /* ✅ ADDED THE MISSING SEMICOLON AND BRACE HERE */

        function initPageHelpers() {
            document.querySelectorAll('[data-format="lowercase"]').forEach(InputHelper.forceLowerCase);
            document.querySelectorAll('[data-format="numeric"]').forEach(InputHelper.forceNumeric);
        }
        document.addEventListener('DOMContentLoaded', initPageHelpers);

        if (typeof Sys !== 'undefined' && Sys.WebForms) {
            Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
                initPageHelpers();
                window.__piSubmitInFlight = false;
                if (window.ProcessIndicator && ProcessIndicator.restoreButtons) {
                    ProcessIndicator.restoreButtons();
                }
            });
        }

        function startOtpTimer() {
            clearInterval(timerInterval);
            var timeLeft = 60;
            var container = document.getElementById('timeDisplay');
            if (container) { container.innerText = timeLeft; }
            timerInterval = setInterval(function () {
                timeLeft--;
                var t = document.getElementById('timeDisplay');
                if (t) { t.innerText = timeLeft; }
                if (timeLeft <= 0) {
                    clearInterval(timerInterval);
                    deferredShowOtpExpired(0);
                }
            }, 1000);
        }
        function stopOtpTimer() { if (timerInterval) clearInterval(timerInterval); }

        function deferredShowOtpExpired(attempt) {
            if (typeof ProcessIndicator !== 'undefined' && ProcessIndicator.isLoading()) {
                if (attempt < 10) {
                    setTimeout(function () { deferredShowOtpExpired(attempt + 1); }, 1000);
                }
                return;
            }
            showOtpExpired();
        }

        function showOtpExpired() {
            Swal.fire({
                icon: 'warning',
                title: 'OTP Code Expired',
                text: 'The verification timeline has expired. Would you like to request a new code?',
                showCancelButton: true,
                confirmButtonColor: '#14532d',
                cancelButtonColor: '#6b7280',
                confirmButtonText: 'Resend OTP',
                cancelButtonText: 'Back to Login'
            }).then(function (result) {
                if (result.isConfirmed) {
                    piShowLoading('Sending Verification Code...',
                        'Please wait while we send your OTP to your registered email address.');
                    document.getElementById('<%= btnHiddenResend.ClientID %>').click();
                } else if (result.dismiss === Swal.DismissReason.cancel) {
                    window.location.href = 'login.aspx';
                }
            });
        }
    </script>
</body>
</html>