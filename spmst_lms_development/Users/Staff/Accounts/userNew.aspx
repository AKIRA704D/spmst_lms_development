<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="userNew.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Accounts.userNew" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Register New Patron | LMSA</title>
    <!-- Bootstrap 5 CSS + Icons + SweetAlert -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <style>
        body { background: transparent; overflow: hidden; }
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
            margin: 0;
            font-size: 0.7rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: #002447;
        }
        .form-control:focus, .form-select:focus {
            border-color: #ffc107;
            box-shadow: 0 0 0 0.2rem rgba(255,193,7,0.25);
        }
        .btn-custom-primary {
            background-color: #002447;
            border: none;
        }
        .btn-custom-primary:hover {
            background-color: #001a33;
        }
        .capitalize-input { text-transform: capitalize; }
        .lowercase-input { text-transform: lowercase; }
        .uppercase-input { text-transform: uppercase; }
        .loading-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0,0,0,0.6);
            backdrop-filter: blur(4px);
            z-index: 9999;
            display: none;
            align-items: center;
            justify-content: center;
        }
        .loading-box {
            background: white;
            border-radius: 1rem;
            padding: 1.5rem;
            text-align: center;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>
    <form id="form1" runat="server" class="h-100 d-flex flex-column">
        <!-- Loading Overlay -->
        <div id="loadingOverlay" class="loading-overlay">
            <div class="loading-box">
                <div class="spinner-border text-primary mb-3" role="status"></div>
                <p class="mb-0 fw-bold text-dark">Saving Record...</p>
            </div>
        </div>

        <!-- Header -->
        <div class="bg-dark text-white px-4 py-3 d-flex justify-content-between align-items-center flex-shrink-0">
            <div class="d-flex align-items-center gap-3">
                <div class="bg-warning rounded-circle d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                    <i class="fas fa-user-plus text-dark"></i>
                </div>
                <div>
                    <h4 class="mb-0 fw-bold">Register New Patron</h4>
                    <small class="text-secondary">LMSA | Account Creation Portal</small>
                </div>
            </div>
            <button type="button" class="btn-close btn-close-white" onclick="closeAndRefresh()" aria-label="Close"></button>
        </div>

        <!-- Scrollable Form Body -->
        <div class="flex-grow-1 overflow-auto p-4" style="background: #f5f7fb;">
            <div class="container-fluid px-0">
                <!-- 1. Account Classification -->
                <div class="section-header">
                    <h6><i class="fas fa-tag me-2"></i> 1. Account Classification</h6>
                </div>
                <div class="row g-3 mb-4">
                    <div class="col-md-4">
                        <label class="form-label fw-bold small text-uppercase">Register As</label>
                        <asp:DropDownList ID="ddlCategory" runat="server" CssClass="form-select" onchange="togglePanels(this.value)">
                            <asp:ListItem Text="-- Select Role --" Value="" />
                            <asp:ListItem Text="Student" Value="student" />
                            <asp:ListItem Text="Faculty" Value="faculty" />
                            <asp:ListItem Text="Staff" Value="staff" />
                        </asp:DropDownList>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-bold small text-uppercase">ID Number <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtID" runat="server" CssClass="form-control" placeholder="0000-000000" maxlength="11" oninput="maskID(this)" />
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-bold small text-uppercase">Email Address <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control lowercase-input" placeholder="username@spamast.edu.ph" onblur="validateEmail(this)" />
                    </div>
                </div>

                <!-- 2. Personal Profile -->
                <div class="section-header">
                    <h6><i class="fas fa-user me-2"></i> 2. Personal Profile</h6>
                </div>
                <div class="row g-3 mb-3">
                    <div class="col-md-3">
                        <label class="form-label fw-bold small text-uppercase">First Name <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtFName" runat="server" CssClass="form-control capitalize-input" placeholder="e.g. Mary Claire" oninput="toTitleCase(this)" />
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-bold small text-uppercase">Middle Name</label>
                        <asp:TextBox ID="txtMName" runat="server" CssClass="form-control capitalize-input" placeholder="e.g. Fernandez" oninput="toTitleCase(this)" />
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-bold small text-uppercase">Last Name <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtLName" runat="server" CssClass="form-control capitalize-input" placeholder="e.g. Salvosa" oninput="toTitleCase(this)" />
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-bold small text-uppercase">Ext.</label>
                        <asp:TextBox ID="txtExt" runat="server" CssClass="form-control capitalize-input" placeholder="e.g. Jr" oninput="toTitleCase(this)" />
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
                        <asp:TextBox ID="txtMobile" runat="server" CssClass="form-control" placeholder="0900-000-0000" maxlength="13" oninput="maskMobile(this)" />
                    </div>
                </div>

                <!-- 3. Institutional Details -->
                <div class="section-header mt-4">
                    <h6><i class="fas fa-building me-2"></i> 3. Institutional Details</h6>
                </div>
                <div class="row g-3">
                    <asp:Panel ID="pnlStudent" runat="server" ClientIDMode="Static">
                        <div class="row g-3">
                            <div class="col-md-3">
                                <label class="form-label fw-bold small text-uppercase">Institute</label>
                                <asp:TextBox ID="txtInst" runat="server" CssClass="form-control uppercase-input" placeholder="e.g. IET" oninput="this.value = this.value.toUpperCase()" />
                            </div>
                            <div class="col-md-3">
                                <label class="form-label fw-bold small text-uppercase">Course</label>
                                <asp:TextBox ID="txtCourse" runat="server" CssClass="form-control uppercase-input" placeholder="e.g. BSIT" oninput="this.value = this.value.toUpperCase()" />
                            </div>
                            <div class="col-md-3">
                                <label class="form-label fw-bold small text-uppercase">Section</label>
                                <asp:TextBox ID="txtSec" runat="server" CssClass="form-control uppercase-input" placeholder="e.g. A" />
                            </div>
                            <div class="col-md-3">
                                <label class="form-label fw-bold small text-uppercase">Year</label>
                                <asp:TextBox ID="txtYear" runat="server" CssClass="form-control" placeholder="e.g. 4th Year" />
                            </div>
                        </div>
                    </asp:Panel>

                    <asp:Panel ID="pnlFaculty" runat="server" ClientIDMode="Static" style="display:none;">
                        <div class="col-md-12">
                            <label class="form-label fw-bold small text-uppercase">Institute/Department</label>
                            <asp:TextBox ID="txtFacInst" runat="server" CssClass="form-control uppercase-input" placeholder="e.g. IET DEPARTMENT" oninput="this.value = this.value.toUpperCase()" />
                        </div>
                    </asp:Panel>

                    <asp:Panel ID="pnlStaff" runat="server" ClientIDMode="Static" style="display:none;">
                        <div class="col-md-12">
                            <label class="form-label fw-bold small text-uppercase">Office Department</label>
                            <asp:TextBox ID="txtOffice" runat="server" CssClass="form-control capitalize-input" placeholder="e.g. Registrar Office" oninput="toTitleCase(this)" />
                        </div>
                    </asp:Panel>
                </div>
            </div>
        </div>

        <!-- Footer Buttons -->
        <div class="bg-white border-top p-3 d-flex justify-content-end gap-3 flex-shrink-0">
            <button type="button" class="btn btn-outline-secondary px-4" onclick="closeAndRefresh()">Cancel</button>
            <asp:LinkButton ID="btnSave" runat="server" CssClass="btn btn-custom-primary text-white px-5" OnClick="BtnSave_Click" OnClientClick="showLoading()">
                <i class="fas fa-save me-2"></i> Save Patron Account
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

        function maskID(input) {
            let val = input.value.replace(/\D/g, '');
            if (val.length > 4) {
                val = val.slice(0, 4) + '-' + val.slice(4, 10);
            }
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
                Swal.fire({
                    icon: 'warning',
                    title: 'Invalid Email Domain',
                    text: 'Please use @spamast.edu.ph or @gmail.com',
                    confirmButtonColor: '#002447'
                });
                input.value = "";
            }
        }

        function togglePanels(role) {
            document.getElementById('pnlStudent').style.display = 'none';
            document.getElementById('pnlFaculty').style.display = 'none';
            document.getElementById('pnlStaff').style.display = 'none';

            if (role === 'student') {
                document.getElementById('pnlStudent').style.display = 'block';
            } else if (role === 'faculty') {
                document.getElementById('pnlFaculty').style.display = 'block';
            } else if (role === 'staff') {
                document.getElementById('pnlStaff').style.display = 'block';
            }
        }

        function showLoading() {
            const overlay = document.getElementById('loadingOverlay');
            overlay.style.display = 'flex';
        }

        function closeAndRefresh() {
            if (window.parent) {
                window.parent.location.reload();
            } else {
                window.location.href = 'AccManage.aspx';
            }
        }
    </script>
</body>
</html>