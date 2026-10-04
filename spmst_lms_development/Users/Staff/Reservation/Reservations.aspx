<%@ Page Title="Reservations" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="Reservations.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Reservation.Reservations" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        /* ============================================
           1. GLOBAL & UTILITY
           ============================================ */
        body { background-color: #f8fafc; }
        .stats-card {
            background: white;
            border-radius: 1rem;
            padding: 1rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
            border: 1px solid #e9ecef;
            text-align: center;
        }
        .stats-card .label {
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            color: #6c757d;
        }
        .stats-card .value {
            font-size: 1.5rem;
            font-weight: 800;
            color: #0d6efd;
        }

        /* ============================================
           2. TABLE STYLES
           ============================================ */
        .res-table {
            width: 100%;
            border-collapse: collapse;
        }
        .res-table th {
            background-color: #f8f9fa;
            padding: 0.75rem 1rem;
            font-size: 0.75rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 1px solid #dee2e6;
        }
        .res-table td {
            padding: 1rem;
            border-bottom: 1px solid #e9ecef;
            vertical-align: middle;
        }
        .status-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 2rem;
            font-size: 0.7rem;
            font-weight: 700;
        }
        .status-pending {
            background-color: #fff3cd;
            color: #856404;
        }
        .status-ready {
            background-color: #d1e7dd;
            color: #0f5132;
        }
        .btn-action {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.25rem 0.75rem;
            border-radius: 0.375rem;
            font-size: 0.75rem;
            font-weight: 600;
            transition: all 0.2s;
        }
        .btn-action-ready {
            background-color: #cfe2ff;
            color: #0d6efd;
            border: 1px solid #9ec5fe;
        }
        .btn-action-pending {
            background-color: white;
            color: #495057;
            border: 1px solid #dee2e6;
        }
        .btn-action-pending:hover {
            background-color: #f8f9fa;
        }

        /* ============================================
           3. EXPIRING CARD
           ============================================ */
        .expiring-card {
            background: white;
            border-radius: 0.75rem;
            border: 1px solid #e9ecef;
            overflow: hidden;
        }
        .expiring-header {
            background-color: #f8f9fa;
            padding: 0.75rem 1rem;
            border-bottom: 1px solid #e9ecef;
        }
        .expiring-item {
            padding: 0.75rem 1rem;
            border-bottom: 1px solid #f1f3f5;
        }
        .expiring-item:last-child { border-bottom: none; }
        .alert-warning-custom {
            background-color: #fff3cd;
            border: 1px solid #ffeeba;
            color: #856404;
            border-radius: 0.5rem;
            padding: 0.75rem;
            font-size: 0.8rem;
            margin-bottom: 1rem;
        }

        /* Live countdown badge */
        .countdown-badge {
            display: inline-flex;
            align-items: center;
            padding: 0.15rem 0.6rem;
            border-radius: 2rem;
            font-size: 0.7rem;
            font-weight: 700;
            font-variant-numeric: tabular-nums;
        }
        .countdown-warn {
            background-color: #fff3cd;
            color: #856404;
        }
        .countdown-urgent {
            background-color: #f8d7da;
            color: #842029;
            animation: pulse-urgent 1.6s ease-in-out infinite;
        }
        @keyframes pulse-urgent {
            0%, 100% { opacity: 1; }
            50%      { opacity: 0.6; }
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid py-4">
        <div class="container-lg">
            <!-- Header -->
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
                <div>
                    <h1 class="h2 fw-bold">Reservations</h1>
                    <p class="text-muted">Manage items held for patron pickup</p>
                </div>
                <div class="stats-card">
                    <div class="label">Total Holds</div>
                    <div class="value"><asp:Literal ID="litTotalHolds" runat="server" Text="0" /> Items</div>
                </div>
            </div>

            <div class="row g-4">
                <!-- Main Table Column -->
                <div class="col-lg-8">
                    <div class="card shadow-sm border-0 rounded-4 overflow-hidden">
                        <div class="card-header bg-white d-flex justify-content-between align-items-center p-3 border-bottom">
                            <h5 class="fw-bold mb-0"><i class="fas fa-bookmark me-2 text-primary"></i>Ready for Pickup</h5>
                            <div class="input-group w-auto">
                                <asp:TextBox ID="txtSearchPatron" runat="server" CssClass="form-control form-control-sm" placeholder="Search Patron ID..." />
                                <asp:LinkButton ID="btnSearch" runat="server" OnClick="FilterReservations" CssClass="btn btn-outline-secondary btn-sm">
                                    <i class="fas fa-search"></i>
                                </asp:LinkButton>
                            </div>
                        </div>
                        <div class="card-body p-0">
                            <div class="table-responsive">
                                <table class="res-table">
                                    <thead>
                                        <tr>
                                            <th>Patron</th>
                                            <th>Book to Retrieve</th>
                                            <th>Status</th>
                                            <th class="text-end">Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <asp:Repeater ID="rptReservations" runat="server">
                                            <ItemTemplate>
                                                <tr>
                                                    <td>
                                                        <div class="fw-bold"><%# Eval("patron_name") %></div>
                                                        <div class="small text-muted">ID: <%# Eval("user_id") %></div>
                                                    </td>
                                                    <td>
                                                        <div class="fw-bold text-primary"><%# Eval("title") %></div>
                                                        <div class="small text-muted">Call #: <%# Eval("call_number") %></div>
                                                        <div class="small text-muted">Acc: <%# Eval("accession_number") %></div>
                                                    </td>
                                                    <td>
                                                        <span class='status-badge <%# Eval("status").ToString() == "Ready" ? "status-ready" : "status-pending" %>'>
                                                            <%# Eval("status") %>
                                                        </span>
                                                    </td>
                                                    <td class="text-end">
                                                        <asp:LinkButton ID="btnAction" runat="server"
                                                            CommandArgument='<%# Eval("transaction_id") %>'
                                                            CssClass='btn-action <%# Eval("status").ToString() == "Ready" ? "btn-action-ready" : "btn-action-pending" %>'
                                                            OnClick="HandleAction_Click">
                                                            <i class='<%# Eval("status").ToString() == "Ready" ? "fas fa-check-circle" : "fas fa-bell-concierge" %>'></i>
                                                            <%# Eval("status").ToString() == "Ready" ? "Notified" : "Mark Ready & Notify" %>
                                                        </asp:LinkButton>
                                                    </td>
                                                </tr>
                                            </ItemTemplate>
                                        </asp:Repeater>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Right Column: Expiring Soon (<= 20 minutes left) -->
                <div class="col-lg-4">
                    <div class="expiring-card">
                        <div class="expiring-header d-flex justify-content-between align-items-center">
                            <h5 class="fw-bold mb-0"><i class="fas fa-clock me-2 text-warning"></i>Expiring Soon</h5>
                            <span class="badge rounded-pill text-bg-warning">
                                <asp:Literal ID="litExpiringCount" runat="server" Text="0" />
                            </span>
                        </div>
                        <div class="p-3">
                            <div class="alert-warning-custom">
                                <i class="fas fa-info-circle me-2"></i>
                                Reservations are held for <strong>1 hour</strong>.
                                The items below have <strong>20 minutes or less</strong> left and will be
                                auto-cancelled once the timer runs out.
                            </div>

                            <asp:Repeater ID="rptExpiring" runat="server">
                                <ItemTemplate>
                                    <div class="expiring-item">
                                        <div class="fw-bold small"><%# Eval("title") %></div>
                                        <div class="small text-muted">
                                            <%# Eval("patron_name") %> &middot; ID: <%# Eval("user_id") %>
                                        </div>
                                        <div class="mt-1">
                                            <span class='countdown-badge <%# GetCountdownClass(Eval("seconds_left")) %>'
                                                  data-seconds='<%# Eval("seconds_left") %>'>
                                                <i class="fas fa-hourglass-half me-1"></i>
                                                <span class="countdown-text"><%# FormatTimeLeft(Eval("seconds_left")) %></span>
                                            </span>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>

                            <asp:PlaceHolder ID="phNoExpiring" runat="server" Visible="false">
                                <div class="text-center text-muted small py-3">
                                    <i class="fas fa-circle-check text-success me-1"></i>
                                    No reservations expiring in the next 20 minutes.
                                </div>
                            </asp:PlaceHolder>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        // ============================================
        // 1. SWEETALERT FOR SERVER MESSAGES
        // ============================================
        function showSweetAlert(title, message, icon) {
            Swal.fire({ title: title, text: message, icon: icon, confirmButtonColor: '#0d6efd' });
        }

        // ============================================
        // 2. LIVE COUNTDOWN FOR "EXPIRING SOON" BADGES
        //    (server value = seconds left before auto-cancel)
        // ============================================
        function startCountdowns() {
            document.querySelectorAll('.countdown-badge[data-seconds]').forEach(function (el) {
                var secs = parseInt(el.getAttribute('data-seconds'), 10);
                if (isNaN(secs)) return;

                var label = el.querySelector('.countdown-text');

                function tick() {
                    if (secs <= 0) {
                        label.textContent = 'Expiring now';
                        el.classList.remove('countdown-warn');
                        el.classList.add('countdown-urgent');
                        return false;
                    }
                    var mins = Math.floor(secs / 60);
                    label.textContent = (mins < 1) ? '< 1 min left' : mins + ' min left';

                    if (secs <= 300) {
                        el.classList.remove('countdown-warn');
                        el.classList.add('countdown-urgent');
                    }
                    secs--;
                    return true;
                }

                if (tick()) {
                    var timer = setInterval(function () {
                        if (!tick()) clearInterval(timer);
                    }, 1000);
                }
            });
        }

        document.addEventListener('DOMContentLoaded', startCountdowns);
        if (window.Sys && Sys.WebForms && Sys.WebForms.PageRequestManager) {
            Sys.WebForms.PageRequestManager.getInstance().add_endRequest(startCountdowns);
        }
    </script>
</asp:Content>