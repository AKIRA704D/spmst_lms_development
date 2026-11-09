<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="View_BookDetails.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Catalog.View_BookDetails" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Book Details</title>
    <link href="<%= ResolveUrl("~/Assets/Themes/spamast-theme.css") %>" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <style>
        /* ---------- Base ---------- */
        html, body {
            height: 100%;
            margin: 0;
            background: var(--sp-paper);
            font-family: var(--sp-sans);
            color: var(--sp-ink);
            overflow: hidden;
        }

        #form1 {
            display: flex;
            flex-direction: column;
            height: 100%;
            overflow: hidden;
        }

        /* ---------- ROW 1 : HEADER ---------- */
        .book-header {
            flex: 0 0 auto;
            background: linear-gradient(135deg, var(--sp-green-900), var(--sp-green-800));
            color: #fff;
            padding: 12px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 3px solid var(--sp-gold);
            z-index: 5;
        }
        .book-header h5 {
            margin: 0;
            font-family: var(--sp-serif);
            font-weight: 700;
            font-size: 1.05rem;
            letter-spacing: 0.3px;
        }
        .book-header small {
            opacity: 0.9;
            font-size: 0.78rem;
        }
        .modal-close {
            background: transparent;
            border: none;
            color: #fff;
            font-size: 1.6rem;
            line-height: 1;
            cursor: pointer;
            padding: 0 8px;
            opacity: 0.8;
            transition: opacity 0.15s;
        }
        .modal-close:hover { opacity: 1; }

        /* ---------- ROW 2 : BOOK INFORMATION ---------- */
        .book-information {
            flex: 0 0 auto;
            background: #fff;
            border-bottom: 1px solid var(--sp-line);
            padding: 16px 20px;
            box-shadow: 0 1px 4px rgba(11, 61, 44, 0.06);
        }
        .book-info-inner {
            display: grid;
            grid-template-columns: 160px 1fr;
            gap: 20px;
            align-items: flex-start;
            max-width: var(--sp-wrap);
            margin: 0 auto;
        }
        .book-cover-container {
            width: 160px;
            height: 220px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: var(--sp-paper);
            border: 1px solid var(--sp-line);
            border-radius: var(--sp-radius);
            overflow: hidden;
        }
        .book-cover-container img {
            width: 100%;
            height: 100%;
            object-fit: contain;
            object-position: center;
            display: block;
        }
        .book-info-fields { min-width: 0; overflow-wrap: break-word; }
        .book-info-fields h2 {
            font-family: var(--sp-serif);
            font-weight: 700;
            color: var(--sp-green-900);
            font-size: 1.35rem;
            margin: 0 0 4px 0;
            line-height: 1.25;
        }
        .book-info-fields .author {
            color: #5a6b5e;
            margin: 0 0 12px 0;
            font-style: italic;
            font-size: 0.9rem;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
            gap: 10px 16px;
        }
        .info-label {
            font-size: 0.65rem;
            font-weight: 700;
            text-transform: uppercase;
            color: #6c757d;
            letter-spacing: 0.5px;
        }
        .info-value {
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--sp-ink);
        }
        .description-cell { grid-column: 1 / -1; }
        .info-value.description {
            font-weight: 400;
            color: #3a4a3e;
            max-height: 64px;
            overflow-y: auto;
            margin-top: 2px;
        }

        /* ---------- ROW 3 : COPIES ---------- */
        .copies-section {
            flex: 1 1 auto;
            min-height: 0;
            display: flex;
            flex-direction: column;
            background: var(--sp-paper);
        }
        .copies-header {
            flex: 0 0 auto;
            padding: 10px 20px;
            background: #fff;
            border-bottom: 1px solid var(--sp-line);
            font-weight: 700;
            font-family: var(--sp-serif);
            color: var(--sp-green-800);
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 0.95rem;
        }
        .copies-scroll {
            flex: 1 1 auto;
            min-height: 0;
            overflow-y: auto;
            overflow-x: hidden;
            scroll-behavior: smooth;
        }
        .copies-grid {
            display: grid;
            gap: 12px;
            padding: 16px 20px;
            grid-template-columns: repeat(5, minmax(0, 1fr));
        }

        /* ---------- Copy Cards ---------- */
        .copy-card {
            border-radius: var(--sp-radius);
            padding: 10px;
            display: flex;
            flex-direction: column;
            gap: 6px;
            min-width: 0;
            transition: transform 0.15s ease, box-shadow 0.15s ease;
        }
        .copy-card.available {
            background: #fff;
            border: 1px solid var(--sp-line);
            opacity: 1;
        }
        .copy-card.available:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(11, 61, 44, 0.12);
            border-color: var(--sp-green-600);
        }
        .copy-card.unavailable {
            background: #e5e7eb;
            border: 1px solid #d1d5db;
            cursor: not-allowed;
        }
        .copy-card.unavailable .copy-acc { color: #6b7280; }
        .copy-card.unavailable .copy-acc-label { color: #9ca3af; }
        .copy-card.unavailable .status-badge {
            filter: grayscale(55%);
            opacity: 0.92;
        }
        .copy-card.unavailable .condition-badge {
            background: #d1d5db;
            color: #4b5563;
        }

        .copy-acc-label {
            font-size: 0.6rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #6c757d;
            font-weight: 700;
        }
        .copy-acc {
            font-weight: 700;
            font-size: 0.85rem;
            color: var(--sp-ink);
            word-break: break-word;
            line-height: 1.2;
        }
        .copy-badges {
            display: flex;
            flex-wrap: wrap;
            gap: 4px;
            margin-top: 2px;
        }
        .status-badge, .condition-badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 999px;
            font-size: 0.63rem;
            font-weight: 600;
            white-space: nowrap;
        }
        .status-available {
            color: #fff;
            background: var(--sp-green-600);
        }
        .status-reserved {
            color: #1e40af;
            background: #dbeafe;
        }
        .status-borrowed {
            color: #b91c1c;
            background: #fee2e2;
        }
        .status-damaged {
            color: #92400e;
            background: #fef3c7;
        }
        .status-default {
            color: #4b5563;
            background: #e5e7eb;
        }
        .condition-good {
            color: var(--sp-green-700);
            background: #ecfdf5;
        }
        .condition-damaged {
            color: #92400e;
            background: #fef3c7;
        }
        .condition-lost {
            color: #b91c1c;
            background: #fee2e2;
        }
        .condition-reserved {
            color: #1e40af;
            background: #dbeafe;
        }
        .condition-default {
            color: #4b5563;
            background: #f3f4f6;
        }

        .empty-state {
            text-align: center;
            padding: 40px 20px;
            color: #6c757d;
            font-style: italic;
        }
        .empty-state i {
            font-size: 1.5rem;
            display: block;
            margin-bottom: 8px;
            color: var(--sp-green-600);
        }

        /* ---------- Responsive ---------- */
        @media (min-width: 1200px) {
            .copies-grid { grid-template-columns: repeat(5, minmax(0, 1fr)); }
        }
        @media (min-width: 768px) and (max-width: 1199px) {
            .copies-grid { grid-template-columns: repeat(4, minmax(0, 1fr)); }
        }
        @media (max-width: 767px) {
            .book-info-inner { grid-template-columns: 110px 1fr; gap: 12px; }
            .book-cover-container { width: 110px; height: 150px; }
            .book-info-fields h2 { font-size: 1.05rem; }
            .info-grid { grid-template-columns: repeat(auto-fit, minmax(110px, 1fr)); gap: 8px 12px; }
            .copies-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); padding: 12px; gap: 10px; }
        }
        @media (max-width: 480px) {
            .book-info-inner { grid-template-columns: 1fr; }
            .book-cover-container { width: 120px; height: 160px; margin: 0 auto; }
            .copies-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .info-value.description { max-height: 48px; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">

        <!-- ============================================================
             ROW 1 : FIXED HEADER
             ============================================================ -->
        <header class="book-header">
            <div>
                <h5><i class="fas fa-book-open" style="margin-right:6px;"></i>Resource Information</h5>
                <small>Primary Acc No: <asp:Literal ID="litAccession" runat="server" Text="N/A" /></small>
            </div>
            <button type="button" class="modal-close" aria-label="Close"
                    onclick="if (window.parent && window.parent.closeUniversalModal) { window.parent.closeUniversalModal(); }">&#215;</button>
        </header>

        <!-- ============================================================
             ROW 2 : FIXED BOOK INFORMATION
             ============================================================ -->
        <section class="book-information">
            <div class="book-info-inner">
                <div class="book-cover-container">
                    <asp:Image ID="imgCover" runat="server" AlternateText="Book Cover" />
                </div>
                <div class="book-info-fields">
                    <h2><asp:Literal ID="litTitle" runat="server" /></h2>
                    <p class="author">by <asp:Literal ID="litAuthor" runat="server" /></p>
                    <div class="info-grid">
                        <div>
                            <div class="info-label">ISBN</div>
                            <div class="info-value"><asp:Literal ID="litISBN" runat="server" /></div>
                        </div>
                        <div>
                            <div class="info-label">Edition</div>
                            <div class="info-value"><asp:Literal ID="litEdition" runat="server" /></div>
                        </div>
                        <div>
                            <div class="info-label">Call Number</div>
                            <div class="info-value"><asp:Literal ID="litCallNum" runat="server" /></div>
                        </div>
                        <div>
                            <div class="info-label">Publisher</div>
                            <div class="info-value"><asp:Literal ID="litPublisher" runat="server" /></div>
                        </div>
                        <div>
                            <div class="info-label">Year</div>
                            <div class="info-value"><asp:Literal ID="litYear" runat="server" /></div>
                        </div>
                        <div>
                            <div class="info-label">Pages</div>
                            <div class="info-value"><asp:Literal ID="litPages" runat="server" /></div>
                        </div>
                        <div class="description-cell">
                            <div class="info-label">Description</div>
                            <div class="info-value description"><asp:Literal ID="litDescription" runat="server" Text="No description available." /></div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- ============================================================
             ROW 3 : SCROLLABLE ITEM COPIES
             ============================================================ -->
        <section class="copies-section">
            <div class="copies-header">
                <i class="fas fa-copy"></i> Physical Copies
            </div>
            <div class="copies-scroll">
                <asp:Repeater ID="rptCopies" runat="server">
                    <HeaderTemplate><div class="copies-grid"></HeaderTemplate>
                    <ItemTemplate>
                        <div class='<%# GetCopyCardClass(Eval("availability_reason")) %>'>
                            <div class="copy-acc-label">Accession No.</div>
                            <div class="copy-acc"><%# Eval("accession_number") %></div>
                            <div class="copy-badges">
                                <span class='<%# GetStatusClass(Eval("availability_reason")) %>'><%# Eval("availability_reason") %></span>
                                <span class='<%# GetConditionClass(Eval("status_condition")) %>'><%# Eval("status_condition") %></span>
                            </div>
                        </div>
                    </ItemTemplate>
                    <FooterTemplate></div></FooterTemplate>
                </asp:Repeater>

                <asp:Panel ID="pnlNoCopies" runat="server" Visible="false" CssClass="empty-state">
                    <i class="fas fa-info-circle"></i>
                    No copies recorded for this resource.
                </asp:Panel>
            </div>
        </section>

    </form>

    <script>
// Tell the parent this page owns a full-height layout with an internal
// scroll region. The parent will skip its content-measuring logic and
// let CSS (calc(90dvh - 2px)) size the iframe instead.
(function signalFullHeight() {
    function apply() {
        if (window.parent && typeof window.parent.setModalFullHeight === 'function') {
            window.parent.setModalFullHeight();
        }
    }

    apply();                                                     // immediately
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', apply);    // after parse
    }
    window.addEventListener('load', apply);                      // after assets
    setTimeout(apply, 100);                                      // beat parent's 50/150/300ms timers
    setTimeout(apply, 300);
    })();
    </script>
</body>
</html>