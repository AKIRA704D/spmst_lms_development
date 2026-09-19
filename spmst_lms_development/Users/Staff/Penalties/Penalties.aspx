<%@ Page Title="Fines & Penalties" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="Penalties.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Penalties.Penalties" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        /* ============================================
           1. GLOBAL & UTILITY
           ============================================ */
        body {
            background-color: #f8fafc;
        }
        /* ============================================
           2. STATS CARD
           ============================================ */
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
            letter-spacing: 0.5px;
        }
        .stats-card .value {
            font-size: 1.75rem;
            font-weight: 800;
            color: #dc3545;
        }
        /* ============================================
           3. TABLE STYLES
           ============================================ */
        .table-penalties th {
            background-color: #f8f9fa;
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 1px solid #dee2e6;
        }
        .table-penalties td {
            vertical-align: middle;
        }
        /* ============================================
           4. MODAL IFRAME
           ============================================ */
        .payment-modal-iframe {
            width: 100%;
            height: 80vh;
            border: none;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid py-4">
        <div class="container-lg">
            <!-- Header -->
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
                <div>
                    <h1 class="h2 fw-bold">Fines &amp; Penalties</h1>
                    <p class="text-muted">Manage library dues and overdue charges (Live Calculation)</p>
                </div>
                <div class="stats-card">
                    <div class="label">Total Outstanding</div>
                    <div class="value" id="totalDisplay">₱ 0.00</div>
                </div>
            </div>

            <!-- Penalties Table -->
            <div class="card shadow-sm border-0 rounded-4 overflow-hidden">
                <div class="card-header bg-white d-flex justify-content-between align-items-center p-3 border-bottom">
                    <h5 class="fw-bold mb-0"><i class="fas fa-exclamation-triangle me-2 text-warning"></i>Active Fine Records</h5>
                    <div class="input-group w-auto">
                        <input type="text" id="tableSearch" class="form-control form-control-sm" placeholder="Filter names..." />
                        <span class="input-group-text bg-white"><i class="fas fa-search text-muted"></i></span>
                    </div>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover table-penalties mb-0">
                            <thead>
                                <tr>
                                    <th>Patron</th>
                                    <th class="text-center">Resource</th>
                                    <th>Reason</th>
                                    <th class="text-end">Base Amount</th>
                                    <th class="text-end">Current Balance</th>
                                    <th class="text-center">Action</th>
                                </tr>
                            </thead>
                            <tbody id="penaltyTableBody">
                                <tr><td colspan="6" class="text-center py-4 text-muted">Loading...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap Modal for Payment -->
    <div class="modal fade" id="paymentModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title fw-bold"><i class="fas fa-credit-card me-2"></i>Settle Payment</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body p-0">
                    <iframe id="paymentFrame" class="payment-modal-iframe"></iframe>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        // ============================================
        // 1. DATA LOADING (AJAX WebMethod)
        // ============================================
        $(document).ready(() => loadData());

        function loadData() {
            $.ajax({
                type: "POST",
                url: "Penalties.aspx/GetPenalties",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: (res) => renderTable(res.d),
                error: () => Swal.fire('Error', 'Failed to load records', 'error')
            });
        }

        function renderTable(data) {
            const container = $('#penaltyTableBody');
            let totalOutstanding = 0;
            container.empty();

            if (!data || data.length === 0) {
                container.html(`<tr><td colspan="6" class="text-center py-4 text-muted">No overdue, damaged, or lost book penalties found.</td></tr>`);
                $('#totalDisplay').text("₱ 0.00");
                return;
            }

            data.forEach(item => {
                totalOutstanding += item.Balance;
                container.append(`
                    <tr>
                        <td>
                            <div class="fw-bold">${escapeHtml(item.PatronName)}</div>
                            <small class="text-muted font-monospace">${escapeHtml(item.UserID)}</small>
                        </td>
                        <td class="text-center">
                            <div class="fw-bold">${escapeHtml(item.Book)}</div>
                            <small class="text-muted font-monospace">${escapeHtml(item.AccessionNumber || 'N/A')}</small>
                        </td>
                        <td>${escapeHtml(item.Reason)}</td>
                        <td class="text-end">₱ ${item.Amount.toFixed(2)}</td>
                        <td class="text-end fw-bold text-danger">₱ ${item.Balance.toFixed(2)}</td>
                        <td class="text-center">
                            <button type="button" onclick="openPayment('${item.TransactionID}')" class="btn btn-sm btn-success">
                                <i class="fas fa-money-bill-wave me-1"></i> Settle
                            </button>
                        </td>
                    </tr>
                `);
            });

            $('#totalDisplay').text("₱ " + totalOutstanding.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }));
        }

        // ============================================
        // 2. SEARCH FILTER (live)
        // ============================================
        $('#tableSearch').on('keyup', function () {
            let value = $(this).val().toLowerCase();
            $("#penaltyTableBody tr").filter(function () {
                $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1);
            });
        });

        // ============================================
        // 3. PAYMENT MODAL HANDLERS
        // ============================================
        let paymentModal = null;

        function openPayment(transactionId) {
            const iframe = document.getElementById('paymentFrame');
            iframe.src = `settlePay.aspx?tid=${transactionId}`;
            const modalEl = document.getElementById('paymentModal');
            paymentModal = new bootstrap.Modal(modalEl);
            paymentModal.show();
        }

        function closePaymentModal() {
            if (paymentModal) paymentModal.hide();
            const iframe = document.getElementById('paymentFrame');
            iframe.src = '';
            loadData(); // Refresh the table after modal closes
        }

        // Listen for payment success message from iframe
        window.addEventListener('message', function (event) {
            if (event.data === 'payment_success') {
                closePaymentModal();
                Swal.fire({
                    title: 'Success!',
                    text: 'Payment has been processed successfully.',
                    icon: 'success',
                    confirmButtonColor: '#0d6efd'
                });
            }
        });

        // Helper to escape HTML
        function escapeHtml(str) {
            if (!str) return '';
            return str.replace(/[&<>]/g, function (m) {
                if (m === '&') return '&amp;';
                if (m === '<') return '&lt;';
                if (m === '>') return '&gt;';
                return m;
            });
        }
    </script>
</asp:Content>