<%@ Page Title="Settle Payment" Language="C#" AutoEventWireup="true" CodeBehind="SettlePay.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Penalties.SettlePay" %>

<!DOCTYPE html>
<html>
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Settle Payment | LMSA</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <link href="<%= ResolveUrl("~/Assets/Themes/SettlePay.css") %>" rel="stylesheet" />
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
</head>
<body>
    <form id="form1" runat="server" class="form-shell settlepay-page">
        <!-- Header (sticky) -->
        <div class="header-bar bg-dark text-white px-4 py-3 d-flex justify-content-between align-items-center">
            <div class="d-flex align-items-center gap-3">
                <div class="bg-warning rounded-circle d-flex align-items-center justify-content-center icon-badge">
                    <i class="fas fa-cash-register text-dark"></i>
                </div>
                <div>
                    <h4 class="mb-0 fw-bold">Settle Payment</h4>
                    <small class="text-secondary">Record payment or book replacement</small>
                </div>
            </div>
            <button type="button" class="btn-close btn-close-white" onclick="closeModal()" aria-label="Close"></button>
        </div>

        <!-- Content -->
        <div class="content-area">
            <div class="container-fluid px-3">
                <div class="loading-spinner" id="loadingSpinner">
                    <div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading...</span></div>
                    <p class="mt-2 text-muted">Loading penalty details...</p>
                </div>

                <div id="contentArea" style="display: none;">

                    <!-- Summary -->
                    <div class="summary-bar mb-4">
                        <div class="summary-item">
                            <span class="summary-label">Total Fine</span>
                            <span class="summary-value" id="summaryTotalFine">₱ 0.00</span>
                        </div>
                        <div class="summary-item">
                            <span class="summary-label">Total Paid</span>
                            <span class="summary-value text-success" id="summaryTotalPaid">₱ 0.00</span>
                        </div>
                        <div class="summary-item">
                            <span class="summary-label">Outstanding</span>
                            <span class="summary-value text-danger" id="summaryBalance">₱ 0.00</span>
                        </div>
                    </div>

                    <!-- 1. Penalty Breakdown -->
                    <div class="form-section">
                        <h6><i class="fas fa-list-ul me-2"></i> 1. Penalty Breakdown</h6>
                    </div>
                    <div class="card border-0 shadow-sm rounded-3 mb-4">
                        <div class="card-body p-3" id="breakdownBody"></div>
                    </div>

                    <!-- 2. Book Replacement Settlement -->
                    <div class="form-section" id="replacementHeader" style="display: none;">
                        <h6><i class="fas fa-book-medical me-2"></i> 2. Book Replacement Settlement</h6>
                    </div>
                    <div class="replacement-wrapper mb-4" id="replacementSection" style="display: none;"></div>

                    <!-- 3. Payment Details -->
                    <div class="form-section">
                        <h6><i class="fas fa-money-check-alt me-2"></i> 3. Payment Details</h6>
                    </div>
                    <div class="row g-3 mb-4">
                        <div class="col-12 col-md-6">
                            <label class="form-label fw-bold small text-uppercase">Payment Method <span class="required-star">*</span></label>
                            <select class="form-select form-select-lg" id="paymentMethod">
                                <option value="Cash" selected>Cash</option>
                                <option value="GCash">GCash</option>
                                <option value="Other Banking App">Other Banking App</option>
                            </select>
                            <div class="form-text">Staff verifies the payment externally before recording.</div>
                        </div>

                        <div class="col-12 col-md-6" id="amountCol">
                            <label class="form-label fw-bold small text-uppercase">Amount to Pay <span class="required-star">*</span></label>
                            <div class="input-group input-group-lg">
                                <span class="input-group-text">₱</span>
                                <input type="number" class="form-control" id="paymentAmount" step="0.01" min="0.01" />
                            </div>
                            <div class="form-text">
                                Max payable after replacements: <span id="maxAmountLabel">₱ 0.00</span>
                            </div>
                        </div>

                        <div class="col-12" id="referenceWrap" style="display: none;">
                            <label class="form-label fw-bold small text-uppercase">
                                <span id="referenceMethodLabel">Reference</span> Number <span class="required-star">*</span>
                            </label>
                            <input type="text" class="form-control" id="referenceNumber"
                                   placeholder="Enter the transaction reference from the patron's proof of payment" />
                            <div class="form-text">Staff must independently verify the reference before confirming.</div>
                        </div>

                        <div class="col-12" id="notesWrap">
                            <label class="form-label fw-bold small text-uppercase">Notes</label>
                            <input type="text" class="form-control" id="notes" placeholder="Optional remarks..." />
                        </div>
                    </div>

                    <!-- 4. Cashier (Cash only) -->
                    <div class="form-section" id="cashierHeader">
                        <h6><i class="fas fa-cash-register me-2"></i> 4. Cashier</h6>
                    </div>
                    <div class="cashier-panel mb-4" id="cashierPanel">
                        <div class="row g-3">
                            <div class="col-12 col-md-6">
                                <label class="form-label fw-bold small text-uppercase">Cash Tendered <span class="required-star">*</span></label>
                                <div class="input-group input-group-lg">
                                    <span class="input-group-text">₱</span>
                                    <input type="number" class="form-control" id="cashTendered" step="0.01" min="0" placeholder="0.00" />
                                </div>
                                <div class="form-text">Amount handed by the patron.</div>
                            </div>
                            <div class="col-12 col-md-6">
                                <label class="form-label fw-bold small text-uppercase d-block">Quick Cash</label>
                                <div class="d-flex flex-wrap gap-2">
                                    <button type="button" class="btn btn-outline-secondary btn-sm quick-cash" data-amount="20">₱20</button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm quick-cash" data-amount="50">₱50</button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm quick-cash" data-amount="100">₱100</button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm quick-cash" data-amount="200">₱200</button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm quick-cash" data-amount="500">₱500</button>
                                    <button type="button" class="btn btn-outline-primary btn-sm" id="btnExactAmount">
                                        <i class="fas fa-equals me-1"></i> Exact
                                    </button>
                                </div>
                            </div>
                        </div>

                        <hr class="my-3" />

                        <div class="change-display" id="changeDisplay">
                            <span id="changeLabel"><i class="fas fa-coins me-2"></i> Change</span>
                            <span class="change-amount" id="changeAmount">₱ 0.00</span>
                        </div>
                        <div class="d-flex justify-content-between mt-3 small">
                            <span class="text-muted">Remaining balance after payment:</span>
                            <strong id="remainingBalance" class="text-danger">₱ 0.00</strong>
                        </div>
                    </div>

                    <!-- Empty-state -->
                    <div class="alert alert-info" id="nothingToPayAlert" style="display: none;">
                        <i class="fas fa-info-circle me-2"></i>
                        All components are covered by replacement. No monetary payment is required.
                    </div>

                </div>
            </div>
        </div>

        <!-- Footer (sticky) -->
        <div class="footer-bar border-top p-3 d-flex justify-content-end gap-3">
            <button type="button" class="btn btn-outline-secondary px-4" onclick="closeModal()">Cancel</button>
            <button type="button" class="btn btn-success px-4" id="btnConfirmReplacement" style="display: none;">
                <i class="fas fa-book-medical me-2"></i> Confirm Replacement
            </button>
            <button type="button" class="btn btn-custom-primary text-white px-4" id="btnConfirmPayment">
                <i class="fas fa-money-bill-wave me-2"></i> Record Payment
            </button>
        </div>
    </form>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        var penaltyData = null;
        var selectedReplacements = {};

        $(document).ready(function () {
            var tid = new URLSearchParams(window.location.search).get('tid');
            if (!tid) {
                Swal.fire('Error', 'No transaction ID provided.', 'error').then(closeModal);
                return;
            }
            loadDetails(tid);

            $('#paymentAmount, #cashTendered').on('input', recalculate);
            $('#paymentMethod').on('change', onMethodChange);

            $(document).on('click', '.quick-cash', function () {
                var add = parseFloat($(this).data('amount')) || 0;
                var cur = parseFloat($('#cashTendered').val()) || 0;
                $('#cashTendered').val((cur + add).toFixed(2));
                recalculate();
            });
            $('#btnExactAmount').on('click', function () {
                var amount = parseFloat($('#paymentAmount').val()) || 0;
                $('#cashTendered').val(amount.toFixed(2));
                recalculate();
            });

            $('#btnConfirmPayment').on('click', submitPayment);
            $('#btnConfirmReplacement').on('click', submitReplacement);

            $(document).on('click', '.btn-select-replacement', function () {
                openReplacementPanel($(this).data('type'));
            });
            $(document).on('click', '.btn-cancel-replacement', function () {
                cancelReplacementPanel($(this).data('type'));
            });
            $(document).on('click', '.btn-confirm-replacement', function () {
                stageReplacement($(this).data('type'));
            });

            onMethodChange();
            window.addEventListener('load', function () { setTimeout(reportHeight, 30); });
            window.addEventListener('resize', reportHeight);
        });

        function loadDetails(tid) {
            $.ajax({
                type: "POST",
                url: "SettlePay.aspx/GetPenaltyDetails",
                data: JSON.stringify({ transactionId: parseInt(tid, 10) }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    if (!res.d) {
                        Swal.fire('Not Found', 'Penalty record not found or already settled.', 'warning')
                            .then(closeModal);
                        return;
                    }
                    penaltyData = res.d;
                    selectedReplacements = {};
                    renderSummary();
                    renderBreakdown();
                    renderReplacementSection();
                    populatePaymentDefaults();
                    $('#loadingSpinner').hide();
                    $('#contentArea').show();
                    onMethodChange();
                    recalculate();
                    reportHeight();
                },
                error: function () {
                    Swal.fire('Error', 'Failed to load penalty details.', 'error').then(closeModal);
                }
            });
        }

        function renderSummary() {
            var totalFine = 0, totalPaid = 0;
            (penaltyData.Components || []).forEach(function (c) {
                totalFine += Number(c.Amount) || 0;
                totalPaid += Number(c.AmountPaid) || 0;
            });
            $('#summaryTotalFine').text(fmt(totalFine));
            $('#summaryTotalPaid').text(fmt(totalPaid));
            $('#summaryBalance').text(fmt(totalFine - totalPaid));
        }

        function renderBreakdown() {
            var $body = $('#breakdownBody').empty();
            var comps = penaltyData.Components || [];
            if (comps.length === 0) {
                $body.html('<div class="text-muted text-center py-3">No penalties on this transaction.</div>');
                return;
            }
            comps.forEach(function (c) { $body.append(buildComponentRow(c)); });
        }

        function buildComponentRow(c) {
            var reasonHtml = '';
            if (c.Type === 'Overdue') {
                if (c.LoanType === 'LoanIn') {
                    reasonHtml = 'Overdue - Loan-in | ' + c.OverdueHours + ' hours overdue × ₱5.00/hour';
                } else {
                    reasonHtml = 'Overdue - Loan-out | ' + c.OverdueDays + ' days overdue × ₱5.00/day';
                }
            } else if (c.Type === 'Damaged') {
                reasonHtml = 'Damaged Book - Physical damage reported during return inspection.';
            } else if (c.Type === 'Lost') {
                reasonHtml = 'Lost Book - Book was reported missing and has not been returned.';
            }

            var badge = '';
            if (c.SettlementType === 'Replacement') {
                badge = '<span class="badge bg-info text-dark ms-1">Replaced</span>';
            } else if (c.AmountPaid >= c.Amount) {
                badge = '<span class="badge bg-success ms-1">Paid</span>';
            } else if (c.AmountPaid > 0) {
                badge = '<span class="badge bg-warning text-dark ms-1">Partial</span>';
            } else {
                badge = '<span class="badge bg-secondary ms-1">Unpaid</span>';
            }

            var row = $('<div class="component-row"></div>');
            row.html(
                '<div class="d-flex justify-content-between align-items-start flex-wrap gap-2">' +
                '<div class="flex-grow-1">' +
                '<div class="fw-bold text-uppercase small">' + c.Type + ' ' + badge + '</div>' +
                '<div class="text-muted small">' + escapeHtml(reasonHtml) + '</div>' +
                '</div>' +
                '<div class="text-end">' +
                '<div class="fw-bold">' + fmt(c.Amount) + '</div>' +
                '<div class="small text-muted">Paid: ' + fmt(c.AmountPaid) + '</div>' +
                '</div>' +
                '</div>'
            );
            return row;
        }

        function renderReplacementSection() {
            var eligible = (penaltyData.Components || []).filter(function (c) {
                return (c.Type === 'Damaged' || c.Type === 'Lost')
                    && c.SettlementType !== 'Replacement'
                    && (Number(c.Amount) - Number(c.AmountPaid)) > 0;
            });

            if (eligible.length === 0) {
                $('#replacementHeader, #replacementSection').hide();
                return;
            }
            $('#replacementHeader, #replacementSection').show();

            var $wrap = $('#replacementSection').empty();
            eligible.forEach(function (c) { $wrap.append(buildReplacementCard(c)); });
        }

        function buildReplacementCard(c) {
            var card = $('<div class="replacement-card"></div>').attr('data-type', c.Type);
            card.html(
                '<div class="d-flex justify-content-between align-items-start flex-wrap gap-2">' +
                '<div>' +
                '<div class="fw-bold"><i class="fas fa-book me-1"></i> Replace ' + c.Type + ' Book</div>' +
                '<div class="text-muted small">' + escapeHtml(penaltyData.Book) + '</div>' +
                '<div class="small font-monospace">Accession: ' + escapeHtml(penaltyData.AccessionNumber || 'N/A') + '</div>' +
                '<div class="small">Amount avoidable: <strong>' + fmt(c.Amount) + '</strong></div>' +
                '</div>' +
                '<div class="text-end">' +
                '<button type="button" class="btn btn-outline-success btn-sm btn-select-replacement" data-type="' + c.Type + '">' +
                '<i class="fas fa-exchange-alt me-1"></i> Settle via Replacement' +
                '</button>' +
                '</div>' +
                '</div>' +
                '<div class="replacement-form mt-3" style="display:none;"></div>'
            );
            return card;
        }

        function openReplacementPanel(type) {
            var $card = $('.replacement-card[data-type="' + type + '"]');
            var $form = $card.find('.replacement-form');

            $form.html(
                '<div class="row g-2">' +
                '<div class="col-12 col-md-6">' +
                '<label class="form-label small fw-bold">Replacement Accession No. <span class="required-star">*</span></label>' +
                '<input type="text" class="form-control form-control-sm repl-acc" placeholder="e.g. ACC-2024-001" />' +
                '</div>' +
                '<div class="col-12 col-md-6">' +
                '<label class="form-label small fw-bold">Replacement Title</label>' +
                '<input type="text" class="form-control form-control-sm repl-title" placeholder="Book title" />' +
                '</div>' +
                '<div class="col-12 col-md-6">' +
                '<label class="form-label small fw-bold">Replacement Author</label>' +
                '<input type="text" class="form-control form-control-sm repl-author" placeholder="Author" />' +
                '</div>' +
                '<div class="col-12 col-md-6">' +
                '<label class="form-label small fw-bold">Replacement ISBN</label>' +
                '<input type="text" class="form-control form-control-sm repl-isbn" placeholder="ISBN (optional)" />' +
                '</div>' +
                '<div class="col-12">' +
                '<label class="form-label small fw-bold">Inspection Remarks</label>' +
                '<textarea class="form-control form-control-sm repl-remarks" rows="2" placeholder="Condition / verification notes"></textarea>' +
                '</div>' +
                '<div class="col-12 d-flex justify-content-end gap-2">' +
                '<button type="button" class="btn btn-outline-secondary btn-sm btn-cancel-replacement" data-type="' + type + '">Cancel</button>' +
                '<button type="button" class="btn btn-success btn-sm btn-confirm-replacement" data-type="' + type + '">' +
                '<i class="fas fa-check me-1"></i> Stage Replacement' +
                '</button>' +
                '</div>' +
                '</div>'
            );
            $form.slideDown(150);
            $card.find('.btn-select-replacement').hide();
            reportHeight();
        }

        function cancelReplacementPanel(type) {
            var $card = $('.replacement-card[data-type="' + type + '"]');
            $card.find('.replacement-form').slideUp(150);
            $card.find('.btn-select-replacement').show();
            $card.find('.alert-success').remove();
            delete selectedReplacements[type];
            recalculate();
        }

        function stageReplacement(type) {
            var $card = $('.replacement-card[data-type="' + type + '"]');
            var acc = $card.find('.repl-acc').val().trim();
            if (!acc) {
                Swal.fire('Accession Required', 'Please enter the replacement accession number.', 'warning');
                return;
            }
            selectedReplacements[type] = {
                Type: type,
                Accession: acc,
                Title: $card.find('.repl-title').val().trim(),
                Author: $card.find('.repl-author').val().trim(),
                Isbn: $card.find('.repl-isbn').val().trim(),
                Remarks: $card.find('.repl-remarks').val().trim()
            };
            $card.find('.replacement-form').slideUp(150);
            $card.find('.btn-select-replacement').hide();
            $card.find('.alert-success').remove();
            $card.append('<div class="alert alert-success py-2 mt-2 mb-0 small"><i class="fas fa-check-circle me-1"></i> Will be recorded on confirm: ' + escapeHtml(acc) + '</div>');
            recalculate();
            reportHeight();
        }

        function populatePaymentDefaults() {
            var max = computeMaxPayable();
            $('#maxAmountLabel').text(fmt(max));
            $('#paymentAmount').attr('max', max.toFixed(2));
            $('#paymentAmount').val(max.toFixed(2));
            if ($('#paymentMethod').val() === 'Cash') {
                $('#cashTendered').val(max.toFixed(2));
            }
            updateFooterButtons();
        }

        function computeMaxPayable() {
            var total = 0;
            (penaltyData.Components || []).forEach(function (c) {
                if (c.SettlementType === 'Replacement') return;
                if (selectedReplacements[c.Type]) return;
                total += Math.max(0, Number(c.Amount) - Number(c.AmountPaid));
            });
            return total;
        }

        function onMethodChange() {
            var method = $('#paymentMethod').val();
            var isCash = method === 'Cash';
            if (isCash) {
                $('#cashierHeader, #cashierPanel').show();
                $('#referenceWrap').hide();
                $('#referenceNumber').val('');
            } else {
                $('#cashierHeader, #cashierPanel').hide();
                $('#referenceWrap').show();
                $('#referenceMethodLabel').text(method + ' Reference');
                $('#cashTendered').val($('#paymentAmount').val());
            }
            updateFooterButtons();
            recalculate();
        }

        function recalculate() {
            if (!penaltyData) return;

            var max = computeMaxPayable();
            var amount = parseFloat($('#paymentAmount').val()) || 0;
            if (amount > max) { amount = max; $('#paymentAmount').val(max.toFixed(2)); }
            if (amount < 0) { amount = 0; $('#paymentAmount').val('0.00'); }

            var remaining = max - amount;
            $('#remainingBalance').text(fmt(remaining));

            if ($('#paymentMethod').val() === 'Cash') {
                var tendered = parseFloat($('#cashTendered').val()) || 0;
                var change = tendered - amount;
                var $display = $('#changeDisplay');
                if (change < 0) {
                    $display.addClass('insufficient');
                    $('#changeAmount').text(fmt(0));
                    $('#changeLabel').html('<i class="fas fa-exclamation-triangle me-2"></i> Short ' + fmt(Math.abs(change)));
                } else {
                    $display.removeClass('insufficient');
                    $('#changeAmount').text(fmt(change));
                    $('#changeLabel').html('<i class="fas fa-coins me-2"></i> Change');
                }
            }
            updateFooterButtons();
        }

        function updateFooterButtons() {
            if (!penaltyData) return;

            var hasStagedReplacement = Object.keys(selectedReplacements).length > 0;
            var max = computeMaxPayable();
            var amount = parseFloat($('#paymentAmount').val()) || 0;

            $('#btnConfirmReplacement').toggle(hasStagedReplacement);

            if (max === 0 && hasStagedReplacement) {
                $('#nothingToPayAlert').show();
                $('#cashierHeader, #cashierPanel').hide();
                $('#amountCol').hide();
                $('#btnConfirmPayment').hide();
            } else {
                $('#nothingToPayAlert').hide();
                $('#amountCol').show();
                $('#btnConfirmPayment').show();

                var canPay = amount > 0;
                if ($('#paymentMethod').val() === 'Cash') {
                    var tendered = parseFloat($('#cashTendered').val()) || 0;
                    canPay = canPay && tendered >= amount;
                }
                if (hasStagedReplacement) canPay = false;

                $('#btnConfirmPayment')
                    .prop('disabled', !canPay)
                    .attr('title', hasStagedReplacement
                        ? 'Confirm the staged replacement(s) first'
                        : '');
            }
        }

        function submitPayment() {
            if (!penaltyData) return;
            var amount = parseFloat($('#paymentAmount').val());
            var method = $('#paymentMethod').val();
            var reference = ($('#referenceNumber').val() || '').trim();
            var tendered = parseFloat($('#cashTendered').val()) || 0;
            var notes = $('#notes').val().trim();
            var max = computeMaxPayable();

            if (!amount || amount <= 0) {
                Swal.fire('Invalid Amount', 'Enter a valid payment amount.', 'warning'); return;
            }
            if (amount > max) {
                Swal.fire('Amount Too High', 'Payment cannot exceed the remaining payable of ' + fmt(max) + '.', 'warning'); return;
            }
            if (method !== 'Cash' && !reference) {
                Swal.fire('Reference Required', 'A reference number is required for ' + method + '.', 'warning'); return;
            }
            if (method === 'Cash' && tendered < amount) {
                Swal.fire('Insufficient Cash', 'Cash tendered is less than the payment amount.', 'warning'); return;
            }

            var $btn = $('#btnConfirmPayment');
            $btn.prop('disabled', true).html('<span class="spinner-border spinner-border-sm me-1"></span> Processing...');

            $.ajax({
                type: "POST",
                url: "SettlePay.aspx/ProcessPayment",
                data: JSON.stringify({
                    transactionId: penaltyData.TransactionID,
                    amount: amount,
                    cashTendered: method === 'Cash' ? tendered : amount,
                    method: method,
                    reference: reference,
                    notes: notes
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    if (res.d === true) {
                        if (window.parent && typeof window.parent.postMessage === 'function') {
                            window.parent.postMessage('payment_success', '*');
                        }
                        if (window.parent && typeof window.parent.closeUniversalModal === 'function') {
                            window.parent.closeUniversalModal();
                        }
                    } else {
                        Swal.fire('Payment Failed', res.d || 'An unknown error occurred.', 'error');
                        $btn.prop('disabled', false).html('<i class="fas fa-money-bill-wave me-2"></i> Record Payment');
                    }
                },
                error: function () {
                    Swal.fire('Error', 'A server error occurred. Please try again.', 'error');
                    $btn.prop('disabled', false).html('<i class="fas fa-money-bill-wave me-2"></i> Record Payment');
                }
            });
        }

        function submitReplacement() {
            if (!penaltyData) return;
            var payload = [];
            for (var t in selectedReplacements) {
                if (selectedReplacements.hasOwnProperty(t)) payload.push(selectedReplacements[t]);
            }
            if (payload.length === 0) {
                Swal.fire('Nothing to Replace', 'Please stage at least one replacement.', 'warning');
                return;
            }

            var $btn = $('#btnConfirmReplacement');
            $btn.prop('disabled', true).html('<span class="spinner-border spinner-border-sm me-1"></span> Saving...');

            $.ajax({
                type: "POST",
                url: "SettlePay.aspx/ProcessReplacement",
                data: JSON.stringify({
                    transactionId: penaltyData.TransactionID,
                    replacements: payload,
                    remarks: $('#notes').val().trim()
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    if (res.d === true) {
                        Swal.fire({
                            title: 'Replacement Recorded',
                            text: 'The replacement has been recorded. Remaining balance has been updated.',
                            icon: 'success'
                        }).then(function () {
                            selectedReplacements = {};
                            $('#loadingSpinner').show();
                            $('#contentArea').hide();
                            loadDetails(penaltyData.TransactionID);
                        });
                    } else {
                        Swal.fire('Replacement Failed', res.d || 'An unknown error occurred.', 'error');
                        $btn.prop('disabled', false).html('<i class="fas fa-book-medical me-2"></i> Confirm Replacement');
                    }
                },
                error: function () {
                    Swal.fire('Error', 'A server error occurred. Please try again.', 'error');
                    $btn.prop('disabled', false).html('<i class="fas fa-book-medical me-2"></i> Confirm Replacement');
                }
            });
        }

        function closeModal() {
            if (window.parent && typeof window.parent.closeUniversalModal === 'function') {
                window.parent.closeUniversalModal();
            }
        }
        function reportHeight() {
            if (window.parent && typeof window.parent.resizeModalIframe === 'function') {
                window.parent.resizeModalIframe();
            }
        }
        function fmt(n) {
            return '₱ ' + Number(n || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        }
        function escapeHtml(s) {
            if (s == null) return '';
            return String(s).replace(/[&<>"']/g, function (m) {
                return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[m];
            });
        }
    </script>
</body>
</html>