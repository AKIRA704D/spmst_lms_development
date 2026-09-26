<%@ Page Title="Book Inventory" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="bookInventory.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Inventory.bookInventory" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <!-- Bootstrap 5 + Icons + SweetAlert2 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>

    <style>
        /* Internal CSS */
        .stats-card {
            background: white;
            border-radius: 0.75rem;
            padding: 1rem 1.25rem;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
            border-left: 4px solid;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .stats-label {
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #6c757d;
            margin-bottom: 0.25rem;
        }
        .stats-value {
            font-size: 1.75rem;
            font-weight: 800;
            line-height: 1;
            color: #212529;
        }
        .badge-in, .badge-total {
            display: inline-block;
            padding: 0.25rem 0.5rem;
            font-size: 0.7rem;
            font-weight: 700;
            border-radius: 0.375rem;
        }
        .badge-total {
            background-color: #f3f4f6;
            color: #374151;
        }
        .badge-in {
            background-color: #d1fae5;
            color: #059669;
            border: 1px solid #059669;
        }
        .status-available, .status-checkedout {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            font-size: 0.7rem;
            font-weight: 700;
            border-radius: 2rem;
        }
        .status-available {
            background-color: #d1fae5;
            color: #059669;
            border: 1px solid #059669;
        }
        .status-checkedout {
            background-color: #fee2e2;
            color: #dc2626;
            border: 1px solid #dc2626;
        }
        .inventory-table th {
            background-color: #f8f9fa;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 1px solid #dee2e6;
        }
        .inventory-table td {
            vertical-align: middle;
        }
        .expand-icon {
            cursor: pointer;
            transition: transform 0.2s;
        }
        .expand-icon.rotated {
            transform: rotate(180deg);
        }
        .detail-row {
            background-color: #fff;
        }
        .modal-iframe {
            width: 100%;
            height: 80vh;
            border: none;
        }
    </style>
    <script>
        function toggleDetails(element, rowId) {
            const icon = element.querySelector('.expand-icon');
            const detailRow = document.getElementById('detail-' + rowId);
            if (detailRow) {
                if (detailRow.style.display === 'none' || detailRow.style.display === '') {
                    detailRow.style.display = 'table-row';
                    if (icon) icon.classList.add('rotated');
                } else {
                    detailRow.style.display = 'none';
                    if (icon) icon.classList.remove('rotated');
                }
            }
}

        /* Helper: find server controls by the tail of their generated ClientID */
        function byIdEndsWith(suffix) {
            return document.querySelector('[id$="' + suffix + '"]');
        }

        function openModal(type, event, resourceId = '') {
            if (event) event.preventDefault();
            const modalEl = document.getElementById('universalModal');
            const iframe = document.getElementById('modalIframe');
            let url = '';
            if (type === 'filter') url = 'bookFilter.aspx';
            if (type === 'edit') url = 'bookUD.aspx?ResourceId=' + resourceId;   // Edit details
            if (type === 'stock') url = 'bookUS.aspx?ResourceId=' + resourceId;   // Update stock
            if (url) {
                iframe.src = url;
                const modal = new bootstrap.Modal(modalEl);
                modal.show();
            }
}

        /* NEW: confirm + post back the delete request */
        function confirmDelete(event, resourceId) {
            if (event) { event.preventDefault(); event.stopPropagation(); }

            Swal.fire({
                title: 'Delete this resource?',
                html: 'The book record and <b>all of its copies</b> will be permanently removed.' +
                    '<br/><span class="text-danger">This action cannot be undone.</span>',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#dc3545',
                cancelButtonColor: '#6c757d',
                confirmButtonText: '<i class="fas fa-trash me-1"></i> Yes, delete it',
                cancelButtonText: 'Cancel',
                reverseButtons: true
            }).then(function(result) {
                if (!result.isConfirmed) return;

                var hf = byIdEndsWith('hfDeleteResourceId');
                var btn = byIdEndsWith('btnDeleteResource');
                if (!hf || !btn) return;

                hf.value = resourceId;
                btn.click();
            });
        }

        function closeUniversalModal() {
            const modalEl = document.getElementById('universalModal');
            const modal = bootstrap.Modal.getInstance(modalEl);
            if (modal) modal.hide();
            document.getElementById('modalIframe').src = '';
        }

        function applyBookFilters(section, dateFrom, dateTo) {
            const url = new URL(window.location.href);
            if (section) url.searchParams.set('section', section); else url.searchParams.delete('section');
            if (dateFrom) url.searchParams.set('from', dateFrom); else url.searchParams.delete('from');
            if (dateTo) url.searchParams.set('to', dateTo); else url.searchParams.delete('to');
            window.location.href = url.href;
        }

        function refreshParentTable() {
            const btn = document.getElementById('<%= btnRefreshTable.ClientID %>');
            if (btn) btn.click();
        }

        var prm = Sys.WebForms.PageRequestManager.getInstance();
        if (prm) {
            prm.add_endRequest(function () {
                document.querySelectorAll('[id^="detail-"]').forEach(function (row) {
                    row.style.display = 'none';
                });
                document.querySelectorAll('.expand-icon').forEach(function (icon) {
                    icon.classList.remove('rotated');
                });
            });
        }
    </script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <asp:UpdatePanel ID="upMain" runat="server" UpdateMode="Conditional">
        <ContentTemplate>
            <asp:Button ID="btnRefreshTable" runat="server" OnClick="btnRefreshTable_Click" style="display:none;" />

            <%-- NEW: delete plumbing --%>
        <asp:HiddenField ID="hfDeleteResourceId" runat="server" />
        <asp:Button ID="btnDeleteResource" runat="server" style="display:none;" OnClick="btnDeleteResource_Click" />

            <div class="container-fluid px-4 py-4">
                <!-- Stats Cards -->
                <div class="row g-4 mb-5">
                    <div class="col-md-3">
                        <div class="stats-card border-primary">
                            <div><div class="stats-label">Overall Total Copies</div><div class="stats-value"><asp:Literal ID="litTotalBooks" runat="server" /></div></div>
                            <i class="fas fa-book-open text-primary fs-2"></i>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="stats-card border-success">
                            <div><div class="stats-label">Total Available Copies</div><div class="stats-value"><asp:Literal ID="litAvailable" runat="server" /></div></div>
                            <i class="fas fa-check-circle text-success fs-2"></i>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="stats-card border-warning">
                            <div><div class="stats-label">Total Damaged Copies</div><div class="stats-value"><asp:Literal ID="litDamage" runat="server" /></div></div>
                            <i class="fas fa-exclamation-triangle text-warning fs-2"></i>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="stats-card border-danger">
                            <div><div class="stats-label">Total Lost/Missing Copies</div><div class="stats-value"><asp:Literal ID="litLost" runat="server" /></div></div>
                            <i class="fas fa-times-circle text-danger fs-2"></i>
                        </div>
                    </div>
                </div>

                <!-- Header -->
                <div class="mb-4">
                    <h2 class="fw-bold text-primary">Book Inventory</h2>
                    <p class="text-muted small">Monitor stock levels and manage collection details</p>
                </div>

                <!-- Search & Actions -->
                <div class="row align-items-center g-3 mb-4">
                    <div class="col-md-6">
                        <div class="input-group">
                            <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control" placeholder="Search by title, author, call number..." AutoPostBack="true" OnTextChanged="Filter_Changed" />
                            <span class="input-group-text bg-white"><i class="fas fa-search text-muted"></i></span>
                        </div>
                    </div>
                    <div class="col-md-6 text-md-end">
                        <div class="btn-group" role="group">
                            <button type="button" class="btn btn-outline-secondary btn-sm" onclick="openModal('filter', event)"><i class="fas fa-filter me-1"></i> Filter</button>
                            <asp:LinkButton ID="btnExport" runat="server" CssClass="btn btn-outline-secondary btn-sm"><i class="fas fa-file-export me-1"></i> Export</asp:LinkButton>
                            <asp:LinkButton ID="btnImport" runat="server" PostBackUrl="bookImport.aspx" CssClass="btn btn-outline-secondary btn-sm"><i class="fas fa-file-import me-1"></i> Import</asp:LinkButton>
                            <asp:LinkButton ID="btnNewBook" runat="server" PostBackUrl="bookNew.aspx" CssClass="btn btn-primary btn-sm"><i class="fas fa-plus me-1"></i> New Book</asp:LinkButton>
                        </div>
                    </div>
                </div>

                <!-- Inventory Table -->
                <div class="table-responsive">
                    <table class="table table-hover table-bordered inventory-table w-100">
                        <thead>
                            <tr>
                                <th style="width: 40px;"></th>
                                <th>Book Details</th>
                                <th>Section</th>
                                <th class="text-center">Quick Stock</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rptInventory" runat="server" OnItemDataBound="rptInventory_ItemDataBound">
                                <ItemTemplate>
                                    <tr class="align-middle" onclick='toggleDetails(this, <%# Eval("resource_id") %>)'>
                                        <td class="text-center">
                                            <i class="fas fa-chevron-down expand-icon text-secondary"></i>
                                        </td>
                                        <td>
                                            <div class="fw-bold text-dark"><%# Eval("title") %></div>
                                            <div class="small text-muted">
                                                <span class="fw-semibold"><%# Eval("author") %></span>
                                                <span class="mx-1">•</span>
                                                <span class="text-primary"><%# Eval("call_number") %><%# !string.IsNullOrEmpty(Eval("dewey_decimal")?.ToString()) ? " [" + Eval("dewey_decimal") + "]" : "" %></span>
                                            </div>
                                        </td>
                                        <td><%# Eval("section") %></td>
                                        <td class="text-center">
                                            <span class="badge-total me-1">Total: <%# Eval("TotalCopies") %></span>
                                            <span class="badge-in">In: <%# Eval("AvailableCopies") %></span>
                                        </td>
                                        <td class="text-nowrap">
                                            <button type="button" class="btn btn-link btn-sm text-primary p-0 me-2" onclick='openModal("edit", event, <%# Eval("resource_id") %>)'><i class="fas fa-edit"></i> Edit</button>
                                            <button type="button" class="btn btn-link btn-sm text-success p-0 me-2" onclick='openModal("stock", event, <%# Eval("resource_id") %>)'><i class="fas fa-tasks"></i> Stock</button>
                                            <button type="button" class="btn btn-link btn-sm text-danger p-0" onclick='confirmDelete(event, <%# Eval("resource_id") %>)'><i class="fas fa-trash"></i> Delete</button>
                                        </td>
                                    </tr>
                                    <tr id="detail-<%# Eval("resource_id") %>" style="display:none;" class="detail-row">
                                        <td colspan="5" class="p-4 bg-light">
                                            <div class="row">
                                                <div class="col-md-3 text-center">
                                                    <div class="border rounded p-3 bg-white">
                                                        <i class="fas fa-book-open fa-4x text-primary"></i>
                                                        <asp:Image ID="imgCover" runat="server" CssClass="Img-fluid mt-2" style="max-height: 150px;" />
                                                    </div>
                                                </div>
                                                <div class="col-md-9">
                                                    <div class="row">
                                                        <div class="col-sm-6 col-lg-3">
                                                            <div class="fw-bold text-muted small">Item Type</div>
                                                            <div><%# Eval("item_type") %></div>
                                                        </div>
                                                        <div class="col-sm-6 col-lg-3">
                                                            <div class="fw-bold text-muted small"><%# !string.IsNullOrEmpty(Eval("isbn")?.ToString()) ? "ISBN" : "ISSN" %></div>
                                                            <div><%# !string.IsNullOrEmpty(Eval("isbn")?.ToString()) ? Eval("isbn") : (Eval("issn") ?? "N/A") %></div>
                                                        </div>
                                                        <div class="col-sm-6 col-lg-3">
                                                            <div class="fw-bold text-muted small">Edition / Series</div>
                                                            <div><%# string.IsNullOrEmpty(Eval("edition")?.ToString()) ? Eval("series") : string.IsNullOrEmpty(Eval("series")?.ToString()) ? Eval("edition") : Eval("edition") + " (" + Eval("series") + ")" %></div>
                                                        </div>
                                                        <div class="col-sm-6 col-lg-3">
                                                            <div class="fw-bold text-muted small">Publisher & Place</div>
                                                            <div class="uppercase"><%# Eval("publisher") %></div>
                                                            <div class="small"><%# Eval("place_of_publication") %></div>
                                                        </div>
                                                        <div class="col-sm-6 col-lg-3">
                                                            <div class="fw-bold text-muted small">Year</div>
                                                            <div><%# !string.IsNullOrEmpty(Eval("pub_year")?.ToString()) ? "Pub: " + Eval("pub_year") : !string.IsNullOrEmpty(Eval("copyright_year")?.ToString()) ? "© " + Eval("copyright_year") : "N/A" %></div>
                                                        </div>
                                                        <div class="col-sm-6 col-lg-3">
                                                            <div class="fw-bold text-muted small">Pages</div>
                                                            <div><%# Eval("pages_numeric") %></div>
                                                        </div>
                                                    </div>
                                                    <div class="mt-3">
                                                        <div class="fw-bold text-muted small">Description</div>
                                                        <div class="small"><%# string.IsNullOrEmpty(Eval("description")?.ToString()) ? "No official description has been recorded for this library resource." : Eval("description") %></div>
                                                    </div>
                                                    <hr />
                                                    <div class="fw-bold text-muted small mb-2"><i class="fas fa-copy me-1"></i> Individual Copy Details</div>
                                                    <div class="row">
                                                        <asp:Repeater ID="rptCopies" runat="server">
                                                            <ItemTemplate>
                                                                <div class="col-sm-6 col-lg-4 mb-2">
                                                                    <div class="border rounded p-2 d-flex justify-content-between align-items-center">
                                                                        <div>
                                                                            <div class="small fw-bold text-muted">Accession</div>
                                                                            <div class="fw-semibold"><%# Eval("accession_number") %></div>
                                                                        </div>
                                                                        <span class='<%# Eval("status_condition").ToString() == "Damage" ? "status-checkedout" : Eval("status_condition").ToString() == "Lost" ? "status-checkedout" : Convert.ToInt32(Eval("is_available")) == 1 ? "status-available" : "status-checkedout" %>'>
                                                                            <%# Eval("status_condition").ToString() == "Damage" ? "Damaged" : Eval("status_condition").ToString() == "Lost" ? "Lost" : Convert.ToInt32(Eval("is_available")) == 1 ? "Available" : "Borrowed" %>
                                                                        </span>
                                                                    </div>
                                                                </div>
                                                            </ItemTemplate>
                                                        </asp:Repeater>
                                                    </div>
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                </div>

                <asp:Label ID="lblNoData" runat="server" Visible="false" CssClass="text-center text-muted d-block py-5">No books found.</asp:Label>
            </div>
        </ContentTemplate>
        <Triggers>
            <asp:AsyncPostBackTrigger ControlID="txtSearch" EventName="TextChanged" />
        </Triggers>
    </asp:UpdatePanel>

    <!-- Bootstrap Modal for iframe -->
    <div class="modal fade" id="universalModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-dialog-centered modal-xl">
            <div class="modal-content" style="height: 90vh; border-radius: 1rem; overflow: hidden;">
                <div class="modal-body p-0" style="height: 100%;">
                    <iframe id="modalIframe" class="modal-iframe" style="width: 100%; height: 100%; border: none;"></iframe>
                </div>
            </div>
        </div>
    </div>
</asp:Content>