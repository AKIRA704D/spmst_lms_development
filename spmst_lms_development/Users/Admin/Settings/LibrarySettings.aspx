<%@ Page Title="" Language="C#" MasterPageFile="~/Users/MasterPage/admin.master" AutoEventWireup="true" CodeBehind="LibrarySettings.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Settings.LibrarySettings" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <title>Library Settings - LMSA Admin</title>
    <style>
        .ls-header { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px; margin-bottom: 22px; }
        .ls-header h2 { font-weight: 800; color: #1e293b; font-size: 1.5rem; margin: 0; }
        .ls-header p { color: #64748b; font-size: 0.9rem; margin: 4px 0 0; }

        .ls-tabs .nav-link { color: #475569; font-weight: 600; border: none; border-bottom: 3px solid transparent; border-radius: 0; padding: 12px 18px; }
        .ls-tabs .nav-link.active { color: #0369a1; border-bottom-color: #0ea5e9; background: none; }
        .ls-tabs { border-bottom: 1px solid #e2e8f0; margin-bottom: 26px; }

        .ls-card { background: #fff; border: 1px solid #e2e8f0; border-radius: 14px; padding: 26px; box-shadow: 0 2px 10px rgba(15,23,42,0.04); }
        .ls-card + .ls-card { margin-top: 20px; }
        .ls-card h5 { font-weight: 700; color: #1e293b; margin-bottom: 4px; }
        .ls-card .sub { color: #64748b; font-size: 0.84rem; margin-bottom: 18px; }

        .ls-form label { font-weight: 700; font-size: 0.83rem; color: #334155; margin-bottom: 5px; }
        .ls-form .form-control, .ls-form .form-select { border-radius: 8px; border: 1.5px solid #e2e8f0; font-size: 0.9rem; }
        .ls-form .form-control:focus, .ls-form .form-select:focus { border-color: #0ea5e9; box-shadow: 0 0 0 3px rgba(14,165,233,0.14); }
        .ls-save-note { font-size: 0.8rem; color: #94a3b8; margin-top: 10px; }
        .ls-save-note.ok { color: #16a34a; font-weight: 600; }

        .ls-table { width: 100%; font-size: 0.88rem; }
        .ls-table th { font-size: 0.72rem; text-transform: uppercase; letter-spacing: .4px; color: #64748b; border-bottom: 2px solid #e2e8f0; padding: 10px 12px; text-align: left; }
        .ls-table td { padding: 12px; border-bottom: 1px solid #f1f5f9; vertical-align: middle; }
        .ls-icon-preview { width: 34px; height: 34px; border-radius: 9px; background: #eef6ff; color: #0284c7; display: inline-flex; align-items: center; justify-content: center; }
        .ls-badge { font-size: 0.7rem; font-weight: 700; padding: 4px 9px; border-radius: 999px; }
        .ls-badge.on { background: #f0fdf4; color: #16a34a; }
        .ls-badge.off { background: #f1f5f9; color: #64748b; }
        .ls-row-actions { display: flex; gap: 6px; }
        .ls-row-actions button { border: 1px solid #e2e8f0; background: #fff; border-radius: 7px; width: 30px; height: 30px; font-size: 0.8rem; color: #475569; }
        .ls-row-actions button:hover { background: #f1f5f9; }
        .ls-row-actions button.danger:hover { background: #fef2f2; color: #dc2626; border-color: #fecaca; }

        .ls-empty { text-align: center; padding: 30px; color: #94a3b8; font-size: 0.88rem; }

        .ls-upload-drop { border: 1.5px dashed #cbd5e1; border-radius: 12px; padding: 22px; text-align: center; color: #64748b; }
        .ls-terms-preview { width: 100%; height: 380px; border: 1px solid #e2e8f0; border-radius: 10px; margin-top: 14px; display: none; }

        .btn-ls-primary { background: linear-gradient(135deg,#0f172a,#1e293b); color: #fff; border: none; border-radius: 999px; padding: 9px 20px; font-weight: 700; font-size: 0.86rem; }
        .btn-ls-primary:hover { color: #fff; opacity: .92; }
        .btn-ls-outline { border: 1.5px solid #e2e8f0; background: #fff; border-radius: 999px; padding: 8px 18px; font-weight: 700; font-size: 0.86rem; color: #334155; }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="ls-header">
        <div>
            <h2><i class="fa-solid fa-gear me-2"></i>Library Settings</h2>
            <p>Manage the content shown on the public LMSA landing page - contact info, about us, services, and terms &amp; conditions.</p>
        </div>
    </div>

    <ul class="nav ls-tabs" id="lsTabs" role="tablist">
        <li class="nav-item"><button class="nav-link active" data-bs-toggle="tab" data-bs-target="#tabContact" type="button"><i class="fa-solid fa-address-card me-1"></i> Contact Info</button></li>
        <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabAbout" type="button"><i class="fa-solid fa-circle-info me-1"></i> About Us</button></li>
        <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabServices" type="button"><i class="fa-solid fa-hand-holding-heart me-1"></i> Services</button></li>
        <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabTerms" type="button"><i class="fa-solid fa-file-contract me-1"></i> Terms &amp; Conditions</button></li>
    </ul>

    <div class="tab-content">

        <!-- CONTACT INFO -->
        <div class="tab-pane fade show active" id="tabContact">
            <div class="ls-card ls-form">
                <h5>Contact Information</h5>
                <div class="sub">Shown on the public "About &amp; Contact" page and site footer.</div>
                <div id="contactForm">
                    <div class="row g-3">
                        <div class="col-12"><label>Address</label><input type="text" class="form-control" id="ciAddress" /></div>
                        <div class="col-md-6"><label>Phone</label><input type="text" class="form-control" id="ciPhone" /></div>
                        <div class="col-md-6"><label>Email</label><input type="email" class="form-control" id="ciEmail" /></div>
                        <div class="col-md-4"><label>Hours - Weekdays</label><input type="text" class="form-control" id="ciHoursWeekdays" placeholder="Mon - Fri: 8:00 AM - 5:00 PM" /></div>
                        <div class="col-md-4"><label>Hours - Saturday</label><input type="text" class="form-control" id="ciHoursSaturday" placeholder="Saturday: 8:00 AM - 12:00 PM" /></div>
                        <div class="col-md-4"><label>Hours - Sunday</label><input type="text" class="form-control" id="ciHoursSunday" placeholder="Sunday & Holidays: Closed" /></div>
                        <div class="col-md-6"><label>Facebook URL <span class="text-muted fw-normal">(optional)</span></label><input type="text" class="form-control" id="ciFacebook" /></div>
                        <div class="col-md-6"><label>Google Maps Embed URL</label><input type="text" class="form-control" id="ciMapUrl" placeholder="https://www.google.com/maps/embed?..." /></div>
                        <div class="col-12">
                            <button type="button" id="ciSaveBtn" class="btn-ls-primary"><i class="fa-solid fa-floppy-disk me-1"></i> Save Contact Info</button>
                            <span class="ls-save-note" id="ciNote"></span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- ABOUT US -->
        <div class="tab-pane fade" id="tabAbout">
            <div class="ls-card ls-form">
                <h5>About Us</h5>
                <div class="sub">Shown on the public "About &amp; Contact" page.</div>
                <div id="aboutForm">
                    <div class="row g-3">
                        <div class="col-12"><label>Heading</label><input type="text" class="form-control" id="auHeading" /></div>
                        <div class="col-12"><label>Body <span class="text-muted fw-normal">(separate paragraphs with a blank line)</span></label><textarea class="form-control" id="auBody" rows="5"></textarea></div>
                        <div class="col-md-4"><label>Stat 1 Label</label><input type="text" class="form-control" id="auStat1Label" placeholder="Institutes Served" /></div>
                        <div class="col-md-2"><label>Value</label><input type="text" class="form-control" id="auStat1Value" placeholder="7" /></div>
                        <div class="col-md-4"><label>Stat 2 Label</label><input type="text" class="form-control" id="auStat2Label" placeholder="SPAMAST Founded" /></div>
                        <div class="col-md-2"><label>Value</label><input type="text" class="form-control" id="auStat2Value" placeholder="1969" /></div>
                        <div class="col-md-4"><label>Stat 3 Label</label><input type="text" class="form-control" id="auStat3Label" placeholder="Days a Week Open" /></div>
                        <div class="col-md-2"><label>Value</label><input type="text" class="form-control" id="auStat3Value" placeholder="6" /></div>
                        <div class="col-12">
                            <button type="button" id="auSaveBtn" class="btn-ls-primary"><i class="fa-solid fa-floppy-disk me-1"></i> Save About Us</button>
                            <span class="ls-save-note" id="auNote"></span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- SERVICES -->
        <div class="tab-pane fade" id="tabServices">
            <div class="ls-card">
                <div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-2">
                    <div>
                        <h5 class="mb-0">Services</h5>
                        <div class="sub mb-0">Shown as cards on the public "Services" page, ordered by Sort Order.</div>
                    </div>
                    <button type="button" class="btn-ls-primary" id="btnAddService"><i class="fa-solid fa-plus me-1"></i> Add Service</button>
                </div>
                <div style="overflow-x:auto;">
                    <table class="ls-table">
                        <thead>
                            <tr><th style="width:50px;"></th><th>Title</th><th>Description</th><th style="width:80px;">Order</th><th style="width:90px;">Status</th><th style="width:90px;"></th></tr>
                        </thead>
                        <tbody id="servicesTableBody">
                            <tr><td colspan="6" class="ls-empty"><i class="fa-solid fa-spinner fa-spin"></i> Loading...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- TERMS & CONDITIONS -->
        <div class="tab-pane fade" id="tabTerms">
            <div class="ls-card ls-form">
                <h5>Upload Terms &amp; Conditions</h5>
                <div class="sub">Only PDF files are accepted. Uploading a new document does not remove older ones - you can keep history and switch which one is active.</div>
                <div id="termsForm">
                    <div class="row g-3">
                        <div class="col-md-6"><label>Title</label><input type="text" class="form-control" id="tTitle" placeholder="Library Terms & Conditions" /></div>
                        <div class="col-md-3"><label>Version <span class="text-muted fw-normal">(optional)</span></label><input type="text" class="form-control" id="tVersion" placeholder="1.0" /></div>
                        <div class="col-md-3 d-flex align-items-end">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="tSetActive" checked />
                                <label class="form-check-label" for="tSetActive">Set as active document</label>
                            </div>
                        </div>
                        <div class="col-12">
                            <label>PDF File</label>
                            <div class="ls-upload-drop">
                                <i class="fa-solid fa-file-pdf fs-3 mb-2 d-block text-danger"></i>
                                <input type="file" id="tFile" accept="application/pdf" class="form-control" style="max-width:340px;margin:0 auto;" />
                                <div class="form-text">This preview shows exactly what visitors will see on the public Terms &amp; Conditions page.</div>
                            </div>
                            <iframe id="tPreviewFrame" class="ls-terms-preview"></iframe>
                        </div>
                        <div class="col-12">
                            <button type="button" id="tUploadBtn" class="btn-ls-primary"><i class="fa-solid fa-cloud-arrow-up me-1"></i> Upload</button>
                            <span class="ls-save-note" id="tNote"></span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="ls-card">
                <h5>Document History</h5>
                <div class="sub mb-0">The document marked Active is the one visitors see on the public Terms &amp; Conditions page.</div>
                <div style="overflow-x:auto;">
                    <table class="ls-table">
                        <thead>
                            <tr><th>Title</th><th>Version</th><th>Uploaded</th><th style="width:90px;">Status</th><th style="width:150px;"></th></tr>
                        </thead>
                        <tbody id="termsTableBody">
                            <tr><td colspan="5" class="ls-empty"><i class="fa-solid fa-spinner fa-spin"></i> Loading...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    </div>

    <!-- Service Add/Edit Modal -->
    <div class="modal fade" id="serviceModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="serviceModalTitle">Add Service</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body ls-form">
                    <input type="hidden" id="svcId" />
                    <div class="row g-3">
                        <div class="col-4">
                            <label>Icon Class</label>
                            <div class="input-group">
                                <span class="input-group-text ls-icon-preview"><i class="fa-solid" id="svcIconPreview"></i></span>
                                <input type="text" class="form-control" id="svcIcon" placeholder="fa-book" />
                            </div>
                            <div class="form-text">Any <a href="https://fontawesome.com/search?o=r&m=free&s=solid" target="_blank" rel="noopener">Font Awesome 6 solid</a> class name.</div>
                        </div>
                        <div class="col-8"><label>Title</label><input type="text" class="form-control" id="svcTitle" /></div>
                        <div class="col-12"><label>Description</label><textarea class="form-control" id="svcDescription" rows="3"></textarea></div>
                        <div class="col-6"><label>Sort Order</label><input type="number" class="form-control" id="svcSortOrder" value="0" /></div>
                        <div class="col-6 d-flex align-items-end">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="svcActive" checked />
                                <label class="form-check-label" for="svcActive">Active (visible to visitors)</label>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-ls-outline" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn-ls-primary" id="btnSaveService">Save Service</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Preview Modal (for history rows) -->
    <div class="modal fade" id="previewModal" tabindex="-1">
        <div class="modal-dialog modal-lg modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="previewModalTitle">Preview</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body p-0">
                    <iframe id="previewModalFrame" style="width:100%;height:70vh;border:0;"></iframe>
                </div>
            </div>
        </div>
    </div>

    <script>
        var apiUrl = '<%= ResolveUrl("~/Users/Admin/Settings/LibrarySettingsData.ashx") %>';
        var siteRoot = '<%= ResolveUrl("~/") %>';

        function lsEscape(str) {
            if (str === null || str === undefined) return '';
            return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
        }
        function lsAssetUrl(p) { return p ? siteRoot + p.replace(/^\/+/, '') : ''; }

        // Appends PDF Open Parameters so the embedded viewer hides its
        // toolbar, thumbnail pane, and status bar (read-only content view).
        function lsPdfViewerUrl(url) {
            if (!url) return '';
            // Strip any existing fragment so we don't end up with "...#...#toolbar=0"
            var base = url.split('#')[0];
            return base + '#toolbar=0&navpanes=0&statusbar=0&messages=0&scrollbar=1&view=FitH';
        }


        function lsApiGet(action) {
            var url = apiUrl + '?action=' + encodeURIComponent(action) + '&_=' + Date.now();
            return fetch(url, {
                headers: { 'X-Requested-With': 'XMLHttpRequest' },
                cache: 'no-store' })
                .then(function (r) { return r.json(); });
        }
        function lsApiPost(action, formData) {
            return fetch(apiUrl + '?action=' + encodeURIComponent(action), { method: 'POST', body: formData })
                .then(function (r) { return r.json(); });
        }

        // ---------------- Contact Info ----------------
        function loadContact() {
            lsApiGet('getcontact').then(function (res) {
                if (!res.success || !res.data) return;
                var d = res.data;
                document.getElementById('ciAddress').value = d.address || '';
                document.getElementById('ciPhone').value = d.phone || '';
                document.getElementById('ciEmail').value = d.email || '';
                document.getElementById('ciHoursWeekdays').value = d.hoursWeekdays || '';
                document.getElementById('ciHoursSaturday').value = d.hoursSaturday || '';
                document.getElementById('ciHoursSunday').value = d.hoursSunday || '';
                document.getElementById('ciFacebook').value = d.facebookUrl || '';
                document.getElementById('ciMapUrl').value = d.mapEmbedUrl || '';
            });
        }

        document.getElementById('ciSaveBtn').addEventListener('click', function () {
            var fd = new FormData();
            fd.append('address', document.getElementById('ciAddress').value);
            fd.append('phone', document.getElementById('ciPhone').value);
            fd.append('email', document.getElementById('ciEmail').value);
            fd.append('hoursWeekdays', document.getElementById('ciHoursWeekdays').value);
            fd.append('hoursSaturday', document.getElementById('ciHoursSaturday').value);
            fd.append('hoursSunday', document.getElementById('ciHoursSunday').value);
            fd.append('facebookUrl', document.getElementById('ciFacebook').value);
            fd.append('mapEmbedUrl', document.getElementById('ciMapUrl').value);

            var note = document.getElementById('ciNote');
            note.textContent = 'Saving...'; note.className = 'ls-save-note';
            lsApiPost('savecontact', fd).then(function (res) {
                note.textContent = res.success ? 'Saved.' : (res.message || 'Could not save.');
                note.className = 'ls-save-note' + (res.success ? ' ok' : '');
            });
        });

        // ---------------- About Us ----------------
        function loadAbout() {
            lsApiGet('getabout').then(function (res) {
                if (!res.success || !res.data) return;
                var d = res.data;
                document.getElementById('auHeading').value = d.heading || '';
                document.getElementById('auBody').value = d.body || '';
                document.getElementById('auStat1Label').value = d.stat1Label || '';
                document.getElementById('auStat1Value').value = d.stat1Value || '';
                document.getElementById('auStat2Label').value = d.stat2Label || '';
                document.getElementById('auStat2Value').value = d.stat2Value || '';
                document.getElementById('auStat3Label').value = d.stat3Label || '';
                document.getElementById('auStat3Value').value = d.stat3Value || '';
            });
        }

        document.getElementById('auSaveBtn').addEventListener('click', function () {
            var fd = new FormData();
            fd.append('heading', document.getElementById('auHeading').value);
            fd.append('body', document.getElementById('auBody').value);
            fd.append('stat1Label', document.getElementById('auStat1Label').value);
            fd.append('stat1Value', document.getElementById('auStat1Value').value);
            fd.append('stat2Label', document.getElementById('auStat2Label').value);
            fd.append('stat2Value', document.getElementById('auStat2Value').value);
            fd.append('stat3Label', document.getElementById('auStat3Label').value);
            fd.append('stat3Value', document.getElementById('auStat3Value').value);

            var note = document.getElementById('auNote');
            note.textContent = 'Saving...'; note.className = 'ls-save-note';
            lsApiPost('saveabout', fd).then(function (res) {
                note.textContent = res.success ? 'Saved.' : (res.message || 'Could not save.');
                note.className = 'ls-save-note' + (res.success ? ' ok' : '');
            });
        });

        // ---------------- Services ----------------
        var serviceModal, previewModal;

        function loadServices() {
            lsApiGet('listservices').then(function (res) {
                var body = document.getElementById('servicesTableBody');
                if (!res.success || !res.data || res.data.length === 0) {
                    body.innerHTML = '<tr><td colspan="6" class="ls-empty"><i class="fa-solid fa-hand-holding-heart"></i><br/>No services yet — add the first one.</td></tr>';
                    return;
                }
                body.innerHTML = res.data.map(function (s) {
                    return '<tr>' +
                        '<td><span class="ls-icon-preview"><i class="fa-solid ' + lsEscape(s.iconClass) + '"></i></span></td>' +
                        '<td class="fw-semibold">' + lsEscape(s.title) + '</td>' +
                        '<td class="text-muted" style="max-width:320px;">' + lsEscape((s.description || '').substring(0, 90)) + ((s.description || '').length > 90 ? '...' : '') + '</td>' +
                        '<td>' + s.sortOrder + '</td>' +
                        '<td><span class="ls-badge ' + (s.isActive ? 'on' : 'off') + '">' + (s.isActive ? 'Active' : 'Hidden') + '</span></td>' +
                        '<td><div class="ls-row-actions">' +
                        '  <button type="button" title="Edit" onclick=\'editService(' + JSON.stringify(s).replace(/'/g, "&#39;") + ')\'><i class="fa-solid fa-pen"></i></button>' +
                        '  <button type="button" class="danger" title="Delete" onclick="deleteService(' + s.serviceId + ', ' + JSON.stringify(s.title) + ')"><i class="fa-solid fa-trash"></i></button>' +
                        '</div></td>' +
                        '</tr>';
                }).join('');
            });
        }

        function resetServiceModal() {
            document.getElementById('svcId').value = '';
            document.getElementById('svcIcon').value = 'fa-book';
            document.getElementById('svcIconPreview').className = 'fa-solid fa-book';
            document.getElementById('svcTitle').value = '';
            document.getElementById('svcDescription').value = '';
            document.getElementById('svcSortOrder').value = '0';
            document.getElementById('svcActive').checked = true;
            document.getElementById('serviceModalTitle').textContent = 'Add Service';
        }

        function editService(s) {
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
            lsApiPost('deleteservice', fd).then(function () { loadServices(); });
        }

        // ---------------- Terms & Conditions ----------------
        var termsCache = {};   // keyed by termsId

        function loadTerms() {
            lsApiGet('listterms').then(function (res) {
                var body = document.getElementById('termsTableBody');

                if (!res.success || !res.data || res.data.length === 0) {
                    termsCache = {};
                    body.innerHTML =
                        '<tr><td colspan="5" class="ls-empty">' +
                        '<i class="fa-solid fa-file-circle-question"></i><br/>' +
                        'No documents uploaded yet.</td></tr>';
                    return;
                }

                // Index by id so the click handler can look up the row later.
                termsCache = {};
                res.data.forEach(function (t) { termsCache[t.termsId] = t; });

                body.innerHTML = res.data.map(function (t) {
                    return '<tr data-id="' + t.termsId + '">' +
                        '<td class="fw-semibold">' + lsEscape(t.title) + '</td>' +
                        '<td>' + lsEscape(t.versionLabel || '—') + '</td>' +
                        '<td class="text-muted">' + lsEscape(t.uploadedAt) + '</td>' +
                        '<td><span class="ls-badge ' + (t.isActive ? 'on' : 'off') + '">' +
                        (t.isActive ? 'Active' : 'Inactive') +
                        '</span></td>' +
                        '<td><div class="ls-row-actions">' +
                        '<button type="button" title="View" data-action="view" data-id="' + t.termsId + '">' +
                        '<i class="fa-solid fa-eye"></i>' +
                        '</button>' +
                        (t.isActive ? '' :
                            '<button type="button" title="Set as active" data-action="activate" data-id="' + t.termsId + '">' +
                            '<i class="fa-solid fa-circle-check"></i>' +
                            '</button>') +
                        '<button type="button" class="danger" title="Delete" data-action="delete" data-id="' + t.termsId + '">' +
                        '<i class="fa-solid fa-trash"></i>' +
                        '</button>' +
                        '</div></td>' +
                        '</tr>';
                }).join('');
            });
        }

        function previewTerms(filePath, title) {
            document.getElementById('previewModalTitle').textContent = title;
            document.getElementById('previewModalFrame').src = lsPdfViewerUrl(lsAssetUrl(filePath));
            previewModal.show();
        }

        function setActiveTerms(id) {
            var fd = new FormData();
            fd.append('termsId', id);
            lsApiPost('setactiveterms', fd).then(function (res) {
                if (res && res.success === false) { alert(res.message || 'Could not activate.'); return; }
                loadTerms();          // <-- reflect the new Active badge immediately
            });
        }

        function deleteTerms(id, title) {
            if (!confirm('Delete "' + title + '"? This cannot be undone.')) return;
            var fd = new FormData();
            fd.append('termsId', id);
            lsApiPost('deleteterms', fd).then(function (res) {
                if (res && res.success === false) { alert(res.message || 'Could not delete.'); return; }
                loadTerms();
            });
        }

        document.getElementById('tFile').addEventListener('change', function (e) {
            var file = e.target.files[0];
            var frame = document.getElementById('tPreviewFrame');
            if (file) {
                frame.src = lsPdfViewerUrl(URL.createObjectURL(file));
                frame.style.display = 'block';
            } else {
                frame.style.display = 'none';
                frame.src = '';
            }
        });

        document.getElementById('tUploadBtn').addEventListener('click', function () {
            var fileInput = document.getElementById('tFile');
            var note = document.getElementById('tNote');
            if (!fileInput.files || fileInput.files.length === 0) {
                note.textContent = 'Choose a PDF file first.'; note.className = 'ls-save-note';
                return;
            }

            var fd = new FormData();
            fd.append('file', fileInput.files[0]);
            fd.append('title', document.getElementById('tTitle').value);
            fd.append('versionLabel', document.getElementById('tVersion').value);
            fd.append('isActive', document.getElementById('tSetActive').checked ? 'true' : 'false');

            note.textContent = 'Uploading...'; note.className = 'ls-save-note';
            lsApiPost('uploadterms', fd).then(function (res) {
                if (res.success) {
                    note.textContent = 'Uploaded.'; note.className = 'ls-save-note ok';
                    document.getElementById('tTitle').value = '';
                    document.getElementById('tVersion').value = '';
                    document.getElementById('tFile').value = '';
                    document.getElementById('tSetActive').checked = true;
                    document.getElementById('tPreviewFrame').style.display = 'none';
                    document.getElementById('tPreviewFrame').src = '';
                    loadTerms();
                } else {
                    note.textContent = res.message || 'Upload failed.'; note.className = 'ls-save-note';
                }
            });
        });

        // ---------------- Init ----------------
        document.addEventListener('DOMContentLoaded', function () {
            serviceModal = new bootstrap.Modal(document.getElementById('serviceModal'));
            previewModal = new bootstrap.Modal(document.getElementById('previewModal'));

            document.getElementById('svcIcon').addEventListener('input', function (e) {
                document.getElementById('svcIconPreview').className = 'fa-solid ' + (e.target.value || 'fa-book');
            });

            document.getElementById('btnAddService').addEventListener('click', function () {
                resetServiceModal();
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

                lsApiPost('saveservice', fd).then(function (res) {
                    if (res.success) {
                        serviceModal.hide();
                        loadServices();
                    } else {
                        alert(res.message || 'Could not save service.');
                    }
                });
            });

            document.getElementById('termsTableBody').addEventListener('click', function(e) {
                var btn = e.target.closest('button[data-action]');
                if (!btn) return;

                var id = parseInt(btn.getAttribute('data-id'), 10);
                var action = btn.getAttribute('data-action');
                var t = termsCache[id];
                if (!t) return;

                if (action === 'view') {
                    previewTerms(t.filePath, t.title);
                } else if (action === 'activate') {
                    setActiveTerms(id);
                } else if (action === 'delete') {
                    deleteTerms(id, t.title);
                }
            });

            loadContact();
            loadAbout();
            loadServices();
            loadTerms();
        });
    </script>

</asp:Content>
