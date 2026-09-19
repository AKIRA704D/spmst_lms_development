<%@ Page Title="Attendance Kiosk" Language="C#" AutoEventWireup="true" CodeBehind="SelfServiceKiosk.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Attendance.Kiosk.SelfServiceKiosk" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Attendance Kiosk – LiBRA SPAMAST</title>

    <!-- External Libraries -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" />
    <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@600;700&family=Lato:ital,wght@0,300;0,400;0,700;1,400&display=swap" rel="stylesheet" />

    <!-- ==================== INTERNAL CSS STYLES ==================== -->
    <style>
        /* ========== 1. GLOBAL & BODY RESET ========== */
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        html, body { width: 100%; height: 100%; overflow-x: hidden; }
        body {
            display: flex;
            flex-direction: column;
            min-height: 100vh;
            background: #eef1f5;
            font-family: 'Lato', 'Segoe UI', sans-serif;
            color: #1e293b;
        }

        /* ========== 2. TOP HEADER BAR (inspired by original) ========== */
        .kiosk-topbar {
            background: #1b4d2e;
            display: flex;
            align-items: stretch;
            height: 96px;
            position: relative;
            overflow: hidden;
            flex-shrink: 0;
        }
        .kiosk-topbar::after {
            content: '';
            position: absolute;
            right: 0; top: 0; bottom: 0;
            width: 260px;
            background: repeating-linear-gradient(-55deg, transparent, transparent 13px, rgba(200,160,40,.32) 13px, rgba(200,160,40,.32) 17px, transparent 17px, transparent 30px, rgba(34,100,50,.42) 30px, rgba(34,100,50,.42) 34px);
            pointer-events: none;
        }
        .topbar-logos { display: flex; align-items: center; gap: 12px; padding: 0 24px; z-index: 1; }
        .topbar-logos Img { height: 64px; width: 64px; object-fit: contain; border-radius: 50%; background: rgba(255,255,255,.08); }
        .topbar-brand {
            display: flex;
            flex-direction: column;
            line-height: 1.2;
            padding-left: 10px;
            border-left: 2px solid rgba(255,255,255,.22);
        }
        .brand-libra { font-family: 'Cinzel', serif; font-size: 21px; font-weight: 700; color: #ffffff; letter-spacing: 2px; }
        .brand-spamast { font-family: 'Cinzel', serif; font-size: 11.5px; font-weight: 600; color: #c8a028; letter-spacing: 4px; text-transform: uppercase; }
        .topbar-title { flex: 1; display: flex; align-items: center; justify-content: center; z-index: 1; }
        .topbar-title h1 { font-family: 'Cinzel', serif; font-size: 28px; font-weight: 700; color: #ffffff; letter-spacing: 7px; text-transform: uppercase; }
        .topbar-date {
            display: flex;
            flex-direction: column;
            align-items: flex-end;
            justify-content: center;
            padding: 0 32px;
            z-index: 1;
        }
        .topbar-date .date-main { font-size: 14px; font-weight: 700; color: #ffffff; letter-spacing: .4px; }
        .topbar-date .date-sub { font-size: 10.5px; color: rgba(255,255,255,.72); letter-spacing: 1px; margin-top: 4px; text-transform: uppercase; }

        /* ========== 3. PAGE BODY & CARD ========== */
        .kiosk-body { flex: 1; display: flex; align-items: center; justify-content: center; padding: 36px 28px; }
        .kiosk-card {
            display: flex;
            flex-direction: column;
            width: 100%;
            max-width: 1080px;
            background: #ffffff;
            border-radius: 10px;
            box-shadow: 0 8px 48px rgba(0,0,0,.14);
            overflow: hidden;
            position: relative;
        }
        .kiosk-card::after {
            content: '';
            position: absolute;
            right: 0; top: 0; bottom: 0;
            width: 7px;
            background: linear-gradient(180deg, #1b4d2e 0%, #2e7d4f 55%, #c8a028 100%);
        }

        /* ========== 4. BOOTSTRAP TAB CUSTOMIZATION ========== */
        .custom-tabs .nav-link {
            color: #64748b;
            font-weight: 500;
            border: none;
            padding: 12px 24px;
            transition: all 0.2s;
        }
        .custom-tabs .nav-link:hover { color: #1b4d2e; border-color: transparent; }
        .custom-tabs .nav-link.active {
            color: #1b4d2e;
            background-color: transparent;
            border-bottom: 2px solid #1b4d2e;
            font-weight: 600;
        }
        .tab-content { margin-top: 20px; }

        /* ========== 5. FORM STYLES (inside first tab) ========== */
        .form-logo {
            width: 70px; height: 70px;
            border: 2.5px solid #1b4d2e;
            border-radius: 50%;
            display: flex;
            align-items: center; justify-content: center;
            margin-bottom: 12px;
            overflow: hidden;
            background: #f0fdf4;
        }
        .form-logo Img { width: 58px; height: 58px; object-fit: contain; }
        .form-welcome { font-family: 'Cinzel', serif; font-size: 21px; font-weight: 700; color: #1b4d2e; margin-bottom: 5px; letter-spacing: .6px; }
        .form-subtitle { font-size: 12.5px; color: #64748b; text-align: center; line-height: 1.55; margin-bottom: 30px; }
        .field-label { display: block; font-size: 10.5px; font-weight: 700; letter-spacing: 1.3px; text-transform: uppercase; color: #64748b; margin-bottom: 6px; }
        .kiosk-input, .kiosk-select {
            width: 100%;
            padding: 12px 14px;
            border: 1.5px solid #d1d5db;
            border-radius: 10px;
            font-family: 'Lato', sans-serif;
            font-size: 13.5px;
            background: #ffffff;
            transition: border-color .2s, box-shadow .2s;
        }
        .kiosk-input:focus, .kiosk-select:focus { border-color: #1b4d2e; box-shadow: 0 0 0 3px rgba(27,77,46,.1); outline: none; }
        .kiosk-input[readonly] { background: #f8fafc; color: #475569; }
        .kiosk-input.populated { background: #f0fdf4; border-color: #1b4d2e; font-weight: 700; color: #14532d; }
        .select-wrap { position: relative; }
        .select-wrap::after {
            content: '';
            position: absolute;
            right: 14px; top: 50%;
            transform: translateY(-50%);
            border-left: 5px solid transparent;
            border-right: 5px solid transparent;
            border-top: 6px solid #1b4d2e;
            pointer-events: none;
        }
        .status-badge {
            display: none;
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 11.5px;
            font-weight: 700;
            text-align: center;
            margin-bottom: 14px;
        }
        .status-in { background: #dcfce7; color: #15803d; border: 1px solid #bbf7d0; display: block; }
        .status-out { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; display: block; }
        .btn-login {
            width: 100%;
            padding: 14px;
            background: #1b4d2e;
            color: #ffffff;
            border: none;
            border-radius: 10px;
            font-family: 'Cinzel', serif;
            font-size: 14.5px;
            font-weight: 700;
            letter-spacing: 2.5px;
            text-transform: uppercase;
            cursor: pointer;
            transition: background .2s, box-shadow .2s;
            box-shadow: 0 4px 16px rgba(27,77,46,.28);
            margin-top: 2px;
            margin-bottom: 20px;
        }
        .btn-login:hover { background: #143d24; box-shadow: 0 6px 22px rgba(27,77,46,.38); }
        .btn-login:disabled { background: #94a3b8; box-shadow: none; cursor: not-allowed; }
        .form-date { text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; padding-top: 14px; width: 100%; }

        /* ========== 6. SCANNER PANEL (second tab) ========== */
        .scanner-wrap {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 20px;
            width: 100%;
            max-width: 340px;
            margin: 0 auto;
        }
        .qr-viewport {
            position: relative;
            width: 310px;
            height: 310px;
            background: #ffffff;
        }
        .qr-viewport .corner {
            position: absolute;
            width: 44px; height: 44px;
            border-color: #1b4d2e;
            border-style: solid;
        }
        .corner.tl { top: 0; left: 0; border-width: 3.5px 0 0 3.5px; }
        .corner.tr { top: 0; right: 0; border-width: 3.5px 3.5px 0 0; }
        .corner.bl { bottom: 0; left: 0; border-width: 0 0 3.5px 3.5px; }
        .corner.br { bottom: 0; right: 0; border-width: 0 3.5px 3.5px 0; }
        .qr-viewport .h-divider { position: absolute; left: 8%; right: 8%; top: 50%; height: 1px; background: #d1d5db; }
        #reader { position: absolute; inset: 0; overflow: hidden; display: none; }
        #reader video { width: 100%; height: 100%; object-fit: cover; }
        .qr-placeholder {
            position: absolute;
            inset: 0;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 14px;
        }
        .qr-placeholder p { font-size: 11.5px; color: #94a3b8; text-align: center; }
        .scan-line {
            position: absolute;
            left: 8px; right: 8px;
            height: 2.5px;
            background: linear-gradient(90deg, transparent, #1b4d2e 30%, #1b4d2e 70%, transparent);
            border-radius: 2px;
            display: none;
            animation: scanMove 2.2s ease-in-out infinite;
            z-index: 10;
        }
        @keyframes scanMove {
            0%   { top: 10px; opacity: 0; }
            8%   { opacity: 1; }
            92%  { opacity: 1; }
            100% { top: calc(100% - 12px); opacity: 0; }
        }
        .btn-cam {
            padding: 11px 30px;
            background: transparent;
            border: 2px solid #1b4d2e;
            border-radius: 8px;
            color: #1b4d2e;
            font-family: 'Lato', sans-serif;
            font-size: 12.5px;
            font-weight: 700;
            letter-spacing: 1px;
            text-transform: uppercase;
            cursor: pointer;
            transition: all .2s;
        }
        .btn-cam:hover { background: #1b4d2e; color: #ffffff; }
        .btn-cam.active { background: #991b1b; border-color: #991b1b; color: #ffffff; }
        .scan-status { font-size: 11.5px; color: #94a3b8; }

        /* ========== 7. LOADING OVERLAY ========== */
        .loading-overlay {
            position: fixed;
            inset: 0;
            background: rgba(0,0,0,.55);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 9999;
        }
        .loading-overlay.show { display: flex; }
        .spinner { width: 48px; height: 48px; border: 3.5px solid rgba(255,255,255,.25); border-top-color: #ffffff; border-radius: 50%; animation: spin .7s linear infinite; }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* ========== 8. RESPONSIVE ========== */
        @media (max-width: 860px) {
            .kiosk-card { flex-direction: column; }
            .topbar-title h1 { font-size: 18px; letter-spacing: 3px; }
            .brand-libra { font-size: 16px; }
        }
        @media (max-width: 560px) {
            .topbar-logos { padding: 0 14px; gap: 8px; }
            .topbar-date { display: none; }
            .topbar-title h1 { font-size: 14px; letter-spacing: 2px; }
            .qr-viewport { width: 260px; height: 260px; }
        }
    </style>
</head>
<body>
<form id="mainForm" runat="server">
    <!-- TOP HEADER BAR -->
    <header class="kiosk-topbar">
        <div class="topbar-logos">
            <Img src="/images/spamast-seal.png" onerror="this.style.display='none'" alt="SPAMAST Seal" />
            <Img src="/images/libra-logo.png" onerror="this.style.display='none'" alt="LiBRA Logo" />
            <div class="topbar-brand">
                <span class="brand-libra">LiBRA</span>
                <span class="brand-spamast">SPAMAST</span>
            </div>
        </div>
        <div class="topbar-title"><h1>Attendance Kiosk</h1></div>
        <div class="topbar-date">
            <span class="date-main"><asp:Literal ID="litDateHeader" runat="server" /></span>
            <span class="date-sub"><asp:Literal ID="litSemHeader" runat="server" /></span>
        </div>
    </header>

    <div class="kiosk-body">
        <div class="kiosk-card">
            <!-- Bootstrap Tabs with Icons -->
            <ul class="nav nav-tabs custom-tabs px-3 pt-3" id="kioskTabs" role="tablist">
                <li class="nav-item">
                    <button class="nav-link active" id="form-tab" data-bs-toggle="tab" data-bs-target="#formPane" type="button" role="tab">
                        <i class="fas fa-edit"></i> Kiosk Form
                    </button>
                </li>
                <li class="nav-item">
                    <button class="nav-link" id="scanner-tab" data-bs-toggle="tab" data-bs-target="#scannerPane" type="button" role="tab">
                        <i class="fas fa-qrcode"></i> QR Scanner
                    </button>
                </li>
            </ul>

            <div class="tab-content px-4 pb-4" id="kioskTabsContent">
                <!-- Tab 1: Kiosk Form -->
                <div class="tab-pane fade show active" id="formPane" role="tabpanel">
                    <div class="text-center">
                        <div class="form-logo mx-auto">
                            <Img src="/images/libra-logo.png" onerror="this.style.display='none'" alt="LiBRA" />
                            <span class="form-logo-fallback">LB</span>
                        </div>
                        <h2 class="form-welcome">Welcome to LiBRA</h2>
                        <p class="form-subtitle">Please scan your QR Code or type<br />your Library Card ID</p>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <label class="field-label">Type Your ID</label>
                            <asp:TextBox ID="txtIdNumber" runat="server" CssClass="kiosk-input" placeholder="0000-000000" ClientIDMode="Static" />
                        </div>
                        <div class="col-md-6">
                            <label class="field-label">Purpose of Visit</label>
                            <div class="select-wrap">
                                <asp:DropDownList ID="ddlPurpose" runat="server" CssClass="kiosk-select" ClientIDMode="Static">
                                    <asp:ListItem Value="" Text="Select…" disabled="disabled" selected="True" />
                                    <asp:ListItem Value="Study" Text="Study / Self-review" />
                                    <asp:ListItem Value="Research" Text="Research" />
                                    <asp:ListItem Value="Borrow/Return" Text="Borrow / Return Books" />
                                    <asp:ListItem Value="Computer Use" Text="Computer Use" />
                                    <asp:ListItem Value="Group Work" Text="Group Work" />
                                    <asp:ListItem Value="Other" Text="Other" />
                                </asp:DropDownList>
                            </div>
                        </div>
                    </div>

                    <div class="row mt-3">
                        <div class="col-md-6">
                            <label class="field-label">Name</label>
                            <asp:TextBox ID="txtFullName" runat="server" CssClass="kiosk-input" placeholder="Full Name" ReadOnly="true" ClientIDMode="Static" />
                        </div>
                        <div class="col-md-6">
                            <label class="field-label">Institute</label>
                            <asp:TextBox ID="txtInstitute" runat="server" CssClass="kiosk-input" placeholder="Institute / Dept." ReadOnly="true" ClientIDMode="Static" />
                        </div>
                    </div>

                    <div id="statusDiv" class="status-badge mt-3"></div>

                    <asp:HiddenField ID="hfUserId" runat="server" ClientIDMode="Static" />
                    <asp:HiddenField ID="hfCurrentStatus" runat="server" ClientIDMode="Static" />
                    <asp:HiddenField ID="hfSelectedPurpose" runat="server" ClientIDMode="Static" />
                    <asp:HiddenField ID="hfCurrentStaff" runat="server" ClientIDMode="Static" />

                    <asp:Button ID="btnLogin" runat="server" Text="LOGIN" CssClass="btn-login" OnClientClick="return onLoginClick();" OnClick="btnLogin_Click" ClientIDMode="Static" Enabled="false" />

                    <div class="form-date">
                        Today is <strong><asp:Literal ID="litDateTime" runat="server" /></strong>
                    </div>
                </div>

                <!-- Tab 2: QR Scanner -->
                <div class="tab-pane fade" id="scannerPane" role="tabpanel">
                    <div class="scanner-wrap">
                        <div class="qr-viewport" id="qrViewport">
                            <span class="corner tl"></span><span class="corner tr"></span>
                            <span class="corner bl"></span><span class="corner br"></span>
                            <div class="h-divider"></div>
                            <div class="scan-line" id="scanLine"></div>
                            <div id="reader"></div>
                            <div class="qr-placeholder" id="qrPlaceholder">
                                <svg width="86" height="86" viewBox="0 0 86 86" fill="none" xmlns="http://www.w3.org/2000/svg">
                                    <rect x="4" y="4" width="28" height="28" rx="3" stroke="#1b4d2e" stroke-width="3.5" fill="none"/>
                                    <rect x="12" y="12" width="12" height="12" fill="#1b4d2e"/>
                                    <rect x="54" y="4" width="28" height="28" rx="3" stroke="#1b4d2e" stroke-width="3.5" fill="none"/>
                                    <rect x="62" y="12" width="12" height="12" fill="#1b4d2e"/>
                                    <rect x="4" y="54" width="28" height="28" rx="3" stroke="#1b4d2e" stroke-width="3.5" fill="none"/>
                                    <rect x="12" y="62" width="12" height="12" fill="#1b4d2e"/>
                                    <rect x="54" y="54" width="8" height="8" fill="#1b4d2e"/>
                                    <rect x="66" y="54" width="8" height="8" fill="#1b4d2e"/>
                                    <rect x="74" y="54" width="8" height="8" fill="#1b4d2e"/>
                                    <rect x="54" y="66" width="8" height="8" fill="#1b4d2e"/>
                                    <rect x="66" y="66" width="8" height="8" fill="#1b4d2e"/>
                                    <rect x="54" y="74" width="8" height="8" fill="#1b4d2e"/>
                                    <rect x="74" y="74" width="8" height="8" fill="#1b4d2e"/>
                                </svg>
                                <p>Point your QR code<br/>toward the camera</p>
                            </div>
                        </div>
                        <span class="scan-status" id="scanStatus">Camera is off</span>
                        <button type="button" class="btn-cam" id="btnCam" onclick="toggleScanner()">
                            <i class="fas fa-camera"></i> Scan QR Code
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</form>

<div id="loadingOverlay" class="loading-overlay"><div class="spinner"></div></div>

<!-- ==================== JAVASCRIPT BLOCKS ==================== -->
<script type="text/javascript">
    // ========== 1. GLOBAL VARIABLES ==========
    let html5QrCode = null;
    let isScannerRunning = false;
    let currentStatus = '';

    // ========== 2. DOCUMENT READY ==========
    $(document).ready(function () {
        $('#txtIdNumber').on('keypress', function (e) { if (e.which === 13) { e.preventDefault(); verifyUser(); } });
        $('#ddlPurpose').on('change', validateLoginBtn);
    });

    // ========== 3. QR SCANNER FUNCTIONS ==========
    function toggleScanner() { isScannerRunning ? stopScanner() : startScanner(); }

    function startScanner() {
        $('#qrPlaceholder').hide();
        $('#reader').show();
        $('#scanLine').show();
        $('#scanStatus').text('Scanning…');
        $('#btnCam').html('<i class="fas fa-times"></i> Close Scanner').addClass('active');

        html5QrCode = new Html5Qrcode('reader');
        html5QrCode.start({ facingMode: 'environment' }, { fps: 30, qrbox: { width: 250, height: 250 } },
            function (decoded) {
                stopScanner();
                $('#scanStatus').text('QR detected – looking up…');
                $('#txtIdNumber').val(decoded);
                verifyUser();
            }
        ).catch(function (err) {
            console.error('Scanner error:', err);
            Swal.fire('Camera Error', 'Could not access camera. Please check permissions.', 'error');
            stopScanner();
        });
        isScannerRunning = true;
    }

    function stopScanner() {
        if (html5QrCode && isScannerRunning) {
            html5QrCode.stop().then(function () {
                $('#reader').hide(); $('#scanLine').hide(); $('#qrPlaceholder').show();
                isScannerRunning = false;
            }).catch(function () { });
        } else {
            $('#reader').hide(); $('#scanLine').hide(); $('#qrPlaceholder').show();
            isScannerRunning = false;
        }
        $('#scanStatus').text('Camera is off');
        $('#btnCam').html('<i class="fas fa-camera"></i> Scan QR Code').removeClass('active');
    }

    // ========== 4. USER VERIFICATION ==========
    function verifyUser() {
        const rawInput = $('#txtIdNumber').val().trim();
        if (!rawInput) { Swal.fire('Empty Field', 'Please scan QR code or type your Library Card ID.', 'warning'); return; }
        showLoading();
        $.ajax({
            type: 'POST',
            url: 'SelfServiceKiosk.aspx/VerifyUser',
            data: JSON.stringify({ inputData: rawInput }),
            contentType: 'application/json; charset=utf-8',
            dataType: 'json',
            success: function (response) {
                hideLoading();
                const res = response.d;
                if (res.success) {
                    $('#txtIdNumber').val(res.userId).addClass('populated');
                    $('#txtFullName').val(res.fullName).addClass('populated');
                    $('#txtInstitute').val(res.institute).addClass('populated');
                    $('#hfUserId').val(res.userId);
                    currentStatus = res.status;
                    $('#hfCurrentStatus').val(currentStatus);

                    const sd = $('#statusDiv');
                    if (currentStatus === 'Entry') {
                        sd.removeClass('status-out').addClass('status-in').text('● Currently INSIDE the Library');
                        $('#btnLogin').val('CHECK-OUT / EXIT');
                        $('#ddlPurpose').prop('disabled', true).val(res.lastPurpose || '');
                    } else {
                        sd.removeClass('status-in').addClass('status-out').text('● Currently OUTSIDE the Library');
                        $('#btnLogin').val('LOGIN');
                        $('#ddlPurpose').prop('disabled', false).val('').focus();
                    }
                    validateLoginBtn();
                    Swal.fire({ icon: 'success', title: 'Welcome!', text: 'Hello, ' + res.fullName, timer: 1600, showConfirmButton: false });
                } else {
                    resetAllFields();
                    Swal.fire('Not Found', res.message || 'Invalid ID or user not found.', 'error');
                }
            },
            error: function () { hideLoading(); Swal.fire('Error', 'Server connection failed. Please try again.', 'error'); }
        });
    }

    function validateLoginBtn() {
        const hasId = $('#txtIdNumber').val().trim() !== '';
        const hasName = $('#txtFullName').val().trim() !== '';
        const hasPurpose = currentStatus === 'Entry' || $('#ddlPurpose').val() !== '';
        $('#btnLogin').prop('disabled', !(hasId && hasName && hasPurpose));
    }

    // ========== 5. ATTENDANCE SUBMISSION ==========
    function onLoginClick() {
        const userId = $('#hfUserId').val();
        const purpose = $('#ddlPurpose').val().trim();
        if (!userId) { Swal.fire('Incomplete', 'Please verify your ID first.', 'warning'); return false; }
        if (currentStatus !== 'Entry' && !purpose) { Swal.fire('Incomplete', 'Please select a purpose for your visit.', 'warning'); $('#ddlPurpose').focus(); return false; }

        showLoading();
        $.ajax({
            type: 'POST',
            url: 'SelfServiceKiosk.aspx/RecordAttendance',
            data: JSON.stringify({ userId: userId, purpose: purpose }),
            contentType: 'application/json; charset=utf-8',
            dataType: 'json',
            success: function (response) {
                hideLoading();
                if (response.d && response.d.success) {
                    Swal.fire({
                        icon: 'success',
                        title: response.d.action === 'checkin' ? 'Check-in Successful!' : 'Check-out Successful!',
                        text: response.d.message,
                        timer: 3000,
                        showConfirmButton: true
                    }).then(() => { resetAllFields(); });
                } else {
                    Swal.fire('Error', response.d?.message || 'Failed to record attendance.', 'error');
                }
            },
            error: function () { hideLoading(); Swal.fire('Error', 'Server error occurred. Please try again.', 'error'); }
        });
        return false;
    }

    // ========== 6. HELPER FUNCTIONS ==========
    function resetAllFields() {
        $('#txtIdNumber, #txtFullName, #txtInstitute').val('').removeClass('populated');
        $('#ddlPurpose').val('').prop('disabled', false);
        $('#hfUserId, #hfCurrentStatus').val('');
        $('#statusDiv').removeClass('status-in status-out').text('').hide();
        currentStatus = '';
        $('#btnLogin').val('LOGIN').prop('disabled', true);
        $('#txtIdNumber').prop('disabled', false).focus();
        $('#btnCam').prop('disabled', false);
    }

    function showLoading() { $('#loadingOverlay').addClass('show'); }
    function hideLoading() { $('#loadingOverlay').removeClass('show'); }
</script>
</body>
</html>