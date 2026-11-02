<%@ Page Title="My Borrowing History" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="History.aspx.cs" Inherits="spmst_lms_development.Users.Patron.History.History" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <link rel="stylesheet" href='<%: ResolveUrl("~/Assets/Themes/history-theme.css") %>' />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        /* ==== Page-specific styles (theme-dependent) ==== */
        .txn-item {
            transition: box-shadow .18s ease, transform .18s ease;
        }
        .txn-item:hover {
            box-shadow: 0 6px 18px rgba(11, 61, 44, 0.08);
            transform: translateY(-1px);
        }
        .txn-item-inner {
            display: flex;
            gap: 1rem;
            align-items: flex-start;
        }
        .txn-cover {
            width: 72px;
            height: 100px;
            object-fit: cover;
            border-radius: 4px;
            flex-shrink: 0;
            background: var(--sp-paper);
            border: 1px solid var(--sp-line);
            box-shadow: 0 1px 2px rgba(0, 0, 0, .06);
        }
        .txn-cover-muted { opacity: 0.82; }

        .txn-meta-label {
            font-size: 0.7rem;
            text-transform: uppercase;
            letter-spacing: .04em;
            color: #6b7280;
            font-weight: 700;
        }
        .txn-meta-value {
            font-size: 0.875rem;
            font-weight: 600;
            color: var(--sp-ink);
            word-break: break-word;
        }
        .txn-title {
            font-family: var(--sp-serif);
            color: var(--sp-green-900);
            font-weight: 700;
            font-size: 1.02rem;
            margin: 0 0 .15rem;
            word-break: break-word;
        }

        .top-stat {
            min-width: 110px;
            padding: .75rem .9rem;
            border-radius: var(--sp-radius);
            color: #fff;
            text-align: center;
        }
        .top-stat .label { font-size: .7rem; text-transform: uppercase; letter-spacing: .05em; opacity: .82; }
        .top-stat .value { font-size: 1.4rem; font-weight: 700; line-height: 1.1; }

        /* Mobile: stack book block and stats more gracefully */
        @media (max-width: 575.98px) {
            .txn-item-inner { flex-direction: column; align-items: stretch; }
            .txn-cover { width: 96px; height: 132px; align-self: center; }
            .txn-title { font-size: .98rem; }
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="sp-page">
        <div class="container-fluid py-4" style="max-width: var(--sp-wrap); margin: 0 auto;">

            <!-- ============ HEADER ============ -->
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
                <div>
                    <h1 class="h2 fw-bold mb-1">My Borrowing <span class="sp-text-gold">History</span></h1>
                    <p class="sp-text-muted mb-0">Track your current loans, view due dates, and review past borrowing activity.</p>
                </div>
                <div class="d-flex gap-2">
                    <div class="top-stat" style="background: var(--sp-green-800);">
                        <div class="label">Active</div>
                        <div class="value"><asp:Literal ID="litTopActive" runat="server" Text="0" /></div>
                    </div>
                    <div class="top-stat" style="background:#b91c1c;">
                        <div class="label">Overdue</div>
                        <div class="value"><asp:Literal ID="litTopOverdue" runat="server" Text="0" /></div>
                    </div>
                </div>
            </div>

            <!-- ============ SUMMARY CARDS ============ -->
            <asp:UpdatePanel ID="upSummary" runat="server" UpdateMode="Conditional">
                <ContentTemplate>
                    <div class="row g-3 mb-4">
                        <div class="col-6 col-lg-3">
                            <div class="sp-card p-3 h-100">
                                <div class="txn-meta-label">Active Loans</div>
                                <div class="display-6 fw-bold sp-text-strong"><asp:Literal ID="litCardActive" runat="server" Text="0" /></div>
                            </div>
                        </div>
                        <div class="col-6 col-lg-3">
                            <div class="sp-card p-3 h-100" style="border-left: 4px solid #b91c1c;">
                                <div class="txn-meta-label" style="color:#b91c1c;">Overdue</div>
                                <div class="display-6 fw-bold" style="color:#b91c1c;"><asp:Literal ID="litCardOverdue" runat="server" Text="0" /></div>
                            </div>
                        </div>
                        <div class="col-6 col-lg-3">
                            <div class="sp-card p-3 h-100" style="border-left: 4px solid var(--sp-gold);">
                                <div class="txn-meta-label" style="color:#8a6d0f;">Outstanding Fines</div>
                                <div class="display-6 fw-bold" style="color:#8a6d0f;">₱<asp:Literal ID="litCardFines" runat="server" Text="0.00" /></div>
                            </div>
                        </div>
                        <div class="col-6 col-lg-3">
                            <div class="sp-card p-3 h-100">
                                <div class="txn-meta-label">Returned</div>
                                <div class="display-6 fw-bold sp-text-strong"><asp:Literal ID="litCardReturned" runat="server" Text="0" /></div>
                            </div>
                        </div>
                    </div>
                </ContentTemplate>
            </asp:UpdatePanel>

            <div class="row g-4">
                <!-- ============ MAIN COLUMN ============ -->
                <div class="col-lg-8">

                    <ul class="nav nav-tabs mb-3" id="txnTabs" role="tablist">
                        <li class="nav-item" role="presentation">
                            <button class="nav-link active" id="tabActiveBtn" data-bs-toggle="tab" data-bs-target="#paneActive" type="button" role="tab">
                                <i class="fas fa-book-open me-1"></i> Active
                                <span class="badge rounded-pill" style="background: var(--sp-green-700); color:#fff;">
                                    <asp:Literal ID="litActiveTabCount" runat="server" Text="0" />
                                </span>
                            </button>
                        </li>
                        <li class="nav-item" role="presentation">
                            <button class="nav-link" id="tabHistoryBtn" data-bs-toggle="tab" data-bs-target="#paneHistory" type="button" role="tab">
                                <i class="fas fa-history me-1"></i> History
                                <span class="badge rounded-pill" style="background: var(--sp-gold); color: var(--sp-green-900);">
                                    <asp:Literal ID="litInactiveTabCount" runat="server" Text="0" />
                                </span>
                            </button>
                        </li>
                    </ul>

                    <div class="tab-content">

                        <!-- ============ ACTIVE PANE ============ -->
                        <div class="tab-pane fade show active" id="paneActive" role="tabpanel">
                            <asp:UpdatePanel ID="upActive" runat="server" UpdateMode="Conditional">
                                <ContentTemplate>
                                    <%-- hidden helpers used to submit renewal asynchronously --%>
                                    <asp:HiddenField ID="hfRenewTxnId" runat="server" />
                                    <asp:Button ID="btnSubmitRenewal" runat="server" Text="submit" style="display:none;" OnClick="btnSubmitRenewal_Click" />

                                    <asp:Repeater ID="rptActive" runat="server">
                                        <ItemTemplate>
                                            <div class="sp-card p-3 mb-3 txn-item">
                                                <div class="txn-item-inner">

                                                    <img class="txn-cover"
                                                         src='<%# Eval("CoverUrl") %>'
                                                         alt="Book cover"
                                                         loading="lazy"
                                                         onerror='this.onerror=null; this.src="<%# DefaultCoverUrl %>";' />

                                                    <div class="flex-grow-1" style="min-width: 0;">
                                                        <div class="d-flex justify-content-between align-items-start gap-2 flex-wrap">
                                                            <div style="min-width: 0;">
                                                                <h5 class="txn-title"><%#: Eval("title") %></h5>
                                                                <div class="small sp-text-muted">
                                                                    <%#: FormatText(Eval("author"), "Unknown Author") %> &middot; <%#: FormatText(Eval("item_type"), "—") %>
                                                                </div>
                                                            </div>
                                                            <span class='sp-badge <%# Eval("StatusCssClass") %>'><%#: Eval("StatusDisplay") %></span>
                                                        </div>

                                                        <div class="row row-cols-2 row-cols-md-4 g-2 mt-2">
                                                            <div class="col">
                                                                <div class="txn-meta-label">Accession</div>
                                                                <div class="txn-meta-value"><%#: Eval("accession_number") %></div>
                                                            </div>
                                                            <div class="col">
                                                                <div class="txn-meta-label">Txn</div>
                                                                <div class="txn-meta-value">#<%# Eval("transaction_id") %></div>
                                                            </div>
                                                            <div class="col">
                                                                <div class="txn-meta-label">Borrowed</div>
                                                                <div class="txn-meta-value"><%#: Eval("BorrowDateText") %></div>
                                                            </div>
                                                            <div class="col">
                                                                <div class="txn-meta-label">Due</div>
                                                                <div class="txn-meta-value <%# (int)Eval("IsOverdueFlag") == 1 ? "sp-text-danger" : "" %>"><%#: Eval("DueDateText") %></div>
                                                            </div>
                                                        </div>

                                                        <div class="mt-2 small <%# (int)Eval("IsOverdueFlag") == 1 ? "sp-text-danger fw-bold" : "sp-text-muted" %>">
                                                            <%#: Eval("DueDateSubtext") %>
                                                        </div>

                                                        <div class="d-flex justify-content-end gap-2 mt-3">
                                                            <button type="button"
                                                                    class="sp-btn sp-btn-outline sp-btn-sm js-renew-btn"
                                                                    style='<%# (int)Eval("CanRenew") == 1 ? "" : "display:none;" %>'
                                                                    data-txn-id='<%# Eval("transaction_id") %>'
                                                                    data-title='<%# HttpUtility.HtmlAttributeEncode(FormatText(Eval("title"), "Untitled")) %>'>
                                                                <i class="fas fa-sync-alt"></i> Request Renewal
                                                            </button>

                                                            <button type="button"
                                                                    class="sp-btn sp-btn-sm js-view-btn"
                                                                    style="background: var(--sp-paper); color: var(--sp-ink); border-color: var(--sp-line);"
                                                                    data-title='<%# HttpUtility.HtmlAttributeEncode(FormatText(Eval("title"), "Untitled")) %>'
                                                                    data-author='<%# HttpUtility.HtmlAttributeEncode(FormatText(Eval("author"), "Unknown Author")) %>'
                                                                    data-acc='<%# HttpUtility.HtmlAttributeEncode(Convert.ToString(Eval("accession_number"))) %>'
                                                                    data-type='<%# HttpUtility.HtmlAttributeEncode(FormatText(Eval("item_type"), "—")) %>'
                                                                    data-borrow='<%# HttpUtility.HtmlAttributeEncode(Convert.ToString(Eval("BorrowDateText"))) %>'
                                                                    data-due='<%# HttpUtility.HtmlAttributeEncode(Convert.ToString(Eval("DueDateText"))) %>'
                                                                    data-status='<%# HttpUtility.HtmlAttributeEncode(Convert.ToString(Eval("StatusDisplay"))) %>'>
                                                                <i class="fas fa-eye"></i> Details
                                                            </button>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </ItemTemplate>
                                        <FooterTemplate>
                                            <asp:Panel runat="server" Visible='<%# rptActive.Items.Count == 0 %>' CssClass="sp-card sp-alert-empty">
                                                <i class="fas fa-book-open d-block"></i>
                                                <div>You currently have no active transactions.</div>
                                            </asp:Panel>
                                        </FooterTemplate>
                                    </asp:Repeater>
                                </ContentTemplate>
                            </asp:UpdatePanel>
                        </div>

                        <!-- ============ HISTORY / INACTIVE PANE ============ -->
                        <div class="tab-pane fade" id="paneHistory" role="tabpanel">
                            <asp:UpdatePanel ID="upInactive" runat="server" UpdateMode="Conditional">
                                <ContentTemplate>
                                    <asp:Repeater ID="rptInactive" runat="server">
                                        <ItemTemplate>
                                            <div class="sp-card p-3 mb-3 txn-item" style="background:#fcfcfc;">
                                                <div class="txn-item-inner">
                                                    <img class="txn-cover txn-cover-muted"
                                                         src='<%# Eval("CoverUrl") %>'
                                                         alt="Book cover"
                                                         loading="lazy"
                                                         onerror='this.onerror=null; this.src="<%# DefaultCoverUrl %>";' />

                                                    <div class="flex-grow-1" style="min-width: 0;">
                                                        <div class="d-flex justify-content-between align-items-start gap-2 flex-wrap">
                                                            <div style="min-width: 0;">
                                                                <h5 class="txn-title" style="color: var(--sp-ink);"><%#: Eval("title") %></h5>
                                                                <div class="small sp-text-muted">
                                                                    <%#: FormatText(Eval("author"), "Unknown Author") %> &middot; <%#: FormatText(Eval("item_type"), "—") %>
                                                                </div>
                                                            </div>
                                                            <span class='sp-badge <%# Eval("StatusCssClass") %>'><%#: Eval("StatusDisplay") %></span>
                                                        </div>

                                                        <div class="row row-cols-2 row-cols-md-4 g-2 mt-2">
                                                            <div class="col">
                                                                <div class="txn-meta-label">Accession</div>
                                                                <div class="txn-meta-value"><%#: Eval("accession_number") %></div>
                                                            </div>
                                                            <div class="col">
                                                                <div class="txn-meta-label">Borrowed</div>
                                                                <div class="txn-meta-value"><%#: Eval("BorrowDateText") %></div>
                                                            </div>
                                                            <div class="col">
                                                                <div class="txn-meta-label">Due</div>
                                                                <div class="txn-meta-value"><%#: Eval("DueDateText") %></div>
                                                            </div>
                                                            <div class="col">
                                                                <div class="txn-meta-label">Returned</div>
                                                                <div class="txn-meta-value"><%#: Eval("ReturnDateText") %></div>
                                                            </div>
                                                        </div>

                                                        <div class="mt-2 small <%# (decimal)Eval("Balance") > 0m ? "sp-text-danger fw-bold" : "sp-text-muted" %>">
                                                            <%#: Eval("DueDateSubtext") %>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </ItemTemplate>
                                        <FooterTemplate>
                                            <asp:Panel runat="server" Visible='<%# rptInactive.Items.Count == 0 %>' CssClass="sp-card sp-alert-empty">
                                                <i class="fas fa-history d-block"></i>
                                                <div>No completed transactions found.</div>
                                            </asp:Panel>
                                        </FooterTemplate>
                                    </asp:Repeater>
                                </ContentTemplate>
                            </asp:UpdatePanel>
                        </div>
                    </div>
                </div>

                <!-- ============ SIDEBAR ============ -->
                <div class="col-lg-4">
                    <div class="sp-card p-3 mb-3">
                        <h6 class="mb-2" style="font-family: var(--sp-serif); color: var(--sp-green-900);">
                            <i class="fas fa-info-circle me-2" style="color: var(--sp-gold);"></i> Borrowing Guidelines
                        </h6>
                        <div class="small sp-text-muted mb-2"><strong>Standard loan:</strong> 3 days from checkout.</div>
                        <div class="small sp-text-muted mb-2"><strong>Renewal:</strong> Up to 2 renewals when no holds exist.</div>
                        <div class="small sp-text-muted mb-2"><strong>Due Soon:</strong> Within 1 day before the due date.</div>
                        <div class="small sp-text-muted mb-2"><strong>Overdue:</strong> ₱5.00 per day for loan-out, ₱5.00 per hour for loan-in.</div>
                        <div class="small sp-text-muted mb-0"><strong>Fines:</strong> Settle at the Circulation Desk before further borrowing.</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        // ---------- Renewal & Detail button handlers ----------
        (function () {
            function esc(s) {
                return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
                    return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
                });
            }

            function submitRenewal(txnId) {
                var hf = document.getElementById('<%= hfRenewTxnId.ClientID %>');
                var btn = document.getElementById('<%= btnSubmitRenewal.ClientID %>');
                if (!hf || !btn) return;
                hf.value = txnId;
                btn.click();
            }

            document.addEventListener('click', function (e) {
                var target = e.target;

                // --- Renew button ---
                var renewBtn = target.closest ? target.closest('.js-renew-btn') : null;
                if (renewBtn) {
                    var txnId = renewBtn.getAttribute('data-txn-id');
                    var title = renewBtn.getAttribute('data-title') || 'this item';
                    Swal.fire({
                        title: 'Request Renewal',
                        html: 'Request a renewal for <strong>' + esc(title) + '</strong>?',
                        icon: 'question',
                        showCancelButton: true,
                        confirmButtonColor: '#14532d',
                        cancelButtonColor: '#6c757d',
                        confirmButtonText: 'Submit Request',
                        cancelButtonText: 'Cancel'
                    }).then(function (result) {
                        if (result.isConfirmed) submitRenewal(txnId);
                    });
                    return;
                }

                // --- Details button ---
                var viewBtn = target.closest ? target.closest('.js-view-btn') : null;
                if (viewBtn) {
                    var html = ''
                        + '<div style="text-align:left">'
                        + '<p style="margin:0 0 .5rem"><strong>Author:</strong> ' + esc(viewBtn.getAttribute('data-author')) + '</p>'
                        + '<p style="margin:0 0 .5rem"><strong>Accession:</strong> ' + esc(viewBtn.getAttribute('data-acc')) + '</p>'
                        + '<p style="margin:0 0 .5rem"><strong>Type:</strong> ' + esc(viewBtn.getAttribute('data-type')) + '</p>'
                        + '<hr/>'
                        + '<p style="margin:0 0 .5rem"><strong>Borrowed:</strong> ' + esc(viewBtn.getAttribute('data-borrow')) + '</p>'
                        + '<p style="margin:0 0 .5rem"><strong>Due:</strong> ' + esc(viewBtn.getAttribute('data-due')) + '</p>'
                        + '<p style="margin:0"><strong>Status:</strong> ' + esc(viewBtn.getAttribute('data-status')) + '</p>'
                        + '</div>';
                    Swal.fire({
                        title: viewBtn.getAttribute('data-title') || 'Book Details',
                        html: html,
                        icon: 'info',
                        confirmButtonColor: '#14532d',
                        confirmButtonText: 'Close'
                    });
                }
            });
        })();

        // Used by code-behind ShowAlert
        function showSweetAlert(title, message, icon) {
            if (typeof Swal === 'undefined') { alert(title + ': ' + message); return; }
            Swal.fire({ title: title, text: message, icon: icon, confirmButtonColor: '#14532d' });
        }
    </script>
</asp:Content>