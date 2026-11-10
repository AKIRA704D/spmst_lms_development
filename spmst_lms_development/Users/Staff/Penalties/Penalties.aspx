<%@ Page Title="Fines & Penalties" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="Penalties.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Penalties.Penalties" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <link href="<%= ResolveUrl("~/Assets/Themes/Penalties.css") %>" rel="stylesheet" />
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid py-4 penalties-page">
        <div class="container-lg">
            <!-- Header -->
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
                <div>
                    <h1 class="h2 fw-bold">Fines &amp; Penalties</h1>
                    <p class="text-muted mb-0">Manage library dues and overdue charges (Live Calculation)</p>
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

        <!-- Universal modal -->
    <div class="modal fade" id="universalModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-dialog-centered modal-xl">
            <div class="modal-content">
                <div class="modal-body">
                    <iframe id="modalIframe" class="modal-iframe"></iframe>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        $(document).ready(function () { loadData(); });

        function loadData() {
            $.ajax({
                type: "POST",
                url: "Penalties.aspx/GetPenalties",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) { renderTable(res.d); },
                error: function () { Swal.fire('Error', 'Failed to load records', 'error'); }
            });
        }

        function buildReasonCell(item) {
            if (item.Components && item.Components.length) {
                var html = '';
                $.each(item.Components, function (i, c) {
                    if (c.SettlementType === 'Replacement') return; // hide replaced lines
                    var line;
                    if (c.Type === 'Overdue') {
                        line = (c.LoanType === 'LoanIn')
                            ? 'Overdue - Loan-in | ' + c.OverdueHours + ' hours overdue × ₱5.00/hour'
                            : 'Overdue - Loan-out | ' + c.OverdueDays + ' days overdue × ₱5.00/day';
                    } else if (c.Type === 'Damaged') {
                        line = 'Damaged Book - Physical damage reported during return inspection.';
                    } else if (c.Type === 'Lost') {
                        line = 'Lost Book - Book was reported missing and has not been returned.';
                    } else {
                        line = c.Type;
                    }
                    var badge = '';
                    if (c.AmountPaid >= c.Amount) {
                        badge = '<span class="badge bg-success ms-1">Paid</span>';
                    } else if (c.AmountPaid > 0) {
                        badge = '<span class="badge bg-warning text-dark ms-1">Partial</span>';
                    } else {
                        badge = '<span class="badge bg-secondary ms-1">Unpaid</span>';
                    }
                    html += '<div class="small">' + escapeHtml(line) + ' ' + badge + '</div>';
                });
                return html || escapeHtml(item.Reason || '');
            }
            return escapeHtml(item.Reason || '');
        }

        function renderTable(data) {
            var container = $('#penaltyTableBody');
            var totalOutstanding = 0;
            container.empty();

            if (!data || data.length === 0) {
                container.html('<tr><td colspan="6" class="text-center py-4 text-muted">No overdue, damaged, or lost book penalties found.</td></tr>');
                $('#totalDisplay').text("₱ 0.00");
                return;
            }

            $.each(data, function (i, item) {
                totalOutstanding += Number(item.Balance) || 0;
                container.append(
                    '<tr>' +
                    '<td>' +
                    '<div class="fw-bold">' + escapeHtml(item.PatronName) + '</div>' +
                    '<small class="text-muted font-monospace">' + escapeHtml(item.UserID) + '</small>' +
                    '</td>' +
                    '<td class="text-center">' +
                    '<div class="fw-bold">' + escapeHtml(item.Book) + '</div>' +
                    '<small class="text-muted font-monospace">' + escapeHtml(item.AccessionNumber || 'N/A') + '</small>' +
                    '</td>' +
                    '<td>' + buildReasonCell(item) + '</td>' +
                    '<td class="text-end">₱ ' + Number(item.Amount).toFixed(2) + '</td>' +
                    '<td class="text-end fw-bold text-danger">₱ ' + Number(item.Balance).toFixed(2) + '</td>' +
                    '<td class="text-center">' +
                    '<button type="button" class="btn btn-sm btn-success btn-settle" data-tid="' + escapeHtml(item.TransactionID) + '">' +
                    '<i class="fas fa-money-bill-wave me-1"></i> Settle' +
                    '</button>' +
                    '</td>' +
                    '</tr>'
                );
            });

            $('#totalDisplay').text("₱ " + totalOutstanding.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }));
            applyFilter();
        }

        function applyFilter() {
            var value = ($('#tableSearch').val() || '').toLowerCase();
            $('#penaltyTableBody tr').each(function () {
                $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1);
            });
        }

        $('#tableSearch').on('keyup', applyFilter);

// ============================================
// Universal modal
// ============================================
function resizeModalIframe() {
    const iframe = document.getElementById('modalIframe');
    if (!iframe || !iframe.src) return;
    try {
        const doc = iframe.contentDocument || iframe.contentWindow.document;
        if (!doc || !doc.body) return;
        const natural = Math.max(
            doc.documentElement.scrollHeight, doc.body.scrollHeight,
            doc.documentElement.offsetHeight, doc.body.offsetHeight);
        const maxH = Math.round(window.innerHeight * 0.9);
        iframe.style.height = Math.min(natural, maxH) + 'px';
    } catch (e) {
        iframe.style.height = '80vh';
    }
}
window.resizeModalIframe = resizeModalIframe;

let currentModal;

function openUniversalModal(url) {
    const modalEl = document.getElementById('universalModal');
    const iframe = document.getElementById('modalIframe');

    iframe.style.height = '0px';
    iframe.onload = function() {
        setTimeout(resizeModalIframe, 50);
        setTimeout(resizeModalIframe, 150);
        setTimeout(resizeModalIframe, 300);
    };
    iframe.src = url;

    currentModal = new bootstrap.Modal(modalEl);
    currentModal.show();
}

function closeUniversalModal() {
    if (currentModal) currentModal.hide();
    const iframe = document.getElementById('modalIframe');
    iframe.src = '';
    iframe.style.height = '0px';
}
window.closeUniversalModal = closeUniversalModal;

$(document).on('click', '.btn-settle', function() {
    var tid = $(this).data('tid');
            openUniversalModal('SettlePay.aspx?tid=' + encodeURIComponent(tid));
        });

        // ============================================
        // Messages from SettlePay.aspx
        // ============================================
        window.addEventListener('message', function (event) {
            var d = event.data;
            var isSuccess = (d === 'payment_success') ||
                (d && typeof d === 'object' && d.type === 'payment_success');
            if (!isSuccess) return;

            closeUniversalModal();
            Swal.fire({
                title: 'Saved',
                text: 'The transaction has been updated.',
                icon: 'success',
                confirmButtonColor: '#0d6efd'
            }).then(function () { loadData(); });
        });

        window.addEventListener('resize', function () {
            var iframe = document.getElementById('modalIframe');
            if (iframe && iframe.getAttribute('src')) resizeModalIframe();
        });

        function escapeHtml(str) {
            if (str === null || str === undefined) return '';
            return String(str).replace(/[&<>"']/g, function (m) {
                switch (m) {
                    case '&': return '&amp;';
                    case '<': return '&lt;';
                    case '>': return '&gt;';
                    case '"': return '&quot;';
                    case "'": return '&#39;';
                }
                return m;
            });
        }
    </script>
</asp:Content>