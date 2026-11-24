<%@ Page Title="My Profile" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="Profile.aspx.cs" Inherits="spmst_lms_development.Users.Patron.Profile" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Assets/Vendor/bootstrap/5.3.3/css/bootstrap.min.css") %>" />

    <style>
        /* ============================================
           1. READONLY / EDITABLE TEXTBOX STYLES
           ============================================ */
        .readonly-textbox {
            background-color: transparent !important;
            border-color: transparent !important;
            box-shadow: none !important;
            padding-left: 0 !important;
            padding-right: 0 !important;
            cursor: default;
            color: #1e293b !important;
            font-weight: 700 !important;
            width: 100%;
            resize: none;
            overflow: hidden;
        }

        .editable-textbox {
            background-color: #f8fafc !important;
            border-color: #cbd5e1 !important;
            border-width: 1px !important;
            padding: 0.5rem 0.75rem !important;
            border-radius: 0.5rem !important;
            color: #0f172a !important;
            font-weight: 500 !important;
            transition: all 0.2s ease-in-out;
            width: 100%;
            resize: vertical;
        }

            .editable-textbox:focus {
                outline: none;
                border-color: #3b82f6 !important;
                box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2) !important;
            }

        /* ============================================
           2. PROFILE CARD STYLES
           ============================================ */
        .profile-header-card {
            background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
            border-radius: 2rem;
            padding: 1.5rem;
            text-align: center;
            color: white;
            box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1);
        }

        .avatar-circle {
            width: 80px;
            height: 80px;
            background: rgba(255,255,255,0.2);
            backdrop-filter: blur(4px);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 2rem;
            font-weight: bold;
            margin: 0 auto 1rem auto;
            border: 2px solid rgba(255,255,255,0.3);
        }

        .qr-box {
            background: white;
            border-radius: 1rem;
            padding: 0.5rem;
            width: 120px;
            height: 120px;
            margin: 1rem auto;
            display: flex;
            align-items: center;
            justify-content: center;
        }

            .qr-box Img {
                width: 100%;
                height: 100%;
                object-fit: contain;
            }

        .info-panel {
            background: white;
            border-radius: 1.5rem;
            padding: 1.5rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            border: 1px solid #e2e8f0;
            margin-bottom: 1.5rem;
        }

        .status-badge {
            background: #d1fae5;
            color: #065f46;
            padding: 0.5rem 1rem;
            border-radius: 2rem;
            font-size: 0.75rem;
            font-weight: bold;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container py-4">
        <h1 class="fw-bold mb-4">My <span class="text-primary">Profile</span></h1>

        <div class="row g-4">
            <!-- Left Column: Profile Card & Status -->
            <div class="col-lg-4">
                <div class="profile-header-card">
                    <div class="avatar-circle">
                        <asp:Literal ID="litInitials" runat="server"></asp:Literal>
                    </div>
                    <h3 class="fw-bold mb-1">
                        <asp:Literal ID="litCardName" runat="server"></asp:Literal></h3>
                    <!-- Card ID color changed to white and bold -->
                    <p class="text-white small mb-3 fw-bold">
                        <span id="userIdDisplay"><asp:Literal ID="litCardID" runat="server"></asp:Literal></span></p>
                    <div class="qr-box">
                        <asp:Image ID="imgQRCode" runat="server" AlternateText="QR Code" />
                    </div>
                    <p class="small text-white-50 mt-2">Digital Library Pass</p>
                    <button id="btnDownloadID" type="button" class="btn btn-light w-100 mt-3" onclick="downloadQR()">
                        <i class="fas fa-download me-2"></i>DOWNLOAD DIGITAL ID
                    </button>
                </div>

                <!-- Library Status Panel - dynamic list -->
                <div class="info-panel mt-3">
                    <div class="d-flex align-items-center gap-2 mb-2">
                        <i class="fas fa-book-open text-success fa-2x"></i>
                        <h6 class="fw-bold mb-0">Library Status</h6>
                    </div>
                    <asp:Literal ID="litLibraryStatusList" runat="server"></asp:Literal>
                </div>
            </div>

            <!-- Right Column: Account Information & Emergency Contact -->
            <div class="col-lg-8">
                <!-- Account Information Panel -->
                <asp:UpdatePanel ID="upAccountInfo" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="info-panel">
                            <div class="d-flex flex-wrap justify-content-between align-items-center mb-4">
                                <div class="d-flex align-items-center gap-2">
                                    <i class="fas fa-user-circle text-primary fa-2x"></i>
                                    <h5 class="fw-bold mb-0">Account Information</h5>
                                </div>
                                <div class="btn-group">
                                    <asp:Button ID="btnEditAccount" runat="server" Text="Edit Profile" OnClick="btnEditAccount_Click" CssClass="btn btn-outline-primary btn-sm" />
                                    <asp:Button ID="btnSaveAccount" runat="server" Text="Save Changes" Visible="false" OnClick="btnSaveAccount_Click" CssClass="btn btn-primary btn-sm" />
                                    <asp:Button ID="btnCancelAccount" runat="server" Text="Cancel" Visible="false" OnClick="btnCancelAccount_Click" CssClass="btn btn-secondary btn-sm" />
                                </div>
                            </div>

                            <div class="row g-3">
                                <div class="row g-3">
                                    <asp:Panel ID="pnlFirstName" runat="server" CssClass="col-md-6">
                                        <label class="form-label small fw-bold text-muted text-uppercase">First Name</label>
                                        <asp:TextBox ID="txtFirstName" runat="server" TextMode="MultiLine" Rows="1" CssClass="readonly-textbox"></asp:TextBox>
                                    </asp:Panel>

                                    <asp:Panel ID="pnlMiddleName" runat="server" CssClass="col-md-6">
                                        <label class="form-label small fw-bold text-muted text-uppercase">Middle Name</label>
                                        <asp:TextBox ID="txtMiddleName" runat="server" TextMode="MultiLine" Rows="1" CssClass="readonly-textbox"></asp:TextBox>
                                    </asp:Panel>

                                    <asp:Panel ID="pnlLastName" runat="server" CssClass="col-md-6">
                                        <label class="form-label small fw-bold text-muted text-uppercase">Last Name</label>
                                        <asp:TextBox ID="txtLastName" runat="server" TextMode="MultiLine" Rows="1" CssClass="readonly-textbox"></asp:TextBox>
                                    </asp:Panel>

                                    <asp:Panel ID="pnlExtensionName" runat="server" CssClass="col-md-6">
                                        <label class="form-label small fw-bold text-muted text-uppercase">Extension Name</label>
                                        <asp:TextBox ID="txtExtension" runat="server" TextMode="SingleLine" Rows="1" CssClass="readonly-textbox" placeholder="Jr., Sr., III"></asp:TextBox>
                                    </asp:Panel>

                                    <asp:Panel ID="pnlGender" runat="server" CssClass="col-md-6">
                                        <label class="form-label small fw-bold text-muted text-uppercase">Gender</label>
                                        <asp:TextBox ID="txtGender" runat="server" TextMode="SingleLine" CssClass="readonly-textbox"></asp:TextBox>
                                    </asp:Panel>

                                    <asp:Panel ID="pnlMobileNumber" runat="server" CssClass="col-md-6">
                                        <label class="form-label small fw-bold text-muted text-uppercase">Mobile Number</label>
                                        <asp:TextBox ID="txtMobile" runat="server" TextMode="SingleLine" MaxLength="11" CssClass="readonly-textbox"></asp:TextBox>
                                    </asp:Panel>

                                    <asp:Panel ID="pnlUserID" runat="server" CssClass="col-md-6">
                                        <label class="form-label small fw-bold text-muted text-uppercase">User ID</label>
                                        <asp:TextBox ID="txtStudentID" runat="server" ReadOnly="true" CssClass="readonly-textbox"></asp:TextBox>
                                    </asp:Panel>

                                    <asp:Panel ID="pnlInstitutionalEmail" runat="server" CssClass="col-md-6">
                                        <label class="form-label small fw-bold text-muted text-uppercase">Institutional Email</label>
                                        <asp:TextBox ID="txtEmail" runat="server" ReadOnly="true" TextMode="MultiLine" Rows="1" CssClass="readonly-textbox"></asp:TextBox>
                                    </asp:Panel>

                                    <asp:Panel ID="pnlDepartment" runat="server" CssClass="col-md-6">
                                        <label class="form-label small fw-bold text-muted text-uppercase">Department / Institute</label>
                                        <asp:TextBox ID="txtDepartment" runat="server" TextMode="MultiLine" Rows="2" CssClass="readonly-textbox"></asp:TextBox>
                                    </asp:Panel>

                                    <asp:Panel ID="pnlCourseYear" runat="server" CssClass="col-md-6">
                                        <label class="form-label small fw-bold text-muted text-uppercase">Course & Year</label>
                                        <asp:TextBox ID="txtCourse" runat="server" TextMode="MultiLine" Rows="2" CssClass="readonly-textbox"></asp:TextBox>
                                    </asp:Panel>

                                    <asp:Panel ID="pnlHomeAddress" runat="server" CssClass="col-12">
                                        <label class="form-label small fw-bold text-muted text-uppercase">Home Address</label>
                                        <asp:TextBox ID="txtAddress" runat="server" TextMode="MultiLine" Rows="2" CssClass="readonly-textbox"></asp:TextBox>
                                    </asp:Panel>
                                </div>
                            </div>
                        </div>
                    </ContentTemplate>
                </asp:UpdatePanel>

                <!-- Emergency Contact Panel -->
                <asp:UpdatePanel ID="upEmergencyContact" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="info-panel">
                            <div class="d-flex flex-wrap justify-content-between align-items-center mb-4">
                                <div class="d-flex align-items-center gap-2">
                                    <i class="fas fa-phone-alt text-danger fa-2x"></i>
                                    <h5 class="fw-bold mb-0">Emergency Contact</h5>
                                </div>
                                <div class="btn-group">
                                    <asp:Button ID="btnEditEmergency" runat="server" Text="Edit Contact" OnClick="btnEditEmergency_Click" CssClass="btn btn-outline-primary btn-sm" />
                                    <asp:Button ID="btnSaveEmergency" runat="server" Text="Save Changes" Visible="false" OnClick="btnSaveEmergency_Click" CssClass="btn btn-primary btn-sm" />
                                    <asp:Button ID="btnCancelEmergency" runat="server" Text="Cancel" Visible="false" OnClick="btnCancelEmergency_Click" CssClass="btn btn-secondary btn-sm" />
                                </div>
                            </div>

                            <div class="row g-3">
                                <div class="col-md-6">
                                    <label class="form-label small fw-bold text-muted text-uppercase">Guardian Name</label>
                                    <asp:TextBox ID="txtGuardianName" runat="server" TextMode="MultiLine" Rows="1" CssClass="readonly-textbox"></asp:TextBox>
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label small fw-bold text-muted text-uppercase">Relationship</label>
                                    <asp:TextBox ID="txtGuardianRel" runat="server" TextMode="MultiLine" Rows="1" CssClass="readonly-textbox"></asp:TextBox>
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label small fw-bold text-muted text-uppercase">Contact Number</label>
                                    <asp:TextBox ID="txtGuardianContact" runat="server" TextMode="MultiLine" Rows="1" CssClass="readonly-textbox"></asp:TextBox>
                                </div>
                            </div>
                        </div>
                    </ContentTemplate>
                </asp:UpdatePanel>
            </div>
        </div>
    </div>

    <script src="<%= ResolveUrl("~/Assets/Vendor/qrcode-generator/1.4.4/qrcode.js") %>"></script>
    <script type="text/javascript">
        // ============================================
        // 1. SWEETALERT FOR SERVER-SIDE MESSAGES
        // ============================================
        function showSweetAlert(title, message, icon) {
            Swal.fire({
                title: title,
                text: message,
                icon: icon,
                confirmButtonColor: '#1e3a8a'
            });
        }

        // ============================================
        // 2. REATTACH BUTTON ICONS AFTER POSTBACK (if needed)
        // ============================================
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            // Icons are already in markup, no extra action needed
        });

        // ============================================
        // 2b. LOCAL QR RENDERING (no external service; works offline)
        // Encodes the same value (the user ID) the old web-service QR encoded.
        // ============================================
        function renderLocalQr() {
            var img = document.getElementById('<%= imgQRCode.ClientID %>');
            if (!img || typeof qrcode !== 'function') return;
            var value = img.getAttribute('data-qr-value');
            if (!value || img.getAttribute('data-qr-done') === value) return;
            try {
                var qr = qrcode(0, 'M');
                qr.addData(value);
                qr.make();
                var n = qr.getModuleCount(), margin = 4, scale = 10;
                var size = (n + margin * 2) * scale;
                var canvas = document.createElement('canvas');
                canvas.width = canvas.height = size;
                var ctx = canvas.getContext('2d');
                ctx.fillStyle = '#ffffff';
                ctx.fillRect(0, 0, size, size);
                ctx.fillStyle = '#000000';
                for (var r = 0; r < n; r++)
                    for (var c = 0; c < n; c++)
                        if (qr.isDark(r, c))
                            ctx.fillRect((c + margin) * scale, (r + margin) * scale, scale, scale);
                img.src = canvas.toDataURL('image/png');
                img.setAttribute('data-qr-done', value);
            } catch (e) {
                console.error('QR render failed:', e);
            }
        }
        document.addEventListener('DOMContentLoaded', renderLocalQr);
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(renderLocalQr);

        // ============================================
        // 3. QR CODE DOWNLOAD FUNCTIONALITY
        // ============================================
        function downloadQR() {
            var img = document.getElementById('<%= imgQRCode.ClientID %>');
            if (!img || !img.src) {
                Swal.fire('Error', 'QR image not found.', 'error');
                return;
            }

            var imageUrl = img.src;
            var userIdEl = document.getElementById('userIdDisplay');
            var userId = userIdEl ? userIdEl.innerText.trim() : 'User';

            // Show a loading indicator (optional)
            Swal.fire({
                title: 'Preparing Download...',
                allowOutsideClick: false,
                didOpen: () => { Swal.showLoading(); }
            });

            // Use fetch to get the image as a binary blob (bypasses CORS download block)
            fetch(imageUrl)
                .then(response => {
                    if (!response.ok) throw new Error('Network response was not ok');
                    return response.blob();
                })
                .then(blob => {
                    // Create a temporary local URL for the blob
                    var blobUrl = window.URL.createObjectURL(blob);

                    // Create a temporary anchor tag to trigger the download
                    var link = document.createElement('a');
                    link.href = blobUrl;
                    link.download = 'DigitalID_' + userId + '.png';

                    // Append, click, and remove
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);

                    // Clean up the memory
                    window.URL.revokeObjectURL(blobUrl);

                    // Close the loading alert
                    Swal.close();
                })
                .catch(error => {
                    console.error('Error downloading QR:', error);
                    Swal.fire('Download Failed', 'Could not download the QR code. Please try again.', 'error');
                });
        }
    </script>
</asp:Content>
