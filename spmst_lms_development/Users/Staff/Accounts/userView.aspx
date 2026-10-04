<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="userView.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Accounts.userView" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Patron Profile | LMSA</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <style>
        html, body { margin: 0; padding: 0; background: transparent; }

        .form-shell { display: flex; flex-direction: column; min-height: 100vh; }

        .header-bar {
            position: sticky; top: 0; z-index: 20;
            background-color: #002447 !important;
        }
        .header-bar small { color: #8fb0d0; }

        .footer-bar {
            position: sticky; bottom: 0; z-index: 20;
            background: #fff;
        }

        .form-section {
            border-left: 4px solid #ffc107;
            background: #f8f9fa;
            padding: 0.75rem 1rem;
            margin-bottom: 1.5rem;
        }
        .form-section h6 {
            font-size: 0.7rem; font-weight: 800;
            text-transform: uppercase; letter-spacing: 1px;
            color: #002447; margin: 0;
        }

        .btn-custom-primary { background-color: #002447; border: none; color: #fff; }
        .btn-custom-primary:hover { background-color: #001a33; color: #fff; }

        /* ---------- Profile hero ---------- */
        .profile-hero {
            background: #fff;
            border-radius: 14px;
            box-shadow: 0 6px 22px rgba(0, 36, 71, 0.08);
            padding: 1.75rem;
            border-left: 4px solid #ffc107;
            display: flex;
            align-items: center;
            gap: 1.75rem;
            margin-bottom: 1.75rem;
            flex-wrap: wrap;
        }

        .profile-photo-wrapper {
            width: 130px; height: 130px;
            border-radius: 50%;
            overflow: hidden;
            border: 3px solid #002447;
            background: #f8f9fa;
            display: flex; align-items: center; justify-content: center;
            box-shadow: 0 6px 18px rgba(0, 36, 71, 0.18);
            flex-shrink: 0;
            color: #002447;
            font-size: 2.75rem; font-weight: 800;
            text-transform: uppercase; letter-spacing: 1px;
            font-family: 'Segoe UI', sans-serif;
        }
        .profile-photo-wrapper img {
            width: 100%; height: 100%;
            object-fit: cover; display: block;
        }

        .profile-meta { flex: 1; min-width: 220px; }
        .profile-name {
            font-size: 1.55rem; font-weight: 800;
            color: #002447; margin: 0 0 0.6rem 0;
            text-transform: uppercase; line-height: 1.15;
            word-break: break-word;
        }

        .badge-role {
            display: inline-flex; align-items: center;
            background: #002447; color: #fff;
            font-size: 0.68rem; font-weight: 700;
            text-transform: uppercase; letter-spacing: 1px;
            padding: 0.35rem 0.75rem; border-radius: 999px;
        }
        .badge-id {
            display: inline-flex; align-items: center;
            background: #fff8e1; color: #8a6d00;
            border: 1px solid #ffe082;
            font-size: 0.68rem; font-weight: 700;
            letter-spacing: 0.5px;
            padding: 0.35rem 0.75rem; border-radius: 999px;
        }
        .status-badge {
            display: inline-flex; align-items: center;
            font-size: 0.68rem; font-weight: 800;
            text-transform: uppercase; letter-spacing: 1px;
            padding: 0.35rem 0.75rem; border-radius: 999px;
        }
        .status-badge.active      { background: #d1fae5; color: #065f46; }
        .status-badge.deactivated { background: #fee2e2; color: #991b1b; }
        .status-badge.inactive    { background: #fef3c7; color: #92400e; }

        /* ---------- Info cards ---------- */
        .info-card {
            background: #fff;
            border-radius: 12px;
            padding: 1.35rem 1.5rem;
            box-shadow: 0 3px 12px rgba(0, 0, 0, 0.04);
            margin-bottom: 1.75rem;
        }
        .info-label {
            display: block;
            font-size: 0.65rem; font-weight: 800;
            color: #adb5bd; text-transform: uppercase;
            letter-spacing: 1px; margin-bottom: 0.3rem;
        }
        .info-value {
            color: #1f2937; font-weight: 600;
            font-size: 0.92rem; word-break: break-word;
            display: inline-block;
        }
        .info-value.text-uppercase { text-transform: uppercase; }
        .info-value.text-capitalize { text-transform: capitalize; }
        .info-value.info-value-email { color: #002447; }

        /* ---------- Borrowing history ---------- */
        .history-table {
            width: 100%; border-collapse: collapse;
            background: #fff; border-radius: 12px; overflow: hidden;
            box-shadow: 0 3px 12px rgba(0, 0, 0, 0.04);
        }
        .history-table thead th {
            background: #002447; color: #fff;
            font-size: 0.65rem; font-weight: 800;
            text-transform: uppercase; letter-spacing: 1px;
            padding: 0.9rem 1rem; text-align: left;
            white-space: nowrap;
        }
        .history-table thead th.text-center { text-align: center; }
        .history-table tbody td {
            padding: 0.9rem 1rem; font-size: 0.85rem;
            color: #495057; border-bottom: 1px solid #f1f3f5;
            vertical-align: middle;
        }
        .history-table tbody tr:last-child td { border-bottom: none; }
        .history-table tbody tr:hover { background: #f8f9fa; }

        .book-title {
            font-weight: 700; color: #002447;
            text-transform: uppercase; font-size: 0.8rem;
            line-height: 1.25; margin: 0;
        }
        .book-isbn {
            font-size: 0.68rem; color: #adb5bd;
            font-style: italic; margin: 0.15rem 0 0 0;
        }

        .status-pill {
            display: inline-block;
            font-size: 0.65rem; font-weight: 800;
            text-transform: uppercase; letter-spacing: 0.5px;
            padding: 0.3rem 0.7rem; border-radius: 999px;
            background: #f3f4f6; color: #374151;
        }
        .status-pill.returned { background: #d1fae5; color: #065f46; }
        .status-pill.overdue  { background: #fee2e2; color: #991b1b; }
        .status-pill.borrowed { background: #dbeafe; color: #1e40af; }
        .status-pill.renewed  { background: #ede9fe; color: #5b21b6; }
        .status-pill.renewal  { background: #fef3c7; color: #92400e; }
        .status-pill.reserved { background: #cffafe; color: #155e75; }
        .status-pill.ready    { background: #d1fae5; color: #065f46; }
        .status-pill.cancelled{ background: #f3f4f6; color: #374151; }

        .empty-state {
            padding: 2.75rem 1rem; text-align: center;
            background: #fff; border-radius: 12px;
            box-shadow: 0 3px 12px rgba(0, 0, 0, 0.04);
            color: #adb5bd;
        }
        .empty-state i {
            font-size: 2.5rem; color: #dee2e6;
            display: block; margin-bottom: 0.75rem;
        }
        .empty-state p {
            font-size: 0.72rem; font-weight: 800;
            text-transform: uppercase; letter-spacing: 1px;
            margin: 0;
        }

        /* ---------- Loader ---------- */
        #loader {
            position: fixed; inset: 0; z-index: 50;
            background: #fff;
            display: flex; flex-direction: column;
            align-items: center; justify-content: center;
        }
        #loader .spinner-border { color: #002447 !important; }
        #loader p {
            margin-top: 1rem;
            font-size: 0.7rem; font-weight: 800;
            color: #adb5bd;
            text-transform: uppercase; letter-spacing: 2px;
        }

        #mainContent { opacity: 0; transition: opacity 0.35s ease; }
        #mainContent.visible { opacity: 1; }
    </style>
    <script>
        function getStatusClass(status) {
            if (!status) return '';
            switch (String(status).toLowerCase()) {
                case 'returned': return 'returned';
                case 'overdue': return 'overdue';
                case 'borrowed': return 'borrowed';
                case 'renewed': return 'renewed';
                case 'renewal': return 'renewal';
                case 'reserved': return 'reserved';
                case 'ready': return 'ready';
                case 'cancelled': return 'cancelled';
                default: return '';
            }
        }

        function applyStatusBadges() {
            document.querySelectorAll('.status-pill[data-status]').forEach(function (el) {
                el.classList.add(getStatusClass(el.getAttribute('data-status')));
            });
        }

        function notifyParentResize() {
            try {
                if (window.parent && window.parent !== window &&
                    typeof window.parent.resizeModalIframe === 'function') {
                    window.parent.resizeModalIframe();
                }
            } catch (e) { /* ignore */ }
        }

        window.addEventListener('load', function () {
            setTimeout(function () {
                var loader = document.getElementById('loader');
                var main = document.getElementById('mainContent');
                if (loader) loader.style.display = 'none';
                if (main) main.classList.add('visible');
                applyStatusBadges();
                notifyParentResize();
            }, 200);
        });

        window.addEventListener('resize', notifyParentResize);
    </script>
</head>
<body>
    <div id="loader">
        <div class="spinner-border" role="status" style="width:3rem; height:3rem;"></div>
        <p>Fetching Profile...</p>
    </div>

    <form id="form1" runat="server" class="form-shell">
        <!-- ============ HEADER ============ -->
        <div class="header-bar text-white px-4 py-3 d-flex justify-content-between align-items-center">
            <div class="d-flex align-items-center gap-3">
                <div class="bg-warning rounded-circle d-flex align-items-center justify-content-center" style="width:40px; height:40px;">
                    <i class="fas fa-id-card text-dark"></i>
                </div>
                <div>
                    <h4 class="mb-0 fw-bold">Patron Profile</h4>
                    <small>View authenticated user details</small>
                </div>
            </div>
            <button type="button" class="btn-close btn-close-white" onclick="window.parent.closeUniversalModal()" aria-label="Close"></button>
        </div>

        <!-- ============ CONTENT ============ -->
        <div class="p-4 flex-grow-1" style="background:#f5f7fb;">
            <div class="container-fluid px-0">
                <div id="mainContent">

                    <!-- Profile Hero -->
                    <div class="profile-hero">
                        <div class="profile-photo-wrapper">
                            <asp:Literal ID="litAvatar" runat="server"></asp:Literal>
                        </div>
                        <div class="profile-meta">
                            <h2 class="profile-name">
                                <asp:Literal ID="litFullName" runat="server"></asp:Literal>
                            </h2>
                            <div class="d-flex flex-wrap align-items-center gap-2">
                                <span class="badge-role">
                                    <i class="fas fa-user-tag me-1"></i><asp:Literal ID="litRole" runat="server"></asp:Literal>
                                </span>
                                <span id="statusBadge" runat="server" class="status-badge">
                                    <asp:Literal ID="litStatus" runat="server"></asp:Literal>
                                </span>
                                <span class="badge-id">
                                    <i class="fas fa-id-badge me-1"></i><asp:Literal ID="litUserID" runat="server"></asp:Literal>
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- 1. Identity & Affiliation -->
                    <div class="form-section">
                        <h6><i class="fas fa-id-card me-2"></i>Identity &amp; Affiliation</h6>
                    </div>

                    <div class="info-card">
                        <div class="row g-4">
                            <div class="col-md-4">
                                <span class="info-label">ID Number</span>
                                <span class="info-value"><asp:Literal ID="litUserIDDetail" runat="server"></asp:Literal></span>
                            </div>

                            <asp:PlaceHolder ID="phAcademicInfo" runat="server" Visible="false">
                                <div class="col-md-4">
                                    <span class="info-label">Institute</span>
                                    <span class="info-value text-uppercase"><asp:Literal ID="litInstitute" runat="server"></asp:Literal></span>
                                </div>
                                <div class="col-md-4">
                                    <span class="info-label">Course &amp; Section</span>
                                    <span class="info-value text-uppercase">
                                        <asp:Literal ID="litCourse" runat="server"></asp:Literal>
                                        &nbsp;-&nbsp;
                                        <asp:Literal ID="litSection" runat="server"></asp:Literal>
                                    </span>
                                </div>
                                <div class="col-md-4">
                                    <span class="info-label">Year Level</span>
                                    <span class="info-value text-uppercase"><asp:Literal ID="litYear" runat="server"></asp:Literal></span>
                                </div>
                            </asp:PlaceHolder>

                            <asp:PlaceHolder ID="phStaffHeader" runat="server" Visible="false">
                                <div class="col-md-8">
                                    <span class="info-label">Office / Department</span>
                                    <span class="info-value text-uppercase"><asp:Literal ID="litDept" runat="server"></asp:Literal></span>
                                </div>
                            </asp:PlaceHolder>
                        </div>
                    </div>

                    <!-- 2. Contact Information -->
                    <div class="form-section">
                        <h6><i class="fas fa-address-book me-2"></i>Contact Information</h6>
                    </div>

                    <div class="info-card">
                        <div class="row g-4">
                            <div class="col-md-3">
                                <span class="info-label">Gender</span>
                                <span class="info-value text-capitalize"><asp:Literal ID="litGender" runat="server"></asp:Literal></span>
                            </div>
                            <div class="col-md-3">
                                <span class="info-label">Mobile Number</span>
                                <span class="info-value"><asp:Literal ID="litContact" runat="server"></asp:Literal></span>
                            </div>
                            <div class="col-md-6">
                                <span class="info-label">Institutional Email</span>
                                <span class="info-value info-value-email">
                                    <i class="fas fa-envelope me-1" style="font-size:0.75rem;"></i><asp:Literal ID="litEmail" runat="server"></asp:Literal>
                                </span>
                            </div>
                            <div class="col-12">
                                <span class="info-label">Address</span>
                                <span class="info-value"><asp:Literal ID="litAddress" runat="server"></asp:Literal></span>
                            </div>
                        </div>
                    </div>

                    <!-- 3. Recent Borrowing History -->
                    <div class="form-section">
                        <h6><i class="fas fa-history me-2"></i>Recent Borrowing History</h6>
                    </div>

                    <asp:PlaceHolder ID="phHistory" runat="server">
                        <div class="table-responsive">
                            <table class="history-table">
                                <thead>
                                    <tr>
                                        <th>Book Title</th>
                                        <th class="text-center">Borrowed</th>
                                        <th class="text-center">Due Date</th>
                                        <th class="text-center">Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <asp:Repeater ID="rptHistory" runat="server">
                                        <ItemTemplate>
                                            <tr>
                                                <td>
                                                    <p class="book-title"><%# Eval("BookTitle") %></p>
                                                    <p class="book-isbn"><%# Eval("ISBN") %></p>
                                                </td>
                                                <td class="text-center"><%# Convert.ToDateTime(Eval("DateBorrowed")).ToString("MMM dd, yyyy") %></td>
                                                <td class="text-center"><%# Convert.ToDateTime(Eval("DueDate")).ToString("MMM dd, yyyy") %></td>
                                                <td class="text-center">
                                                    <span class="status-pill" data-status='<%# Eval("Status") %>'><%# Eval("Status") %></span>
                                                </td>
                                            </tr>
                                        </ItemTemplate>
                                    </asp:Repeater>
                                </tbody>
                            </table>
                        </div>
                    </asp:PlaceHolder>

                    <asp:PlaceHolder ID="phNoHistory" runat="server" Visible="false">
                        <div class="empty-state">
                            <i class="fa-solid fa-book-open"></i>
                            <p>No transaction records found</p>
                        </div>
                    </asp:PlaceHolder>

                </div>
            </div>
        </div>

        <!-- ============ FOOTER ============ -->
        <div class="footer-bar border-top p-3 d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div style="color:#198754; font-size:0.7rem; font-style:italic; font-weight:600; letter-spacing:0.3px;">
                <i class="fas fa-shield-alt me-2"></i>AUTHENTICATED PROFILE &bull; LMSA SYSTEM
            </div>
            <button type="button" class="btn btn-custom-primary px-4" onclick="window.parent.closeUniversalModal()">
                <i class="fas fa-times me-2"></i>Close View
            </button>
        </div>
    </form>
</body>
</html>