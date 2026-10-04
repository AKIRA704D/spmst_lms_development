﻿﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="userNew.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Accounts.userNew" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Register New Patron | LMSA</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <style>
        html, body { background: transparent; margin: 0; padding: 0; }

        .required-star { color: #dc3545; font-weight: bold; margin-left: 2px; }

        .section-header {
            background-color: #f8f9fa;
            border-left: 4px solid #ffc107;
            padding: 0.5rem 1rem;
            margin-bottom: 1rem;
            display: flex;
            align-items: center;
        }
        .section-header h6 {
            margin: 0; font-size: 0.7rem; font-weight: 800;
            text-transform: uppercase; letter-spacing: 1px; color: #002447;
        }

        .form-control:focus, .form-select:focus {
            border-color: #ffc107;
            box-shadow: 0 0 0 0.2rem rgba(255,193,7,0.25);
        }
        .btn-custom-primary { background-color: #002447; border: none; }
        .btn-custom-primary:hover { background-color: #001a33; }

        .capitalize-input { text-transform: capitalize; }
        .lowercase-input  { text-transform: lowercase; }
        .uppercase-input  { text-transform: uppercase; }

        .sticky-header {
            position: sticky;
            top: 0;
            z-index: 1030;
            box-shadow: 0 2px 8px rgba(0,0,0,0.15);
        }
        .sticky-footer {
            position: sticky;
            bottom: 0;
            z-index: 1030;
            box-shadow: 0 -2px 8px rgba(0,0,0,0.08);
        }

        .profile-photo-wrapper {
            width: 130px; height: 130px;
            border-radius: 50%;
            overflow: hidden;
            border: 3px solid #002447;
            background: #f8f9fa;
            display: flex; align-items: center; justify-content: center;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
        }
        .profile-photo-wrapper img {
            width: 100%; height: 100%; object-fit: cover; display: none;
        }
        .profile-photo-wrapper .placeholder-icon {
            font-size: 3rem; color: #adb5bd;
        }

        .visually-hidden-input {
            position: absolute;
            width: 1px; height: 1px;
            padding: 0; margin: -1px;
            overflow: hidden;
            clip: rect(0, 0, 0, 0);
            white-space: nowrap;
            border: 0;
        }

        /* Loading overlay — kept local to the iframe viewport.
           backdrop-filter removed to avoid iframe-compositor edge cases. */
        .loading-overlay {
            position: fixed; top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0, 0, 0, 0.55);
            z-index: 9999;
            display: none;
            align-items: center; justify-content: center;
        }
        .loading-box {
            background: white; border-radius: 1rem; padding: 1.5rem;
            text-align: center; box-shadow: 0 10px 25px rgba(0,0,0,0.15);
        }
    </style>
</head>
<body>
    <form id="form1" runat="server" enctype="multipart/form-data">

        <!-- Loading Overlay (default hidden) -->
        <div id="loadingOverlay" class="loading-overlay" style="display:none;">
            <div class="loading-box">
                <div class="spinner-border text-primary mb-3" role="status"></div>
                <p class="mb-0 fw-bold text-dark">Saving Record...</p>
            </div>
        </div>

        <!-- Header (sticky) -->
        <div class="bg-dark text-white px-4 py-3 d-flex justify-content-between align-items-center sticky-header">
            <div class="d-flex align-items-center gap-3">
                <div class="bg-warning rounded-circle d-flex align-items-center justify-content-center" style="width:40px; height:40px;">
                    <i class="fas fa-user-plus text-dark"></i>
                </div>
                <div>
                    <h4 class="mb-0 fw-bold">Register New Patron</h4>
                    <small class="text-secondary">LMSA | Account Creation Portal</small>
                </div>
            </div>
            <button type="button" class="btn-close btn-close-white" onclick="closeModal()" aria-label="Close"></button>
        </div>

        <!-- Body -->
        <div class="p-4" style="background:#f5f7fb;">
            <div class="container-fluid px-0">

                <!-- 1. Account Classification -->
                <div class="section-header">
                    <h6><i class="fas fa-tag me-2"></i> 1. Account Classification</h6>
                </div>
                <div class="row g-3 mb-4">
                    <div class="col-md-4">
                        <label class="form-label fw-bold small text-uppercase">Register As</label>
                        <asp:DropDownList ID="ddlCategory" runat="server" ClientIDMode="Static"
                            CssClass="form-select" onchange="togglePanels(this.value)">
                            <asp:ListItem Text="-- Select Role --" Value="" />
                            <asp:ListItem Text="Student" Value="student" />
                            <asp:ListItem Text="Faculty" Value="faculty" />
                            <asp:ListItem Text="Staff"   Value="staff" />
                        </asp:DropDownList>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-bold small text-uppercase">ID Number <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtID" runat="server" CssClass="form-control"
                            placeholder="0000-000000" maxlength="11" oninput="maskID(this)" />
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-bold small text-uppercase">Email Address <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control lowercase-input"
                            placeholder="username@spamast.edu.ph" onblur="validateEmail(this)" />
                    </div>
                </div>

                <!-- 2. Profile Photo -->
                <div class="section-header">
                    <h6><i class="fas fa-camera me-2"></i> 2. Profile Photo</h6>
                </div>
                <div class="row g-3 mb-4 align-items-center">
                    <div class="col-auto">
                        <div class="profile-photo-wrapper">
                            <img id="profilePreview" src="" alt="Profile preview" />
                            <i id="profilePlaceholder" class="fas fa-user placeholder-icon"></i>
                        </div>
                    </div>
                    <div class="col">
                        <label class="form-label fw-bold small text-uppercase">Upload Photo</label>
                        <div class="d-flex gap-2 flex-wrap">
                            <label for="fuProfile" class="btn btn-sm btn-outline-secondary mb-0">
                                <i class="fas fa-upload me-1"></i> Choose File
                            </label>
                            <button type="button" id="btnRemovePhoto" class="btn btn-sm btn-outline-danger"
                                    onclick="removeProfilePhoto()" style="display:none;">
                                <i class="fas fa-trash me-1"></i> Remove
                            </button>

                            <asp:FileUpload ID="fuProfile" runat="server" ClientIDMode="Static"
                                CssClass="visually-hidden-input" accept="image/*"
                                onchange="previewProfile(this)" />
                        </div>
                        <small class="text-muted d-block mt-2">
                            <i class="fas fa-info-circle me-1"></i>
                            JPG, JPEG, PNG, GIF or WEBP. Maximum size: 5 MB.
                        </small>
                    </div>
                </div>

                <!-- 3. Personal Profile -->
                <div class="section-header">
                    <h6><i class="fas fa-user me-2"></i> 3. Personal Profile</h6>
                </div>

                <div class="row g-3 mb-3">
                    <div class="col-md-3">
                        <label class="form-label fw-bold small text-uppercase">First Name <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtFName" runat="server" CssClass="form-control capitalize-input"
                            placeholder="e.g. Mary Claire" oninput="toTitleCase(this)" />
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-bold small text-uppercase">Middle Name</label>
                        <asp:TextBox ID="txtMName" runat="server" CssClass="form-control capitalize-input"
                            placeholder="e.g. Fernandez" oninput="toTitleCase(this)" />
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-bold small text-uppercase">Last Name <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtLName" runat="server" CssClass="form-control capitalize-input"
                            placeholder="e.g. Salvosa" oninput="toTitleCase(this)" />
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-bold small text-uppercase">Ext.</label>
                        <asp:TextBox ID="txtExt" runat="server" CssClass="form-control capitalize-input"
                            placeholder="e.g. Jr" oninput="toTitleCase(this)" />
                    </div>
                </div>

                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-bold small text-uppercase">Gender</label>
                        <asp:DropDownList ID="ddlGender" runat="server" CssClass="form-select">
                            <asp:ListItem Text="-- Select Gender --" Value="" />
                            <asp:ListItem Text="Male" Value="Male" />
                            <asp:ListItem Text="Female" Value="Female" />
                        </asp:DropDownList>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold small text-uppercase">Mobile Number</label>
                        <asp:TextBox ID="txtMobile" runat="server" CssClass="form-control"
                            placeholder="0900-000-0000" maxlength="13" oninput="maskMobile(this)" />
                    </div>
                </div>

                <div class="row g-3 mt-1">
                    <div class="col-12">
                        <label class="form-label fw-bold small text-uppercase">Address</label>
                        <asp:TextBox ID="txtAddress" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="2"
                                     placeholder="Street, Barangay, City/Municipality, Province" />
                    </div>
                </div>

                <!-- 4. Institutional Details -->
                <div id="institutionalSection" style="display:none;">
                    <div class="section-header mt-4">
                        <h6><i class="fas fa-building me-2"></i> 4. Institutional Details</h6>
                    </div>

                    <asp:Panel ID="pnlStudent" runat="server" ClientIDMode="Static" style="display:none;">
                        <div class="row g-3">
                            <div class="col-md-3">
                                <label class="form-label fw-bold small text-uppercase">Institute</label>
                                <asp:TextBox ID="txtInst" runat="server" CssClass="form-control uppercase-input"
                                    placeholder="e.g. IET" oninput="this.value = this.value.toUpperCase()" />
                            </div>
                            <div class="col-md-3">
                                <label class="form-label fw-bold small text-uppercase">Course</label>
                                <asp:TextBox ID="txtCourse" runat="server" CssClass="form-control uppercase-input"
                                    placeholder="e.g. BSIT" oninput="this.value = this.value.toUpperCase()" />
                            </div>
                            <div class="col-md-3">
                                <label class="form-label fw-bold small text-uppercase">Section</label>
                                <asp:TextBox ID="txtSec" runat="server" CssClass="form-control uppercase-input"
                                    placeholder="e.g. A" />
                            </div>
                            <div class="col-md-3">
                                <label class="form-label fw-bold small text-uppercase">Year</label>
                                <asp:TextBox ID="txtYear" runat="server" CssClass="form-control"
                                    placeholder="e.g. 4th Year" />
                            </div>
                        </div>
                    </asp:Panel>

                    <asp:Panel ID="pnlFaculty" runat="server" ClientIDMode="Static" style="display:none;">
                        <div class="row g-3">
                            <div class="col-md-12">
                                <label class="form-label fw-bold small text-uppercase">Institute/Department</label>
                                <asp:TextBox ID="txtFacInst" runat="server" CssClass="form-control uppercase-input"
                                    placeholder="e.g. IET DEPARTMENT" oninput="this.value = this.value.toUpperCase()" />
                            </div>
                        </div>
                    </asp:Panel>

                    <asp:Panel ID="pnlStaff" runat="server" ClientIDMode="Static" style="display:none;">
                        <div class="row g-3">
                            <div class="col-md-12">
                                <label class="form-label fw-bold small text-uppercase">Office Department</label>
                                <asp:TextBox ID="txtOffice" runat="server" CssClass="form-control capitalize-input"
                                    placeholder="e.g. Registrar Office" oninput="toTitleCase(this)" />
                            </div>
                        </div>
                    </asp:Panel>
                </div>

            </div>
        </div>

        <!-- Footer (sticky) -->
        <div class="bg-white border-top p-3 d-flex justify-content-end gap-3 sticky-footer">
            <button type="button" class="btn btn-outline-secondary px-4" onclick="closeModal()">Cancel</button>
            <asp:LinkButton ID="btnSave" runat="server" CssClass="btn btn-custom-primary text-white px-5"
                OnClick="BtnSave_Click" OnClientClick="showLoading();">
                <i class="fas fa-save me-2"></i> Save Patron Account
            </asp:LinkButton>
        </div>
    </form>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        /* ---------- Formatters ---------- */
        function toTitleCase(input) {
            let words = input.value.split(' ');
            for (let i = 0; i < words.length; i++) {
                if (words[i].length > 0)
                    words[i] = words[i].charAt(0).toUpperCase() + words[i].slice(1).toLowerCase();
            }
            input.value = words.join(' ');
        }
        function maskID(input) {
            let val = input.value.replace(/\D/g, '');
            if (val.length > 4) val = val.slice(0, 4) + '-' + val.slice(4, 10);
            input.value = val;
        }
        function maskMobile(input) {
            let val = input.value.replace(/\D/g, '');
            let masked = '';
            if (val.length > 0) masked += val.slice(0, 4);
            if (val.length > 4) masked += '-' + val.slice(4, 7);
            if (val.length > 7) masked += '-' + val.slice(7, 11);
            input.value = masked;
        }
        function validateEmail(input) {
            input.value = input.value.toLowerCase();
            const val = input.value;
            if (val !== "" && !val.endsWith("@spamast.edu.ph") && !val.endsWith("@gmail.com")) {
                getSwal().fire({
                    icon: 'warning', title: 'Invalid Email Domain',
                    text: 'Please use @spamast.edu.ph or @gmail.com',
                    confirmButtonColor: '#002447'
                });
                input.value = "";
            }
        }

        /* ---------- Swal helper (parent-aware, safe) ---------- */
        function getSwal() {
            try {
                if (window.parent && window.parent !== window && window.parent.Swal)
                    return window.parent.Swal;
            } catch (e) { /* ignore cross-origin */ }
            return window.Swal;
        }

        /* ---------- Profile photo preview ---------- */
        const MAX_PHOTO_BYTES = 5 * 1024 * 1024;
        const ALLOWED_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

        function previewProfile(input) {
            if (!input.files || !input.files[0]) return;
            const file = input.files[0];
            const nameLower = (file.name || '').toLowerCase();
            const extOk = ALLOWED_EXTENSIONS.some(ext => nameLower.endsWith(ext));

            if (!extOk) {
                getSwal().fire({
                    icon: 'warning', title: 'Invalid Format',
                    text: 'Please choose a JPG, JPEG, PNG, GIF or WEBP image.',
                    confirmButtonColor: '#002447'
                });
                input.value = '';
                return;
            }
            if (file.size > MAX_PHOTO_BYTES) {
                getSwal().fire({
                    icon: 'warning', title: 'File Too Large',
                    text: 'Maximum profile photo size is 5 MB.',
                    confirmButtonColor: '#002447'
                });
                input.value = '';
                return;
            }

            const reader = new FileReader();
            reader.onload = function (e) {
                const img = document.getElementById('profilePreview');
                img.src = e.target.result;
                img.style.display = 'block';
                document.getElementById('profilePlaceholder').style.display = 'none';
                document.getElementById('btnRemovePhoto').style.display = 'inline-block';
                notifyParentResize();
            };
            reader.readAsDataURL(file);
        }

        function removeProfilePhoto() {
            var fu = document.getElementById('fuProfile');
            if (fu) fu.value = '';
            const img = document.getElementById('profilePreview');
            img.src = '';
            img.style.display = 'none';
            document.getElementById('profilePlaceholder').style.display = 'block';
            document.getElementById('btnRemovePhoto').style.display = 'none';
            notifyParentResize();
        }

        /* ---------- Modal auto-resize ---------- */
        function notifyParentResize() {
            try {
                if (window.parent && window.parent !== window &&
                    typeof window.parent.resizeModalIframe === 'function') {
                    window.parent.resizeModalIframe();
                }
            } catch (e) { /* ignore */ }
        }

        /* ---------- Role toggling ---------- */
        function togglePanels(role) {
            var inst = document.getElementById('institutionalSection');
            if (inst) inst.style.display = role ? 'block' : 'none';

            var s = document.getElementById('pnlStudent');
            var f = document.getElementById('pnlFaculty');
            var st = document.getElementById('pnlStaff');
            if (s) s.style.display = (role === 'student') ? 'block' : 'none';
            if (f) f.style.display = (role === 'faculty') ? 'block' : 'none';
            if (st) st.style.display = (role === 'staff') ? 'block' : 'none';

            notifyParentResize();
        }

        /* ---------- Loading overlay ---------- */
        function showLoading() {
            var o = document.getElementById('loadingOverlay');
            if (o) o.style.display = 'flex';
            notifyParentResize();
        }
        function hideLoading() {
            var o = document.getElementById('loadingOverlay');
            if (o) o.style.display = 'none';
            notifyParentResize();
        }

        /* ---------- Modal close (mirrors userUpdate convention) ---------- */
        function closeModal() {
            try {
                if (window.parent && window.parent !== window &&
                    typeof window.parent.closeUniversalModal === 'function') {
                    window.parent.closeUniversalModal();
                } else {
                    window.location.href = 'AccManage.aspx';
                }
            } catch (e) {
                try { window.location.href = 'AccManage.aspx'; } catch (_) { /* ignore */ }
            }
        }

        /* ---------- Init: hide overlay immediately ---------- */
        function pageInit() {
            var overlay = document.getElementById('loadingOverlay');
            if (overlay) overlay.style.display = 'none';

            var ddl = document.getElementById('ddlCategory');
            if (ddl) togglePanels(ddl.value);
        }

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', pageInit);
        } else {
            pageInit();
        }
    </script>
</body>
</html>