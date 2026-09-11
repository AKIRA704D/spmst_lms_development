<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="login.aspx.cs" Inherits="spmst_lms_development.Login.login" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>SPAMAST Library - LMSA Sign In</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" rel="stylesheet" />

    <style>
        /* Base Page Setup & Library Blurred Background */
        body {
            background: linear-gradient(rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.3)), url('../Assests/img/lmsa_bg.jpg') no-repeat center center fixed;
            background-size: cover;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            overflow-x: hidden;
        }

        /* Sticky Transparent Header */
        .sticky-header {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            z-index: 1030;
            padding: 15px 30px;
            background: rgba(0, 0, 0, 0.4);
            backdrop-filter: blur(5px);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header-logo {
            height: 35px;
            width: auto;
            object-fit: contain;
            filter: drop-shadow(0 2px 4px rgba(0,0,0,0.15));
            transition: transform 0.3s ease;
        }

        /* Subtle interactive pop when hovering over the brand area */
        .header-brand:hover .header-logo {
            transform: scale(1.08);
}
        .header-brand {
            color: #ffffff;
            font-size: 0.95rem;
            font-weight: 600;
            letter-spacing: 0.5px;
        }
        .header-brand span {
            display: block;
            font-size: 0.75rem;
            font-weight: 400;
            color: #ced4da;
        }

        /* Back Button Interaction */
        .btn-back {
            background-color: #4b51ac;
            color: #ffffff;
            border: none;
            padding: 8px 20px;
            border-radius: 6px;
            font-size: 0.85rem;
            font-weight: 500;
            text-decoration: none;
            transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .btn-back:hover {
            background-color: #3b408c;
            color: #ffffff;
            transform: translateX(-3px);
            box-shadow: 0 4px 12px rgba(75, 81, 172, 0.4);
        }
        .btn-back i {
            transition: transform 0.3s ease;
        }
        .btn-back:hover i {
            transform: translateX(-2px);
        }

        /* Central Login Wrapper Container */
        .login-wrapper {
            flex: 1;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 100px 15px 40px 15px; /* Cushion top spacing for sticky header */
        }

        /* Core Unified Login Card */
        .login-card {
            background-color: #ffffff;
            border-radius: 16px;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.4);
            overflow: hidden;
            width: 100%;
            max-width: 1050px;
            min-height: 580px;
            display: flex;
            border: none;
        }

        /* Left Split Panel - Brand Blue Identity Section */
        .login-sidebar {
            background-color: #1a56db;
            width: 45%;
            padding: 40px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            gap: 35px;
            position: relative;
        }
        .sidebar-logo {
            width: 175px;
            height: 175px;
            object-fit: contain;
            filter: drop-shadow(0 8px 16px rgba(0, 0, 0, 0.2));
            transition: transform 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }
        .sidebar-logo:hover {
            transform: scale(1.06) rotate(2deg);
        }

        /* Right Split Panel - Interaction Control Form */
        .login-form-area {
            width: 55%;
            padding: 50px 60px;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }

        /* Typography & Greetings Styling */
        .greetings-container {
            text-align: center;
            margin-bottom: 30px;
        }
        .wave-emoji {
            display: inline-block;
            font-size: 1.8rem;
            animation: waveHand 2.5s infinite;
            transform-origin: 70% 70%;
        }
        .login-title {
            color: #111827;
            font-weight: 700;
            font-size: 1.85rem;
            margin-top: 5px;
            margin-bottom: 4px;
        }
        .login-subtitle {
            color: #6b7280;
            font-size: 0.9rem;
        }

        /* Interactive Inputs & Elements Form Styling */
        .form-label {
            font-size: 0.85rem;
            font-weight: 600;
            color: #374151;
            margin-bottom: 6px;
        }
        .input-group-custom {
            position: relative;
            margin-bottom: 22px;
        }
        .form-control-custom {
            width: 100%;
            padding: 11px 16px;
            font-size: 0.95rem;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            color: #1f2937;
            background-color: #ffffff;
            transition: all 0.25s ease;
        }
        .form-control-custom:focus {
            border-color: #1a56db;
            box-shadow: 0 0 0 4px rgba(26, 86, 219, 0.15);
            outline: none;
        }
        
        /* Interactive Visibility Password Eye Layout */
        .password-toggle-container {
            position: relative;
        }
        .password-toggle-btn {
            position: absolute;
            right: 14px;
            top: 50%;
            transform: translateY(-50%);
            border: none;
            background: none;
            color: #9ca3af;
            cursor: pointer;
            padding: 0;
            font-size: 1.1rem;
            transition: color 0.2s ease;
            z-index: 10;
        }
        .password-toggle-btn:hover {
            color: #4b5563;
        }

        /* Inline Action Links Navigation Styles */
        .action-link {
            font-size: 0.82rem;
            color: #1a56db;
            text-decoration: none;
            font-weight: 600;
            transition: color 0.2s ease;
        }
        .action-link:hover {
            color: #1145b5;
            text-decoration: underline;
        }
        .account-registration-hint {
            font-size: 0.88rem;
            color: #4b5563;
            text-align: center;
            margin-top: -4px;
            margin-bottom: 24px;
        }

        /* Action Buttons Interaction Handlers */
        .btn-signin {
            background-color: #2b3244;
            color: #ffffff;
            border: none;
            width: 100%;
            padding: 12px;
            font-size: 0.95rem;
            font-weight: 600;
            border-radius: 8px;
            transition: all 0.25s ease;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
        }
        .btn-signin:hover {
            background-color: #1e2330;
            transform: translateY(-1px);
            box-shadow: 0 6px 15px rgba(43, 50, 68, 0.3);
        }
        .btn-signin:active {
            transform: translateY(1px);
        }

        /* Notification Banner Messages Overlay Box */
        .security-badge-banner {
            background-color: #ecfdf5;
            border: 1px solid #a7f3d0;
            border-radius: 8px;
            padding: 10px 14px;
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 0.82rem;
            color: #065f46;
            font-weight: 500;
            margin-bottom: 22px;
        }
        .security-badge-banner i {
            font-size: 1rem;
            color: #10b981;
            animation: shieldPulse 2s infinite ease-in-out;
        }

        /* Bottom Layout Terms Constraints */
        .terms-checkbox-label {
            font-size: 0.8rem;
            color: #6b7280;
            user-select: none;
            cursor: pointer;
        }
        .form-check-input-custom {
            width: 15px;
            height: 15px;
            cursor: pointer;
            border-radius: 4px;
            border: 1px solid #d1d5db;
            transition: all 0.2s ease;
        }
        .form-check-input-custom:checked {
            background-color: #1a56db;
            border-color: #1a56db;
        }

        /* Keyframes CSS Component Micro-Animations */
        @keyframes waveHand {
            0% { transform: rotate( 0.0deg) }
           10% { transform: rotate(14.0deg) }
           20% { transform: rotate(-8.0deg) }
           30% { transform: rotate(14.0deg) }
           40% { transform: rotate(-4.0deg) }
           50% { transform: rotate(10.0deg) }
           60% { transform: rotate( 0.0deg) }
          100% { transform: rotate( 0.0deg) }
        }
        @keyframes shieldPulse {
            0% { transform: scale(1); opacity: 1; }
            50% { transform: scale(1.12); opacity: 0.8; }
            100% { transform: scale(1); opacity: 1; }
        }

        /* Responsive Breakpoints Viewports Fixes */
        @media (max-width: 991.98px) {
            .login-card { max-width: 720px; min-height: auto; }
            .login-sidebar { width: 40%; padding: 30px; gap: 25px; }
            .sidebar-logo { width: 130px; height: 130px; }
            .login-form-area { width: 60%; padding: 40px; }
        }
        @media (max-width: 767.98px) {
            body { background-attachment: scroll; }
            .login-wrapper { padding-top: 90px; }
            .login-card { flex-direction: column; max-width: 480px; }
            .login-sidebar { width: 100%; padding: 35px 20px; flex-direction: row; gap: 30px; }
            .sidebar-logo { width: 90px; height: 90px; }
            .login-form-area { width: 100%; padding: 35px 25px; }
            .sticky-header { padding: 12px 20px; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        
        <header class="sticky-header">
            <div class="header-brand d-flex align-items-center">
                <img src="../Assests/img/lmsa_logo.png" alt="LMSA Logo" class="header-logo me-2" />
                <div>
                    <strong>SPAMAST LIBRARY</strong>
                    <span>LMSA v2.0 Platform</span>
                </div>
            </div>
            <a href="landingPage.aspx" class="btn-back">
                <i class="fa-solid fa-arrow-left"></i><span>Back</span>
            </a>
        </header>

        <div class="login-wrapper">
            <div class="login-card">
                
                <div class="login-sidebar">
                    <img src="../Assests/img/lib_logo_wbg.png" alt="LMSA Logo" class="sidebar-logo" />
                    <img src="../Assests/img/spmst_logo_wbg.png" alt="SPAMAST Logo" class="sidebar-logo" />
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

                    <asp:Button ID="btnSignIn" runat="server" Text="Sign In" CssClass="btn-signin" OnClick="btnSignIn_Click" />

                    <div class="security-badge-banner">
                        <i class="fa-solid fa-shield-halved"></i>
                        <span>Your info is <strong>protected and secure</strong></span>
                    </div>

                    <div class="d-flex align-items-start gap-2 mt-2">
                        <input type="checkbox" id="chkTerms" class="form-check-input form-check-input-custom" required="required" />
                        <label for="chkTerms" class="terms-checkbox-label">
                            By signing in, you agree to our <a href="termsServices.aspx" class="action-link" style="font-size: 0.8rem;">Terms of Service</a>
                        </label>
                    </div>

                </div>
            </div>
        </div>

    </form>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>    
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            const passwordInput = document.getElementById('<%= txtPassword.ClientID %>');
            const toggleButton = document.getElementById('btnTogglePassword');
            const eyeIcon = document.getElementById('eyeIcon');

            if (toggleButton && passwordInput) {
                toggleButton.addEventListener('click', function () {
                    if (passwordInput.type === 'password') {
                        passwordInput.type = 'text';
                        eyeIcon.classList.remove('fa-eye');
                        eyeIcon.classList.add('fa-eye-slash');
                        // Micro interaction animation
                        eyeIcon.style.transform = 'scale(1.1)';
                    } else {
                        passwordInput.type = 'password';
                        eyeIcon.classList.remove('fa-eye-slash');
                        eyeIcon.classList.add('fa-eye');
                        eyeIcon.style.transform = 'scale(1)';
                    }
                });
                
                // Reset eye scale transition
                eyeIcon.addEventListener('transitionend', () => { eyeIcon.style.transform = 'scale(1)'; });
            }
        });
    </script>
</body>
</html>