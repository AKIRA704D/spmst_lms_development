<%@ Page Title="Reservations" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master"
    AutoEventWireup="true" CodeBehind="Reservations.aspx.cs"
    Inherits="spmst_lms_development.Users.Staff.Reservation.Reservations" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <link href="<%= ResolveUrl("~/Assets/Themes/reservations-theme.css") %>" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="reservations-page">
        <div class="container-fluid">
            <div class="container-lg px-0">

                <%-- Wrap everything that must re-render on Mark Ready / Search in an UpdatePanel --%>
                <asp:UpdatePanel ID="upReservations" runat="server"
                    UpdateMode="Conditional" ChildrenAsTriggers="true">
                    <ContentTemplate>

                        <!-- Header -->
                        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
                            <div>
                                <h1 class="h2 page-title">Reservations</h1>
                                <p class="page-subtitle">Manage items held for patron pickup. Holds expire 1 hour after being marked Ready.</p>
                            </div>
                            <div class="stats-card">
                                <div class="label">Total Holds</div>
                                <div class="value"><asp:Literal ID="litTotalHolds" runat="server" Text="0" /> Items</div>
                            </div>
                        </div>

                        <div class="row g-4">

                            <!-- Main reservations table -->
                            <div class="col-lg-8">
                                <div class="sp-card">
                                    <div class="sp-card-header">
                                        <h5><i class="fas fa-bookmark me-2"></i>Reservation Queue</h5>
                                        <div class="sp-search">
                                            <asp:TextBox ID="txtSearchPatron" runat="server"
                                                placeholder="Search Patron ID or name…" />
                                            <asp:LinkButton ID="btnSearch" runat="server"
                                                OnClick="FilterReservations" CssClass="btn btn-sm">
                                                <i class="fas fa-search"></i>
                                            </asp:LinkButton>
                                        </div>
                                    </div>
                                    <div class="sp-card-body">
                                        <div class="table-responsive">
                                            <asp:Repeater ID="rptReservations" runat="server">
                                                <HeaderTemplate>
                                                    <table class="res-table">
                                                        <thead>
                                                            <tr>
                                                                <th>Patron</th>
                                                                <th>Book to Retrieve</th>
                                                                <th>Status</th>
                                                                <th>Expiration</th>
                                                                <th class="text-end">Action</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody>
                                                </HeaderTemplate>
                                                <ItemTemplate>
                                                    <tr class='<%# Eval("row_css") %>'>
                                                        <td data-label="Patron">
                                                            <span class="patron-name"><%# Eval("patron_name") %></span>
                                                            <span class="patron-id">ID: <%# Eval("user_id") %></span>
                                                        </td>
                                                        <td data-label="Book to Retrieve">
                                                            <div class="book-cell">
                                                                <img class="cover-thumb"
                                                                     src='<%# Eval("cover_url") %>'
                                                                     alt='<%# Eval("title") %> cover'
                                                                     loading="lazy"
                                                                     onerror="this.onerror=null;this.src='<%= ResolveUrl("~/Assets/Covers/default-cover.jpg") %>';" />
                                                                <div>
                                                                    <span class="book-title"><%# Eval("title") %></span>
                                                                    <span class="book-meta">Call #: <%# Eval("call_number") %></span>
                                                                    <span class="book-meta">Acc: <%# Eval("accession_number") %></span>
                                                                </div>
                                                            </div>
                                                        </td>
                                                        <td data-label="Status">
                                                            <span class='status-badge <%# Eval("status_css") %>'>
                                                                <%# Eval("display_status") %>
                                                            </span>
                                                        </td>
                                                        <td data-label="Expiration">
                                                            <span class="book-meta"><%# Eval("expiry_display") %></span>
                                                        </td>
                                                        <td data-label="Action" class="text-end">
                                                            <asp:PlaceHolder ID="phAction" runat="server"
                                                                Visible='<%# Convert.ToBoolean(Eval("action_visible")) %>'>
                                                                <asp:LinkButton ID="btnAction" runat="server"
                                                                    CommandArgument='<%# Eval("transaction_id") %>'
                                                                    CssClass='<%# Eval("action_css") %>'
                                                                    OnClick="HandleAction_Click"
                                                                    OnClientClick="return confirmMarkReady(this);">
                                                                    <i class='<%# Eval("action_icon") %>'></i>
                                                                    <%# Eval("action_text") %>
                                                                </asp:LinkButton>
                                                            </asp:PlaceHolder>
                                                        </td>
                                                    </tr>
                                                </ItemTemplate>
                                                <FooterTemplate>
                                                        </tbody>
                                                    </table>
                                                </FooterTemplate>
                                            </asp:Repeater>

                                            <asp:Panel ID="pnlEmptyReservations" runat="server" Visible="false" CssClass="sp-empty">
                                                <i class="fas fa-inbox"></i>
                                                <p>No reservations match the current filter.</p>
                                            </asp:Panel>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Expiring Soon -->
                            <div class="col-lg-4">
                                <div class="expiring-card">
                                    <div class="expiring-header">
                                        <h5><i class="fas fa-clock me-2"></i>Expiring Soon</h5>
                                        <span class="badge rounded-pill">
                                            <asp:Literal ID="litExpiringCount" runat="server" Text="0" />
                                        </span>
                                    </div>
                                    <div class="p-3">
                                        <div class="expiring-alert">
                                            <i class="fas fa-info-circle me-2"></i>
                                            Items below have <strong>20 minutes or less</strong> remaining and
                                            will be auto-cancelled by the database when their 1-hour hold ends.
                                        </div>

                                        <asp:Repeater ID="rptExpiring" runat="server">
                                            <ItemTemplate>
                                                <div class="expiring-item">
                                                    <img class="expiring-cover"
                                                         src='<%# Eval("cover_url") %>'
                                                         alt='<%# Eval("title") %> cover'
                                                         loading="lazy"
                                                         onerror="this.onerror=null;this.src='<%= ResolveUrl("~/Assets/Covers/default-cover.jpg") %>';" />
                                                    <div class="expiring-info">
                                                        <span class="book-title"><%# Eval("title") %></span>
                                                        <span class="book-meta"><%# Eval("patron_name") %> &middot; ID: <%# Eval("user_id") %></span>
                                                        <span class="book-meta">Acc: <%# Eval("accession_number") %></span>
                                                        <div class="expiry-time">Expires: <%# Eval("expiry_display") %></div>
                                                        <span class='countdown-badge <%# GetCountdownClass(Eval("seconds_left")) %>'
                                                              data-seconds='<%# Eval("seconds_left") %>'
                                                              data-expiry-ticks='<%# Eval("expiry_ticks") %>'>
                                                            <i class="fas fa-hourglass-half"></i>
                                                            <span class="countdown-text"><%# FormatTimeLeft(Eval("seconds_left")) %></span>
                                                        </span>
                                                    </div>
                                                </div>
                                            </ItemTemplate>
                                        </asp:Repeater>

                                        <asp:Panel ID="phNoExpiring" runat="server" Visible="false" CssClass="sp-empty">
                                            <i class="fas fa-circle-check"></i>
                                            <p>No reservations expiring in the next 20 minutes.</p>
                                        </asp:Panel>
                                    </div>
                                </div>
                            </div>

                        </div>

                    </ContentTemplate>
                </asp:UpdatePanel>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        function showSweetAlert(title, message, icon) {
            Swal.fire({ title: title, text: message, icon: icon, confirmButtonColor: '#14532d' });
        }

        /* -------------------------------------------------------------
         * Trigger a LinkButton's server postback reliably.
         * An <a> element has no `name`, so `button.name` is undefined.
         * The LinkButton's href already contains the correct UniqueID:
         *     href="javascript:__doPostBack('ctl00$...$btnAction','')"
         * ------------------------------------------------------------- */
        function triggerLinkButtonPostBack(button) {
            var href = (button && button.getAttribute('href')) || '';
            var match = href.match(/__doPostBack\('([^']+)'/);
            if (match && match[1]) {
                __doPostBack(match[1], '');
                return;
            }

            /* Fallback: temporarily strip OnClientClick and click the anchor,
               which lets the built-in href run __doPostBack with the right ID. */
            try {
                var saved = button.onclick;
                button.onclick = null;
                button.click();
                button.onclick = saved;
            } catch (e) { /* no-op */ }
        }

        function confirmMarkReady(button) {
            Swal.fire({
                title: 'Mark Ready & Notify Patron?',
                text: 'The patron will be notified via SMS, Email and In-App that this item is ready for pickup.',
                icon: 'question',
                showCancelButton: true,
                confirmButtonColor: '#14532d',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, mark ready',
                cancelButtonText: 'Cancel'
            }).then(function (result) {
                if (result.isConfirmed && button) {
                    triggerLinkButtonPostBack(button);
                }
            });
            return false;
        }

        /* -------------------------------------------------------------
         * Live countdown for Expiring Soon badges.
         * Re-runs after every async UpdatePanel postback via endRequest.
         * ------------------------------------------------------------- */
        function startCountdowns() {
            document.querySelectorAll('.countdown-badge[data-seconds]').forEach(function (el) {
                if (el.dataset.countdownStarted === '1') return;
                el.dataset.countdownStarted = '1';

                var secs = parseInt(el.getAttribute('data-seconds'), 10);
                if (isNaN(secs)) return;

                var label = el.querySelector('.countdown-text');

                function applyClasses(s) {
                    el.classList.remove('countdown-warn', 'countdown-urgent', 'countdown-done');
                    if (s <= 0) {
                        el.classList.add('countdown-done');
                    } else if (s <= 300) {
                        el.classList.add('countdown-urgent');
                    } else {
                        el.classList.add('countdown-warn');
                    }
                }

                function tick() {
                    if (secs <= 0) {
                        label.textContent = 'Expiring now';
                        applyClasses(0);
                        return false;
                    }
                    var m = Math.floor(secs / 60);
                    var s = secs % 60;
                    label.textContent = m + ':' + (s < 10 ? '0' : '') + s + ' left';
                    applyClasses(secs);
                    secs--;
                    return true;
                }

                applyClasses(secs);
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