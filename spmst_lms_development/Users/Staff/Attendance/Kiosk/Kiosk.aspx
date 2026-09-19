<%@ Page Title="Staff Assisted Kiosk" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="Kiosk.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Attendance.Kiosk.Kiosk" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <!-- External Libraries -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css" />

    <!-- ==================== INTERNAL CSS STYLES ==================== -->
    <style>
        /* ========== 1. GLOBAL & BODY OVERRIDES ========== */
        body {
            background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            min-height: 100vh;
            margin: 0;
        }

        /* ========== 2. KIOSK WRAPPER & CARD ========== */
        .kiosk-wrapper {
            display: flex;
            justify-content: center;
            align-items: flex-start;
            min-height: 100vh;
            padding: 40px 20px;
        }
        .kiosk-card {
            width: 100%;
            max-width: 1200px;
            background: white;
            border-radius: 24px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }

        /* ========== 3. NAVIGATION BAR ========== */
        .nav-bar {
            background: #f8fafc;
            padding: 15px 25px;
            border-bottom: 1px solid #e2e8f0;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        .btn-back {
            background: #64748b;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 12px;
            font-weight: 600;
            font-size: 14px;
            cursor: pointer;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            text-decoration: none;
        }
        .btn-back:hover { background: #475569; transform: translateY(-1px); color: white; }
        .nav-title {
            font-size: 16px;
            font-weight: 600;
            color: #1e293b;
            margin-left: auto;
        }

        /* ========== 4. BOOTSTRAP TAB CUSTOMIZATION ========== */
        .custom-tabs .nav-link {
            color: #64748b;
            font-weight: 500;
            border: none;
            padding: 12px 24px;
            transition: all 0.2s;
        }
        .custom-tabs .nav-link:hover {
            color: #1e3a8a;
            border-color: transparent;
        }
        .custom-tabs .nav-link.active {
            color: #1e3a8a;
            background-color: transparent;
            border-bottom: 2px solid #1e3a8a;
            font-weight: 600;
        }
        .tab-content {
            margin-top: 20px;
        }

        /* ========== 5. FORM & QR SECTIONS (inside first tab) ========== */
        .form-section, .qr-section {
            padding: 25px;
        }
        .qr-placeholder {
            width: 100%;
            max-width: 250px;
            aspect-ratio: 1/1;
            border: 4px dashed #cbd5e1;
            border-radius: 20px;
            margin: 0 auto 20px auto;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #94a3b8;
            font-size: 70px;
            background: white;
            position: relative;
            overflow: hidden;
            box-shadow: inset 0 4px 10px rgba(0,0,0,0.05);
        }
        #reader { width: 100%; height: 100%; border-radius: 16px; display: none; }
        .scan-line {
            position: absolute;
            left: 0;
            top: 50%;
            width: 100%;
            height: 3px;
            background: #ef4444;
            box-shadow: 0 0 10px #ef4444;
            display: none;
            animation: scan-anim 2.5s infinite ease-in-out;
        }
        @keyframes scan-anim {
            0% { top: 5%; }
            50% { top: 95%; }
            100% { top: 5%; }
        }
        .btn-camera {
            background: #1e3a8a;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 50px;
            font-weight: bold;
            font-size: 14px;
            cursor: pointer;
            transition: all 0.2s;
            width: 100%;
            max-width: 250px;
        }
        .btn-camera:hover { background: #1e40af; transform: translateY(-2px); }

        /* ========== 6. INPUT FIELDS & BUTTONS ========== */
        .input-group { display: flex; flex-direction: column; gap: 8px; margin-bottom: 18px; }
        .input-group.row { flex-direction: row; align-items: center; }
        .input-label {
            font-size: 13px;
            font-weight: 700;
            color: #64748b;
            text-transform: uppercase;
        }
        .input-field {
            width: 100%;
            padding: 14px 18px;
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            font-size: 15px;
            font-weight: 600;
            background: #fff;
            transition: border-color 0.2s;
        }
        .input-field:focus {
            border-color: #3b82f6;
            outline: none;
            box-shadow: 0 0 0 3px rgba(59,130,246,0.1);
        }
        .input-field:read-only {
            background: #f8fafc;
            color: #94a3b8;
            border-color: #f1f5f9;
            cursor: not-allowed;
        }
        .btn-verify {
            background: #0ea5e9;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 12px;
            font-weight: bold;
            cursor: pointer;
            transition: background 0.2s;
            font-size: 15px;
            white-space: nowrap;
        }
        .btn-verify:hover { background: #0284c7; }
        .btn-submit {
            width: 100%;
            background: #10b981;
            color: white;
            border: none;
            padding: 18px;
            border-radius: 14px;
            font-size: 16px;
            font-weight: 800;
            margin-top: auto;
            cursor: pointer;
            transition: all 0.2s;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .btn-submit:disabled {
            background: #cbd5e1;
            cursor: not-allowed;
        }
        .btn-submit:hover:not(:disabled) {
            background: #059669;
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(16,185,129,0.2);
        }

        /* ========== 7. STATUS BADGES & CLOCK ========== */
        .status-alert {
            margin-top: -5px;
            margin-bottom: 15px;
            padding: 12px 20px;
            border-radius: 12px;
            text-align: center;
            font-weight: bold;
            display: none;
            font-size: 14px;
        }
        .status-in {
            background: #dcfce7;
            color: #166534;
            border: 1px solid #bbf7d0;
        }
        .status-out {
            background: #fee2e2;
            color: #991b1b;
            border: 1px solid #fecaca;
        }
        .live-clock-display {
            background: #f8fafc;
            padding: 12px 20px;
            border-radius: 12px;
            color: #475569;
            font-weight: 700;
            font-size: 14px;
            text-align: center;
            border: 1px solid #e2e8f0;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            margin-top: 5px;
        }

        /* ========== 8. RECENT ACTIVITY TABLE (inside second tab) ========== */
        .table-container {
            max-height: 400px;
            overflow-y: auto;
            border-radius: 12px;
            border: 1px solid #e2e8f0;
        }
        .activity-table {
            width: 100%;
            border-collapse: collapse;
        }
        .activity-table thead {
            position: sticky;
            top: 0;
            background: #f1f5f9;
            z-index: 10;
        }
        .activity-table th {
            padding: 16px;
            color: #475569;
            font-weight: 700;
            font-size: 13px;
            text-transform: uppercase;
        }
        .activity-table td {
            padding: 14px 16px;
            border-bottom: 1px solid #f1f5f9;
            color: #1e293b;
            font-size: 14px;
            font-weight: 500;
        }
        .activity-table tr:hover td { background: #f8fafc; }
        .badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
        }
        .badge-in { background: #dcfce7; color: #166534; }
        .badge-out { background: #f1f5f9; color: #475569; }

        /* ========== 9. LOADING OVERLAY ========== */
        .loading-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0,0,0,0.7);
            display: none;
            justify-content: center;
            align-items: center;
            z-index: 3000;
        }
        .spinner {
            width: 50px;
            height: 50px;
            border: 4px solid white;
            border-top-color: #3b82f6;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* ========== 10. RESPONSIVE ========== */
        @media (max-width: 768px) {
            .kiosk-wrapper { padding: 20px 10px; }
            .nav-bar { padding: 12px 15px; }
            .btn-back { padding: 8px 16px; font-size: 12px; }
            .form-section, .qr-section { padding: 20px; }
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="kiosk-wrapper">
        <div class="kiosk-card">
            <!-- Navigation Bar -->
            <div class="nav-bar">
                <div class="nav-title">
                    <i class="fas fa-chalkboard-user"></i> Staff Assisted Kiosk
                </div>
            </div>

            <!-- Bootstrap Tabs with Icons & Active Status -->
            <ul class="nav nav-tabs custom-tabs px-3 pt-3" id="kioskTabs" role="tablist">
                <li class="nav-item" role="presentation">
                    <button class="nav-link active" id="kiosk-tab" data-bs-toggle="tab" data-bs-target="#kioskPane" type="button" role="tab">
                        <i class="fas fa-id-card"></i> Check-in / Check-out
                    </button>
                </li>
                <li class="nav-item" role="presentation">
                    <button class="nav-link" id="activity-tab" data-bs-toggle="tab" data-bs-target="#activityPane" type="button" role="tab">
                        <i class="fas fa-history"></i> Today's Activity
                    </button>
                </li>
            </ul>

            <div class="tab-content px-4 pb-4" id="kioskTabsContent">
                <!-- Tab 1: Main Kiosk Form + QR Scanner -->
                <div class="tab-pane fade show active" id="kioskPane" role="tabpanel">
                    <div class="row">
                        <div class="col-md-6 form-section">
                            <div class="section-title mb-3"><i class="fas fa-user-edit"></i> PATRON DETAILS</div>
                            <div class="input-group row">
                                <input type="text" id="txtIdNumber" class="input-field flex-grow-1" placeholder="Scan or Type ID Number" autocomplete="off" />
                                <button type="button" id="btnVerify" class="btn-verify ms-2" onclick="verifyUser()">Verify</button>
                            </div>
                            <div class="input-group">
                                <input type="text" id="txtFullName" class="input-field" placeholder="Full Name" readonly />
                            </div>
                            <div class="input-group">
                                <input type="text" id="txtInstitute" class="input-field" placeholder="Institute / Course / Office" readonly />
                            </div>
                            <div id="divStatus" class="status-alert status-out">Current Status: Outside</div>
                            <div id="purposeContainer">
                                <div class="section-title mt-3"><i class="fas fa-clipboard-check"></i> PURPOSE OF VISIT</div>
                                <div class="input-group">
                                    <div class="datalist-wrapper w-100">
                                        <input type="text" id="txtPurpose" list="purposeOptions" class="input-field" placeholder="Select or Type Purpose..." disabled />
                                        <datalist id="purposeOptions"></datalist>
                                    </div>
                                </div>
                            </div>
                            <div class="input-group">
                                <div class="live-clock-display">
                                    <i class="fas fa-clock"></i> <span id="clockSpan">Loading Time...</span>
                                </div>
                            </div>
                            <button type="button" id="btnSubmit" class="btn-submit mt-3" onclick="submitAttendance()" disabled>COMPLETE CHECK-IN</button>
                        </div>

                        <div class="col-md-6 qr-section text-center">
                            <h3 style="font-size: 24px; font-weight: 800; color: #1e293b;"><i class="fas fa-qrcode"></i> SCAN QR</h3>
                            <p class="text-muted">Hold library QR code to the camera</p>
                            <div class="qr-placeholder mx-auto" id="qrContainer">
                                <i class="fas fa-qrcode" id="qrIcon"></i>
                                <div id="reader"></div>
                                <div id="scanLine" class="scan-line"></div>
                            </div>
                            <button type="button" id="btnOpenCamera" class="btn-camera mt-3" onclick="toggleScanner()">
                                <i class="fas fa-camera"></i> Open Camera
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Tab 2: Recent Activity Log -->
                <div class="tab-pane fade" id="activityPane" role="tabpanel">
                    <div class="table-container">
                        <table class="activity-table">
                            <thead>
                                <tr>
                                    <th>Patron Name</th>
                                    <th>Purpose</th>
                                    <th>Time In</th>
                                    <th>Time Out</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody id="recentActivityList">
                                <tr><td colspan="5" class="text-center text-muted py-4">Loading data...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <audio id="scanBeep" src="https://Assets.mixkit.co/active_storage/sfx/766/766-preview.mp3" preload="auto"></audio>
    <div id="loadingOverlay" class="loading-overlay"><div class="spinner"></div></div>

    <!-- ==================== JAVASCRIPT BLOCKS ==================== -->
    <script type="text/javascript">
        // ========== 1. GLOBAL VARIABLES ==========
        let html5QrCode;
        let isScannerRunning = false;
        let currentStatus = "";

        // ========== 2. DOCUMENT READY INITIALIZATION ==========
        $(document).ready(function () {
            startLiveClock();
            loadRecentActivity();
            loadPurposes();

            $('#txtIdNumber').keypress(function (e) {
                if (e.which === 13) { e.preventDefault(); verifyUser(); }
            });
        });

        // ========== 3. CLOCK & DATA LOADING ==========
        function startLiveClock() {
            setInterval(function () {
                const now = new Date();
                const options = { weekday: 'long', year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit' };
                document.getElementById('clockSpan').innerText = now.toLocaleDateString('en-US', options);
            }, 1000);
        }

        function loadPurposes() {
            $.ajax({
                type: "POST",
                url: "Kiosk.aspx/GetPurposes",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    let datalist = document.getElementById('purposeOptions');
                    datalist.innerHTML = "";
                    response.d.forEach(purpose => {
                        let option = document.createElement('option');
                        option.value = purpose;
                        datalist.appendChild(option);
                    });
                }
            });
        }

        function loadRecentActivity() {
            $.ajax({
                type: "POST",
                url: "Kiosk.aspx/GetRecentActivity",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    let rows = "";
                    if (response.d && response.d.length > 0) {
                        response.d.forEach(act => {
                            let badgeClass = act.Status === "Entry" ? "badge-in" : "badge-out";
                            rows += `<tr>
                                <td><strong>${escapeHtml(act.Name)}</strong></td>
                                <td>${escapeHtml(act.Purpose)}</td>
                                <td>${act.TimeIn}</td>
                                <td class="text-muted">${act.TimeOut}</td>
                                <td><span class="badge ${badgeClass}">${act.Status === 'Entry' ? 'INSIDE' : 'EXITED'}</span></td>
                            </tr>`;
                        });
                    } else {
                        rows = `<tr><td colspan="5" class="text-center text-muted py-4">No activity recorded today yet.</td></tr>`;
                    }
                    $('#recentActivityList').html(rows);
                }
            });
        }

        // ========== 4. QR SCANNER FUNCTIONS ==========
        function toggleScanner() {
            isScannerRunning ? stopScanner() : startScanner();
        }

        function startScanner() {
            $('#qrIcon').hide();
            $('#reader').show();
            $('#scanLine').show();
            $('#btnOpenCamera').html('<i class="fas fa-times"></i> Close Camera').css('background', '#dc2626');

            html5QrCode = new Html5Qrcode("reader");
            const config = { fps: 30, qrbox: { width: 250, height: 250 } };
            html5QrCode.start({ facingMode: "environment" }, config, (decodedText) => {
                $('#scanLine').hide();
                document.getElementById('scanBeep').play();
                $('#txtIdNumber').val(decodedText);
                toggleScanner();
                verifyUser();
            }).catch(err => {
                console.error("Scanner error:", err);
                Swal.fire('Camera Error', 'Could not access camera. Please check permissions.', 'error');
                toggleScanner();
            });
            isScannerRunning = true;
        }

        function stopScanner() {
            if (html5QrCode && isScannerRunning) {
                html5QrCode.stop().then(() => {
                    $('#qrIcon').show();
                    $('#reader').hide();
                    $('#scanLine').hide();
                    isScannerRunning = false;
                    $('#btnOpenCamera').html('<i class="fas fa-camera"></i> Open Camera').css('background', '#1e3a8a');
                }).catch(() => { });
            } else {
                $('#qrIcon').show();
                $('#reader').hide();
                $('#scanLine').hide();
                isScannerRunning = false;
            }
        }

        // ========== 5. USER VERIFICATION & ATTENDANCE SUBMISSION ==========
        function verifyUser() {
            const rawInput = $('#txtIdNumber').val().trim();
            if (!rawInput) {
                Swal.fire('Empty Field', 'Please scan a QR or type an ID Number', 'warning');
                return;
            }
            showLoading();
            $.ajax({
                type: "POST",
                url: "Kiosk.aspx/VerifyUser",
                data: JSON.stringify({ inputData: rawInput }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    hideLoading();
                    const res = response.d;
                    if (res.success) {
                        $('#txtIdNumber').val(res.userId);
                        $('#txtFullName').val(res.fullName);
                        $('#txtInstitute').val(res.institute);
                        currentStatus = res.status;
                        const statusDiv = $('#divStatus');
                        const purposeInput = $('#txtPurpose');
                        const btnSubmit = $('#btnSubmit');

                        statusDiv.show();
                        btnSubmit.prop('disabled', false);

                        if (currentStatus === "Entry") {
                            statusDiv.removeClass('status-out').addClass('status-in').text('You are about to Checkout from the Library');
                            btnSubmit.text('COMPLETE CHECK-OUT');
                            purposeInput.val(res.lastPurpose || 'N/A').prop('disabled', true);
                        } else {
                            statusDiv.removeClass('status-in').addClass('status-out').text('Welcome To SPAMAST Library');
                            btnSubmit.text('COMPLETE CHECK-IN');
                            purposeInput.val('').prop('disabled', false).focus();
                        }
                        Swal.fire({ icon: 'success', title: 'Verified!', text: `Welcome, ${res.fullName}`, timer: 1500, showConfirmButton: false });
                    } else {
                        resetForm(true);
                        Swal.fire('Not Found', 'Invalid ID or User not found.', 'error');
                    }
                },
                error: function () {
                    hideLoading();
                    Swal.fire('Error', 'Server connection failed.', 'error');
                }
            });
        }

        function submitAttendance() {
            const userId = $('#txtIdNumber').val().trim();
            const purpose = $('#txtPurpose').val().trim();

            if (!userId) {
                Swal.fire('Incomplete', 'Please verify an ID first.', 'warning');
                return;
            }
            if (currentStatus !== "Entry" && !purpose) {
                Swal.fire('Incomplete', 'Please select or type a purpose for your visit.', 'warning');
                $('#txtPurpose').focus();
                return;
            }

            showLoading();
            $.ajax({
                type: "POST",
                url: "Kiosk.aspx/RecordAttendance",
                data: JSON.stringify({ userId: userId, purpose: purpose }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    hideLoading();
                    if (response.d.success) {
                        Swal.fire({
                            icon: 'success',
                            title: 'Success!',
                            text: response.d.message,
                            timer: 3000,
                            showConfirmButton: true
                        });
                        loadRecentActivity();
                        resetForm(false);
                    } else {
                        Swal.fire('Error', response.d.message || 'Failed to record attendance.', 'error');
                    }
                },
                error: function () {
                    hideLoading();
                    Swal.fire('Error', 'Server error occurred. Please try again.', 'error');
                }
            });
        }

        // ========== 6. HELPER FUNCTIONS ==========
        function resetForm(keepId = false) {
            if (!keepId) $('#txtIdNumber').val('');
            $('#txtFullName, #txtInstitute').val('');
            $('#divStatus').hide();
            $('#txtPurpose').val('').prop('disabled', true);
            $('#btnSubmit').prop('disabled', true).text('COMPLETE CHECK-IN');
            currentStatus = "";
        }

        function showLoading() { $('#loadingOverlay').fadeIn(); }
        function hideLoading() { $('#loadingOverlay').fadeOut(); }

        function escapeHtml(str) {
            if (!str) return '';
            return str.replace(/[&<>]/g, function (m) {
                if (m === '&') return '&amp;';
                if (m === '<') return '&lt;';
                if (m === '>') return '&gt;';
                return m;
            });
        }
    </script>
</asp:Content>