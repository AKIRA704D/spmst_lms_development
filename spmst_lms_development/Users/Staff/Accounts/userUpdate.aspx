﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="userUpdate.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Accounts.userUpdate" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Update Patron | LMSA</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <style>
        html, body {
            margin: 0;
            padding: 0;
            background: transparent;
        }

        .form-shell {
            display: flex;
            flex-direction: column;
        }

        .header-bar {
            position: sticky;
            top: 0;
            z-index: 20;
        }

        .footer-bar {
            position: sticky;
            bottom: 0;
            z-index: 20;
            background: #fff;
        }

        .form-section {
            border-left: 4px solid #ffc107;
            background: #f8f9fa;
            padding: 0.75rem 1rem;
            margin-bottom: 1.5rem;
        }
        .form-section h6 {
            font-size: 0.7rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: #002447;
            margin: 0;
        }
        .required-star { color: #dc3545; font-weight: bold; margin-left: 2px; }
        .btn-custom-primary { background-color: #002447; border: none; }
        .btn-custom-primary:hover { background-color: #001a33; }
        .form-control:focus, .form-select:focus {
            border-color: #ffc107;
            box-shadow: 0 0 0 0.2rem rgba(255,193,7,0.25);
        }
        textarea.form-control { resize: vertical; min-height: 72px; }

        /* ---- Profile photo styles (added) ---- */
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
    </style>
</head>
<body>
    <form id="form1" runat="server" class="form-shell" enctype="multipart/form-data">
        <!-- Header (sticky) -->
        <div class="header-bar bg-dark text-white px-4 py-3 d-flex justify-content-between align-items-center">
            <div class="d-flex align-items-center gap-3">
                <div class="bg-warning rounded-circle d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                    <i class="fas fa-user-edit text-dark"></i>
                </div>
                <div>
                    <h4 class="mb-0 fw-bold">Update Patron Record</h4>
                    <small class="text-secondary">Modify existing library member credentials</small>
                </div>
            </div>
            <button type="button" class="btn-close btn-close-white" onclick="window.parent.closeUniversalModal()" aria-label="Close"></button>
        </div>

        <!-- Content (flows naturally) -->
        <div class="p-4" style="background: #f5f7fb;">
            <div class="container-fluid px-0">
                <!-- 1. Account Identification -->
                <div class="form-section">
                    <h6><i class="fas fa-id-card me-2"></i> 1. Account Identification</h6>
                </div>
                <div class="row g-3 mb-4">
                    <div class="col-md-4">
                        <label class="form-label fw-bold small text-uppercase">Account Type</label>
                        <asp:TextBox ID="txtRoleDisplay" runat="server" Enabled="false" CssClass="form-control bg-light" />
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-bold small text-uppercase">ID Number</label>
                        <asp:TextBox ID="txtID" runat="server" Enabled="false" CssClass="form-control bg-light" />
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-bold small text-uppercase">Email Address <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" placeholder="username@spamast.edu.ph" onblur="validateEmail(this)" />
                    </div>
                </div>

                <!-- 2. Profile Photo (NEW) -->
                <div class="form-section">
                    <h6><i class="fas fa-camera me-2"></i> 2. Profile Photo</h6>
                </div>
                <div class="row g-3 mb-4 align-items-center">
                    <div class="col-auto">
                        <div class="profile-photo-wrapper">
                            <img id="profilePreview" runat="server" clientidmode="Static" alt="Profile preview" style="display:none;" />
                            <i id="profilePlaceholder" runat="server" clientidmode="Static" class="fas fa-user placeholder-icon"></i>
                        </div>
                    </div>
                    <div class="col">
                        <label class="form-label fw-bold small text-uppercase">Change Photo</label>
                        <div class="d-flex gap-2 flex-wrap">
                            <label for="fuProfile" class="btn btn-sm btn-outline-secondary mb-0">
                                <i class="fas fa-upload me-1"></i> Choose File
                            </label>
                            <button type="button" id="btnRemovePhoto" runat="server" clientidmode="Static"
                                    class="btn btn-sm btn-outline-danger" style="display:none;"
                                    onclick="removeProfilePhoto(); return false;">
                                <i class="fas fa-trash me-1"></i> Remove
                            </button>

                            <asp:FileUpload ID="fuProfile" runat="server" ClientIDMode="Static"
                                CssClass="visually-hidden-input" accept="image/*"
                                onchange="previewProfile(this)" />

                            <!-- Hidden flag: 0 = no change / replace; 1 = remove existing photo -->
                            <asp:HiddenField ID="hfRemovePhoto" runat="server" ClientIDMode="Static" Value="0" />
                        </div>
                        <small class="text-muted d-block mt-2">
                            <i class="fas fa-info-circle me-1"></i>
                            JPG, JPEG, PNG, GIF or WEBP. Maximum size: 5 MB.
                        </small>
                    </div>
                </div>

                <!-- 3. Personal Profile -->
                <div class="form-section">
                    <h6><i class="fas fa-user me-2"></i> 3. Personal Profile</h6>
                </div>
                <div class="row g-3 mb-3">
                    <div class="col-md-3">
                        <label class="form-label fw-bold small text-uppercase">First Name <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtFName" runat="server" CssClass="form-control" placeholder="e.g. Mary Claire" oninput="toTitleCase(this)" />
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-bold small text-uppercase">Middle Name</label>
                        <asp:TextBox ID="txtMName" runat="server" CssClass="form-control" placeholder="e.g. Fernandez" oninput="toTitleCase(this)" />
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-bold small text-uppercase">Last Name <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtLName" runat="server" CssClass="form-control" placeholder="e.g. Salvosa" oninput="toTitleCase(this)" />
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-bold small text-uppercase">Ext.</label>
                        <asp:TextBox ID="txtExt" runat="server" CssClass="form-control" placeholder="e.g. Jr" oninput="toTitleCase(this)" />
                    </div>
                </div>
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-bold small text-uppercase">Gender</label>
                        <asp:DropDownList ID="ddlGender" runat="server" CssClass="form-select">
                            <asp:ListItem Text="Male" Value="Male" />
                            <asp:ListItem Text="Female" Value="Female" />
                        </asp:DropDownList>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold small text-uppercase">Mobile Number</label>
                        <asp:TextBox ID="txtMobile" runat="server" CssClass="form-control" placeholder="0900-000-0000" oninput="maskMobile(this)" maxlength="13" />
                    </div>
                </div>
                <div class="row g-3 mt-1">
                    <div class="col-12">
                        <label class="form-label fw-bold small text-uppercase">Address</label>
                        <asp:TextBox ID="txtAddress" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="2"
                                     placeholder="Street, Barangay, City/Municipality, Province" />
                    </div>
                </div>

                <!-- 4. Affiliation Details -->
                <div class="form-section mt-4">
                    <h6><i class="fas fa-building me-2"></i> 4. Affiliation Details</h6>
                </div>
                <div class="row g-3">
                    <asp:Panel ID="pnlStudent" runat="server" Visible="false">
                        <div class="row g-3">
                            <div class="col-md-3">
                                <label class="form-label fw-bold small text-uppercase">Institute</label>
                                <asp:TextBox ID="txtInst" runat="server" CssClass="form-control text-uppercase" placeholder="e.g. IET" oninput="this.value = this.value.toUpperCase()" />
                            </div>
                            <div class="col-md-3">
                                <label class="form-label fw-bold small text-uppercase">Course</label>
                                <asp:TextBox ID="txtCourse" runat="server" CssClass="form-control text-uppercase" placeholder="e.g. BSIT" oninput="this.value = this.value.toUpperCase()" />
                            </div>
                            <div class="col-md-3">
                                <label class="form-label fw-bold small text-uppercase">Section</label>
                                <asp:TextBox ID="txtSec" runat="server" CssClass="form-control text-uppercase" placeholder="e.g. A" />
                            </div>
                            <div class="col-md-3">
                                <label class="form-label fw-bold small text-uppercase">Year</label>
                                <asp:TextBox ID="txtYear" runat="server" CssClass="form-control" placeholder="e.g. 4th Year" />
                            </div>
                        </div>
                    </asp:Panel>

                    <asp:Panel ID="pnlFaculty" runat="server" Visible="false">
                        <div class="col-md-12">
                            <label class="form-label fw-bold small text-uppercase">Institute/Department</label>
                            <asp:TextBox ID="txtFacInst" runat="server" CssClass="form-control text-uppercase" placeholder="e.g. IET DEPARTMENT" oninput="this.value = this.value.toUpperCase()" />
                        </div>
                    </asp:Panel>

                    <asp:Panel ID="pnlStaff" runat="server" Visible="false">
                        <div class="col-md-12">
                            <label class="form-label fw-bold small text-uppercase">Office Department</label>
                            <asp:TextBox ID="txtOffice" runat="server" CssClass="form-control" placeholder="e.g. Registrar Office" oninput="toTitleCase(this)" />
                        </div>
                        <div class="col-md-12 mt-2">
                            <div class="form-check">
                                <asp:CheckBox ID="chkHeadLibrarian" runat="server" CssClass="form-check-input" />
                                <label class="form-check-label fw-bold small text-uppercase ms-2" for="<%= chkHeadLibrarian.ClientID %>">
                                    Head Librarian
                                </label>
                            </div>
                        </div>
                    </asp:Panel>
                </div>
            </div>
        </div>

        <!-- Footer (sticky) -->
        <div class="footer-bar border-top p-3 d-flex justify-content-end gap-3">
            <button type="button" class="btn btn-outline-secondary px-4" onclick="window.parent.closeUniversalModal()">Cancel</button>
            <asp:LinkButton ID="btnUpdate" runat="server" CssClass="btn btn-custom-primary text-white px-5" OnClick="BtnUpdate_Click">
                <i class="fas fa-save me-2"></i> Update Record
            </asp:LinkButton>
        </div>
    </form>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function toTitleCase(input) {
            let words = input.value.split(' ');
            for (let i = 0; i < words.length; i++) {
                if (words[i].length > 0) {
                    words[i] = words[i].charAt(0).toUpperCase() + words[i].slice(1).toLowerCase();
                }
            }
            input.value = words.join(' ');
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
                Swal.fire({
                    icon: 'warning',
                    title: 'Invalid Email Domain',
                    text: 'Please use @spamast.edu.ph or @gmail.com',
                    confirmButtonColor: '#002447'
                });
                input.value = "";
            }
        }

        /* ---------- Profile photo preview / remove (NEW) ---------- */
        const MAX_PHOTO_BYTES = 5 * 1024 * 1024;
        const ALLOWED_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

        function notifyParentResize() {
            try {
                if (window.parent && window.parent !== window &&
                    typeof window.parent.resizeModalIframe === 'function') {
                    window.parent.resizeModalIframe();
                }
            } catch (e) { /* ignore */ }
        }

        function previewProfile(input) {
            if (!input.files || !input.files[0]) return;
            const file = input.files[0];
            const nameLower = (file.name || '').toLowerCase();
            const extOk = ALLOWED_EXTENSIONS.some(ext => nameLower.endsWith(ext));

            if (!extOk) {
                Swal.fire({
                    icon: 'warning', title: 'Invalid Format',
                    text: 'Please choose a JPG, JPEG, PNG, GIF or WEBP image.',
                    confirmButtonColor: '#002447'
                });
                input.value = '';
                return;
            }
            if (file.size > MAX_PHOTO_BYTES) {
                Swal.fire({
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
                // A new file has been chosen — this is a replace, not a remove.
                document.getElementById('hfRemovePhoto').value = '0';
                notifyParentResize();
            };
            reader.readAsDataURL(file);
        }

        function removeProfilePhoto() {
            // Clear the FileUpload so a previously-chosen file isn't submitted
            var fu = document.getElementById('fuProfile');
            if (fu) fu.value = '';

            // Hide preview
            const img = document.getElementById('profilePreview');
            img.src = '';
            img.style.display = 'none';
            document.getElementById('profilePlaceholder').style.display = 'block';
            document.getElementById('btnRemovePhoto').style.display = 'none';

            // Mark that the existing DB photo should be removed
            document.getElementById('hfRemovePhoto').value = '1';
            notifyParentResize();
        }

        // Tell the parent to re-measure after the page renders.
        (function () {
            function report() {
                if (window.parent && typeof window.parent.resizeModalIframe === 'function') {
                    window.parent.resizeModalIframe();
                }
            }
            window.addEventListener('load', function () { setTimeout(report, 30); });
            window.addEventListener('resize', report);
        })();
    </script>
</body>
</html>