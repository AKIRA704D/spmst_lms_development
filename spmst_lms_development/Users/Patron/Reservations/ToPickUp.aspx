<%@ Page Title="My Reservations" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="ToPickUp.aspx.cs" Inherits="spmst_lms_development.Users.Patron.Reservations.ToPickUp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <link href="<%= ResolveUrl("~/Assets/Themes/to-pick-up-theme.css") %>" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="pickup-page">
        <header class="pickup-header">
            <div>
                <h1 class="pickup-title">My Book Reservations</h1>
                <p class="pickup-subtitle">Track your reserved books and pickup deadlines.</p>
            </div>
        </header>

        <section class="pickup-summary-grid" aria-label="Reservation summary">
            <div class="summary-card pickup-summary-card accent-ready">
                <div class="summary-card-title">
                    <i class="fas fa-check-circle" aria-hidden="true"></i> Ready For Pickup
                </div>
                <div class="summary-card-value">
                    <asp:Literal ID="litReadyCount" runat="server" Text="0" />
                </div>
            </div>

            <div class="summary-card pickup-summary-card accent-processing">
                <div class="summary-card-title">
                    <i class="fas fa-clock" aria-hidden="true"></i> Processing
                </div>
                <div class="summary-card-value">
                    <asp:Literal ID="litProcessingCount" runat="server" Text="0" />
                </div>
            </div>
        </section>

        <section class="pickup-panel" aria-label="Active reservations">
            <div class="pickup-panel-header">
                <h2><i class="fas fa-bookmark" aria-hidden="true"></i> Active Reservations</h2>
            </div>

            <asp:Repeater ID="rptReservations" runat="server" OnItemCommand="rptReservations_ItemCommand">
                <HeaderTemplate>
                    <div class="reservation-list">
                </HeaderTemplate>

                <ItemTemplate>
                    <article class='<%# Eval("RowCss") %>'>
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
                                Visible='<%# System.Convert.ToBoolean(Eval("CancelVisible")) %>'
                                OnClientClick='<%# "return confirmCancel(this, " + System.Web.HttpUtility.JavaScriptStringEncode(System.Convert.ToString(Eval("Title")), true) + ");" %>' />

                            <asp:PlaceHolder ID="phExpiredNote" runat="server"
                                Visible='<%# System.Convert.ToBoolean(Eval("IsExpired")) %>'>
                                <span class="expired-note">Reservation expired</span>
                            </asp:PlaceHolder>
                        </div>
                    </article>
                </ItemTemplate>

                <FooterTemplate>
                    </div>
                </FooterTemplate>
            </asp:Repeater>

            <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="pickup-empty">
                <i class="fas fa-book-open" aria-hidden="true"></i>
                <p>You have no active book reservations at this time.</p>
            </asp:Panel>
        </section>
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
    </script>
</asp:Content>