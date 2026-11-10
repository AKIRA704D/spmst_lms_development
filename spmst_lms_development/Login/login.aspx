﻿﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="login.aspx.cs" Inherits="spmst_lms_development.Login.login" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>SPAMAST Library - LMSA Sign In</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />

    <!-- Theme font (optional - falls back to Helvetica/Arial) -->
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;600;700&display=swap" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" rel="stylesheet" />

    <!-- Universal system theme -->
    <link href="<%= ResolveUrl("~/Assets/Themes/spamast-theme.css") %>" rel="stylesheet" />
    <!-- Page-specific theme -->
    <link href="<%= ResolveUrl("~/Assets/Themes/LoginPage.css") %>" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">

        <header class="sticky-header">
            <div class="header-brand d-flex align-items-center">
                <!-- DYNAMIC LOGO -->
                <img src="<%= LibraryLogoUrl %>" alt="LMSA Logo" class="header-logo me-2" />
                <div>
                    <strong>SPAMAST LIBRARY</strong>
                    <span>LMSA v2.0 Platform</span>
                </div>
            </div>
            <a href="<%= ResolveUrl("~/LandingPage/Home.aspx") %>" class="btn-back">
                <i class="fa-solid fa-arrow-left"></i><span>Back</span>
            </a>
        </header>

        <div class="login-wrapper">
            <div class="login-card">

                <div class="login-sidebar">
                    <!-- DYNAMIC LOGOS -->
                    <img src="<%= LibraryLogoUrl %>" alt="LMSA Logo" class="sidebar-logo" />
                    <img src="<%= SchoolLogoUrl %>" alt="SPAMAST Logo" class="sidebar-logo" />
                </div>

                <div class="login-form-area">

                    <div class="greetings-container">
                        <span class="wave-emoji">👋</span>
                        <h2 class="login-title">Mabuhay!</h2>
                        <p class="login-subtitle">Welcome back, Ka-Aral. Ready to explore today?</p>
                    </div>

                    <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert alert-danger d-flex align-items-center p-3 mb-4 rounded-3 border-0" style="font-size: 0.88rem; color: #842029; background-color: #f8d7da;">
                        <i class="fa-solid fa-circle-exclamation me-2 fs-5"></i>
                        <div><asp:Label ID="lblAlertMessage" runat="server"></asp:Label></div>
                    </asp:Panel>

                    <div class="input-group-custom">
                        <label class="form-label" for="txtEmail">Email</label>
                        <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control-custom" autocomplete="email" placeholder="Enter your email" TextMode="Email"></asp:TextBox>
                    </div>

                    <div class="input-group-custom">
                        <div class="d-flex justify-content-between align-items-center mb-1">
                            <label class="form-label mb-0" for="txtPassword">Password</label>
                            <a href="forgotpass.aspx" class="action-link">Forgot Password?</a>
                        </div>
                        <div class="password-toggle-container">
                            <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control-custom" placeholder="Enter your password" TextMode="Password"></asp:TextBox>
                            <button type="button" id="btnTogglePassword" class="password-toggle-btn" aria-label="Toggle password visibility">
                                <i class="fa-solid fa-eye" id="eyeIcon"></i>
                            </button>
                        </div>
                    </div>

                    <div class="account-registration-hint">
                        Don't have an active account? <a href="verifyAcc.aspx" class="action-link">Verify Account</a>
                    </div>

                    <asp:Button ID="btnSignIn" runat="server" Text="Sign In" CssClass="btn-signin"
                                OnClick="btnSignIn_Click"
                                OnClientClick="return handleSignIn(this);" />

                    <div class="security-badge-banner">
                        <i class="fa-solid fa-shield-halved"></i>
                        <span>Your info is <strong>protected and secure</strong></span>
                    </div>

                    <div class="d-flex align-items-start gap-2 mt-2">
                        <input type="checkbox" id="chkTerms" name="chkTerms" class="form-check-input form-check-input-custom" required="required" />
                        <label for="chkTerms" class="terms-checkbox-label">
                            By signing in, you agree to our <a href="termsServices.aspx" class="action-link" style="font-size: 0.8rem;">Terms of Service</a>
                        </label>
                    </div>

                </div>
            </div>
        </div>

    </form>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <!-- SweetAlert2 is required for the loading indicator -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            var passwordInput = document.getElementById('<%= txtPassword.ClientID %>');
            var toggleButton = document.getElementById('btnTogglePassword');
            var eyeIcon = document.getElementById('eyeIcon');

            if (toggleButton && passwordInput) {
                toggleButton.addEventListener('click', function () {
                    if (passwordInput.type === 'password') {
                        passwordInput.type = 'text';
                        eyeIcon.classList.remove('fa-eye');
                        eyeIcon.classList.add('fa-eye-slash');
                        eyeIcon.style.transform = 'scale(1.1)';
                    } else {
                        passwordInput.type = 'password';
                        eyeIcon.classList.remove('fa-eye-slash');
                        eyeIcon.classList.add('fa-eye');
                        eyeIcon.style.transform = 'scale(1)';
                    }
                });
                eyeIcon.addEventListener('transitionend', function () { eyeIcon.style.transform = 'scale(1)'; });
            }
        });

        function handleSignIn(btn) {
            try {
                var form = document.forms[0];

                if (form && typeof form.reportValidity === 'function' && !form.reportValidity()) {
                    return false;
                }

                if (typeof Swal !== 'undefined') {
                    Swal.fire({
                        title: 'Processing...',
                        allowOutsideClick: false,
                        allowEscapeKey: false,
                        showConfirmButton: false,
                        didOpen: function () { Swal.showLoading(); }
                    });
                }

                if (btn) {
                    btn.value = 'Signing In...';
                    btn.classList.add('btn-loading');
                    btn.setAttribute('aria-busy', 'true');
                }
            } catch (err) {
                if (window.console && console.error) {
                    console.error('Sign-in handler error:', err);
                }
            }
            return true;
        }
    </script>
</body>
</html>