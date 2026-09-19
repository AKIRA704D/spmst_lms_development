<%@ Page Title="My Reservations" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="ToPickUp.aspx.cs" Inherits="spmst_lms_development.Users.Patron.Reservations.ToPickUp" %>

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

        /* ============================================
           2. SUMMARY CARDS
           ============================================ */
        .summary-card {
            background: white;
            border: 1px solid #e2e8f0;
            border-radius: 0.75rem;
            padding: 1rem;
            position: relative;
            overflow: hidden;
            transition: transform 0.2s;
        }
        .summary-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        }
        .summary-card-title {
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #6c757d;
            margin-bottom: 0.5rem;
        }
        .summary-card-value {
            font-size: 1.8rem;
            font-weight: 800;
            line-height: 1;
        }
        .card-accent {
            position: absolute;
            right: 0;
            top: 0;
            width: 6px;
            height: 100%;
        }
        .accent-blue { background-color: #0d6efd; }
        .accent-yellow { background-color: #ffc107; }

        /* ============================================
           3. RESERVATION TABLE / ROWS
           ============================================ */
        .reservation-row {
            display: flex;
            flex-wrap: wrap;
            gap: 1rem;
            padding: 1rem;
            border-bottom: 1px solid #e9ecef;
            transition: background-color 0.2s;
        }
        .reservation-row:hover {
            background-color: #f8f9fa;
        }
        .book-icon {
            width: 40px;
            height: 52px;
            background-color: #1e3a8a;
            border-radius: 0.25rem;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            box-shadow: 0 1px 2px rgba(0,0,0,0.05);
        }
        .deadline-time {
            font-size: 0.7rem;
            color: #dc3545;
            font-weight: 600;
        }
        .status-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            font-size: 0.7rem;
            font-weight: 700;
            border-radius: 2rem;
            text-transform: uppercase;
        }
        .status-ready {
            background-color: #d1e7dd;
            color: #0f5132;
        }
        .status-processing {
            background-color: #fff3cd;
            color: #856404;
        }

        /* ============================================
           4. RESPONSIVE OVERRIDES
           ============================================ */
        @media (min-width: 768px) {
            .reservation-row {
                flex-wrap: nowrap;
                align-items: center;
            }
            .reservation-row > div {
                flex: 1;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container py-4">
        <!-- Header -->
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
            <div>
                <h1 class="h2 fw-bold text-primary">My Book Reservations</h1>
                <p class="text-muted">Track your reserved books and pickup deadlines.</p>
            </div>
        </div>

        <!-- Summary Cards -->
        <div class="row g-4 mb-5">
            <div class="col-md-6">
                <div class="summary-card">
                    <div class="card-accent accent-blue"></div>
                    <h6 class="summary-card-title"><i class="fas fa-check-circle me-1"></i> Ready For Pickup</h6>
                    <div class="summary-card-value text-primary"><asp:Literal ID="litReadyCount" runat="server" Text="0" /></div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="summary-card">
                    <div class="card-accent accent-yellow"></div>
                    <h6 class="summary-card-title"><i class="fas fa-clock me-1"></i> Processing</h6>
                    <div class="summary-card-value text-warning"><asp:Literal ID="litProcessingCount" runat="server" Text="0" /></div>
                </div>
            </div>
        </div>

        <!-- Reservations Table -->
        <div class="card shadow-sm border-0 rounded-4 overflow-hidden">
            <div class="card-header bg-white border-0 pt-3">
                <h5 class="fw-bold mb-0"><i class="fas fa-bookmark me-2 text-primary"></i> Active Reservations</h5>
            </div>
            <div class="card-body p-0">
                <asp:Repeater ID="rptReservations" runat="server" OnItemCommand="rptReservations_ItemCommand">
                    <ItemTemplate>
                        <div class="reservation-row">
                            <!-- Book Details -->
                            <div class="d-flex gap-3 align-items-center" style="flex: 2;">
                                <div class="book-icon"><i class="fas fa-book"></i></div>
                                <div>
                                    <h6 class="fw-bold mb-0"><%# Eval("Title") %></h6>
                                    <p class="small text-muted mb-0">by <%# Eval("Author") %></p>
                                </div>
                            </div>
                            <!-- Reserved On -->
                            <div>
                                <span class="small text-muted d-md-none">Reserved On: </span>
                                <span><%# Convert.ToDateTime(Eval("ReservedDate")).ToString("MMM dd, yyyy") %></span>
                            </div>
                            <!-- Status -->
                            <div>
                                <span class="small text-muted d-md-none">Status: </span>
                                <span class="status-badge <%# GetStatusCss(Eval("Status").ToString()) %>">
                                    <%# Eval("Status").ToString() == "Ready" ? "Ready for Pickup" : "Processing" %>
                                </span>
                            </div>
                            <!-- Deadline -->
                            <div>
                                <span class="small text-muted d-md-none">Deadline: </span>
                                <div>
                                    <span class="fw-semibold"><%# GetDeadlineDate(Eval("Status").ToString(), Eval("DeadlineDate")) %></span>
                                    <div class="deadline-time"><%# GetDeadlineTime(Eval("Status").ToString()) %></div>
                                </div>
                            </div>
                            <!-- Action -->
                            <div>
                                <asp:Button ID="btnCancel" runat="server"
                                    CommandName="CancelReservation"
                                    CommandArgument='<%# Eval("TransactionID") + "|" + Eval("AccessionNumber") + "|" + Eval("Title") %>'
                                    Text="Cancel Request"
                                    CssClass="btn btn-sm btn-outline-danger"
                                    OnClientClick='<%# "return confirmCancel(\"" + Eval("Title") + "\");" %>' />
                            </div>
                        </div>
                    </ItemTemplate>
                    <FooterTemplate>
                        <asp:PlaceHolder ID="phEmpty" runat="server" Visible='<%# rptReservations.Items.Count == 0 %>'>
                            <div class="text-center py-5">
                                <i class="fas fa-book-open fa-3x text-muted mb-3"></i>
                                <p class="text-muted">You have no active book reservations at this time.</p>
                            </div>
                        </asp:PlaceHolder>
                    </FooterTemplate>
                </asp:Repeater>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        // ============================================
        // 1. CONFIRM CANCEL (SweetAlert)
        // ============================================
        function confirmCancel(bookTitle) {
            Swal.fire({
                title: 'Cancel Reservation',
                text: `Are you sure you want to cancel your reservation for "${bookTitle}"?`,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#dc3545',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, cancel it',
                cancelButtonText: 'No, keep it'
            }).then((result) => {
                if (result.isConfirmed) {
                    // Find the button that triggered the click and trigger its postback
                    const btn = document.activeElement;
                    if (btn && btn.id) {
                        __doPostBack(btn.id, '');
                    }
                }
            });
            return false;
        }

        // ============================================
        // 2. SWEETALERT FOR SERVER-SIDE MESSAGES
        // ============================================
        function showSweetAlert(title, message, icon) {
            Swal.fire({ title: title, text: message, icon: icon, confirmButtonColor: '#0d6efd' });
        }
    </script>
</asp:Content>