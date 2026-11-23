<%@ Page Title="" Language="C#" MasterPageFile="~/Users/MasterPage/admin.master" AutoEventWireup="true" CodeBehind="LibraryTermsSettings.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Settings.LibraryTermsSettings" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="<%= ResolveUrl("~/Assets/Themes/library-settings.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Assets/Themes/library-terms-settings.css") %>" rel="stylesheet" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="ls-child-header">
        <div>
            <a href="LibrarySettings.aspx" class="ls-back-btn"><i class="fa-solid fa-arrow-left"></i> Back to Settings</a>
            <h2 class="ls-child-title">Terms &amp; Conditions</h2>
            <p class="ls-child-subtitle">Upload PDF documents and control which version is active.</p>
        </div>
    </div>

    <div class="ls-card ls-form mb-4">
        <h5 class="fw-bold mb-3 text-dark">Upload New Document</h5>
        <div class="row g-3">
            <div class="col-md-6"><label>Title</label><input type="text" class="form-control" id="tTitle" placeholder="Library Terms & Conditions" /></div>
            <div class="col-md-3"><label>Version <span class="text-muted fw-normal">(optional)</span></label><input type="text" class="form-control" id="tVersion" placeholder="1.0" /></div>
            <div class="col-md-3 d-flex align-items-end">
                <div class="form-check mb-2">
                    <input class="form-check-input" type="checkbox" id="tSetActive" checked />
                    <label class="form-check-label" for="tSetActive">Set as active document</label>
                </div>
            </div>
            <div class="col-12">
                <label>PDF File</label>
                <div class="ls-upload-drop">
                    <i class="fa-solid fa-file-pdf fs-3 mb-2 d-block text-danger"></i>
                    <input type="file" id="tFile" accept="application/pdf" class="form-control" style="max-width:340px;margin:0 auto;" />
                </div>
                <iframe id="tPreviewFrame" class="ls-terms-preview"></iframe>
            </div>
            <div class="col-12 mt-4">
                <button type="button" id="tUploadBtn" class="ls-dash-btn"><i class="fa-solid fa-cloud-arrow-up me-2"></i>Upload Document</button>
                <span class="ls-save-note" id="tNote"></span>
            </div>
        </div>
    </div>

    <div class="ls-card">
        <h5 class="fw-bold mb-3 text-dark">Document History</h5>
        <div style="overflow-x:auto;">
            <table class="ls-table">
                <thead>
                    <tr><th>Title</th><th>Version</th><th>Uploaded</th><th style="width:90px;">Status</th><th style="width:140px;"></th></tr>
                </thead>
                <tbody id="termsTableBody">
                    <tr><td colspan="5" class="text-center p-4 text-muted"><i class="fa-solid fa-spinner fa-spin"></i> Loading...</td></tr>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Preview Modal -->
    <div class="modal fade" id="previewModal" tabindex="-1">
        <div class="modal-dialog modal-lg modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="previewModalTitle">Preview</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body p-0">
                    <iframe id="previewModalFrame" style="width:100%;height:75vh;border:0;"></iframe>
                </div>
            </div>
        </div>
    </div>

    <script src="<%= ResolveUrl("~/Assets/Script//library-settings-common.js") %>"></script>
    <script>
var termsCache = {};
var previewModal;

function loadTerms() {
    LsApi.get('listterms').then(function (res) {
        var body = document.getElementById('termsTableBody');
        if (!res.success || !res.data || res.data.length === 0) {
            body.innerHTML = '<tr><td colspan="5" class="text-center p-4 text-muted">No documents uploaded yet.</td></tr>';
            return;
        }

        termsCache = {};
        res.data.forEach(function (t) { termsCache[t.termsId] = t; });

        body.innerHTML = res.data.map(function (t) {
            return '<tr data-id="' + t.termsId + '">' +
                '<td class="fw-semibold">' + LsUI.escape(t.title) + '</td>' +
                '<td>' + LsUI.escape(t.versionLabel || '—') + '</td>' +
                '<td class="text-muted">' + LsUI.escape(t.uploadedAt) + '</td>' +
                '<td><span class="ls-badge ' + (t.isActive ? 'on' : 'off') + '">' + (t.isActive ? 'Active' : 'Inactive') + '</span></td>' +
                '<td><div class="ls-row-actions">' +
                '<button type="button" title="View" data-action="view" data-id="' + t.termsId + '"><i class="fa-solid fa-eye"></i></button>' +
                (t.isActive ? '' : '<button type="button" title="Set Active" data-action="activate" data-id="' + t.termsId + '"><i class="fa-solid fa-circle-check"></i></button>') +
                '<button type="button" class="danger" title="Delete" data-action="delete" data-id="' + t.termsId + '"><i class="fa-solid fa-trash"></i></button>' +
                '</div></td></tr>';
        }).join('');
    });
}

document.getElementById('termsTableBody').addEventListener('click', function (e) {
    var btn = e.target.closest('button[data-action]');
    if (!btn) return;
    var id = parseInt(btn.getAttribute('data-id'), 10);
    var action = btn.getAttribute('data-action');
    var t = termsCache[id];
    if (!t) return;

    if (action === 'view') {
        document.getElementById('previewModalTitle').textContent = t.title;
        document.getElementById('previewModalFrame').src = LsUI.pdfViewerUrl(LsUI.assetUrl(t.filePath));
        previewModal.show();
    } else if (action === 'activate') {
        var fd = new FormData(); fd.append('termsId', id);
        LsApi.post('setactiveterms', fd).then(function (res) { if (res.success) loadTerms(); });
    } else if (action === 'delete') {
        if (confirm('Delete "' + t.title + '"? This cannot be undone.')) {
            var fd2 = new FormData(); fd2.append('termsId', id);
            LsApi.post('deleteterms', fd2).then(function (res) { if (res.success) loadTerms(); });
        }
    }
});

document.getElementById('tFile').addEventListener('change', function (e) {
    var file = e.target.files[0];
    var frame = document.getElementById('tPreviewFrame');
    if (file) {
        frame.src = LsUI.pdfViewerUrl(URL.createObjectURL(file));
        frame.style.display = 'block';
    } else {
        frame.style.display = 'none';
        frame.src = '';
    }
});

document.getElementById('tUploadBtn').addEventListener('click', function () {
    var fileInput = document.getElementById('tFile');
    if (!fileInput.files || fileInput.files.length === 0) {
        LsUI.showNote('tNote', 'Choose a PDF file first.', false); return;
    }

    var fd = new FormData();
    fd.append('file', fileInput.files[0]);
    fd.append('title', document.getElementById('tTitle').value);
    fd.append('versionLabel', document.getElementById('tVersion').value);
    fd.append('isActive', document.getElementById('tSetActive').checked ? 'true' : 'false');

    LsUI.showNote('tNote', 'Uploading...', false);
    LsApi.post('uploadterms', fd).then(function (res) {
        if (res.success) {
            LsUI.showNote('tNote', 'Uploaded successfully.', true);
            document.getElementById('tTitle').value = '';
            document.getElementById('tVersion').value = '';
            document.getElementById('tFile').value = '';
            document.getElementById('tPreviewFrame').style.display = 'none';
            loadTerms();
        } else {
            LsUI.showNote('tNote', res.message || 'Upload failed.', false);
        }
    });
});

document.addEventListener('DOMContentLoaded', function () {
    previewModal = new bootstrap.Modal(document.getElementById('previewModal'));
    loadTerms();
        });
    </script>
</asp:Content>