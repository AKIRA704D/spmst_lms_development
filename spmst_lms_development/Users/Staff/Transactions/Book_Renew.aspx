<%@ Page Title="Book Renewal" Language="C#" MasterPageFile="~/Users/MasterPage/Admin.Master" AutoEventWireup="true" CodeBehind="Book_Renew.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Transactions.Book_Renew" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="https://unpkg.com/html5-qrcode"></script>

    <style>
        /* ============================================
           1. SCANNER OVERLAY & ANIMATION
           ============================================ */
        #scanner-area {
            max-width: 400px;
            margin: 0 auto;
            position: relative;
        }
        .scanner-overlay {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 260px;
            height: 260px;
            z-index: 10;
            pointer-events: none;
        }
        .scanner-line {
            position: absolute;
            width: 100%;
            height: 3px;
            background: rgba(30, 58, 138, 0.6);
            box-shadow: 0 0 10px 2px rgba(30, 58, 138, 0.8);
            top: 0;
            animation: scanLine 2s linear infinite;
        }
        @keyframes scanLine {
            0% { top: 0%; }
            50% { top: 100%; }
            100% { top: 0%; }
        }
        #reader {
            width: 100%;
            border-radius: 15px;
            overflow: hidden;
            background: #000;
            border: 2px solid #1e3a8a !important;
        }

        /* ============================================
           2. CUSTOM TABS (nav-pills)
           ============================================ */
        .nav-pills .nav-link.active {
            background-color: #1e3a8a !important;
        }
        .bg-light-blue {
            background-color: #eef4ff;
        }
        .avatar-circle.small {
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
        }
        .card.rounded-4 {
            border-radius: 1rem !important;
        }
        .step-locked {
            opacity: 0.4;
            pointer-events: none;
            filter: grayscale(100%);
            transition: all 0.3s ease-in-out;
        }
        .btn-primary {
            background-color: #1e3a8a !important;
            border: none;
        }
        .due-date-warning {
            background-color: #fee2e2;
            border: 1px solid #dc2626;
            border-radius: 0.5rem;
            padding: 0.75rem;
            margin-bottom: 1rem;
        }
        .penalty-item {
            background-color: #fff5f5;
            border-left: 3px solid #dc2626;
            padding: 0.5rem;
            margin-bottom: 0.5rem;
            font-size: 0.8rem;
        }
    </style>

    <script type="text/javascript">
        // Reusable scanner (only book barcode, but we also need patron scanner – reuse same logic)
        let html5QrScanner = null;
        let isCameraActive = false;
        const scanSound = new Audio('https://Assets.mixkit.co/active_storage/sfx/766/766-preview.mp3');

        async function startScanner(target) {
            scanSound.play().then(() => { scanSound.pause(); scanSound.currentTime = 0; }).catch(e => console.log("Audio prep failed", e));
            window.activeScannerTarget = target;
            const scannerArea = document.getElementById('scanner-area');
            scannerArea.classList.remove('d-none');

            if (html5QrScanner && isCameraActive) {
                try { await html5QrScanner.stop(); } catch (e) { }
            }
            if (html5QrScanner) {
                try { html5QrScanner.clear(); } catch (e) { }
            }

            html5QrScanner = new Html5Qrcode("reader");
            const config = { fps: 15, qrbox: { width: 250, height: 250 }, aspectRatio: 1.0 };

            try {
                await html5QrScanner.start({ facingMode: "environment" }, config, onScanSuccess);
                isCameraActive = true;
                document.getElementById('reader').style.border = "4px solid #1e3a8a";
            } catch (err) {
                console.error("Camera error:", err);
                Swal.fire('Camera Error', 'Could not access camera. Please check permissions.', 'error');
                scannerArea.classList.add('d-none');
            }
        }

        function onScanSuccess(decodedText) {
            scanSound.play();
            document.getElementById('scanner-area').classList.add('d-none');
            if (html5QrScanner && isCameraActive) {
                html5QrScanner.stop().catch(e => console.warn(e));
                isCameraActive = false;
            }
            let cleanedText = decodedText.trim().replace(/[\n\r\t]/g, '');
            if (window.activeScannerTarget === 'patron') {
                const txtPatron = document.getElementById('<%= txtPatronQR.ClientID %>');
                if (txtPatron) {
                    txtPatron.value = cleanedText;
                    txtPatron.dispatchEvent(new Event('change', { bubbles: true }));
                    setTimeout(() => __doPostBack('<%= txtPatronQR.UniqueID %>', ''), 50);
                }
            } else {
                const txtBook = document.getElementById('<%= txtBookBarcode.ClientID %>');
                if (txtBook) {
                    txtBook.value = cleanedText;
                    txtBook.dispatchEvent(new Event('change', { bubbles: true }));
                    setTimeout(() => __doPostBack('<%= txtBookBarcode.UniqueID %>', ''), 50);
                }
            }
        }

        function stopScanner() {
            const scannerArea = document.getElementById('scanner-area');
            if (scannerArea) scannerArea.classList.add('d-none');
            if (html5QrScanner && isCameraActive) {
                html5QrScanner.stop().catch(e => console.warn(e));
                isCameraActive = false;
            }
        }

        // Re-enable approve button after partial postback
        function enableRenewButton() {
            var btn = document.getElementById('<%= btnRenew.ClientID %>');
            if (btn) { btn.disabled = false; btn.style.opacity = '1'; btn.style.pointerEvents = 'auto'; }
        }
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            enableRenewButton();
        });
    </script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid py-4">
        <div class="mb-4">
            <h2 class="fw-bold">Good Day, Librarian! 👋</h2>
            <p class="text-muted">Process book renewals and manage overdue items.</p>
        </div>

        <div class="row g-4">
            <div class="col-lg-7">
                <div class="card border-0 shadow-sm rounded-4 overflow-hidden">
                    <div class="card-header bg-white border-0 p-3">
                        <ul class="nav nav-pills bg-light rounded-3 p-1">
                            <li class="nav-item">
                                <asp:HyperLink ID="lnkBorrow" runat="server" NavigateUrl="Book_Borrow.aspx" CssClass="nav-link text-secondary fw-semibold">
                                    <i class="fas fa-book-open me-1"></i> Borrow
                                </asp:HyperLink>
                            </li>
                            <li class="nav-item">
                                <asp:HyperLink ID="lnkReturn" runat="server" NavigateUrl="Book_Return.aspx" CssClass="nav-link text-secondary fw-semibold">
                                    <i class="fas fa-undo-alt me-1"></i> Returning
                                </asp:HyperLink>
                            </li>
                            <li class="nav-item">
                                <asp:HyperLink ID="lnkRenew" runat="server" NavigateUrl="Book_Renew.aspx" CssClass="nav-link active fw-semibold">
                                    <i class="fas fa-sync-alt me-1"></i> Renew
                                </asp:HyperLink>
                            </li>
                        </ul>
                    </div>

                    <div class="card-body p-4">
                        <asp:UpdatePanel ID="UPCirculation" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <!-- Scanner UI -->
                                <div id="scanner-area" class="mb-4 d-none">
                                    <div style="position: relative;">
                                        <div id="reader"></div>
                                        <div class="scanner-overlay"><div class="scanner-line"></div></div>
                                    </div>
                                    <button type="button" onclick="stopScanner()" class="btn btn-danger w-100 mt-2">Close Camera</button>
                                </div>

                                <!-- Step 1: Patron -->
                                <div class="mb-4">
                                    <label class="form-label text-uppercase fw-bold small text-muted">Step 1: Identify Patron</label>
                                    <div class="input-group input-group-lg border rounded-3 overflow-hidden">
                                        <span class="input-group-text bg-white border-0"><i class="fas fa-id-card"></i></span>
                                        <asp:TextBox ID="txtPatronQR" runat="server" CssClass="form-control border-0 bg-white" placeholder="Scan QR"
                                            OnTextChanged="txtPatronQR_TextChanged" AutoPostBack="true" />
                                        <button class="btn btn-white border-0" type="button" onclick="startScanner('patron')">
                                            <i class="fas fa-camera text-primary"></i>
                                        </button>
                                    </div>
                                </div>

                                <!-- Patron Info Panel -->
                                <asp:Panel ID="pnlPatronInfo" runat="server" Visible="false" CssClass="bg-light-blue p-3 rounded-3 mb-4">
                                    <div class="d-flex align-items-center gap-3 mb-2">
                                        <div class="avatar-circle small bg-primary text-white"><asp:Literal ID="litInitial" runat="server" Text="?" /></div>
                                        <div>
                                            <h6 class="mb-0 fw-bold"><asp:Literal ID="litPatronName" runat="server" /></h6>
                                            <small class="text-muted"><asp:Literal ID="litPatronDept" runat="server" /></small>
                                            <div><span class="badge bg-secondary mt-1"><asp:Literal ID="litPatronRole" runat="server" /></span></div>
                                        </div>
                                    </div>
                                    <!-- Penalties Section -->
                                    <div id="penaltySection" runat="server" visible="false" class="mt-2">
                                        <hr />
                                        <div class="small fw-bold text-danger mb-1"><i class="fas fa-exclamation-triangle me-1"></i> Unsettled Penalties</div>
                                        <asp:Repeater ID="rptPenalties" runat="server">
                                            <ItemTemplate>
                                                <div class="penalty-item">
                                                    <div class="fw-bold"><%# Eval("BookTitle") %></div>
                                                    <div class="small">Acc: <%# Eval("AccessionNumber") %></div>
                                                    <div class="small text-danger">Penalty: <%# Eval("PenaltyType") %></div>
                                                </div>
                                            </ItemTemplate>
                                            <FooterTemplate>
                                                <div id="noPenalties" runat="server" visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>' class="text-muted small">No unsettled penalties.</div>
                                            </FooterTemplate>
                                        </asp:Repeater>
                                    </div>
                                </asp:Panel>

                                <!-- Step 2: Book -->
                                <div id="divBookStep" runat="server" class="mb-4 step-locked">
                                    <label class="form-label text-uppercase fw-bold small text-muted">Step 2: Scan Book to Renew</label>
                                    <div class="input-group input-group-lg border rounded-3 overflow-hidden">
                                        <span class="input-group-text bg-white border-0"><i class="fas fa-book"></i></span>
                                        <asp:TextBox ID="txtBookBarcode" runat="server" CssClass="form-control border-0 bg-white" placeholder="Scan Barcode"
                                            OnTextChanged="txtBookBarcode_TextChanged" AutoPostBack="true" Enabled="false" />
                                        <button id="btnBookCam" runat="server" class="btn btn-white border-0" type="button" onclick="startScanner('book')" disabled="disabled">
                                            <i class="fas fa-camera text-primary"></i>
                                        </button>
                                    </div>
                                </div>

                                <!-- Book Info Panel -->
                                <asp:Panel ID="pnlBookInfo" runat="server" Visible="false" CssClass="card border-0 bg-light p-3 rounded-4 mb-3">
                                    <h6 class="fw-bold mb-1"><asp:Literal ID="litBookTitle" runat="server" /></h6>
                                    <p class="small text-muted mb-0">Author: <asp:Literal ID="litBookAuthor" runat="server" /></p>
                                    <p class="small text-muted mb-0">Section: <asp:Literal ID="litBookSection" runat="server" /></p>
                                    <p class="small text-muted mb-3">Acc no. <asp:Literal ID="litBookAccNo" runat="server" /></p>
                                    <div class="due-date-warning">
                                        <i class="fas fa-calendar-alt me-2"></i>
                                        <span class="fw-bold">Current Due Date:</span>
                                        <asp:Literal ID="litDueDate" runat="server" />
                                    </div>
                                    <div class="d-flex align-items-center gap-2 mb-3">
                                        <label class="small text-muted">Loan Type:</label>
                                        <asp:DropDownList ID="ddlLoanType" runat="server" CssClass="form-select form-select-sm w-auto shadow-sm" Enabled="false">
                                            <asp:ListItem Text="LOAN-OUT" Value="LOAN-OUT" Selected="True" />
                                            <asp:ListItem Text="LOAN-IN" Value="LOAN-IN" />
                                        </asp:DropDownList>
                                    </div>
                                    <div class="d-flex gap-3">
                                        <asp:Button ID="btnRenew" runat="server" Text="Approve Renewal" CssClass="btn btn-primary w-100 py-2 fw-bold shadow-sm" OnClick="btnRenew_Click" />
                                        <asp:Button ID="btnDeny" runat="server" Text="Deny Renewal" CssClass="btn btn-outline-danger w-100 py-2 fw-bold" OnClick="btnDeny_Click" Visible="false" />
                                    </div>
                                </asp:Panel>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </div>
                </div>
            </div>

            <!-- Right Sidebar -->
            <div class="col-lg-5">
                <div class="card border-0 shadow-sm rounded-4 mb-4">
                    <div class="card-header bg-white border-0 p-3 d-flex align-items-center gap-2">
                        <div class="p-1 bg-primary rounded-circle"></div>
                        <span class="fw-bold">Live Feed</span>
                    </div>
                    <div class="card-body border-top">
                        <asp:UpdatePanel ID="UPLiveFeed" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <div id="divAwaiting" runat="server" class="text-center text-muted py-5" visible="true">
                                    <i class="fas fa-stream mb-2 fs-3 opacity-25"></i>
                                    <p>Awaiting renewals...</p>
                                </div>
                                <asp:Repeater ID="rptFeed" runat="server">
                                    <ItemTemplate>
                                        <div class="d-flex gap-3 mb-3 border-bottom pb-2">
                                            <div class="text-primary mt-1"><i class="fas fa-sync-alt"></i></div>
                                            <div style="flex:1;">
                                                <div class="fw-bold text-dark"><%# Eval("PatronName") %> - <span class="fw-normal text-muted"><%# Eval("PatronID") %></span></div>
                                                <div class="small text-dark"><%# Eval("BookTitle") %> (<%# Eval("AccessionNumber") %>)</div>
                                                <div class="small text-muted"><%# Eval("LoanType") %> | <%# Eval("PatronRole") %></div>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </div>
                </div>

                <!-- Online Renewals Panel -->
                <div class="card border-0 shadow-sm rounded-4">
                    <div class="card-header bg-white border-0 p-3">
                        <h6 class="fw-bold text-primary mb-0"><i class="fas fa-laptop-house me-2"></i>Pending Online Renewals</h6>
                    </div>
                    <div class="card-body p-0">
                        <asp:UpdatePanel ID="UPPendingRenewals" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <div id="divNoPending" runat="server" class="text-center text-muted py-5" visible="true">
                                    <i class="fas fa-check-circle fa-2x mb-2 opacity-25"></i>
                                    <p>No pending requests</p>
                                </div>
                                <asp:Repeater ID="rptPendingRenewals" runat="server">
                                    <ItemTemplate>
                                        <div class="border-bottom p-3 hover-bg-light" style="cursor:pointer;" onclick="loadRenewal('<%# Eval("user_id") %>', '<%# Eval("accession_number") %>')">
                                            <div class="fw-bold text-dark"><%# Eval("PatronName") %></div>
                                            <div class="small text-muted"><%# Eval("PatronID") %> | <%# Eval("PatronRole") %></div>
                                            <div class="small text-dark mt-1"><i class="fas fa-book me-1"></i><%# Eval("BookTitle") %></div>
                                            <div class="small text-muted">Acc: <%# Eval("AccessionNumber") %></div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        function loadRenewal(patronId, accessionNumber) {
            // Fill patron QR and trigger postback
            var txtPatron = document.getElementById('<%= txtPatronQR.ClientID %>');
            if (txtPatron) {
                txtPatron.value = patronId;
                __doPostBack('<%= txtPatronQR.UniqueID %>', '');
                // After patron loads, fill book barcode after a short delay
                setTimeout(function () {
                    var txtBook = document.getElementById('<%= txtBookBarcode.ClientID %>');
                    if (txtBook) {
                        txtBook.value = accessionNumber;
                        __doPostBack('<%= txtBookBarcode.UniqueID %>', '');
                    }
                }, 500);
            }
        }
    </script>
</asp:Content>