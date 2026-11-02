<%@ Page Title="Library Catalog" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="BrowseCatalog.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Catalog.BrowseCatalog" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <link href="<%= ResolveUrl("~/Assets/Themes/browse-catalog-theme.css") %>" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="catalog-page">

        <!-- Header -->
        <header class="catalog-header">
            <div>
                <h1 class="catalog-title">What's your next <span class="accent">adventure?</span></h1>
                <p class="catalog-greeting">
                    Welcome back, <asp:Literal ID="litPatronName" runat="server" Text="Patron" />.
                </p>
            </div>
            <div class="catalog-date">
                <p class="date-label">SPAMAST Library</p>
                <p class="date-value"><%= DateTime.Now.ToString("dddd, MMM dd") %></p>
            </div>
        </header>

        <asp:UpdatePanel ID="upSearch" runat="server" UpdateMode="Conditional">
            <ContentTemplate>

                <!-- Search + category filters -->
                <div class="catalog-toolbar">
                    <div class="search-wrap">
                        <i class="fas fa-search"></i>
                        <asp:TextBox ID="txtSearch" runat="server" CssClass="search-input"
                            placeholder="Search by title, author, or ISBN..."
                            AutoPostBack="true"
                            OnTextChanged="txtSearch_TextChanged"
                            onkeyup="debounceSearch(this);" />
                    </div>

                    <div class="category-pills">
                        <asp:LinkButton ID="lnkAll" runat="server" OnClick="Category_Click" CommandArgument=""
                            CssClass="category-pill active">
                            <i class="fas fa-book-open"></i> All Categories
                        </asp:LinkButton>
                        <asp:Repeater ID="rptSections" runat="server">
                            <ItemTemplate>
                                <asp:LinkButton ID="lnkSection" runat="server" OnClick="Category_Click"
                                    CommandArgument='<%# Eval("section_name") %>'
                                    CssClass="category-pill inactive">
                                    <i class="fas fa-tag"></i> <%# Eval("section_name") %>
                                </asp:LinkButton>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </div>

                <!-- Responsive books grid -->
                <div class="books-grid">
                    <asp:Repeater ID="rptBooks" runat="server" OnItemDataBound="rptBooks_ItemDataBound">
                        <ItemTemplate>
                            <article class="book-card">

                                <!-- Cover -->
                                <div class="book-cover-container">
                                    <asp:Image ID="imgCover" runat="server"
                                        AlternateText='<%# Eval("title") %>' />
                                </div>

                                <!-- Info -->
                                <div class="book-info">
                                    <span class='status-badge <%# Eval("display_status").ToString() == "Available" ? "status-available" : "status-unavailable" %>'>
                                        <span class="dot"></span>
                                        <%# Eval("display_status").ToString().ToUpper() %>
                                    </span>

                                    <span class="book-section" title='<%# Eval("section") %>'>
                                        <%# Eval("section") %>
                                    </span>

                                    <h3 class="book-title"><%# Eval("title") %></h3>
                                    <p class="book-author">by <%# Eval("author") %></p>

                                    <div class="book-stats">
                                        <div class="book-stat">
                                            <span class="label">Total</span>
                                            <span class="value"><%# Eval("total_copies") %></span>
                                        </div>
                                        <div class="book-stat">
                                            <span class="label">Available</span>
                                            <span class="value available"><%# Eval("available_copies") %></span>
                                        </div>
                                    </div>

                                    <div class="book-actions">
                                        <asp:LinkButton ID="btnReserve" runat="server"
                                            OnClientClick='<%# "return openReserveModal(" + Eval("resource_id") + ");" %>'
                                            Enabled='<%# Eval("display_status").ToString() == "Available" %>'
                                            CssClass='<%# Eval("display_status").ToString() == "Available" ? "book-btn book-btn-primary" : "book-btn book-btn-disabled" %>'
                                            ToolTip="Reserve this book">
                                            <i class="fas fa-bookmark"></i> Reserve
                                        </asp:LinkButton>

                                        <asp:LinkButton ID="btnViewDetails" runat="server"
                                            OnClientClick='<%# "return openDetailsModal(" + Eval("resource_id") + ");" %>'
                                            CssClass="book-btn book-btn-outline"
                                            ToolTip="View details">
                                            <i class="fas fa-eye"></i>
                                        </asp:LinkButton>
                                    </div>
                                </div>
                            </article>
                        </ItemTemplate>
                    </asp:Repeater>
                </div>

                <!-- No results -->
                <asp:Panel ID="pnlNoResults" runat="server" Visible="false" CssClass="no-results">
                    <i class="fas fa-book-open"></i>
                    <p>No books found matching your criteria.</p>
                </asp:Panel>

            </ContentTemplate>
        </asp:UpdatePanel>
    </div>

    <!-- Universal modal -->
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

       function isFullHeight() {
           const iframe = document.getElementById('modalIframe');
           return !!(iframe && iframe.classList.contains('full-height'));
       }

       function resizeModalIframe() {
           const iframe = document.getElementById('modalIframe');
           if (!iframe || !iframe.getAttribute('src')) return;

           // Full-height pages: CSS owns the height, don't measure/shrink.
           if (isFullHeight()) return;

           // Content-sized pages (Reserved_Book.aspx, etc.)
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

       // Called by full-height child pages (e.g. View_BookDetails.aspx) from within the iframe.
       function setModalFullHeight() {
           const iframe = document.getElementById('modalIframe');
           if (!iframe) return;
           iframe.classList.add('full-height');
           iframe.style.removeProperty('height');   // let the CSS class win
       }
       window.setModalFullHeight = setModalFullHeight;

       function clearModalFullHeight() {
           const iframe = document.getElementById('modalIframe');
           if (!iframe) return;
           iframe.classList.remove('full-height');
       }

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
               clearModalFullHeight();               // reset sizing mode for the new page
               iframe.style.height = '0px';
               iframe.onload = function () {
                   // Retry a few times to beat asset load / layout jitter
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
           if (currentModal) currentModal.hide();

           const iframe = document.getElementById('modalIframe');
           if (iframe) {
               iframe.onload = null;
               iframe.src = '';
               iframe.style.height = '0px';
               clearModalFullHeight();
           }
       }
       window.closeUniversalModal = closeUniversalModal;

       // ============================================
       // 3. WINDOW RESIZE HANDLING
       // ============================================
       window.addEventListener('resize', function () {
           const iframe = document.getElementById('modalIframe');
           if (!iframe || !iframe.getAttribute('src')) return;

           // Full-height pages track the viewport via CSS (calc(90dvh - 2px))
           if (isFullHeight()) return;

           resizeModalIframe();
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