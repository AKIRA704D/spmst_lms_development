<%@ Page Title="Notifications" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="Notifications.aspx.cs" Inherits="spmst_lms_development.Users.Patron.Notifications.Notifications" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        /* ============================================
           1. NOTIFICATION CARD STYLES
           ============================================ */
        .notification-item {
            transition: all 0.2s ease;
            border-radius: 1.5rem;
        }
        .notification-item:hover {
            transform: translateX(4px);
        }
        .notification-unread {
            background: linear-gradient(135deg, #ffffff 0%, #eef2ff 100%);
            border-left: 4px solid #0d6efd;
        }
        .notification-read {
            opacity: 0.75;
            background: #ffffff;
        }

        /* ============================================
           2. ICON & BADGE STYLES
           ============================================ */
        .notif-icon {
            width: 56px;
            height: 56px;
            border-radius: 1rem;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
        }
        .notif-icon-danger { background-color: #fee2e2; color: #dc2626; }
        .notif-icon-success { background-color: #d1fae5; color: #059669; }
        .notif-icon-info { background-color: #dbeafe; color: #2563eb; }
        .badge-danger { background-color: #fee2e2; color: #dc2626; }
        .badge-success { background-color: #d1fae5; color: #059669; }
        .badge-info { background-color: #dbeafe; color: #2563eb; }

        /* ============================================
           3. FILTER SIDEBAR (Vertical Pills)
           ============================================ */
        .filter-pill {
            display: block;
            width: 100%;
            text-align: left;
            padding: 0.75rem 1rem;
            border-radius: 0.75rem;
            font-weight: 600;
            transition: all 0.2s;
            color: #6c757d;
            background: transparent;
            border: none;
        }
        .filter-pill:hover {
            background-color: #f8f9fa;
            color: #0d6efd;
        }
        .filter-pill.active {
            background-color: #0d6efd;
            color: white;
            box-shadow: 0 4px 10px rgba(13,110,253,0.2);
        }
        .filter-pill i {
            width: 24px;
            margin-right: 10px;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid py-4">
        <div class="container-lg">
            <!-- Header -->
            <div class="d-flex flex-wrap justify-content-between align-items-center mb-4">
                <div>
                    <h1 class="h2 fw-bold">
                        <i class="fas fa-bell text-primary me-2"></i>
                        My <span class="text-primary">Notifications</span>
                    </h1>
                    <p class="text-muted">Stay updated with your library activities and announcements.</p>
                </div>
                <asp:LinkButton ID="btnMarkAllRead" runat="server" OnClick="MarkAllRead_Click" 
                    CssClass="btn btn-outline-primary rounded-pill px-4">
                    <i class="fas fa-check-double me-2"></i> Mark All as Read
                </asp:LinkButton>
            </div>

            <div class="row g-4">
                <!-- Filter Sidebar (Left Column) -->
                <div class="col-md-3">
                    <div class="card shadow-sm border-0 rounded-4 sticky-top" style="top: 1rem;">
                        <div class="card-body p-3">
                            <h6 class="text-muted text-uppercase small fw-bold mb-3">
                                <i class="fas fa-filter me-1"></i> Filter by Type
                            </h6>
                            <div class="d-flex flex-column gap-2">
                                <asp:LinkButton ID="btnFilterAll" runat="server" OnClick="Filter_Click" CommandArgument="All" 
                                    CssClass="filter-pill active">
                                    <i class="fas fa-bell"></i> All Notifications
                                </asp:LinkButton>
                                <asp:LinkButton ID="btnFilterDue" runat="server" OnClick="Filter_Click" CommandArgument="Due Date" 
                                    CssClass="filter-pill">
                                    <i class="fas fa-calendar-times"></i> Due Dates
                                </asp:LinkButton>
                                <asp:LinkButton ID="btnFilterRes" runat="server" OnClick="Filter_Click" CommandArgument="Reservation" 
                                    CssClass="filter-pill">
                                    <i class="fas fa-bookmark"></i> Reservations
                                </asp:LinkButton>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Notifications List (Right Column) -->
                <div class="col-md-9">
                    <asp:Repeater ID="rptNotifications" runat="server" OnItemCommand="rptNotifications_ItemCommand">
                        <ItemTemplate>
                            <div class='notification-item card mb-3 shadow-sm border-0 overflow-hidden
                                <%# Eval("is_read").ToString() == "0" ? "notification-unread" : "notification-read" %>'>
                                <div class="card-body p-4">
                                    <div class="d-flex gap-3">
                                        <!-- Icon -->
                                        <div class='notif-icon <%# GetIconBackground(Eval("title").ToString()) %>'>
                                            <i class='<%# GetIconClass(Eval("title").ToString()) %>'></i>
                                        </div>

                                        <!-- Content -->
                                        <div class="flex-grow-1">
                                            <div class="d-flex align-items-center gap-2 flex-wrap mb-1">
                                                <span class='badge rounded-pill px-2 py-1 <%# GetBadgeClass(Eval("title").ToString()) %>'>
                                                    <%# Eval("title").ToString().ToUpper() %>
                                                </span>
                                                <h5 class="fw-bold mb-0"><%# Eval("title") %></h5>
                                                <%# Eval("is_read").ToString() == "0" ? "<span class='badge bg-primary rounded-pill'>New</span>" : "" %>
                                            </div>
                                            <p class="text-muted mb-2"><%# Eval("message") %></p>
                                            <div class="d-flex gap-3 text-muted small">
                                                <div><i class="far fa-clock me-1"></i> <%# GetRelativeTime(Eval("created_at")) %></div>
                                                <%# Eval("is_read").ToString() == "0" ? "<div class='text-primary'><i class='fas fa-circle' style='font-size:6px;'></i> Unread</div>" : "" %>
                                            </div>
                                        </div>

                                        <!-- Action Button -->
                                        <div>
                                            <asp:LinkButton ID="btnView" runat="server" CommandName="View" CommandArgument='<%# Eval("notification_id") %>'
                                                CssClass="btn btn-light border rounded-circle d-flex align-items-center justify-content-center"
                                                style="width: 40px; height: 40px;">
                                                <i class="fas fa-eye text-primary"></i>
                                            </asp:LinkButton>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>

                    <!-- Empty State -->
                    <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="text-center py-5">
                        <i class="fas fa-bell-slash fa-4x text-muted mb-3"></i>
                        <p class="text-muted fw-bold">No notifications found</p>
                        <p class="text-muted small">You're all caught up!</p>
                    </asp:Panel>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        // ============================================
        // 1. SWEETALERT FOR SERVER-SIDE MESSAGES
        // ============================================
        function showSweetAlert(title, message, icon) {
            Swal.fire({
                title: title,
                text: message,
                icon: icon,
                confirmButtonColor: '#0d6efd'
            });
        }

        // ============================================
        // 2. REATTACH FILTER ACTIVE STATE AFTER POSTBACK
        // ============================================
        function setActiveFilterButton(activeId) {
            document.querySelectorAll('.filter-pill').forEach(btn => {
                btn.classList.remove('active');
            });
            const activeBtn = document.getElementById(activeId);
            if (activeBtn) activeBtn.classList.add('active');
        }

        // Handle UpdatePanel partial postback
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function() {
            // The active state is already set server-side, but we can re-apply if needed
        });
    </script>
</asp:Content>