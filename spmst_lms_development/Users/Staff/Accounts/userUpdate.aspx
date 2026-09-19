<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="userUpdate.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Accounts.userUpdate" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Update Patron | LMSA</title>
    <!-- Bootstrap 5 CSS + Icons + SweetAlert -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <style>
        body {
            background: transparent;
            overflow: hidden;
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
        .required-star {
            color: #dc3545;
            font-weight: bold;
            margin-left: 2px;
        }
        .card-custom {
            border: none;
            box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.05);
        }
        .btn-custom-primary {
            background-color: #002447;
            border: none;
        }
        .btn-custom-primary:hover {
            background-color: #001a33;
        }
        .form-control:focus, .form-select:focus {
            border-color: #ffc107;
            box-shadow: 0 0 0 0.2rem rgba(255,193,7,0.25);
        }
    </style>
</head>
<body>
    <form id="form1" runat="server" class="h-100 d-flex flex-column">
        <!-- Header -->
        <div class="bg-dark text-white px-4 py-3 d-flex justify-content-between align-items-center flex-shrink-0">
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

        <!-- Scrollable Form Body -->
        <div class="flex-grow-1 overflow-auto p-4" style="background: #f5f7fb;">
            <div class="container-fluid px-0">
                <!-- Account Identification -->
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

                <!-- Personal Profile -->
                <div class="form-section">
                    <h6><i class="fas fa-user me-2"></i> 2. Personal Profile</h6>
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

                <!-- Affiliation Details -->
                <div class="form-section mt-4">
                    <h6><i class="fas fa-building me-2"></i> 3. Affiliation Details</h6>
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
                    </asp:Panel>
                </div>
            </div>
        </div>

        <!-- Footer Buttons -->
        <div class="bg-white border-top p-3 d-flex justify-content-end gap-3 flex-shrink-0">
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
    </script>
</body>
</html>