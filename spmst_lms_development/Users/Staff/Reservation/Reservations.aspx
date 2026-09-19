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

                <!-- Right Column: Expiring Soon -->
                <div class="col-lg-4">
                    <div class="expiring-card">
                        <div class="expiring-header">
                            <h5 class="fw-bold mb-0"><i class="fas fa-clock me-2 text-warning"></i>Expiring Soon</h5>
                        </div>
                        <div class="p-3">
                            <div class="alert-warning-custom">
                                <i class="fas fa-info-circle me-2"></i> These items will be returned to the stacks if not picked up today.
                            </div>
                            <asp:Repeater ID="rptExpiring" runat="server">
                                <ItemTemplate>
                                    <div class="expiring-item">
                                        <div class="fw-bold small"><%# Eval("title") %></div>
                                        <div class="small text-muted"><%# Eval("patron_name") %></div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>
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
    </script>
</asp:Content>