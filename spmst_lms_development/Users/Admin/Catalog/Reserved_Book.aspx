<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Reserved_Book.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Catalog.Reserved_Book" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <title>Reserve Book</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <link href="<%= ResolveUrl("~/Assets/Themes/spmast-theme.css") %>" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <style>
        /* ============================================================
           Base
           ============================================================ */
        html { margin: 0; padding: 0; }
        body {
            margin: 0; padding: 0;
            background: #fff;
            font-family: var(--sp-sans);
            color: var(--sp-ink);
        }

        /* ============================================================
           Sticky header + step indicator
           ============================================================ */
        .reserve-top {
            position: sticky;
            top: 0;
            z-index: 20;
            background: #fff;
            border-bottom: 1px solid var(--sp-line);
        }
        .reserve-header {
            background: linear-gradient(135deg, var(--sp-green-900), var(--sp-green-800));
            color: #fff;
            padding: 12px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 3px solid var(--sp-gold);
        }
        .reserve-header-title {
            margin: 0;
            font-family: var(--sp-serif);
            font-weight: 700;
            font-size: 1.05rem;
        }
        .reserve-header-sub {
            font-size: 0.75rem;
            opacity: 0.9;
        }
        .reserve-close-btn {
            display: inline-block;
            color: #fff;
            font-size: 1.6rem;
            line-height: 1;
            text-decoration: none;
            padding: 0 8px;
            opacity: 0.85;
            transition: opacity 0.15s;
        }
        .reserve-close-btn:hover { opacity: 1; color: #fff; text-decoration: none; }

        /* Step indicator */
        .step-indicator {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 10px 16px;
            background: #fff;
        }
        .step-item {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 0.78rem;
            color: #8a998f;
            font-weight: 600;
            white-space: nowrap;
        }
        .step-num {
            width: 24px;
            height: 24px;
            border-radius: 50%;
            border: 2px solid var(--sp-line);
            background: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.7rem;
            font-weight: 700;
            color: #8a998f;
        }
        .step-connector {
            width: 20px;
            height: 2px;
            background: var(--sp-line);
        }
        .step-item.active .step-num {
            background: var(--sp-green-700);
            border-color: var(--sp-green-700);
            color: #fff;
        }
        .step-item.active .step-label { color: var(--sp-green-900); }
        .step-item.completed .step-num {
            background: var(--sp-green-600);
            border-color: var(--sp-green-600);
            color: #fff;
        }
        .step-item.completed .step-label { color: var(--sp-green-700); }

        /* ============================================================
           Scrollable main content
           ============================================================ */
        .reserve-main {
            padding: 18px 20px 24px;
            max-width: 720px;
            margin: 0 auto;
        }
        .step-heading {
            font-family: var(--sp-serif);
            font-weight: 700;
            color: var(--sp-green-900);
            font-size: 1.05rem;
            margin: 0 0 4px;
        }
        .step-desc {
            font-size: 0.85rem;
            color: #5b6b60;
            margin: 0 0 16px;
        }

        /* ============================================================
           Book summary
           ============================================================ */
        .book-summary {
            display: grid;
            grid-template-columns: 90px 1fr;
            gap: 14px;
            padding: 12px;
            background: var(--sp-paper);
            border: 1px solid var(--sp-line);
            border-radius: var(--sp-radius);
            margin-bottom: 20px;
            align-items: flex-start;
        }
        .book-cover-container {
            width: 90px;
            height: 130px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #fff;
            border: 1px solid var(--sp-line);
            border-radius: 6px;
            overflow: hidden;
        }
        .book-cover-container img {
            width: 100%;
            height: 100%;
            object-fit: contain;
            object-position: center;
            display: block;
        }
        .book-summary-info { min-width: 0; }
        .book-title {
            font-family: var(--sp-serif);
            font-weight: 700;
            font-size: 1rem;
            color: var(--sp-green-900);
            margin: 0 0 4px;
            line-height: 1.3;
        }
        .book-author {
            font-size: 0.82rem;
            color: #5b6b60;
            font-style: italic;
            margin: 0 0 8px;
        }
        .book-section {
            display: inline-block;
            font-size: 0.68rem;
            letter-spacing: 0.02em;
            text-transform: uppercase;
            font-weight: 700;
            color: var(--sp-green-800);
            background: #eef5ef;
            border-radius: 4px;
            padding: 2px 8px;
        }

        /* ============================================================
           Notice cards
           ============================================================ */
        .notice-card {
            display: flex;
            gap: 12px;
            padding: 12px 14px;
            border-radius: var(--sp-radius);
            border: 1px solid var(--sp-line);
            background: var(--sp-paper);
            margin-bottom: 12px;
        }
        .notice-icon {
            flex-shrink: 0;
            font-size: 1.15rem;
            line-height: 1.2;
            width: 1.5rem;
            text-align: center;
            padding-top: 2px;
        }
        .notice-body { flex: 1 1 auto; min-width: 0; }
        .notice-title {
            font-weight: 700;
            font-size: 0.9rem;
            color: var(--sp-green-900);
            margin: 0 0 6px;
        }
        .notice-text {
            margin: 0 0 6px;
            font-size: 0.83rem;
            line-height: 1.5;
            color: #2a3b30;
        }
        .notice-text:last-child { margin-bottom: 0; }
        .notice-list {
            margin: 0;
            padding-left: 1.1rem;
            font-size: 0.83rem;
            line-height: 1.55;
            color: #2a3b30;
        }
        .notice-list li { margin-bottom: 3px; }

        .notice-info    { background: #ecfdf5; border-color: var(--sp-green-600); }
        .notice-info     .notice-icon { color: var(--sp-green-600); }
        .notice-reminder{ background: #fef9e7; border-color: var(--sp-gold); }
        .notice-reminder .notice-icon { color: var(--sp-gold); }
        .notice-warning { background: #fff8e1; border-color: #f0a500; }
        .notice-warning  .notice-icon { color: #c17c00; }
        .notice-critical{ background: #fef2f2; border-color: #dc2626; }
        .notice-critical .notice-icon { color: #dc2626; }

        /* ============================================================
           Location radio
           ============================================================ */
        .location-rbl {
            display: flex;
            flex-direction: column;
            gap: 8px;
            margin-bottom: 16px;
            max-height: 260px;
            overflow-y: auto;
            padding: 2px;
        }
        .location-rbl input[type="radio"] {
            position: absolute;
            opacity: 0;
            pointer-events: none;
        }
        .location-rbl label {
            display: block;
            padding: 11px 14px;
            border: 1px solid var(--sp-line);
            border-radius: var(--sp-radius);
            background: #fff;
            cursor: pointer;
            font-weight: 500;
            font-size: 0.88rem;
            color: var(--sp-ink);
            transition: border-color 0.15s, background 0.15s, box-shadow 0.15s;
            margin: 0;
        }
        .location-rbl label:hover {
            border-color: var(--sp-green-600);
            background: #f8fdf9;
        }
        .location-rbl input[type="radio"]:checked + label {
            border-color: var(--sp-green-700);
            background: #ecfdf5;
            box-shadow: 0 0 0 2px rgba(27, 122, 61, 0.15);
            font-weight: 600;
        }

        /* ============================================================
           Agreement + action buttons
           ============================================================ */
        .agreement-box {
            background: var(--sp-paper);
            border: 1px solid var(--sp-line);
            border-radius: var(--sp-radius);
            padding: 12px 14px;
            margin-bottom: 16px;
        }
        .agreement-box .form-check-label {
            font-size: 0.83rem;
            line-height: 1.5;
            color: #2a3b30;
        }
        .countdown-note {
            margin: 10px 0 0;
            font-size: 0.78rem;
            color: #5b6b60;
            line-height: 1.45;
            display: flex;
            gap: 6px;
        }
        .countdown-note i { color: var(--sp-green-600); padding-top: 2px; }

        .action-row {
            display: flex;
            gap: 10px;
        }
        .btn-sp-primary,
        .btn-sp-outline {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            padding: 11px 16px;
            border-radius: var(--sp-radius);
            font-weight: 600;
            font-size: 0.9rem;
            border: 1px solid transparent;
            text-decoration: none !important;
            cursor: pointer;
            transition: background 0.15s, border-color 0.15s;
            flex: 1 1 auto;
        }
        .btn-sp-primary {
            background: var(--sp-green-700);
            color: #fff;
        }
        .btn-sp-primary:hover { background: var(--sp-green-900); color: #fff; }
        .btn-sp-primary:disabled,
        .btn-sp-primary.aspNetDisabled {
            background: #d1d5db; color: #6b7280; cursor: not-allowed;
        }
        .btn-sp-outline {
            background: transparent;
            border-color: var(--sp-line);
            color: var(--sp-green-900);
        }
        .btn-sp-outline:hover {
            background: var(--sp-paper);
            border-color: var(--sp-green-600);
        }
        .w-100 { width: 100%; }

        /* ============================================================
           Step 3 success
           ============================================================ */
        .success-header {
            text-align: center;
            padding: 8px 0 14px;
        }
        .success-icon-wrap {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 60px; height: 60px;
            border-radius: 50%;
            background: #ecfdf5;
            margin-bottom: 10px;
        }
        .success-icon-wrap i { font-size: 2rem; color: var(--sp-green-600); }
        .success-title {
            font-family: var(--sp-serif);
            font-weight: 700;
            color: var(--sp-green-900);
            font-size: 1.2rem;
            margin: 0 0 4px;
        }
        .success-sub {
            font-size: 0.82rem;
            color: #5b6b60;
            margin: 0;
        }

        .info-card {
            background: var(--sp-paper);
            border: 1px solid var(--sp-line);
            border-radius: var(--sp-radius);
            padding: 12px 14px;
            margin-bottom: 14px;
        }
        .info-row {
            display: flex;
            flex-direction: column;
            gap: 2px;
            padding: 6px 0;
            border-bottom: 1px dashed var(--sp-line);
        }
        .info-row:first-child { padding-top: 0; }
        .info-row:last-child { border-bottom: 0; padding-bottom: 0; }
        .info-label {
            font-size: 0.65rem;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            font-weight: 700;
            color: #6c757d;
        }
        .info-value {
            font-size: 0.9rem;
            font-weight: 600;
            color: var(--sp-ink);
            overflow-wrap: break-word;
        }
        .info-value.pending {
            display: flex;
            align-items: center;
            gap: 6px;
            color: #b45309;
            font-size: 0.85rem;
        }

        /* ============================================================
           Responsive
           ============================================================ */
        @media (max-width: 480px) {
            .reserve-main { padding: 14px 14px 20px; }
            .book-summary { grid-template-columns: 76px 1fr; gap: 10px; }
            .book-cover-container { width: 76px; height: 110px; }
            .step-label { display: none; }
            .action-row { flex-direction: column-reverse; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager ID="sm1" runat="server" />

        <asp:UpdatePanel ID="upReservation" runat="server" UpdateMode="Conditional">
            <ContentTemplate>

                <!-- ================= STICKY TOP ================= -->
                <div class="reserve-top">
                    <div class="reserve-header">
                        <div>
                            <h5 class="reserve-header-title">Reserve Book</h5>
                            <small class="reserve-header-sub">Complete the 3-step reservation process</small>
                        </div>
                        <asp:LinkButton ID="btnClose" runat="server" OnClick="Cancel_Click"
                            CssClass="reserve-close-btn" ToolTip="Close"
                            CausesValidation="false" aria-label="Close">&#215;</asp:LinkButton>
                    </div>

                    <div class="step-indicator">
                        <asp:Panel ID="step1" runat="server" CssClass="step-item active">
                            <div class="step-num">1</div>
                            <div class="step-label">Notices</div>
                        </asp:Panel>
                        <div class="step-connector"></div>
                        <asp:Panel ID="step2" runat="server" CssClass="step-item">
                            <div class="step-num">2</div>
                            <div class="step-label">Location</div>
                        </asp:Panel>
                        <div class="step-connector"></div>
                        <asp:Panel ID="step3" runat="server" CssClass="step-item">
                            <div class="step-num">3</div>
                            <div class="step-label">Confirm</div>
                        </asp:Panel>
                    </div>
                </div>

                <!-- ================= MAIN CONTENT ================= -->
                <div class="reserve-main">

                    <!-- ----- STEP 1: NOTICES ----- -->
                    <asp:Panel ID="pnlStep1" runat="server">
                        <div class="book-summary">
                            <div class="book-cover-container">
                                <asp:Image ID="imgCover" runat="server" AlternateText="Book Cover" />
                            </div>
                            <div class="book-summary-info">
                                <h6 class="book-title"><asp:Literal ID="litTitle" runat="server" /></h6>
                                <p class="book-author">by <asp:Literal ID="litAuthor" runat="server" /></p>
                                <span class="book-section"><asp:Literal ID="litSection" runat="server" /></span>
                            </div>
                        </div>

                        <h5 class="step-heading">Reservation Notices</h5>
                        <p class="step-desc">Please read the following notices before proceeding.</p>

                        <div class="notice-card notice-warning">
                            <div class="notice-icon"><i class="fas fa-clock"></i></div>
                            <div class="notice-body">
                                <h6 class="notice-title">One-Hour Pickup Limit</h6>
                                <p class="notice-text">
                                    After the library processes your reservation and marks the book as
                                    <strong>Ready for Pickup</strong>, you will receive a notification.
                                    You must collect the book <strong>within ONE HOUR</strong> after
                                    receiving that notification.
                                </p>
                                <p class="notice-text">
                                    Failure to collect within that period will result in
                                    <strong>automatic cancellation</strong> of your reservation.
                                </p>
                                <p class="notice-text">
                                    <em>The one-hour countdown does <strong>NOT</strong> start when you
                                    submit the reservation.</em>
                                </p>
                            </div>
                        </div>

                        <div class="notice-card notice-reminder">
                            <div class="notice-icon"><i class="fas fa-id-card"></i></div>
                            <div class="notice-body">
                                <h6 class="notice-title">What to Bring</h6>
                                <ul class="notice-list">
                                    <li>Valid SPAMAST school / library identification card</li>
                                    <li>Reservation confirmation or pickup-ready notification</li>
                                    <li>Any additional documents required by library policy</li>
                                </ul>
                            </div>
                        </div>

                        <div class="action-row mt-3">
                            <asp:Button ID="btnCancel1" runat="server" Text="Cancel"
                                CssClass="btn-sp-outline" OnClick="Cancel_Click"
                                CausesValidation="false" />
                            <asp:Button ID="btnNext1" runat="server" Text="Next →"
                                CssClass="btn-sp-primary" OnClick="Step1Next_Click" />
                        </div>
                    </asp:Panel>

                    <!-- ----- STEP 2: LOCATION ----- -->
                    <asp:Panel ID="pnlStep2" runat="server" Visible="false">
                        <h5 class="step-heading">Select Pickup Location</h5>
                        <p class="step-desc">Choose where you'll collect the book. Only locations with available copies are shown.</p>

                        <asp:Panel ID="pnlNoLocations" runat="server" Visible="false"
                            CssClass="notice-card notice-critical">
                            <div class="notice-icon"><i class="fas fa-exclamation-triangle"></i></div>
                            <div class="notice-body">
                                <h6 class="notice-title">No Pickup Locations Available</h6>
                                <p class="notice-text">
                                    All copies of this book are currently unavailable (borrowed,
                                    reserved, ready, damaged, or lost). Please try again later or
                                    choose a different book.
                                </p>
                            </div>
                        </asp:Panel>

                        <asp:RadioButtonList ID="rblLocations" runat="server"
                            RepeatLayout="Flow"
                            RepeatDirection="Vertical"
                            CssClass="location-rbl" />

                        <div class="action-row">
                            <asp:Button ID="btnCancel2" runat="server" Text="Cancel"
                                CssClass="btn-sp-outline" OnClick="Cancel_Click"
                                CausesValidation="false" />
                            <asp:Button ID="btnNext2" runat="server" Text="Next →"
                                CssClass="btn-sp-primary" OnClick="Step2Next_Click" />
                        </div>
                    </asp:Panel>

                    <!-- ----- STEP 3a: CONFIRMATION (final DB write happens here) ----- -->
                    <asp:Panel ID="pnlStep3Confirm" runat="server" Visible="false">
                        <h5 class="step-heading">Confirm Your Reservation</h5>
                        <p class="step-desc">Review the details below. Your reservation is not yet submitted.</p>

                        <div class="info-card">
                            <div class="info-row">
                                <span class="info-label">Book</span>
                                <span class="info-value"><asp:Literal ID="litConfirmBook" runat="server" /></span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">Pickup Location</span>
                                <span class="info-value"><asp:Literal ID="litConfirmLocation" runat="server" /></span>
                            </div>
                        </div>

                        <div class="notice-card notice-info">
                            <div class="notice-icon"><i class="fas fa-info-circle"></i></div>
                            <div class="notice-body">
                                <h6 class="notice-title">Before You Confirm</h6>
                                <p class="notice-text">
                                    Clicking <strong>Confirm Reservation</strong> will record your
                                    reservation request. Your one-hour pickup countdown will
                                    <strong>not start</strong> until the library notifies you that
                                    the book is ready for pickup.
                                </p>
                            </div>
                        </div>

                        <div class="agreement-box">
                            <div class="form-check">
                                <asp:CheckBox ID="chkTerms" runat="server" CssClass="form-check-input" />
                                <asp:Label ID="lblTerms" runat="server" AssociatedControlID="chkTerms"
                                    CssClass="form-check-label">
                                    I understand and agree that once I receive notification that my
                                    reserved book is <strong>Ready for Pickup</strong>, I must collect
                                    it <strong>within ONE HOUR</strong>. Failure to collect the book
                                    within the specified period will result in
                                    <strong>automatic cancellation</strong> of my reservation.
                                </asp:Label>
                            </div>
                            <p class="countdown-note">
                                <i class="fas fa-info-circle"></i>
                                <span>The one-hour pickup countdown starts <strong>only when the library
                                notifies you</strong> that your reserved book is ready for collection.</span>
                            </p>
                        </div>

                        <div class="action-row">
                            <asp:Button ID="btnCancel3" runat="server" Text="Cancel"
                                CssClass="btn-sp-outline" OnClick="Cancel_Click"
                                CausesValidation="false" />
                            <asp:Button ID="btnConfirm" runat="server" Text="Confirm Reservation"
                                CssClass="btn-sp-primary" OnClick="Confirm_Click" />
                        </div>
                    </asp:Panel>

                    <!-- ----- STEP 3b: SUCCESS ----- -->
                    <asp:Panel ID="pnlStep3Success" runat="server" Visible="false">

                        <div class="success-header">
                            <div class="success-icon-wrap">
                                <i class="fas fa-check-circle"></i>
                            </div>
                            <h4 class="success-title">Reservation Successfully Submitted!</h4>
                            <p class="success-sub">Your reservation request has been recorded.</p>
                        </div>

                        <div class="info-card">
                            <div class="info-row">
                                <span class="info-label">Book</span>
                                <span class="info-value"><asp:Literal ID="litTitleStep3" runat="server" /></span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">Pickup Location</span>
                                <span class="info-value"><asp:Literal ID="litPickupLocation" runat="server" /></span>
                            </div>
                            <div class="info-row">
                                <span class="info-label">Pickup Deadline</span>
                                <span class="info-value pending">
                                    <i class="fas fa-hourglass-half"></i>
                                    Pending – Waiting for Pickup-Ready Notification
                                </span>
                            </div>
                        </div>

                        <div class="notice-card notice-warning">
                            <div class="notice-icon"><i class="fas fa-clock"></i></div>
                            <div class="notice-body">
                                <h6 class="notice-title">Your pickup countdown has NOT started yet</h6>
                                <p class="notice-text">
                                    Please wait for the library to notify you when your book is
                                    ready for pickup. The <strong>one-hour pickup period begins
                                    only after you receive that notification</strong>.
                                </p>
                            </div>
                        </div>

                        <div class="notice-card notice-reminder">
                            <div class="notice-icon"><i class="fas fa-id-card"></i></div>
                            <div class="notice-body">
                                <h6 class="notice-title">What to Bring when Collecting</h6>
                                <ul class="notice-list">
                                    <li>Valid SPAMAST school / library identification card</li>
                                    <li>Reservation confirmation or pickup-ready notification</li>
                                    <li>Any additional documents required by library policy</li>
                                </ul>
                            </div>
                        </div>

                        <div class="notice-card notice-critical">
                            <div class="notice-icon"><i class="fas fa-exclamation-triangle"></i></div>
                            <div class="notice-body">
                                <h6 class="notice-title">Automatic Cancellation Warning</h6>
                                <p class="notice-text">
                                    Once you receive the pickup-ready notification, you have
                                    <strong>ONE HOUR</strong> to collect the book. Failure to do so
                                    will result in <strong>automatic cancellation</strong> of your
                                    reservation.
                                </p>
                            </div>
                        </div>

                        <asp:LinkButton ID="btnBrowseMore" runat="server" OnClick="Cancel_Click"
                            CssClass="btn-sp-primary w-100 mt-2" CausesValidation="false">
                            <i class="fas fa-book-open me-1"></i> Browse More Books
                        </asp:LinkButton>
                    </asp:Panel>

                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </form>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>