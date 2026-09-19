<%@ Page Title="Book Returns" Language="C#" MasterPageFile="~/Users/MasterPage/Admin.Master" AutoEventWireup="true" CodeBehind="Book_Return.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Transactions.Book_Return" %>

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
            background: rgba(5, 150, 105, 0.6);
            box-shadow: 0 0 10px 2px rgba(5, 150, 105, 0.8);
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
            border: 2px solid #10b981 !important;
        }

        /* ============================================
           2. CUSTOM TABS (nav-pills)
           ============================================ */
        .nav-pills .nav-link.active {
            background-color: #10b981 !important;
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
        .btn-success {
            background-color: #10b981 !important;
            border: none;
        }
    </style>

    <script type="text/javascript">
        // Scanner logic (same as Book_Borrow, but target is book barcode only)
        let html5QrScanner = null;
        let isCameraActive = false;
        const scanSound = new Audio('https://Assets.mixkit.co/active_storage/sfx/766/766-preview.mp3');

        async function startScanner() {
            scanSound.play().then(() => {
                scanSound.pause();
                scanSound.currentTime = 0;
            }).catch(e => console.log("Audio prep failed", e));

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
                document.getElementById('reader').style.border = "4px solid #10b981";
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
                html5QrScanner.stop().catch(e => console.warn("Stop error", e));
                isCameraActive = false;
            }

            let cleanedText = decodedText.trim().replace(/[\n\r\t]/g, '');
            const txtBook = document.getElementById('<%= txtBookReturnQR.ClientID %>');
            if (txtBook) {
                txtBook.value = cleanedText;
                txtBook.dispatchEvent(new Event('change', { bubbles: true }));
                setTimeout(() => {
                    __doPostBack('<%= txtBookReturnQR.UniqueID %>', '');
                }, 50);
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

        // Re-enable complete button after partial postback
        function enableCompleteButton() {
            var btn = document.getElementById('<%= btnCompleteReturn.ClientID %>');
            if (btn) { btn.disabled = false; btn.style.opacity = '1'; btn.style.pointerEvents = 'auto'; }
        }
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            enableCompleteButton();
        });
    </script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid py-4">
        <div class="mb-4">
            <h2 class="fw-bold">Good Day, Librarian! 👋</h2>
            <p class="text-muted">Process book returns and manage condition reports.</p>
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
                                <asp:HyperLink ID="lnkReturn" runat="server" NavigateUrl="Book_Return.aspx" CssClass="nav-link active fw-semibold">
                                    <i class="fas fa-undo-alt me-1"></i> Returning
                                </asp:HyperLink>
                            </li>
                            <li class="nav-item">
                                <asp:HyperLink ID="lnkRenew" runat="server" NavigateUrl="Book_Renew.aspx" CssClass="nav-link text-secondary fw-semibold">
                                    <i class="fas fa-sync-alt me-1"></i> Renew
                                </asp:HyperLink>
                            </li>
                        </ul>
                    </div>

                    <div class="card-body p-4">
                        <asp:UpdatePanel ID="UPReturn" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <!-- Scanner UI -->
                                <div id="scanner-area" class="mb-4 d-none">
                                    <div style="position: relative;">
                                        <div id="reader"></div>
                                        <div class="scanner-overlay"><div class="scanner-line"></div></div>
                                    </div>
                                    <button type="button" onclick="stopScanner()" class="btn btn-danger w-100 mt-2">Close Camera</button>
                                </div>

                                <!-- Book Barcode Input -->
                                <div class="mb-4">
                                    <label class="form-label text-uppercase fw-bold small text-muted">Scan Book Barcode</label>
                                    <div class="input-group input-group-lg border rounded-3 overflow-hidden">
                                        <span class="input-group-text bg-white border-0"><i class="fas fa-barcode"></i></span>
                                        <asp:TextBox ID="txtBookReturnQR" runat="server" CssClass="form-control border-0 bg-white"
                                            placeholder="Scan Barcode" OnTextChanged="txtBookReturnQR_TextChanged" AutoPostBack="true" />
                                        <button class="btn btn-white border-0" type="button" onclick="startScanner()">
                                            <i class="fas fa-camera text-primary"></i>
                                        </button>
                                    </div>
                                </div>

                                <!-- Return Info Panel (shown after valid book scan) -->
                                <asp:Panel ID="pnlReturnInfo" runat="server" Visible="false" CssClass="card border-0 bg-light p-3 rounded-4 mb-3">
                                    <div class="row g-3">
                                        <div class="col-md-6 border-end">
                                            <h6 class="fw-bold mb-1"><asp:Literal ID="litBookTitle" runat="server" /></h6>
                                            <p class="small text-muted mb-0">Author: <asp:Literal ID="litAuthor" runat="server" /></p>
                                            <p class="small text-muted mb-3">Acc no. <asp:Literal ID="litAccNo" runat="server" /></p>
                                        </div>
                                        <div class="col-md-6">
                                            <p class="small text-muted mb-1">Borrowed By: <span class="fw-bold text-dark"><asp:Literal ID="litPatronName" runat="server" /></span></p>
                                            <p class="small text-muted mb-3">Department: <asp:Literal ID="litPatronDept" runat="server" /></p>
                                            <div class="mb-2">
                                                <label class="small fw-semibold">Condition:</label>
                                                <asp:DropDownList ID="ddlCondition" runat="server" CssClass="form-select form-select-sm mt-1">
                                                    <asp:ListItem Text="Good" Value="Good" />
                                                    <asp:ListItem Text="Damage" Value="Damage" />
                                                    <asp:ListItem Text="Lost" Value="Lost" />
                                                </asp:DropDownList>
                                            </div>
                                            <div class="mb-3">
                                                <label class="small fw-semibold">Notes:</label>
                                                <asp:TextBox ID="txtReturnNote" runat="server" TextMode="MultiLine" Rows="2" CssClass="form-control form-control-sm mt-1" placeholder="Optional remarks..." />
                                            </div>
                                        </div>
                                    </div>
                                    <asp:Button ID="btnCompleteReturn" runat="server" Text="Complete Return" CssClass="btn btn-success w-100 py-2 fw-bold shadow-sm mt-2" OnClick="btnCompleteReturn_Click" />
                                </asp:Panel>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </div>
                </div>
            </div>

            <!-- Live Feed Column -->
            <div class="col-lg-5">
                <div class="card border-0 shadow-sm rounded-4 h-100">
                    <div class="card-header bg-white border-0 p-3 d-flex align-items-center gap-2">
                        <div class="p-1 bg-success rounded-circle"></div>
                        <span class="fw-bold">Live Feed</span>
                    </div>
                    <div class="card-body border-top">
                        <asp:UpdatePanel ID="UPLiveFeed" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <div id="divAwaiting" runat="server" class="text-center text-muted py-5" visible="true">
                                    <i class="fas fa-stream mb-2 fs-3 opacity-25"></i>
                                    <p>Awaiting returns...</p>
                                </div>
                                <asp:Repeater ID="rptFeed" runat="server">
                                    <ItemTemplate>
                                        <div class="d-flex gap-3 mb-3 border-bottom pb-2">
                                            <div class="text-success mt-1"><i class="fas fa-check-circle"></i></div>
                                            <div style="flex:1;">
                                                <div class="fw-bold text-dark"><%# Eval("PatronName") %> - <span class="fw-normal text-muted"><%# Eval("PatronID") %></span></div>
                                                <div class="small text-dark"><%# Eval("BookTitle") %> (<%# Eval("AccessionNumber") %>)</div>
                                                <div class="small text-muted">Returned - <%# Eval("Condition") %></div>
                                            </div>
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
</asp:Content>