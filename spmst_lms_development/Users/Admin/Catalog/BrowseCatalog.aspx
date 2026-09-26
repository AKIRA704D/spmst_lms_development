<%@ Page Title="Library Catalog" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="BrowseCatalog.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Catalog.BrowseCatalog" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        /* ============================================
           1. GLOBAL & UTILITY
           ============================================ */
        .card-shadow {
            box-shadow: 0 20px 40px -15px rgba(0, 0, 0, 0.08);
        }
        .category-pill {
            cursor: pointer;
            transition: all 0.2s;
            border: none;
        }
        .category-pill.active {
            background-color: #0d6efd;
            color: white;
        }
        .category-pill.inactive {
            background-color: #e9ecef;
            color: #6c757d;
        }
        .category-pill.inactive:hover {
            background-color: #dee2e6;
        }
        .btn-reserve {
            background: linear-gradient(135deg, #0d6efd, #0b5ed7);
            transition: all 0.3s ease;
        }
        .btn-reserve:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3);
        }
        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.25rem;
            padding: 0.25rem 0.75rem;
            border-radius: 2rem;
            font-size: 0.7rem;
            font-weight: 600;
        }
        .status-available {
            background-color: #d1fae5;
            color: #059669;
        }
        .status-unavailable {
            background-color: #fef3c7;
            color: #b45309;
        }
        .copy-stats {
            background-color: #f8f9fa;
            border-radius: 0.75rem;
            padding: 0.5rem;
        }

        /* ============================================
           2. UNIVERSAL MODAL & IFRAME
           ============================================ */
        #universalModal .modal-content {
            border-radius: 1rem;
            overflow: hidden;
            max-height: 90vh;
        }

        /* modal-body does NOT scroll — the iframe handles it */
        #universalModal .modal-body {
            padding: 0;
            overflow: hidden;
        }

        .modal-iframe {
            width: 100%;
            height: 0; /* JS sets it dynamically */
            border: none;
            display: block;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container py-4">
        <!-- Header -->
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
            <div>
                <h1 class="display-5 fw-bold">What's your next <span class="text-primary">adventure?</span></h1>
                <p class="text-muted">Welcome back, <asp:Literal ID="litPatronName" runat="server" Text="Patron" />.</p>
            </div>
            <div class="bg-white p-3 rounded-3 shadow-sm border text-md-end">
                <p class="small text-muted mb-0">SPAMAST Library</p>
                <p class="fw-bold mb-0"><%= DateTime.Now.ToString("dddd, MMM dd") %></p>
            </div>
        </div>

        <asp:UpdatePanel ID="upSearch" runat="server" UpdateMode="Conditional">
            <ContentTemplate>
                <!-- Search Bar -->
                <div class="card p-4 shadow-sm border-0 rounded-4 mb-4">
                    <div class="input-group">
                        <span class="input-group-text bg-white border-end-0"><i class="fas fa-search text-muted"></i></span>
                        <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control form-control-lg border-start-0"
                            placeholder="Search by title, author, or ISBN..." AutoPostBack="true"
                            OnTextChanged="txtSearch_TextChanged" onkeyup="debounceSearch(this);" />
                    </div>
                    <!-- Category Pills -->
                    <div class="d-flex flex-wrap gap-2 mt-4">
                        <asp:LinkButton ID="lnkAll" runat="server" OnClick="Category_Click" CommandArgument=""
                            CssClass="btn category-pill active">
                            <i class="fas fa-book-open me-1"></i> All Categories
                        </asp:LinkButton>
                        <asp:Repeater ID="rptSections" runat="server">
                            <ItemTemplate>
                                <asp:LinkButton ID="lnkSection" runat="server" OnClick="Category_Click"
                                    CommandArgument='<%# Eval("section_name") %>'
                                    CssClass="btn category-pill inactive">
                                    <i class="fas fa-tag me-1"></i> <%# Eval("section_name") %>
                                </asp:LinkButton>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </div>

                <!-- Books Grid -->
                <div class="row g-4">
                    <asp:Repeater ID="rptBooks" runat="server" OnItemDataBound="rptBooks_ItemDataBound">
                        <ItemTemplate>
                            <div class="col-lg-6">
                                <div class="card h-100 shadow-sm border-0 rounded-4 overflow-hidden">
                                    <div class="row g-0 h-100">
                                        <!-- Cover Column -->
                                        <div class="col-md-4 position-relative">
                                            <asp:Image ID="imgCover" runat="server" CssClass="Img-fluid h-100 w-100 object-fit-cover" style="min-height: 200px;" />
                                            <div class="position-absolute bottom-0 start-0 end-0 p-2 bg-dark bg-opacity-75 text-white small">
                                                <i class="fas fa-book me-1"></i> <%# Eval("section") %>
                                            </div>
                                        </div>
                                        <!-- Details Column -->
                                        <div class="col-md-8">
                                            <div class="card-body h-100 d-flex flex-column">
                                                <div class="mb-2">
                                                    <span class='status-badge <%# Eval("display_status").ToString() == "Available" ? "status-available" : "status-unavailable" %>'>
                                                        <span class="w-2 h-2 rounded-circle bg-current d-inline-block me-1"></span>
                                                        <%# Eval("display_status").ToString().ToUpper() %>
                                                    </span>
                                                </div>
                                                <h5 class="card-title fw-bold"><%# Eval("title") %></h5>
                                                <p class="card-text text-muted small">by <%# Eval("author") %></p>
                                                <div class="row mt-2 g-2">
                                                    <div class="col-6">
                                                        <div class="copy-stats text-center">
                                                            <span class="small text-muted">Total Copies</span>
                                                            <h6 class="mb-0 fw-bold"><%# Eval("total_copies") %></h6>
                                                        </div>
                                                    </div>
                                                    <div class="col-6">
                                                        <div class="copy-stats text-center">
                                                            <span class="small text-muted">Available</span>
                                                            <h6 class="mb-0 fw-bold text-success"><%# Eval("available_copies") %></h6>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="mt-3 d-flex gap-2">
                                                    <asp:LinkButton ID="btnReserve" runat="server"
                                                        OnClientClick='<%# "return openReserveModal(" + Eval("resource_id") + ");" %>'
                                                        Enabled='<%# Eval("display_status").ToString() == "Available" %>'
                                                        CssClass='<%# Eval("display_status").ToString() == "Available" ? "btn btn-primary flex-grow-1" : "btn btn-secondary flex-grow-1 disabled" %>'>
                                                        <i class="fas fa-bookmark me-1"></i> Reserve
                                                    </asp:LinkButton>
                                                    <asp:LinkButton ID="btnViewDetails" runat="server"
                                                        OnClientClick='<%# "return openDetailsModal(" + Eval("resource_id") + ");" %>'
                                                        CssClass="btn btn-outline-secondary">
                                                        <i class="fas fa-eye"></i>
                                                    </asp:LinkButton>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>
                </div>

                <!-- No Results -->
                <asp:Panel ID="pnlNoResults" runat="server" Visible="false" CssClass="text-center py-5">
                    <i class="fas fa-book-open fa-3x text-muted mb-3"></i>
                    <p class="text-muted">No books found matching your criteria.</p>
                </asp:Panel>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>

    <!-- Universal modal (same behavior pattern as UserAcc.aspx) -->
    <div class="modal fade" id="universalModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-dialog-centered modal-xl">
            <div class="modal-content">
                <div class="modal-body">
                    <iframe id="modalIframe" class="modal-iframe"></iframe>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        // ============================================
        // 1. SEARCH DEBOUNCING
        // ============================================
        let searchTimer;
        function debounceSearch(input) {
            clearTimeout(searchTimer);
            searchTimer = setTimeout(function () {
                __doPostBack(input.id, '');
            }, 300);
        }

        // ============================================
        // 2. UNIVERSAL MODAL HANDLERS
        // ============================================
        let currentModal = null;

        /*
         * Resize the iframe to the natural content height, capped at 90vh.
         * Short content -> iframe shrinks to content height.
         * Tall content  -> iframe is capped at 90vh and scrolls internally.
         */
        function resizeModalIframe() {
            const iframe = document.getElementById('modalIframe');
            if (!iframe || !iframe.getAttribute('src')) return;

            try {
                const doc = iframe.contentDocument || iframe.contentWindow.document;
                if (!doc || !doc.body) return;

                const natural = Math.max(
                    doc.documentElement.scrollHeight,
                    doc.body.scrollHeight,
                    doc.documentElement.offsetHeight,
                    doc.body.offsetHeight
                );

                const maxH = Math.round(window.innerHeight * 0.9);
                const finalH = Math.min(natural, maxH);

                iframe.style.height = finalH + 'px';
            } catch (e) {
                iframe.style.height = '80vh';
            }
        }

        window.resizeModalIframe = resizeModalIframe;

        function getUniversalModal() {
            if (!currentModal) {
                const modalEl = document.getElementById('universalModal');
                currentModal = new bootstrap.Modal(modalEl);
            }
            return currentModal;
        }

        function openUniversalModal(page, idParam, idValue) {
            const iframe = document.getElementById('modalIframe');

            if (iframe) {
                // Reset previous modal height before loading new content.
                iframe.style.height = '0px';

                // Re-measure after load; repeated timeouts catch late-rendered content.
                iframe.onload = function () {
                    setTimeout(resizeModalIframe, 50);
                    setTimeout(resizeModalIframe, 150);
                    setTimeout(resizeModalIframe, 300);
                };

                iframe.src = `${page}?${idParam}=${idValue}`;
            }

            getUniversalModal().show();
            return false;
        }

        function openReserveModal(bookId) {
            return openUniversalModal('Reserved_Book.aspx', 'BookID', bookId);
        }

        function openDetailsModal(resourceId) {
            return openUniversalModal('View_BookDetails.aspx', 'ResourceID', resourceId);
        }

        function closeUniversalModal() {
            if (currentModal) {
                currentModal.hide();
            }

            const iframe = document.getElementById('modalIframe');
            if (iframe) {
                iframe.onload = null;
                iframe.src = '';
                iframe.style.height = '0px';
            }
        }

        window.closeUniversalModal = closeUniversalModal;

        // ============================================
        // 3. WINDOW RESIZE HANDLING
        // ============================================
        window.addEventListener('resize', function () {
            const iframe = document.getElementById('modalIframe');
            if (iframe && iframe.getAttribute('src')) {
                resizeModalIframe();
            }
        });

        // ============================================
        // 4. UPDATE PANEL POSTBACK FOCUS
        // ============================================
        let prm = Sys.WebForms.PageRequestManager.getInstance();
        prm.add_endRequest(function () {
            let searchBox = document.getElementById('<%= txtSearch.ClientID %>');
            if (searchBox) searchBox.focus();
        });
    </script>
</asp:Content>