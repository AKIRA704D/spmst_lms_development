<%@ Page Title="My Reservations" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master"
    AutoEventWireup="true" CodeBehind="ToPickUp.aspx.cs"
    Inherits="spmst_lms_development.Users.Patron.Reservations.ToPickUp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <link href="<%= ResolveUrl("~/Assets/Themes/reservations-theme.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Assets/Themes/to-pick-up-theme.css") %>" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="pickup-page">
        <div class="container">
            <header class="pickup-header mb-4">
                <h1 class="pickup-title">My Book Reservations</h1>
                <p class="pickup-subtitle">Track your reserved books and pickup deadlines.</p>
            </header>

            <section class="pickup-summary-grid mb-4" aria-label="Reservation summary">
                <div class="summary-card pickup-summary-card accent-ready sp-card">
                    <div class="summary-card-title">
                        <i class="fas fa-check-circle" aria-hidden="true"></i> Ready For Pickup
                    </div>
                    <div class="summary-card-value">
                        <span id="readyCountValue"><asp:Literal ID="litReadyCount" runat="server" Text="0" /></span>
                    </div>
                </div>

                <div class="summary-card pickup-summary-card accent-processing sp-card">
                    <div class="summary-card-title">
                        <i class="fas fa-clock" aria-hidden="true"></i> Processing
                    </div>
                    <div class="summary-card-value">
                        <span id="processingCountValue"><asp:Literal ID="litProcessingCount" runat="server" Text="0" /></span>
                    </div>
                </div>
            </section>

            <section class="pickup-panel sp-card" aria-label="Active reservations">
                <div class="pickup-panel-header sp-card-header">
                    <h2><i class="fas fa-bookmark" aria-hidden="true"></i> Active Reservations</h2>
                    <span class="book-meta" id="lastUpdatedLabel" aria-live="polite"></span>
                </div>

                <div id="reservationListContainer">
                    <asp:Repeater ID="rptReservations" runat="server" OnItemCommand="rptReservations_ItemCommand">
                        <HeaderTemplate>
                            <div class="reservation-list">
                        </HeaderTemplate>

                        <ItemTemplate>
                            <article class='<%# Eval("RowCss") %>' data-txn-id='<%# Eval("TransactionID") %>'>
                                <div class="reservation-cover-wrap">
                                    <img class="reservation-cover"
                                         src='<%# Eval("CoverUrl") %>'
                                         alt='<%# Eval("Title") %> cover'
                                         loading="lazy"
                                         onerror='<%# "this.onerror=null;this.src=\"" + Eval("CoverFallbackUrl") + "\";" %>' />
                                </div>

                                <div class="reservation-main">
                                    <h3 class="reservation-title"><%# Eval("Title") %></h3>
                                    <p class="reservation-author">by <%# Eval("DisplayAuthor") %></p>

                                    <div class="reservation-meta">
                                        <span>
                                            <span class="meta-label">Reserved:</span>
                                            <%# Eval("ReservedDateDisplay") %>
                                        </span>
                                        <span>
                                            <span class="meta-label">Status:</span>
                                            <span class='status-badge <%# Eval("StatusCss") %>'>
                                                <%# Eval("StatusText") %>
                                            </span>
                                        </span>
                                        <span>
                                            <span class="meta-label">Expiry:</span>
                                            <span class="expiry-text"><%# Eval("ExpiryDisplay") %></span>
                                        </span>
                                    </div>
                                </div>

                                <div class="reservation-actions">
                                    <asp:Button ID="btnCancel" runat="server"
                                        CommandName="CancelReservation"
                                        CommandArgument='<%# Eval("TransactionID") %>'
                                        Text="Cancel Reservation"
                                        CssClass="btn-cancel"
                                        Visible='<%# Convert.ToBoolean(Eval("CancelVisible")) %>'
                                        OnClientClick='<%# "return confirmCancel(this, " + System.Web.HttpUtility.JavaScriptStringEncode(Convert.ToString(Eval("Title")), true) + ");" %>' />

                                    <asp:PlaceHolder ID="phExpiredNote" runat="server"
                                        Visible='<%# Convert.ToBoolean(Eval("IsExpired")) %>'>
                                        <span class="expired-note">Reservation expired</span>
                                    </asp:PlaceHolder>
                                </div>
                            </article>
                        </ItemTemplate>

                        <FooterTemplate>
                            </div>
                        </FooterTemplate>
                    </asp:Repeater>

                    <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="sp-empty">
                        <i class="fas fa-book-open"></i>
                        <p>You have no active book reservations at this time.</p>
                    </asp:Panel>
                </div>
            </section>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        function confirmCancel(button, bookTitle) {
            Swal.fire({
                title: 'Cancel Reservation',
                text: 'Are you sure you want to cancel your reservation for "' + bookTitle + '"?',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#14532d',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, cancel it',
                cancelButtonText: 'No, keep it'
            }).then(function (result) {
                if (result.isConfirmed && button) {
                    __doPostBack(button.name, '');
                }
            });
            return false;
        }

        function showSweetAlert(title, message, icon) {
            Swal.fire({
                title: title,
                text: message,
                icon: icon,
                confirmButtonColor: '#14532d'
            });
        }

        /* ==================================================================
         * Real-time polling: refreshes reservation statuses from the server
         * without a full page reload. Uses only session-authenticated data.
         * ================================================================== */
        (function () {
            var ENDPOINT = '<%= ResolveUrl("~/Handlers/ReservationStatusHandler.ashx") %>';
            var POLL_MS = 15000;
            var pollTimer = null;
            var isPolling = false;
            var firstPoll = true;
            var previousStatus = {};   /* txnId -> last seen server status */
            var previousCss = {};      /* txnId -> last seen row class */

            function setCounters(ready, processing) {
                var r = document.getElementById('readyCountValue');
                var p = document.getElementById('processingCountValue');
                if (r) r.textContent = ready;
                if (p) p.textContent = processing;
            }

            function setLastUpdated() {
                var lbl = document.getElementById('lastUpdatedLabel');
                if (!lbl) return;
                var now = new Date();
                lbl.textContent = 'Updated ' + now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            }

            function notifyReady(title) {
                if (typeof Swal === 'undefined') return;
                Swal.fire({
                    title: 'Book Ready for Pickup!',
                    text: 'Your reservation for "' + title + '" is now ready for pickup.',
                    icon: 'success',
                    confirmButtonColor: '#14532d',
                    toast: true,
                    position: 'top-end',
                    showConfirmButton: false,
                    timer: 6000,
                    timerProgressBar: true
                });
            }

            function applyStatusUpdate(payload) {
                setCounters(payload.ReadyCount, payload.ProcessingCount);
                setLastUpdated();

                var container = document.getElementById('reservationListContainer');
                if (!container) return;

                var cards = container.querySelectorAll('[data-txn-id]');
                var domIds = {};
                cards.forEach(function (c) { domIds[c.getAttribute('data-txn-id')] = true; });

                var newIds = {};
                payload.Reservations.forEach(function (r) { newIds[String(r.TransactionId)] = true; });

                var setChanged = false;
                for (var id in domIds) { if (!newIds[id]) { setChanged = true; break; } }
                if (!setChanged) {
                    for (var nid in newIds) { if (!domIds[nid]) { setChanged = true; break; } }
                }

                if (setChanged && !firstPoll) {
                    /* Structure changed: safe to reload to pick up server-rendered state. */
                    window.location.reload();
                    return;
                }
                firstPoll = false;

                payload.Reservations.forEach(function (r) {
                    var card = container.querySelector('[data-txn-id="' + r.TransactionId + '"]');
                    if (!card) return;

                    /* Row CSS (e.g. .reservation-expired) */
                    if (card.className !== r.RowCss) card.className = r.RowCss;

                    /* Status badge */
                    var badge = card.querySelector('.status-badge');
                    if (badge) {
                        if (badge.textContent.trim() !== r.StatusText)
                            badge.textContent = r.StatusText;
                        if (badge.className !== ('status-badge ' + r.StatusCss))
                            badge.className = 'status-badge ' + r.StatusCss;
                    }

                    /* Expiry text */
                    var expiry = card.querySelector('.expiry-text');
                    if (expiry && expiry.textContent.trim() !== r.ExpiryDisplay)
                        expiry.textContent = r.ExpiryDisplay;

                    /* Cancel button visibility (server-rendered; hidden via CSS) */
                    var cancel = card.querySelector('.btn-cancel');
                    if (cancel) cancel.style.display = r.CancelVisible ? '' : 'none';

                    /* Expired note */
                    var expiredNote = card.querySelector('.expired-note');
                    if (expiredNote && r.IsExpired) expiredNote.style.display = '';
                    if (expiredNote && !r.IsExpired) expiredNote.style.display = 'none';

                    /* Transition into Ready => toast */
                    var prev = previousStatus[r.TransactionId];
                    if (prev && prev !== 'Ready' && r.Status === 'Ready' && !r.IsExpired) {
                        notifyReady(r.Title);
                    }
                    previousStatus[r.TransactionId] = r.Status;
                    previousCss[r.TransactionId] = r.RowCss;
                });

                /* Hide empty panel if we now have rows */
                var emptyPanel = document.querySelector('.pickup-panel .sp-empty');
                if (emptyPanel) emptyPanel.style.display = payload.Reservations.length > 0 ? 'none' : '';
            }

            function poll() {
                if (isPolling) return;
                if (document.hidden) return;
                isPolling = true;

                fetch(ENDPOINT, {
                    method: 'GET',
                    credentials: 'same-origin',
                    headers: { 'Accept': 'application/json' },
                    cache: 'no-store'
                })
                .then(function (resp) {
                    if (resp.status === 401) { window.location.href = '<%= ResolveUrl("~/Login/login.aspx") %>'; return null; }
                    if (!resp.ok) throw new Error('HTTP ' + resp.status);
                    return resp.json();
                })
                    .then(function (data) {
                        if (data && data.Success) applyStatusUpdate(data);
                    })
                    .catch(function () { /* silent — retry on next tick */ })
                    .finally(function () { isPolling = false; });
            }

            function start() {
                if (pollTimer) return;
                pollTimer = setInterval(poll, POLL_MS);
                poll();
            }

            document.addEventListener('visibilitychange', function () {
                if (!document.hidden) poll();
            });

            if (document.readyState === 'loading')
                document.addEventListener('DOMContentLoaded', start);
            else
                start();
        })();
    </script>
</asp:Content>