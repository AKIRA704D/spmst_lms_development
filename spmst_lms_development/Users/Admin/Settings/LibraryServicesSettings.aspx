<%@ Page Title="" Language="C#" MasterPageFile="~/Users/MasterPage/admin.master" AutoEventWireup="true" CodeBehind="LibraryServicesSettings.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Settings.LibraryServicesSettings" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="<%= ResolveUrl("~/Assets/Themes/library-settings.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Assets/Themes/library-services-settings.css") %>" rel="stylesheet" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="ls-child-header" style="justify-content: space-between;">
        <div>
            <a href="LibrarySettings.aspx" class="ls-back-btn"><i class="fa-solid fa-arrow-left"></i> Back to Settings</a>
            <h2 class="ls-child-title">Library Services</h2>
            <p class="ls-child-subtitle">Manage the cards displayed on the public Services page.</p>
        </div>
        <div>
            <button type="button" class="ls-dash-btn" id="btnAddService"><i class="fa-solid fa-plus me-2"></i>Add Service</button>
        </div>
    </div>

    <div class="ls-card">
        <div style="overflow-x:auto;">
            <table class="ls-table">
                <thead>
                    <tr><th style="width:50px;"></th><th>Title</th><th>Description</th><th style="width:80px;">Order</th><th style="width:90px;">Status</th><th style="width:90px;"></th></tr>
                </thead>
                <tbody id="servicesTableBody">
                    <tr><td colspan="6" class="text-center p-4 text-muted"><i class="fa-solid fa-spinner fa-spin"></i> Loading...</td></tr>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Service Modal -->
    <div class="modal fade" id="serviceModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content ls-form">
                <div class="modal-header">
                    <h5 class="modal-title" id="serviceModalTitle">Add Service</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" id="svcId" />
                    <div class="row g-3">
                        <div class="col-4">
                            <label>Icon Class</label>
                            <div class="input-group">
                                <span class="input-group-text ls-icon-preview"><i class="fa-solid" id="svcIconPreview"></i></span>
                                <input type="text" class="form-control" id="svcIcon" placeholder="fa-book" />
                            </div>
                            <div class="form-text" style="font-size:0.75rem;">Any FA6 solid class.</div>
                        </div>
                        <div class="col-8"><label>Title</label><input type="text" class="form-control" id="svcTitle" /></div>
                        <div class="col-12"><label>Description</label><textarea class="form-control" id="svcDescription" rows="3"></textarea></div>
                        <div class="col-6"><label>Sort Order</label><input type="number" class="form-control" id="svcSortOrder" value="0" /></div>
                        <div class="col-6 d-flex align-items-end">
                            <div class="form-check mb-2">
                                <input class="form-check-input" type="checkbox" id="svcActive" checked />
                                <label class="form-check-label" for="svcActive">Active (visible)</label>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="ls-dash-btn" id="btnSaveService">Save Service</button>
                </div>
            </div>
        </div>
    </div>

    <script src="<%= ResolveUrl("~/Assets/Script//library-settings-common.js") %>"></script>
    <script>
var serviceModal;
var servicesData = [];

function loadServices() {
    LsApi.get('listservices').then(function (res) {
        var body = document.getElementById('servicesTableBody');
        if (!res.success || !res.data || res.data.length === 0) {
            body.innerHTML = '<tr><td colspan="6" class="text-center p-4 text-muted">No services yet.</td></tr>';
            return;
        }
        servicesData = res.data;
        body.innerHTML = res.data.map(function (s, index) {
            return '<tr>' +
                '<td><span class="ls-icon-preview"><i class="fa-solid ' + LsUI.escape(s.iconClass) + '"></i></span></td>' +
                '<td class="fw-semibold">' + LsUI.escape(s.title) + '</td>' +
                '<td class="text-muted" style="max-width:300px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">' + LsUI.escape(s.description || '') + '</td>' +
                '<td>' + s.sortOrder + '</td>' +
                '<td><span class="ls-badge ' + (s.isActive ? 'on' : 'off') + '">' + (s.isActive ? 'Active' : 'Hidden') + '</span></td>' +
                '<td><div class="ls-row-actions">' +
                '  <button type="button" title="Edit" onclick="editService(' + index + ')"><i class="fa-solid fa-pen"></i></button>' +
                '  <button type="button" class="danger" title="Delete" onclick="deleteService(' + s.serviceId + ', \'' + LsUI.escape(s.title).replace(/'/g, "\\'") + '\')"><i class="fa-solid fa-trash"></i></button>' +
                '</div></td>' +
                '</tr>';
        }).join('');
    });
}

function editService(index) {
    var s = servicesData[index];
    document.getElementById('svcId').value = s.serviceId;
    document.getElementById('svcIcon').value = s.iconClass;
    document.getElementById('svcIconPreview').className = 'fa-solid ' + s.iconClass;
    document.getElementById('svcTitle').value = s.title;
    document.getElementById('svcDescription').value = s.description || '';
    document.getElementById('svcSortOrder').value = s.sortOrder;
    document.getElementById('svcActive').checked = !!s.isActive;
    document.getElementById('serviceModalTitle').textContent = 'Edit Service';
    serviceModal.show();
}

function deleteService(id, title) {
    if (!confirm('Remove "' + title + '" from Services?')) return;
    var fd = new FormData();
    fd.append('serviceId', id);
    LsApi.post('deleteservice', fd).then(function () { loadServices(); });
}

document.addEventListener('DOMContentLoaded', function () {
    serviceModal = new bootstrap.Modal(document.getElementById('serviceModal'));

    document.getElementById('svcIcon').addEventListener('input', function (e) {
        document.getElementById('svcIconPreview').className = 'fa-solid ' + (e.target.value || 'fa-book');
    });

    document.getElementById('btnAddService').addEventListener('click', function () {
        document.getElementById('svcId').value = '';
        document.getElementById('svcIcon').value = 'fa-book';
        document.getElementById('svcIconPreview').className = 'fa-solid fa-book';
        document.getElementById('svcTitle').value = '';
        document.getElementById('svcDescription').value = '';
        document.getElementById('svcSortOrder').value = '0';
        document.getElementById('svcActive').checked = true;
        document.getElementById('serviceModalTitle').textContent = 'Add Service';
        serviceModal.show();
    });

    document.getElementById('btnSaveService').addEventListener('click', function () {
        var title = document.getElementById('svcTitle').value.trim();
        if (!title) { alert('Title is required.'); return; }

        var fd = new FormData();
        fd.append('serviceId', document.getElementById('svcId').value);
        fd.append('iconClass', document.getElementById('svcIcon').value || 'fa-book');
        fd.append('title', title);
        fd.append('description', document.getElementById('svcDescription').value);
        fd.append('sortOrder', document.getElementById('svcSortOrder').value || '0');
        fd.append('isActive', document.getElementById('svcActive').checked ? 'true' : 'false');

        LsApi.post('saveservice', fd).then(function (res) {
            if (res.success) {
                serviceModal.hide();
                loadServices();
            } else {
                alert(res.message || 'Could not save service.');
            }
        });
    });

    loadServices();
        });
    </script>
</asp:Content>