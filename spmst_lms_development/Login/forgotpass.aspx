<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ForgotPass.aspx.cs" Inherits="spmst_lms_development.ForgotPass" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Forgot Password - SPAMAST Library</title>
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        /* Base Page Setup & Library Blurred Background Setup */
        body, html {
            min-height: 100vh;
            margin: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(rgba(0, 0, 0, 0.45), rgba(0, 0, 0, 0.45)), url('../Assets/Img/lmsa_bg.jpg') no-repeat center center fixed;
            background-size: cover;
            display: flex;
            flex-direction: column;
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
        
        .btn-back {
            color: #fff; 
            text-decoration: none; 
            background: #4b51ac;
            padding: 8px 18px; 
            border-radius: 6px; 
            font-size: 0.85rem;
            font-weight: 500;
            transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .btn-back:hover { 
            background: #3b408c; 
            color: white; 
            transform: translateX(-3px); 
            box-shadow: 0 4px 12px rgba(75, 81, 172, 0.4);
        }

        /* Workspace Main Interface Layout Wrappers */
        .page-container {
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 100px 15px 40px 15px;
        }
        
        /* Core Functional Password Reset Card */
        .auth-card {
            display: flex;
            background: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 15px 35px rgba(0,0,0,0.4);
            max-width: 1050px;
            width: 100%;
            min-height: 580px;
            border: none;
            transition: all 0.3s ease;
        }
         
        /* Left Split Panel - Brand Blue Identity Section */
        .blue-panel {
            background: #1a56db; 
            color: white;
            width: 45%;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 40px;
            text-align: center;
            gap: 20px;
        }
        .blue-panel h3 { font-weight: 700; font-size: 1.6rem; letter-spacing: 0.5px; margin: 0; }
        .blue-panel p { opacity: 0.85; font-size: 0.9rem; max-width: 280px; margin: 0; }
        
        /* Animated Component Icon Keyframes Hooks */
        .animated-lock {
            font-size: 75px;
            animation: pulse-lock 2.5s infinite ease-in-out;
            filter: drop-shadow(0 6px 10px rgba(0,0,0,0.15));
        }
        @keyframes pulse-lock {
            0% { transform: scale(1); }
            50% { transform: scale(1.08); text-shadow: 0 0 20px rgba(255,255,255,0.6); }
            100% { transform: scale(1); }
        }

        /* Right Split Panel - Interaction Control Form */
        .form-panel {
            width: 55%;
            padding: 45px 55px;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }
        .form-panel h3 { color: #111827; font-weight: 700; font-size: 1.6rem; margin-bottom: 6px; }
        .form-panel p { color: #6b7280; font-size: 0.9rem; margin-bottom: 25px; }
        
        /* Interactive Inputs & Elements Form Styling */
        .form-label { font-size: 0.85rem; font-weight: 600; color: #374151; margin-bottom: 6px; }
        .form-control {
            border-radius: 8px;
            padding: 11px 16px;
            border: 1px solid #d1d5db;
            font-size: 0.95rem;
            color: #1f2937;
            transition: all 0.25s ease;
        }
        .form-control:hover {
            border-color: #9ca3af;
        }
        .form-control:focus {
            border-color: #1a56db;
            box-shadow: 0 0 0 4px rgba(26, 86, 219, 0.15);
            outline: none;
            transform: translateY(-1px);
        }

        /* Action Buttons Interaction Handlers */
        .btn-primary {
            background-color: #2b3244;
            border: none;
            border-radius: 8px;
            padding: 12px;
            font-size: 0.95rem;
            font-weight: 600;
            transition: all 0.25s ease;
            width: 100%;
            margin-top: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
        }
        .btn-primary:hover {
            background-color: #1e2330;
            transform: translateY(-2px);
            box-shadow: 0 6px 15px rgba(43, 50, 68, 0.3);
        }
        .btn-secondary {
            background-color: #f3f4f6;
            color: #4b5563;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            padding: 12px;
            font-size: 0.95rem;
            font-weight: 600;
            transition: all 0.25s ease;
        }
        .btn-secondary:hover {
            background-color: #e5e7eb;
            color: #1f2937;
        }

        /* Interactive OTP Counter Display Text */
        .timer-text { 
            color: #dc3545; 
            font-weight: 700; 
            font-size: 1.1rem; 
            margin: 15px 0;
            background: #fff5f5;
            padding: 8px 15px;
            border-radius: 20px;
            display: inline-block;
            border: 1px dashed #feb2b2;
        }

        /* Password Wrapper adjustments for absolute eye positioning */
        .password-wrapper {
            position: relative;
        }
        .password-wrapper .form-control {
            padding-right: 45px;
        }
        .toggle-password-btn {
            position: absolute;
            top: 50%;
            right: 15px;
            transform: translateY(-50%);
            border: none;
            background: transparent;
            color: #6b7280;
            cursor: pointer;
            z-index: 5;
            padding: 0;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .toggle-password-btn:focus {
            outline: none;
        }

        /* =========================================================================
         * CORE RESPONSIVE VIEWPORT BREAKPOINTS
         * ========================================================================= */
        @media (max-width: 991.98px) {
            .auth-card { max-width: 750px; min-height: auto; }
            .blue-panel { width: 40%; padding: 30px 20px; }
            .form-panel { width: 60%; padding: 40px; }
        }
        
        @media (max-width: 767.98px) {
            body, html { background-attachment: scroll; }
            .page-container { padding-top: 85px; }
            .auth-card { 
                flex-direction: column; 
                max-width: 480px; 
                min-height: auto;
            }
            .blue-panel { 
                width: 100%; 
                padding: 35px 20px; 
                flex-direction: row; 
                text-align: left;
                gap: 20px;
            }
            .animated-lock { font-size: 50px; }
            .blue-panel h3 { font-size: 1.3rem; }
            .blue-panel p { max-width: 100%; font-size: 0.85rem; }
            .form-panel { width: 100%; padding: 35px 25px; }
            .form-panel h3 { font-size: 1.4rem; }
            .sticky-header { padding: 10px 20px; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager ID="ScriptManager1" runat="server"></asp:ScriptManager>

       <header class="sticky-header">
            <div class="header-brand d-flex align-items-center">
                <Img src="../Assets/Img/lmsa_logo.png" alt="LMSA Logo" class="header-logo me-2" />
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
                    <i class="fa-solid fa-unlock-keyhole animated-lock"></i>
                    <div>
                        <h3>Password Reset</h3>
                        <p class="mt-1">Verify your operational profile identities to configure alternative recovery paths securely.</p>
                    </div>
                </div>

                <div class="form-panel">
                    <asp:UpdatePanel ID="updMain" runat="server">
                        <ContentTemplate>
                            
                            <asp:Panel ID="pnlFindAccount" runat="server" Visible="true">
                                <h3>Find Your Account</h3>
                                <p>Provide your user assignment metrics to continue.</p>
                                
                                <div class="mb-3">
                                    <label class="form-label">User ID / ID Number</label>
                                    <asp:TextBox ID="txtUserId" runat="server" CssClass="form-control" placeholder="e.g. 2024-0001"></asp:TextBox>
                                </div>
                                <div class="mb-4">
                                    <label class="form-label">Registered Email Address</label>
                                    <asp:TextBox ID="txtEmail" runat="server" TextMode="Email" CssClass="form-control" data-format="lowercase" placeholder="username@lmsa.edu.ph"></asp:TextBox>
                                </div>
                                
                                <asp:Button ID="btnFindAccount" runat="server" Text="Find Account" CssClass="btn btn-primary" OnClick="btnFindAccount_Click" OnClientClick="return InputHelper.validateSubmission('[id$=\'txtUserId\']', '[id$=\'txtEmail\']');" />
                            </asp:Panel>

                           <asp:Panel ID="pnlOtp" runat="server" Visible="false" CssClass="text-center">
                                <h3>Verification Required</h3>
                                <p>A 6-digit verification code was successfully processed and dispatched towards your registered profile inbox address.</p>
                                
                                <div class="timer-text" id="divTimer">Time remaining: <span id="timeDisplay">60</span>s</div>
                                
                                <div class="mb-3 mt-2">
                                    <asp:TextBox ID="txtOtp" runat="server" CssClass="form-control text-center" placeholder="******" MaxLength="6" data-format="numeric" style="letter-spacing: 8px; font-size: 22px; font-weight: 700; max-width:260px; margin:0 auto;"></asp:TextBox>
                                </div>
                                
                                <div class="d-flex gap-2 justify-content-center mt-4">
                                    <asp:Button ID="btnVerifyOtp" runat="server" Text="Verify OTP" CssClass="btn btn-primary w-auto px-4 mt-0" OnClick="btnVerifyOtp_Click" />
                                    <asp:Button ID="btnCancel" runat="server" Text="Cancel" CssClass="btn btn-secondary w-auto px-4" OnClick="btnCancel_Click" CausesValidation="false" formnovalidate="true" />
                                </div>

                                <asp:Button ID="btnHiddenResend" runat="server" OnClick="btnHiddenResend_Click" style="display:none;" />
                            </asp:Panel>

                            <asp:Panel ID="pnlResetPassword" runat="server" Visible="false">
                                    <h3 class="text-center">Reset Password</h3>
                                    <p class="text-muted text-center">Set up your highly secured alphanumeric credentials.</p>

                                    <div class="mb-3 position-relative">
                                        <label class="form-label">New Password</label>
                                        <asp:TextBox ID="txtNewPass" runat="server" TextMode="Password" class="form-control" placeholder="••••••••"></asp:TextBox>
                                        <i class="fa-solid fa-eye position-absolute end-0 top-50 translate-middle-y me-3 toggle-password-icon" 
                                           style="cursor: pointer; z-index: 10; margin-top: 15px;" 
                                           onclick="InputHelper.togglePassword('<%= txtNewPass.ClientID %>', this)"></i>
                                    </div>

                                    <div class="mb-3 position-relative">
                                        <label class="form-label">Confirm New Password</label>
                                        <asp:TextBox ID="txtConfirmPass" runat="server" TextMode="Password" class="form-control" placeholder="••••••••"></asp:TextBox>
                                        <i class="fa-solid fa-eye position-absolute end-0 top-50 translate-middle-y me-3 toggle-password-icon" 
                                           style="cursor: pointer; z-index: 10; margin-top: 15px;" 
                                           onclick="InputHelper.togglePassword('<%= txtConfirmPass.ClientID %>', this)"></i>
                                    </div>

                                    <div class="mt-4">
                                        <asp:Button ID="btnResetPassword" runat="server" Text="Reset Password" Password="true" CssClass="btn btn-primary w-100" OnClick="btnResetPassword_Click" />
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
        let timerInterval;

        const InputHelper = {
            forceLowerCase: function (element) {
                element.addEventListener('input', function () {
                    this.value = this.value.toLowerCase();
                });
            },
            forceNumeric: function (element) {
                element.addEventListener('input', function () {
                    this.value = this.value.replace(/[^0-9]/g, '');
                });
            },
            // Dynamically toggles password string visibility mapping tracking
            togglePassword: function (inputId, iconElement) {
                const passwordInput = document.getElementById(inputId);
                if (passwordInput) {
                    if (passwordInput.type === 'password') {
                        passwordInput.type = 'text';
                        iconElement.classList.remove('fa-eye');
                        iconElement.classList.add('fa-eye-slash');
                    } else {
                        passwordInput.type = 'password';
                        iconElement.classList.remove('fa-eye-slash');
                        iconElement.classList.add('fa-eye');
                    }
                }
            }
        };

        // Lifecycle re-initialization routine loop handles
        function initPageHelpers() {
            document.querySelectorAll('[data-format="lowercase"]').forEach(InputHelper.forceLowerCase);
            document.querySelectorAll('[data-format="numeric"]').forEach(InputHelper.forceNumeric);
        }

        // Initial binding setup
        document.addEventListener('DOMContentLoaded', initPageHelpers);

        // CRITICAL FIX: Rebind helpers immediately after an ASP.NET UpdatePanel or Postback renders new elements
        if (typeof Sys !== 'undefined' && Sys.WebForms) {
            Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
                initPageHelpers();
            });
        }

        function startOtpTimer() {
            clearInterval(timerInterval);
            let timeLeft = 60;
            const container = document.getElementById('timeDisplay');
            if (container) { container.innerText = timeLeft; }

            timerInterval = setInterval(() => {
                timeLeft--;
                const updateTarget = document.getElementById('timeDisplay');
                if (updateTarget) { updateTarget.innerText = timeLeft; }

                if (timeLeft <= 0) {
                    clearInterval(timerInterval);
                    showOtpExpired();
                }
            }, 1000);
        }

        function stopOtpTimer() {
            if (timerInterval) {
                clearInterval(timerInterval);
            }
        }

        function showOtpExpired() {
            Swal.fire({
                icon: 'warning',
                title: 'OTP Code Expired',
                text: 'The verification timeline has expired. Would you like to re-verify or request a new code transmission?',
                showCancelButton: true,
                confirmButtonColor: '#1a56db',
                cancelButtonColor: '#6b7280',
                confirmButtonText: 'Resend OTP',
                cancelButtonText: 'Back to Login'
            }).then((result) => {
                if (result.isConfirmed) {
                    document.getElementById('<%= btnHiddenResend.ClientID %>').click();
            } else if (result.dismiss === Swal.DismissReason.cancel) {
                window.location.href = 'login.aspx';
            }
        });
        }

        function showClientProcessing() {
            // Basic validation check to ensure we don't show loader on empty inputs
            var userId = document.getElementById('<%= txtUserId.ClientID %>').value.trim();
            var email = document.getElementById('<%= txtEmail.ClientID %>').value.trim();

            if (userId !== "" && email !== "") {
                Swal.fire({
                    title: 'Processing Request',
                    text: 'Verifying credentials and preparing secure routing protocols...',
                    allowOutsideClick: false,
                    didOpen: () => {
                        Swal.showLoading();
                    }
                });
                return true; // Allows the postback to proceed to the backend
            }
            return true; // Let backend handle empty string alerts
        }
</script>
</body>
</html>