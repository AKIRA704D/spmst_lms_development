<%@ Page Title="Settle Payment" Language="C#" AutoEventWireup="true" CodeBehind="SettlePay.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Penalties.SettlePay" %>

<!DOCTYPE html>
<html>
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Settle Payment | LMSA</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <style>
        /* ------------------------------------------------------------------
           Match userUpdate.aspx: let the page flow to its natural height.
           The parent measures document.body.scrollHeight and sizes the iframe.
           Header/Footer use position:sticky so they pin *only* when the
           parent caps the iframe at 90vh.
           ------------------------------------------------------------------ */
        html, body {
            margin: 0;
            padding: 0;
            background: transparent;
        }

        .form-shell {
            display: flex;
            flex-direction: column;
        }

        .header-bar {
            position: sticky;
            top: 0;
            z-index: 20;
        }

        .footer-bar {
            position: sticky;
            bottom: 0;
            z-index: 20;
            background: #fff;
        }

        .form-section {
            border-left: 4px solid #ffc107;
            background: #f8f9fa;
            padding: 0.75rem 1rem;
            margin-bottom: 1.5rem;
        }
        .form-section h6 {
            font-size: 0.7rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: #002447;
            margin: 0;
        }
        .required-star { color: #dc3545; font-weight: bold; margin-left: 2px; }
        .btn-custom-primary { background-color: #002447; border: none; }
        .btn-custom-primary:hover { background-color: #001a33; }
        .form-control:focus, .form-select:focus {
            border-color: #ffc107;
            box-shadow: 0 0 0 0.2rem rgba(255,193,7,0.25);
        }

        /* Info rows (penalty details) */
        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 0.5rem 0;
            border-bottom: 1px solid #e9ecef;
        }
        .info-row:last-child { border-bottom: none; }
        .info-label { color: #6c757d; font-size: 0.85rem; }
        .info-value { font-weight: 600; text-align: right; }
        .balance-highlight { color: #dc3545; font-weight: 700; font-size: 1.05rem; }

        /* Cashier panel */
        .cashier-panel {
            background: #fff8e1;
            border: 2px dashed #ffc107;
            border-radius: 0.75rem;
            padding: 1rem;
        }
        .change-display {
            background: #d1e7dd;
            border: 2px solid #198754;
            border-radius: 0.5rem;
            padding: 0.75rem 1rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-weight: 700;
            transition: background 0.15s, border-color 0.15s;
        }
        .change-display.insufficient {
            background: #f8d7da;
            border-color: #dc3545;
        }
        .change-amount {
            font-size: 1.5rem;
            color: #0f5132;
        }
        .change-display.insufficient .change-amount { color: #842029; }

        .loading-spinner { text-align: center; padding: 2rem; }
    </style>
</head>
<body>
    <form id="form1" runat="server" class="form-shell">
        <!-- Header (sticky) -->
        <div class="header-bar bg-dark text-white px-4 py-3 d-flex justify-content-between align-items-center">
            <div class="d-flex align-items-center gap-3">
                <div class="bg-warning rounded-circle d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                    <i class="fas fa-cash-register text-dark"></i>
                </div>
                <div>
                    <h4 class="mb-0 fw-bold">Settle Payment</h4>
                    <small class="text-secondary">Process fine payment and compute change</small>
                </div>
            </div>
            <button type="button" class="btn-close btn-close-white" onclick="closeModal()" aria-label="Close"></button>
        </div>

        <!-- Content -->
        <div class="p-4" style="background: #f5f7fb;">
            <div class="container-fluid px-0">
                <div class="loading-spinner" id="loadingSpinner">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                    <p class="mt-2 text-muted">Loading penalty details...</p>
                </div>

                <div id="contentArea" style="display: none;">
                    <!-- 1. Penalty Details -->
                    <div class="form-section">
                        <h6><i class="fas fa-file-invoice-dollar me-2"></i> 1. Penalty Details</h6>
                    </div>
                    <div class="card border-0 shadow-sm rounded-3 mb-4">
                        <div class="card-body p-3">
                            <div class="info-row">
                                <span class="info-label">Patron</span>
                                <span class="info-value" id="patronName">—</span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">Patron ID</span>
                                <span class="info-value font-monospace" id="patronId">—</span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">Resource</span>
                                <span class="info-value" id="bookTitle">—</span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">Accession No.</span>
                                <span class="info-value font-monospace" id="accessionNumber">—</span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">Reason</span>
                                <span class="info-value" id="reason">—</span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">Total Fine</span>
                                <span class="info-value" id="totalFine">₱ 0.00</span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">Current Balance</span>
                                <span class="info-value balance-highlight" id="currentBalance">₱ 0.00</span>
                            </div>
                        </div>
                    </div>

                    <!-- 2. Payment Information -->
                    <div class="form-section">
                        <h6><i class="fas fa-money-check-alt me-2"></i> 2. Payment Information</h6>
                    </div>
                    <div class="row g-3 mb-4">
                        <div class="col-md-6">
                            <label class="form-label fw-bold small text-uppercase">Payment Amount <span class="required-star">*</span></label>
                            <div class="input-group">
                                <span class="input-group-text">₱</span>
                                <input type="number" class="form-control" id="paymentAmount" step="0.01" min="0.01" required />
                            </div>
                            <div class="form-text">Amount applied to balance (max: <span id="maxAmountLabel">₱ 0.00</span>)</div>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-bold small text-uppercase">Payment Method <span class="required-star">*</span></label>
                            <select class="form-select" id="paymentMethod" required>
                                <option value="">Select method...</option>
                                <option value="Cash" selected>Cash</option>
                                <option value="GCash">GCash</option>
                                <option value="Bank Transfer">Bank Transfer</option>
                                <option value="Credit/Debit Card">Credit/Debit Card</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-bold small text-uppercase">Reference Number</label>
                            <input type="text" class="form-control" id="referenceNumber" placeholder="Optional" />
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-bold small text-uppercase">Notes</label>
                            <input type="text" class="form-control" id="notes" placeholder="Optional remarks..." />
                        </div>
                    </div>

                    <!-- 3. Cashier -->
                    <div class="form-section">
                        <h6><i class="fas fa-cash-register me-2"></i> 3. Cashier</h6>
                    </div>
                    <div class="cashier-panel mb-4" id="cashierPanel">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label fw-bold small text-uppercase">Cash Tendered <span class="required-star">*</span></label>
                                <div class="input-group input-group-lg">
                                    <span class="input-group-text">₱</span>
                                    <input type="number" class="form-control" id="cashTendered" step="0.01" min="0" placeholder="0.00" />
                                </div>
                                <div class="form-text">Amount handed by the patron</div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-bold small text-uppercase d-block">Quick Cash</label>
                                <div class="d-flex flex-wrap gap-2">
                                    <button type="button" class="btn btn-outline-secondary btn-sm quick-cash" data-amount="20">₱20</button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm quick-cash" data-amount="50">₱50</button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm quick-cash" data-amount="100">₱100</button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm quick-cash" data-amount="200">₱200</button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm quick-cash" data-amount="500">₱500</button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm quick-cash" data-amount="1000">₱1000</button>
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
                </div>
            </div>
        </div>

        <!-- Footer (sticky) -->
        <div class="footer-bar border-top p-3 d-flex justify-content-end gap-3">
            <button type="button" class="btn btn-outline-secondary px-4" onclick="closeModal()">Cancel</button>
            <button type="button" class="btn btn-custom-primary text-white px-5" id="btnConfirmPayment" disabled>
                <i class="fas fa-check-circle me-2"></i> Confirm Payment
            </button>
        </div>
    </form>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        var penaltyData = null;

        $(document).ready(function () {
            var urlParams = new URLSearchParams(window.location.search);
            var tid = urlParams.get('tid');
            if (!tid) {
                Swal.fire('Error', 'No transaction ID provided.', 'error').then(function () {
                    closeModal();
                });
                return;
            }

            $.ajax({
                type: "POST",
                url: "SettlePay.aspx/GetPenaltyDetails",
                data: JSON.stringify({ transactionId: tid }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    if (res.d) {
                        penaltyData = res.d;
                        populateDetails(penaltyData);
                        $('#loadingSpinner').hide();
                        $('#contentArea').show();
                        $('#btnConfirmPayment').prop('disabled', false);
                        reportHeight();
                    } else {
                        Swal.fire('Not Found', 'Penalty record not found or already settled.', 'warning').then(function () {
                            closeModal();
                        });
                    }
                },
                error: function () {
                    Swal.fire('Error', 'Failed to load penalty details.', 'error').then(function () {
                        closeModal();
                    });
                }
            });

            // Live recalculation
            $('#paymentAmount, #cashTendered').on('input', recalculate);
            $('#paymentMethod').on('change', onMethodChange);

            // Quick cash buttons (additive)
            $(document).on('click', '.quick-cash', function () {
                var add = parseFloat($(this).data('amount')) || 0;
                var current = parseFloat($('#cashTendered').val()) || 0;
                $('#cashTendered').val((current + add).toFixed(2));
                recalculate();
            });

            // Exact amount button
            $('#btnExactAmount').on('click', function () {
                var amount = parseFloat($('#paymentAmount').val()) || 0;
                $('#cashTendered').val(amount.toFixed(2));
                recalculate();
            });

            onMethodChange();

            // Report height to parent
            window.addEventListener('load', function () { setTimeout(reportHeight, 30); });
            window.addEventListener('resize', reportHeight);
        });

        function reportHeight() {
            if (window.parent && typeof window.parent.resizeModalIframe === 'function') {
                window.parent.resizeModalIframe();
            }
        }

        function populateDetails(data) {
            $('#patronName').text(data.PatronName);
            $('#patronId').text(data.UserID);
            $('#bookTitle').text(data.Book);
            $('#accessionNumber').text(data.AccessionNumber || 'N/A');
            $('#reason').text(data.Reason);
            $('#totalFine').text('₱ ' + Number(data.Amount).toFixed(2));
            $('#currentBalance').text('₱ ' + Number(data.Balance).toFixed(2));
            $('#maxAmountLabel').text('₱ ' + Number(data.Balance).toFixed(2));
            $('#paymentAmount').attr('max', Number(data.Balance).toFixed(2));
            $('#paymentAmount').val(Number(data.Balance).toFixed(2));
            $('#cashTendered').val(Number(data.Balance).toFixed(2));
            recalculate();
        }

        function onMethodChange() {
            var method = $('#paymentMethod').val();
            if (method === 'Cash' || method === '') {
                $('#cashierPanel').show();
            } else {
                // Non-cash: tendered equals amount, no change
                $('#cashierPanel').hide();
                $('#cashTendered').val($('#paymentAmount').val());
                recalculate();
            }
        }

        function recalculate() {
            if (!penaltyData) return;

            var amount = parseFloat($('#paymentAmount').val()) || 0;
            var balance = Number(penaltyData.Balance);

            var remaining = balance - amount;
            if (remaining < 0) remaining = 0;
            $('#remainingBalance').text('₱ ' + remaining.toFixed(2));

            var method = $('#paymentMethod').val();
            if (method === 'Cash' || method === '') {
                var tendered = parseFloat($('#cashTendered').val()) || 0;
                var change = tendered - amount;
                var display = $('#changeDisplay');
                var changeAmt = $('#changeAmount');
                var changeLbl = $('#changeLabel');

                if (change < 0) {
                    display.addClass('insufficient');
                    changeAmt.text('₱ 0.00');
                    changeLbl.html('<i class="fas fa-exclamation-triangle me-2"></i> Insufficient — short ₱ ' + Math.abs(change).toFixed(2));
                } else {
                    display.removeClass('insufficient');
                    changeAmt.text('₱ ' + change.toFixed(2));
                    changeLbl.html('<i class="fas fa-coins me-2"></i> Change');
                }
            }
        }

        function closeModal() {
            if (window.parent && typeof window.parent.closeUniversalModal === 'function') {
                window.parent.closeUniversalModal();
            }
        }

        $('#btnConfirmPayment').on('click', function () {
            if (!penaltyData) return;

            var amount = parseFloat($('#paymentAmount').val());
            var method = $('#paymentMethod').val();
            var reference = $('#referenceNumber').val().trim();
            var notes = $('#notes').val().trim();
            var tendered = parseFloat($('#cashTendered').val()) || 0;

            if (!amount || amount <= 0) {
                Swal.fire('Invalid Amount', 'Please enter a valid payment amount.', 'warning');
                return;
            }
            if (amount > penaltyData.Balance) {
                Swal.fire('Amount Too High', 'Payment cannot exceed the current balance of ₱' + Number(penaltyData.Balance).toFixed(2) + '.', 'warning');
                return;
            }
            if (!method) {
                Swal.fire('Method Required', 'Please select a payment method.', 'warning');
                return;
            }
            if ((method === 'Cash' || method === '') && tendered < amount) {
                Swal.fire('Insufficient Cash', 'Cash tendered is less than the payment amount.', 'warning');
                return;
            }

            var $btn = $(this);
            $btn.prop('disabled', true).html('<span class="spinner-border spinner-border-sm me-1"></span> Processing...');

            $.ajax({
                type: "POST",
                url: "SettlePay.aspx/ProcessPayment",
                data: JSON.stringify({
                    transactionId: penaltyData.TransactionID,
                    amount: amount,
                    method: method,
                    cashTendered: tendered,
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
                        $btn.prop('disabled', false).html('<i class="fas fa-check-circle me-2"></i> Confirm Payment');
                    }
                },
                error: function () {
                    Swal.fire('Error', 'A server error occurred. Please try again.', 'error');
                    $btn.prop('disabled', false).html('<i class="fas fa-check-circle me-2"></i> Confirm Payment');
                }
            });
        });
    </script>
</body>
</html>