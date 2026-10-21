<%@ Page Title="My Dashboard" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="PatronDash.aspx.cs" Inherits="spmst_lms_development.Users.Patron.Dashboard.PatronDash" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Assets/Themes/patron-dashboard-theme.css") %>" />
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="pd-wrap">

        <%-- ============ HEADER ============ --%>
        <header class="pd-header">
            <div>
                <p class="pd-eyebrow"><asp:Literal ID="litTodayDate" runat="server" /></p>
                <h1 class="pd-title">
                    Welcome back, <asp:Literal ID="litFirstName" runat="server" Text="Reader" Mode="Encode" /> 👋
                </h1>
                <p class="pd-subtitle">A quick look at what you're reading, what's waiting, and where you stand.</p>
            </div>
            <div class="pd-rank-badge" aria-label="Library standing">
                <span class="pd-rank-label">Library Standing</span>
                <span class="pd-rank-value"><asp:Literal ID="litRank" runat="server" Text="New Explorer 📖" /></span>
            </div>
        </header>

        <%-- ============ STATS ============ --%>
        <section class="pd-stats" aria-label="Summary statistics">
            <a href="#pdBorrowedHeading" class="pd-stat" aria-label="Currently borrowed books">
                <span class="pd-stat-value"><asp:Literal ID="litOnHand" runat="server" Text="0" /></span>
                <span class="pd-stat-label">Borrowed</span>
            </a>
            <a href="#pdReservationsHeading" class="pd-stat" aria-label="Active reservations">
                <span class="pd-stat-value"><asp:Literal ID="litReservations" runat="server" Text="0" /></span>
                <span class="pd-stat-label">Reservations</span>
            </a>
            <a href="#pdReservationsHeading" class="pd-stat" aria-label="Books ready for pickup">
                <span class="pd-stat-value"><asp:Literal ID="litReady" runat="server" Text="0" /></span>
                <span class="pd-stat-label">Ready for Pickup</span>
            </a>
            <a href="#pdBorrowedHeading" class="pd-stat" aria-label="Returned books">
                <span class="pd-stat-value"><asp:Literal ID="litReturned" runat="server" Text="0" /></span>
                <span class="pd-stat-label">Returned</span>
            </a>
            <a href="#pdReservationsHeading" class="pd-stat" aria-label="Pending renewals">
                <span class="pd-stat-value"><asp:Literal ID="litPendingRenewals" runat="server" Text="0" /></span>
                <span class="pd-stat-label">Renewals</span>
            </a>
            <a href="#pdFinesHeading" class="pd-stat pd-stat-fine" aria-label="Outstanding fines">
                <span class="pd-stat-value"><asp:Literal ID="litFines" runat="server" Text="₱0.00" /></span>
                <span class="pd-stat-label">Outstanding Fines</span>
            </a>
        </section>

        <%-- ============ MAIN GRID ============ --%>
        <div class="pd-grid">

            <%-- ---------- LEFT COLUMN ---------- --%>
            <div class="pd-col">

                <section class="pd-card" aria-labelledby="pdBorrowedHeading">
                    <header class="pd-card-header">
                        <h2 id="pdBorrowedHeading" class="pd-card-title">Currently Borrowed</h2>
                    </header>

                    <asp:Panel ID="pnlNoBorrowed" runat="server" CssClass="pd-empty" Visible="false">
                        <p>You don't have any borrowed books right now.</p>
                    </asp:Panel>

                    <asp:Repeater ID="rptBorrowed" runat="server">
                        <HeaderTemplate><ul class="pd-books"></HeaderTemplate>
                        <ItemTemplate>
                            <li class="pd-book">
                                <img src='<%#: ResolveCover(Eval("cover_path")) %>' alt="" class="pd-book-cover" loading="lazy" />
                                <div class="pd-book-info">
                                    <h3 class="pd-book-title"><%#: Eval("title") %></h3>
                                    <p class="pd-book-author"><%#: Eval("author") %></p>
                                    <p class="pd-book-meta">
                                        Borrowed <%# Eval("borrow_date", "{0:MMM dd, yyyy}") %>
                                        · Due <%# Eval("due_date", "{0:MMM dd, yyyy}") %>
                                    </p>
                                </div>
                                <span class='pd-pill <%# Eval("pill_class") %>'><%#: Eval("pill_text") %></span>
                            </li>
                        </ItemTemplate>
                        <FooterTemplate></ul></FooterTemplate>
                    </asp:Repeater>
                </section>

                <section class="pd-card" aria-labelledby="pdReservationsHeading">
                    <header class="pd-card-header">
                        <h2 id="pdReservationsHeading" class="pd-card-title">Reservations &amp; Renewals</h2>
                    </header>

                    <asp:Panel ID="pnlNoActivity" runat="server" CssClass="pd-empty" Visible="false">
                        <p>No active reservations or renewal requests.</p>
                    </asp:Panel>

                    <asp:Repeater ID="rptActivity" runat="server">
                        <HeaderTemplate><ul class="pd-books"></HeaderTemplate>
                        <ItemTemplate>
                            <li class="pd-book">
                                <img src='<%#: ResolveCover(Eval("cover_path")) %>' alt="" class="pd-book-cover" loading="lazy" />
                                <div class="pd-book-info">
                                    <h3 class="pd-book-title"><%#: Eval("title") %></h3>
                                    <p class="pd-book-author"><%#: Eval("author") %></p>
                                    <p class="pd-book-meta"><%#: Eval("meta") %></p>
                                </div>
                                <span class='pd-pill <%# Eval("pill_class") %>'><%#: Eval("pill_text") %></span>
                            </li>
                        </ItemTemplate>
                        <FooterTemplate></ul></FooterTemplate>
                    </asp:Repeater>
                </section>

            </div>

            <%-- ---------- RIGHT COLUMN ---------- --%>
            <div class="pd-col">

                <section class="pd-card" aria-labelledby="pdRecsHeading">
                    <header class="pd-card-header">
                        <h2 id="pdRecsHeading" class="pd-card-title">Recommended For You</h2>
                    </header>

                    <asp:Panel ID="pnlNoRecs" runat="server" CssClass="pd-empty" Visible="false">
                        <p>Borrow your first book to unlock personalized recommendations.</p>
                    </asp:Panel>

                    <asp:Repeater ID="rptRecommendations" runat="server">
                        <HeaderTemplate><ul class="pd-recs"></HeaderTemplate>
                        <ItemTemplate>
                            <li class="pd-rec">
                                <img src='<%#: ResolveCover(Eval("cover_path")) %>' alt="" class="pd-rec-cover" loading="lazy" />
                                <div>
                                    <p class="pd-rec-title"><%#: Eval("title") %></p>
                                    <p class="pd-rec-author"><%#: Eval("author") %></p>
                                </div>
                            </li>
                        </ItemTemplate>
                        <FooterTemplate></ul></FooterTemplate>
                    </asp:Repeater>
                </section>

                <section class="pd-card" aria-labelledby="pdFinesHeading">
                    <header class="pd-card-header">
                        <h2 id="pdFinesHeading" class="pd-card-title">Fines &amp; Penalties</h2>
                    </header>

                    <asp:Panel ID="pnlNoFines" runat="server" CssClass="pd-empty" Visible="false">
                        <p>You have no outstanding fines. 🎉</p>
                    </asp:Panel>

                    <asp:Repeater ID="rptFines" runat="server">
                        <HeaderTemplate><ul class="pd-fines"></HeaderTemplate>
                        <ItemTemplate>
                            <li class="pd-fine">
                                <div>
                                    <p class="pd-fine-title"><%#: Eval("title") %></p>
                                    <p class="pd-fine-reason"><%#: Eval("reason") %></p>
                                </div>
                                <span class="pd-fine-amount">₱<%# Eval("balance", "{0:N2}") %></span>
                            </li>
                        </ItemTemplate>
                        <FooterTemplate></ul></FooterTemplate>
                    </asp:Repeater>
                </section>

                <section class="pd-card" aria-labelledby="pdNotifHeading">
                    <header class="pd-card-header">
                        <h2 id="pdNotifHeading" class="pd-card-title">Notifications</h2>
                    </header>

                    <asp:Panel ID="pnlNoNotif" runat="server" CssClass="pd-empty" Visible="false">
                        <p>No notifications yet.</p>
                    </asp:Panel>

                    <asp:Repeater ID="rptNotifications" runat="server">
                        <HeaderTemplate><ul class="pd-notifs"></HeaderTemplate>
                        <ItemTemplate>
                            <li class='pd-notif <%# Eval("notif_class") %>'>
                                <p class="pd-notif-title"><%#: Eval("title") %></p>
                                <p class="pd-notif-msg"><%#: Eval("message") %></p>
                                <p class="pd-notif-date"><%# Eval("created_at", "{0:MMM dd, yyyy h:mm tt}") %></p>
                            </li>
                        </ItemTemplate>
                        <FooterTemplate></ul></FooterTemplate>
                    </asp:Repeater>
                </section>

                <section class="pd-card" aria-labelledby="pdQuickHeading">
                    <header class="pd-card-header">
                        <h2 id="pdQuickHeading" class="pd-card-title">Quick Actions</h2>
                    </header>
                    <ul class="pd-actions">
                        <%-- TODO: replace href with the real catalog page URL once confirmed --%>
                        <li><a href="<%= ResolveUrl("~/Users/Admin/Catalog/BrowseCatalog.aspx") %>" data-todo="Wire to the real catalog page URL" class="pd-action">🔍 Search the catalog</a></li>
                        <li><a href="#" class="pd-action">📚 View borrowed books</a></li>
                        <li><a href="<%= ResolveUrl("~/Users/Patron/Reservations/ToPickUp.aspx") %>" class="pd-action">📅 Reservations &amp; renewals</a></li>
                        <li><a href="<%= ResolveUrl("~/Users/Patron/Reservations/ToPickUp.aspx") %>" class="pd-action"> 💳 View my fines</a></li>
                     </ul>
                </section>

            </div>
        </div>
    </div>
</asp:Content>