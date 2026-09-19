<%@ Page Title="My Borrowing History" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="History.aspx.cs" Inherits="spmst_lms_development.Users.Patron.History.History" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        /* ============================================
           1. GLOBAL & UTILITY
           ============================================ */
        body {
            background-color: #f8fafc;
        }
        .stats-card {
            background: white;
            border-radius: 1rem;
            padding: 1rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
            border: 1px solid #e9ecef;
            transition: transform 0.2s;
        }
        .stats-card:hover {
            transform: translateY(-2px);
        }

        /* ============================================
           2. STATUS BADGES
           ============================================ */
        .status-overdue {
            background-color: #fee2e2;
            color: #dc2626;
            border: 1px solid #fecaca;
        }
        .status-borrowed {
            background-color: #dbeafe;
            color: #2563eb;
            border: 1px solid #bfdbfe;
        }
        .status-returned {
            background-color: #f3f4f6;
            color: #4b5563;
            border: 1px solid #e5e7eb;
        }
        .status-renewal {
            background-color: #fef3c7;
            color: #d97706;
            border: 1px solid #fde68a;
        }

        /* ============================================
           3. BOOK COVER PLACEHOLDER
           ============================================ */
        .book-cover {
            width: 48px;
            height: 64px;
            border-radius: 0.25rem;
            background-color: #1e293b;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            box-shadow: 0 1px 2px rgba(0,0,0,0.05);
        }
        .book-cover.code, .book-cover.journal {
            background-color: #f97316;
        }

        /* ============================================
           4. TABLE / ROW STYLES
           ============================================ */
        .history-header {
            background-color: #0d6efd;
            color: white;
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 0.75rem 1rem;
        }
        .history-row {
            padding: 1rem;
            border-bottom: 1px solid #e9ecef;
            transition: background-color 0.2s;
        }
        .history-row:hover {
            background-color: #f8f9fa;
        }
        .due-date-overdue {
            color: #dc3545;
            font-weight: 700;
        }
        .due-date-normal {
            color: #212529;
        }
        .due-date-returned {
            color: #6c757d;
        }

        /* ============================================
           5. SIDEBAR GUIDELINES
           ============================================ */
        .guidelines-card {
            background-color: #f8f9fa;
            border-radius: 1rem;
            padding: 1rem;
            border: 1px solid #e9ecef;
        }
        .guidelines-card h6 {
            font-weight: 700;
            margin-bottom: 0.75rem;
            padding-bottom: 0.5rem;
            border-bottom: 1px solid #dee2e6;
        }
        .guideline-item {
            display: flex;
            gap: 0.75rem;
            margin-bottom: 1rem;
            font-size: 0.85rem;
        }
        .guideline-icon {
            width: 1.25rem;
            height: 1.25rem;
            flex-shrink: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
            font-weight: 700;
            background-color: white;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container py-4">
        <!-- Header -->
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
            <div>
                <h1 class="h2 fw-bold">My Borrowing <span class="text-primary">History</span></h1>
                <p class="text-muted">Keep track of your current loans and past academic readings.</p>
            </div>
            <div class="d-flex gap-3">
                <div class="stats-card text-center bg-primary text-white">
                    <div class="small fw-bold text-white-50">Active Loans</div>
                    <div class="h3 fw-bold mb-0"><asp:Literal ID="litTopActive" runat="server">0</asp:Literal></div>
                </div>
                <div class="stats-card text-center bg-danger text-white">
                    <div class="small fw-bold text-white-50">Overdue</div>
                    <div class="h3 fw-bold mb-0"><asp:Literal ID="litTopOverdue" runat="server">0</asp:Literal></div>
                </div>
            </div>
        </div>

        <!-- Summary Cards -->
        <div class="row g-4 mb-4">
            <div class="col-md-4">
                <div class="stats-card">
                    <div class="small text-muted text-uppercase fw-bold">Active Loans</div>
                    <div class="display-6 fw-bold"><asp:Literal ID="litCardActive" runat="server">0</asp:Literal></div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="stats-card border-danger">
                    <div class="small text-danger text-uppercase fw-bold">Pending Fines (Pay at counter)</div>
                    <div class="display-6 fw-bold text-danger">₱<asp:Literal ID="litCardFines" runat="server">0.00</asp:Literal></div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="stats-card">
                    <div class="small text-muted text-uppercase fw-bold">Returned This Semester</div>
                    <div class="display-6 fw-bold"><asp:Literal ID="litCardReturned" runat="server">0</asp:Literal></div>
                </div>
            </div>
        </div>

        <!-- Main Content: History Table + Guidelines -->
        <div class="row g-4">
            <div class="col-lg-8">
                <div class="card shadow-sm border-0 rounded-4 overflow-hidden">
                    <div class="history-header">
                        <div class="row">
                            <div class="col-5">Book Details</div>
                            <div class="col-3">Due Date</div>
                            <div class="col-2">Type</div>
                            <div class="col-2">Actions</div>
                        </div>
                    </div>
                    <asp:UpdatePanel ID="upHistory" runat="server" UpdateMode="Conditional">
                        <ContentTemplate>
                            <div class="divide-y divide-gray-100">
                                <asp:Repeater ID="rptHistory" runat="server" OnItemCommand="rptHistory_ItemCommand">
                                    <ItemTemplate>
                                        <div class="history-row">
                                            <div class="row align-items-center">
                                                <!-- Book Details -->
                                                <div class="col-5 d-flex gap-3 align-items-start">
                                                    <div class='book-cover <%# GetBookCoverClass(Eval("item_type").ToString()) %>'>
                                                        <i class="fas fa-book"></i>
                                                    </div>
                                                    <div>
                                                        <h6 class="fw-bold mb-0"><%# Eval("title") %></h6>
                                                        <p class="small text-muted mb-0">Acc: <%# Eval("accession_number") %></p>
                                                    </div>
                                                </div>
                                                <!-- Due Date -->
                                                <div class="col-3">
                                                    <div class='<%# GetDueDateClass(Eval("status").ToString(), Eval("due_date")) %>'>
                                                        <%# Convert.ToDateTime(Eval("due_date")).ToString("MMM d, yyyy") %>
                                                    </div>
                                                    <div class="small text-muted">
                                                        <%# GetDueDateSubtext(Eval("status").ToString(), Eval("due_date")) %>
                                                    </div>
                                                </div>
                                                <!-- Type -->
                                                <div class="col-2">
                                                    <span class="badge bg-light text-dark"><%# Eval("item_type") %></span>
                                                </div>
                                                <!-- Actions -->
                                                <div class="col-2 text-end">
                                                    <asp:LinkButton ID="btnRenew" runat="server"
                                                        CommandName="RenewBook" CommandArgument='<%# Eval("transaction_id") %>'
                                                        Visible='<%# Eval("status").ToString() == "Borrowed" %>'
                                                        CssClass="btn btn-sm btn-outline-primary me-2"
                                                        ToolTip="Request Renewal">
                                                        <i class="fas fa-sync-alt"></i>
                                                    </asp:LinkButton>
                                                    <asp:LinkButton ID="btnView" runat="server"
                                                        CommandName="ViewInfo" CommandArgument='<%# Eval("accession_number") %>'
                                                        CssClass="btn btn-sm btn-outline-secondary"
                                                        ToolTip="View Book Details">
                                                        <i class="fas fa-eye"></i>
                                                    </asp:LinkButton>
                                                </div>
                                            </div>
                                            <div class="mt-2">
                                                <span class='badge <%# GetStatusCssClass(Eval("status").ToString()) %>'>
                                                    <%# Eval("status") %>
                                                </span>
                                                <%# GetStatusSubtext(Eval("status").ToString(), Eval("balance")) %>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                    <FooterTemplate>
                                        <asp:PlaceHolder ID="phEmpty" runat="server" Visible='<%# rptHistory.Items.Count == 0 %>'>
                                            <div class="text-center py-5 text-muted">No borrowing history found.</div>
                                        </asp:PlaceHolder>
                                    </FooterTemplate>
                                </asp:Repeater>
                            </div>
                        </ContentTemplate>
                    </asp:UpdatePanel>
                </div>
            </div>

            <!-- Guidelines Sidebar -->
            <div class="col-lg-4">
                <div class="guidelines-card">
                    <h6><i class="fas fa-info-circle me-2"></i> Borrowing Guidelines</h6>
                    <div class="guideline-item">
                        <div class="guideline-icon bg-primary text-white">i</div>
                        <p class="mb-0">The standard borrowing period is <strong>3 days</strong> from the date of checkout.</p>
                    </div>
                    <div class="guideline-item">
                        <div class="guideline-icon bg-success text-white">↻</div>
                        <p class="mb-0">You may <strong>renew up to 2 times</strong> if there are no pending reservations.</p>
                    </div>
                    <div class="guideline-item">
                        <div class="guideline-icon bg-warning text-dark">!</div>
                        <p class="mb-0">Books marked as <strong>Due Soon</strong> are within 3 days of their due date.</p>
                    </div>
                    <div class="guideline-item">
                        <div class="guideline-icon bg-danger text-white">!</div>
                        <p class="mb-0">Books marked as <strong>Overdue</strong> have passed their due date. Please return immediately.</p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        // ============================================
        // 1. SWEETALERT CONFIRM FOR RENEWAL
        // ============================================
        function confirmRenewal(bookTitle) {
            Swal.fire({
                title: 'Request Renewal',
                text: `Are you sure you want to request a renewal for "${bookTitle}"?`,
                icon: 'question',
                showCancelButton: true,
                confirmButtonColor: '#0d6efd',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, request',
                cancelButtonText: 'Cancel'
            }).then((result) => {
                if (result.isConfirmed) {
                    // The button's command will be processed by the server
                    const btn = document.activeElement;
                    if (btn && btn.id) {
                        __doPostBack(btn.id, '');
                    }
                }
            });
            return false;
        }

        // ============================================
        // 2. SWEETALERT FOR SERVER MESSAGES
        // ============================================
        function showSweetAlert(title, message, icon) {
            Swal.fire({ title: title, text: message, icon: icon, confirmButtonColor: '#0d6efd' });
        }
    </script>
</asp:Content>