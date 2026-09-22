<%@ Page Title="Account Management" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="userAcc.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Accounts.userAcc" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />

    <style>
        .btn-hidden { display: none; }
        .search-box { width: 260px; }

        .table th, .table td { vertical-align: middle; white-space: nowrap; }
        .table th { background-color: #f8f9fa; font-weight: 600; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.5px; }

        .badge-active { background-color: #d1e7dd; color: #0f5132; }
        .badge-inactive { background-color: #f8d7da; color: #842029; }
        .badge-deactivated { background-color: #e2e3e5; color: #41464b; }

        .action-btn { background: none; border: none; cursor: pointer; font-size: 1.1rem; margin: 0 5px; transition: 0.2s; }
        .action-btn.view:hover { color: #0d6efd; }
        .action-btn.edit:hover { color: #198754; }
        .action-btn.toggle:hover { color: #dc3545; }

        .filter-bar { background: white; border-radius: 0.5rem; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }

        .tab-custom .nav-link { color: #6c757d; font-weight: 500; border-bottom: 2px solid transparent; }
        .tab-custom .nav-link.active { color: #0d6efd; border-bottom-color: #0d6efd; background: transparent; }

        /* ---------- Modal & iframe ---------- */
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
            height: 0;              /* JS sets it */
            border: none;
            display: block;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <asp:UpdatePanel ID="upMain" runat="server" UpdateMode="Conditional">
        <ContentTemplate>
            <asp:Button ID="btnRefreshTable" runat="server" OnClick="btnRefreshTable_Click" CssClass="btn-hidden" />

            <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
                <div>
                    <h1 class="h3 fw-bold mb-1">Account Management</h1>
                    <p class="text-muted small mb-0">Manage library members and their access status.</p>
                </div>
                <div class="d-flex flex-wrap gap-2 filter-bar p-2">
                    <div class="position-relative">
                        <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control form-control-sm ps-3 pe-5 search-box"
                            placeholder="Search by name, ID, or course..." AutoPostBack="true" OnTextChanged="txtSearch_TextChanged" />
                        <i class="fas fa-search position-absolute top-50 end-0 translate-middle-y me-3 text-muted small"></i>
                    </div>
                    <button type="button" class="btn btn-sm btn-outline-secondary" onclick="openModal('filter')">
                        <i class="fas fa-filter me-1"></i> FILTER
                    </button>
                    <asp:LinkButton ID="btnExport" runat="server" CssClass="btn btn-sm btn-outline-secondary">
                        <i class="fas fa-file-export me-1"></i> EXPORT
                    </asp:LinkButton>
                    <button type="button" class="btn btn-sm btn-outline-secondary" onclick="openModal('newPatron')">
                        <i class="fas fa-plus me-1"></i> NEW USER
                    </button>
                </div>
            </div>

            <ul class="nav nav-tabs tab-custom border-0 mb-4 gap-3" id="patronTabs">
                <li class="nav-item">
                    <button id="tabAll" runat="server" type="button" onserverclick="FilterTab_Click" class="nav-link">
                        <i class="fas fa-users me-1"></i> All Patrons
                    </button>
                </li>
                <li class="nav-item">
                    <button id="tabFaculty" runat="server" type="button" onserverclick="FilterTab_Click" class="nav-link">
                        <i class="fas fa-chalkboard-user me-1"></i> Faculty
                    </button>
                </li>
                <li class="nav-item">
                    <button id="tabStudent" runat="server" type="button" onserverclick="FilterTab_Click" class="nav-link">
                        <i class="fas fa-graduation-cap me-1"></i> Student
                    </button>
                </li>
                <li class="nav-item">
                    <button id="tabStaff" runat="server" type="button" onserverclick="FilterTab_Click" class="nav-link">
                        <i class="fas fa-id-card me-1"></i> Staff
                    </button>
                </li>
            </ul>

            <div class="table-responsive">
                <asp:Repeater ID="rptPatrons" runat="server">
                    <HeaderTemplate>
                        <table class="table table-hover table-bordered align-middle bg-white rounded shadow-sm" style="min-width: 800px;">
                            <thead><tr><th>ID Number</th><th>Name</th><th class="text-center">Ext.</th><th class="text-center">Gender</th><th>Institute</th><th class="text-center">Role</th><th class="text-center">Status</th><th class="text-center">Actions</th></tr></thead>
                            <tbody>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td class="font-monospace small"><%# Eval("user_id") %></td>
                            <td class="fw-semibold"><%# Eval("full_name") %></td>
                            <td class="text-center"><%# Eval("ext_name") %></td>
                            <td class="text-center text-capitalize"><%# Eval("gender") %></td>
                            <td><%# Eval("institute") %></td>
                            <td class="text-center text-capitalize"><%# Eval("display_role") %></td>
                            <td class="text-center">
                                <span class='badge rounded-pill px-3 py-2 
                                    <%# Convert.ToInt32(Eval("is_active")) == 1 ? "badge-active" : 
                                       Convert.ToInt32(Eval("is_active")) == 2 ? "badge-deactivated" : "badge-inactive" %>'>
                                    <%# Convert.ToInt32(Eval("is_active")) == 1 ? "ACTIVE" : 
                                        Convert.ToInt32(Eval("is_active")) == 2 ? "DEACTIVATED" : "INACTIVE" %>
                                </span>
                            </td>
                            <td class="text-center">
                                <button type="button" class="action-btn view" onclick='openModal("view", "<%# Eval("user_id") %>", "<%# Eval("display_role") %>")'><i class="fas fa-eye"></i></button>
                                <button type="button" class="action-btn edit" onclick='openModal("edit", "<%# Eval("user_id") %>")'><i class="fas fa-edit"></i></button>
                                <asp:LinkButton runat="server" CommandArgument='<%# Eval("user_id") %>' OnCommand="HandleAccountAction" CssClass="action-btn toggle">
                                    <i class='<%# Convert.ToInt32(Eval("is_active")) == 2 ? "fas fa-user-check" : "fas fa-user-slash" %>'></i>
                                </asp:LinkButton>
                            </td>
                        </tr>
                    </ItemTemplate>
                    <FooterTemplate></tbody></table></FooterTemplate>
                </asp:Repeater>
            </div>

            <asp:Label ID="lblNoData" runat="server" Visible="false" CssClass="text-muted text-center d-block py-5">No patrons found.</asp:Label>
        </ContentTemplate>
        <Triggers>
            <asp:AsyncPostBackTrigger ControlID="txtSearch" EventName="TextChanged" />
            <asp:AsyncPostBackTrigger ControlID="tabAll" EventName="ServerClick" />
            <asp:AsyncPostBackTrigger ControlID="tabFaculty" EventName="ServerClick" />
            <asp:AsyncPostBackTrigger ControlID="tabStudent" EventName="ServerClick" />
            <asp:AsyncPostBackTrigger ControlID="tabStaff" EventName="ServerClick" />
        </Triggers>
    </asp:UpdatePanel>

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

    <script type="text/javascript">
        let currentModal;

        /* =========================================================
           Cap the iframe at 90vh only when content actually exceeds it.
           - Short content  → iframe = content height (no scroll, no sticky needed)
           - Tall content   → iframe = 90vh (internal scroll; sticky header/footer work)
           ========================================================= */
        function resizeModalIframe() {
            const iframe = document.getElementById('modalIframe');
            if (!iframe || !iframe.src) return;

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

        function openModal(type, userId = '', role = '') {
            const modalEl = document.getElementById('universalModal');
            const iframe = document.getElementById('modalIframe');
            let url = '';
            switch (type) {
                case 'filter':    url = 'userFilter.aspx'; break;
                case 'newPatron': url = 'userNew.aspx';    break;
                case 'edit':      url = `userUpdate.aspx?UserID=${userId}`; break;
                case 'view':      url = `userView.aspx?UserID=${userId}&role=${role}`; break;
                default: return;
            }

            iframe.style.height = '0px';
            iframe.onload = function () { setTimeout(resizeModalIframe, 50); };
            iframe.src = url;

            currentModal = new bootstrap.Modal(modalEl);
            currentModal.show();
        }

        function closeUniversalModal() {
            if (currentModal) currentModal.hide();
            const iframe = document.getElementById('modalIframe');
            iframe.src = '';
            iframe.style.height = '0px';
        }

        function refreshParentTable() {
            const btn = document.getElementById('<%= btnRefreshTable.ClientID %>');
            if (btn) btn.click();
        }

        function showSwal(title, message, type) {
            Swal.fire({ title: title, text: message, icon: type, confirmButtonColor: '#0d6efd' });
        }

        function initTabs() {
            var container = document.getElementById('patronTabs');
            if (!container) return;
            var btns = container.querySelectorAll('.nav-link');
            btns.forEach(function (btn) {
                btn.addEventListener('click', function (e) {
                    btns.forEach(function (b) { b.classList.remove('active'); });
                    this.classList.add('active');
                });
            });
        }

        window.addEventListener('resize', function () {
            const iframe = document.getElementById('modalIframe');
            if (iframe && iframe.src) resizeModalIframe();
        });

        var prm = Sys.WebForms.PageRequestManager.getInstance();
        if (prm) {
            prm.add_endRequest(function () {
                if (currentModal) { currentModal.dispose(); currentModal = null; }
                initTabs();
            });
        }

        document.addEventListener('DOMContentLoaded', function () { initTabs(); });
    </script>
</asp:Content>