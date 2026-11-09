<%@ Page Title="Book Circulation" Language="C#" MasterPageFile="~/Users/MasterPage/Admin.Master" AutoEventWireup="true" CodeBehind="Book_Borrow.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Transactions.Book_Borrow" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="https://unpkg.com/html5-qrcode"></script>
    <link href="<%= ResolveUrl("~/Assets/Themes/spamast-theme.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Assets/Themes/book_borrow-theme.css") %>" rel="stylesheet" />

    <script>
        let html5QrScanner = null;
        let isCameraActive = false;
        const scanSound = new Audio('https://Assets.mixkit.co/active_storage/sfx/766/766-preview.mp3');

        async function startScanner(target) {
            scanSound.play().then(() => {
                scanSound.pause();
                scanSound.currentTime = 0;
            }).catch(e => console.log("Audio prep failed", e));

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

            const config = {
                fps: 15,
                qrbox: { width: 250, height: 250 },
                aspectRatio: 1.0
            };

            try {
                await html5QrScanner.start(
                    { facingMode: "environment" },
                    config,
                    onScanSuccess
                );
                isCameraActive = true;
                document.getElementById('reader').style.border = "4px solid #14532d";
            } catch (err) {
                console.error("Camera access error:", err);
                alert("Camera access blocked or failed. Please check your browser permissions.");
                scannerArea.classList.add('d-none');
            }
        }

        function onScanSuccess(decodedText) {
            scanSound.play();
            document.getElementById('scanner-area').classList.add('d-none');

            if (html5QrScanner && isCameraActive) {
                html5QrScanner.stop().then(() => {
                    isCameraActive = false;
                    processScan(decodedText);
                }).catch((err) => {
                    console.warn("Camera stop error:", err);
                    isCameraActive = false;
                    processScan(decodedText);
                });
            } else {
                processScan(decodedText);
            }
        }

        function processScan(decodedText) {
            if (window.activeScannerTarget === 'patron') {
                const txtPatron = document.getElementById('<%= txtPatronQR.ClientID %>');
                txtPatron.value = decodedText;
                txtPatron.dispatchEvent(new Event('change', { bubbles: true }));

                setTimeout(() => {
                    __doPostBack('<%= txtPatronQR.UniqueID %>', '');
                }, 50);
            } else {
                const txtBook = document.getElementById('<%= txtBookBarcode.ClientID %>');
                txtBook.value = decodedText;
                txtBook.dispatchEvent(new Event('change', { bubbles: true }));

                setTimeout(() => {
                    __doPostBack('<%= txtBookBarcode.UniqueID %>', '');
                }, 50);
            }
        }

        function stopScanner() {
            document.getElementById('scanner-area').classList.add('d-none');

            if (html5QrScanner && isCameraActive) {
                html5QrScanner.stop().then(() => {
                    isCameraActive = false;
                }).catch((err) => {
                    isCameraActive = false;
                });
            }
        }
    </script>

    <script type="text/javascript">
        function enableCompleteButton() {
            var btn = document.getElementById('<%= btnComplete.ClientID %>');
            if (btn) {
                btn.disabled = false;
                btn.style.opacity = '1';
                btn.style.pointerEvents = 'auto';
            }
        }

        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            enableCompleteButton();
        });
    </script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <%-- Default cover URL is written by code-behind on Page_Load. --%>
    <asp:HiddenField ID="hfDefaultCover" runat="server" />

    <%-- Pick up the hidden value early so onerror has a valid fallback. --%>
    <script type="text/javascript">
        var spDefaultCover = document.getElementById('<%= hfDefaultCover.ClientID %>').value;
    </script>

    <div class="container-fluid py-4 book-borrow-page">
        <div class="page-header d-flex align-items-center gap-3 mb-4">
            <div class="sp-logo-container" aria-label="SPAMAST Library Logo">
                <div class="sp-logo"></div>
            </div>
            <div class="min-w-0">
                <h2 class="fw-bold mb-1">Good Day, Librarian! 👋</h2>
                <p class="text-muted mb-0">What would you like to help a patron with today?</p>
            </div>
        </div>

        <div class="row g-4">
            <div class="col-lg-7">
                <div class="card border-0 shadow-sm rounded-4 overflow-hidden">
                    <div class="card-header bg-white border-0 p-3">
                        <ul class="nav nav-pills bg-light rounded-3 p-1">
                            <li class="nav-item">
                                <asp:HyperLink ID="lnkBorrow" runat="server" NavigateUrl="Book_Borrow.aspx" CssClass="nav-link active fw-semibold">
                                    <i class="fas fa-book-open me-1"></i> Borrow
                                </asp:HyperLink>
                            </li>
                            <li class="nav-item">
                                <asp:HyperLink ID="lnkReturn" runat="server" NavigateUrl="Book_Return.aspx" CssClass="nav-link text-secondary fw-semibold">
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
                        <asp:UpdatePanel ID="UPCirculation" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <div id="scanner-area" class="mb-4 d-none">
                                    <div style="position: relative;">
                                        <div id="reader"></div>
                                        <div class="scanner-overlay">
                                            <div class="scanner-line"></div>
                                        </div>
                                    </div>
                                    <button type="button" onclick="stopScanner()" class="btn btn-danger w-100 mt-2">Close Camera</button>
                                </div>

                                <!-- Step 1: Patron -->
                                <div class="mb-4">
                                    <label class="form-label text-uppercase fw-bold small text-muted">Step 1: Identify Patron</label>
                                    <div class="input-group input-group-lg border rounded-3 overflow-hidden">
                                        <span class="input-group-text bg-white border-0"><i class="fas fa-id-card"></i></span>
                                        <asp:TextBox ID="txtPatronQR" runat="server" CssClass="form-control border-0 bg-white"
                                            placeholder="Scan QR" OnTextChanged="txtPatronQR_TextChanged" AutoPostBack="true"></asp:TextBox>
                                        <button class="btn btn-white border-0" type="button" onclick="startScanner('patron')">
                                            <i class="fas fa-camera text-primary"></i>
                                        </button>
                                    </div>
                                </div>

                                <!-- Patron Info Panel -->
                                <asp:Panel ID="pnlPatronInfo" runat="server" Visible="false" CssClass="bg-light-blue p-3 rounded-3 mb-4 d-flex align-items-center gap-3">
                                    <div class="avatar-circle small bg-primary text-white"><asp:Literal ID="litInitial" runat="server" Text="?" /></div>
                                    <div>
                                        <h6 class="mb-0 fw-bold"><asp:Literal ID="litPatronName" runat="server" /></h6>
                                        <small class="text-muted"><asp:Literal ID="litPatronDept" runat="server" /></small>
                                        <div><span class="badge bg-secondary mt-1"><asp:Literal ID="litPatronRole" runat="server" /></span></div>
                                    </div>
                                </asp:Panel>

                                <!-- Step 2: Book / Reservation -->
                                <div id="divBookStep" runat="server" class="mb-4 step-locked">
                                    <label class="form-label text-uppercase fw-bold small text-muted">Step 2: Scan Book / Process Reservation</label>
                                    <div class="input-group input-group-lg border rounded-3 overflow-hidden">
                                        <span class="input-group-text bg-white border-0"><i class="fas fa-book"></i></span>
                                        <asp:TextBox ID="txtBookBarcode" runat="server" CssClass="form-control border-0 bg-white"
                                            placeholder="Scan Barcode" OnTextChanged="txtBookBarcode_TextChanged"
                                            AutoPostBack="true" Enabled="false"></asp:TextBox>
                                        <button id="btnBookCam" runat="server" class="btn btn-white border-0" type="button"
                                            onclick="startScanner('book')" disabled="disabled">
                                            <i class="fas fa-camera text-primary"></i>
                                        </button>
                                    </div>
                                </div>

                                <asp:Panel ID="pnlNoReserved" runat="server" Visible="false" CssClass="alert alert-light border small mb-3">
                                    No existing <strong>Reserved</strong> transactions were found for this patron. Continue by scanning a book accession number.
                                </asp:Panel>

                                <!-- Automatically detected Reserved transactions -->
                                <asp:Panel ID="pnlReservedTransactions" runat="server" Visible="false" CssClass="reserved-section mb-4">
                                    <div class="section-heading">
                                        Existing Reserved Transactions
                                        (<asp:Literal ID="litReservedCount" runat="server" Text="0" />)
                                    </div>
                                    <div class="transaction-grid">
                                        <asp:Repeater ID="rptReservedTransactions" runat="server" OnItemCommand="rptReservedTransactions_ItemCommand">
                                            <ItemTemplate>
                                                <div class="transaction-card reserved-card">
                                                    <img class="txn-cover"
                                                         src='<%# GetCoverUrl(Eval("CoverPath")) %>'
                                                         alt="Book cover"
                                                         onerror="this.onerror=null;this.src=spDefaultCover;" />
                                                    <div class="txn-main">
                                                        <div class="txn-title"><%# DisplayText(Eval("BookTitle")) %></div>
                                                        <div class="txn-author">Author: <%# DisplayText(Eval("Author")) %></div>

                                                        <div class="txn-row">
                                                            <span class="txn-label">Acc no.</span>
                                                            <span><%# Eval("AccessionNumber") %></span>
                                                        </div>
                                                        <div class="txn-row">
                                                            <span class="txn-label">Section</span>
                                                            <span><%# DisplayText(Eval("Section")) %></span>
                                                        </div>
                                                        <div class="txn-row">
                                                            <span class="txn-label">Status</span>
                                                            <span class='badge <%# GetStatusBadgeClass(Eval("Status")) %>'><%# Eval("Status") %></span>
                                                        </div>
                                                        <div class="txn-row">
                                                            <span class="txn-label">Loan Type</span>
                                                            <span><%# Eval("LoanType") %></span>
                                                        </div>
                                                        <div class="txn-row">
                                                            <span class="txn-label">Penalty</span>
                                                            <span><%# GetPenaltyDisplay(Eval("PenaltyType"), Eval("FineAmount")) %></span>
                                                        </div>

                                                        <asp:Button ID="btnSelectReservation" runat="server"
                                                            Text="Process Reservation"
                                                            CommandName="SelectReservation"
                                                            CommandArgument='<%# Eval("TransactionID") %>'
                                                            CssClass="btn sp-btn-primary btn-sm w-100 mt-2"
                                                            CausesValidation="false" />
                                                    </div>
                                                </div>
                                            </ItemTemplate>
                                        </asp:Repeater>
                                    </div>
                                </asp:Panel>

                                <!-- Book Info Panel -->
                                <asp:Panel ID="pnlBookInfo" runat="server" Visible="false" CssClass="card border-0 bg-light p-3 rounded-4 mb-3 book-info-panel">
                                    <h6 class="fw-bold mb-1"><asp:Literal ID="litBookTitle" runat="server" /></h6>
                                    <p class="small text-muted mb-0">Author: <asp:Literal ID="litBookAuthor" runat="server" /></p>
                                    <p class="small text-muted mb-0">Section: <asp:Literal ID="litBookSection" runat="server" /></p>
                                    <p class="small text-muted mb-3">Acc no. <asp:Literal ID="litBookAccNo" runat="server" /></p>
                                    <div class="d-flex align-items-center gap-2 mb-3">
                                        <label class="small text-muted">Type:</label>
                                        <asp:DropDownList ID="ddlLoanType" runat="server" CssClass="form-select form-select-sm w-auto shadow-sm">
                                            <asp:ListItem Text="LOAN-OUT" Value="LOAN-OUT" Selected="True" />
                                            <asp:ListItem Text="LOAN-IN" Value="LOAN-IN" />
                                        </asp:DropDownList>
                                    </div>
                                    <asp:Button ID="btnComplete" runat="server" Text="Complete Transaction" CssClass="btn btn-success w-100 py-2 fw-bold shadow-sm" OnClick="btnComplete_Click" />
                                </asp:Panel>

                                <!-- Active Transaction Summary -->
                                <asp:Panel ID="pnlActiveSummary" runat="server" Visible="false" CssClass="active-section mt-4">
                                    <div class="section-heading">
                                        Active Transactions
                                        (<asp:Literal ID="litActiveCount" runat="server" Text="0" />)
                                    </div>
                                    <div class="transaction-grid">
                                        <asp:Repeater ID="rptActiveTransactions" runat="server">
                                            <ItemTemplate>
                                                <div class="transaction-card">
                                                    <img class="txn-cover"
                                                         src='<%# GetCoverUrl(Eval("CoverPath")) %>'
                                                         alt="Book cover"
                                                         onerror="this.onerror=null;this.src=spDefaultCover;" />
                                                    <div class="txn-main">
                                                        <div class="txn-title"><%# DisplayText(Eval("BookTitle")) %></div>
                                                        <div class="txn-author">Author: <%# DisplayText(Eval("Author")) %></div>

                                                        <div class="txn-row">
                                                            <span class="txn-label">Acc no.</span>
                                                            <span><%# Eval("AccessionNumber") %></span>
                                                        </div>
                                                        <div class="txn-row">
                                                            <span class="txn-label">Section</span>
                                                            <span><%# DisplayText(Eval("Section")) %></span>
                                                        </div>
                                                        <div class="txn-row">
                                                            <span class="txn-label">Status</span>
                                                            <span class='badge <%# GetStatusBadgeClass(Eval("Status")) %>'><%# Eval("Status") %></span>
                                                        </div>
                                                        <div class="txn-row">
                                                            <span class="txn-label">Loan Type</span>
                                                            <span><%# Eval("LoanType") %></span>
                                                        </div>
                                                        <div class="txn-row">
                                                            <span class="txn-label">Penalty</span>
                                                            <span><%# GetPenaltyDisplay(Eval("PenaltyType"), Eval("FineAmount")) %></span>
                                                        </div>
                                                    </div>
                                                </div>
                                            </ItemTemplate>
                                        </asp:Repeater>
                                    </div>
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
                                <div class="text-center text-muted py-5" id="divAwaiting" runat="server">
                                    <i class="fas fa-stream mb-2 fs-3 opacity-25"></i>
                                    <p>Awaiting transactions...</p>
                                </div>
                                <asp:Repeater ID="rptFeed" runat="server">
                                    <ItemTemplate>
                                        <div class="d-flex gap-3 mb-3 border-bottom pb-2">
                                            <div class="text-success mt-1"><i class="fas fa-check-circle"></i></div>
                                            <div style="flex:1;">
                                                <div class="fw-bold text-dark"><%# Eval("PatronName") %> - <span class="fw-normal text-muted"><%# Eval("PatronID") %></span></div>
                                                <div class="small text-dark"><%# Eval("BookTitle") %> (<%# Eval("AccessionNumber") %>)</div>
                                                <div class="small text-muted"><%# Eval("LoanType") %> | <%# Eval("PatronRole") %></div>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                                <div id="div1" runat="server" class="text-center text-muted py-5" visible="true">
                                    <i class="fas fa-stream mb-2 fs-3 opacity-25"></i>
                                    <p>Awaiting transactions...</p>
                                </div>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>