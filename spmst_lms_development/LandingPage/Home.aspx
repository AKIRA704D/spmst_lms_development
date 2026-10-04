<%@ Page Title="" Language="C#" MasterPageFile="~/LandingPage/LandingPage.Master" AutoEventWireup="true" CodeBehind="Home.aspx.cs" Inherits="spmst_lms_development.LandingPage.Home" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <title>LMSA | SPAMAST Library — Home</title>
    <style>
        /* ---- Hero ---- */
        .lmsa-hero {
            background: radial-gradient(1200px 500px at 85% -10%, rgba(212,175,55,0.16), transparent 60%),
                        linear-gradient(135deg, var(--lmsa-navy) 0%, var(--lmsa-navy-2) 100%);
            color: #fff;
            padding: 68px 0 40px;
            position: relative;
            overflow: hidden;
        }
        .lmsa-hero-grid { display: grid; grid-template-columns: 1.15fr 0.85fr; gap: 40px; align-items: center; }
        .lmsa-hero-eyebrow { display: inline-flex; align-items: center; gap: 8px; background: rgba(212,175,55,0.15); color: var(--lmsa-gold); font-weight: 700; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 1px; padding: 7px 14px; border-radius: 999px; margin-bottom: 18px; }
        .lmsa-hero h1 { font-size: 2.5rem; font-weight: 800; line-height: 1.18; margin-bottom: 16px; }
        .lmsa-hero h1 span { color: var(--lmsa-gold); }
        .lmsa-hero p.lead { color: #cbd5e1; font-size: 1.02rem; max-width: 540px; margin-bottom: 26px; }
        .lmsa-hero-actions { display: flex; flex-wrap: wrap; gap: 12px; }
        .lmsa-btn-ghost { display: inline-flex; align-items: center; gap: 8px; border: 1.5px solid rgba(255,255,255,0.35); color: #fff; font-weight: 700; font-size: 0.92rem; padding: 12px 24px; border-radius: 999px; transition: all .15s ease; }
        .lmsa-btn-ghost:hover { background: rgba(255,255,255,0.1); color: #fff; }

        .lmsa-hero-visual { position: relative; display: flex; align-items: center; justify-content: center; }
        .lmsa-hero-orb { width: 300px; height: 300px; border-radius: 50%; background: linear-gradient(135deg, rgba(14,165,233,0.25), rgba(212,175,55,0.2)); display: flex; align-items: center; justify-content: center; }
        .lmsa-hero-orb i { font-size: 6.5rem; color: rgba(255,255,255,0.9); }
        .lmsa-hero-float { position: absolute; background: #fff; color: var(--lmsa-navy); border-radius: var(--lmsa-radius); padding: 12px 16px; box-shadow: var(--lmsa-shadow-lg); font-weight: 700; font-size: 0.82rem; display: flex; align-items: center; gap: 10px; }
        .lmsa-hero-float i { color: var(--lmsa-blue); font-size: 1rem; }
        .lmsa-hero-float.f1 { top: 6%; left: -4%; }
        .lmsa-hero-float.f2 { bottom: 8%; right: -6%; }
        @media (max-width: 991.98px) {
            .lmsa-hero-grid { grid-template-columns: 1fr; }
            .lmsa-hero-visual { margin-top: 20px; }
            .lmsa-hero-float { display: none; }
        }

        .lmsa-stat-strip { display: grid; grid-template-columns: repeat(5, 1fr); gap: 14px; margin-top: 44px; }
        .lmsa-stat-card { background: rgba(255,255,255,0.07); border: 1px solid rgba(255,255,255,0.12); border-radius: var(--lmsa-radius); padding: 16px 14px; text-align: center; backdrop-filter: blur(6px); }
        .lmsa-stat-card .num { font-size: 1.5rem; font-weight: 800; color: #fff; }
        .lmsa-stat-card .lbl { font-size: 0.72rem; color: #94a3b8; text-transform: uppercase; letter-spacing: .5px; font-weight: 600; margin-top: 2px; }
        @media (max-width: 767.98px) { .lmsa-stat-strip { grid-template-columns: repeat(2, 1fr); } }

        /* ---- Quick access ---- */
        .lmsa-quick-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 16px; }
        .lmsa-quick-tile { display: flex; flex-direction: column; align-items: center; gap: 10px; text-align: center; padding: 24px 14px; }
        .lmsa-quick-tile .ic { width: 58px; height: 58px; border-radius: 16px; background: linear-gradient(135deg,#eef6ff,#e0f2fe); color: var(--lmsa-blue-dark); display: flex; align-items: center; justify-content: center; font-size: 1.35rem; }
        .lmsa-quick-tile span { font-weight: 700; font-size: 0.86rem; color: var(--lmsa-navy-2); }
        @media (max-width: 767.98px) { .lmsa-quick-grid { grid-template-columns: repeat(2, 1fr); } }

        /* ---- Top borrowers ---- */
        .lmsa-borrower-card { min-width: 168px; max-width: 168px; scroll-snap-align: start; padding: 18px 14px; text-align: center; position: relative; }
        .lmsa-borrower-card .rank-pin { position: absolute; top: 10px; left: 10px; }
        .lmsa-borrower-avatar { width: 68px; height: 68px; border-radius: 50%; object-fit: cover; border: 3px solid #fff; box-shadow: 0 0 0 3px #eef2f7; margin: 6px auto 12px; display: block; background-color: #eef2f7; }
        .lmsa-borrower-name { font-weight: 700; font-size: 0.86rem; color: var(--lmsa-navy); line-height: 1.25; min-height: 40px; }
        .lmsa-borrower-role { font-size: 0.68rem; font-weight: 700; text-transform: uppercase; letter-spacing: .4px; margin: 6px 0; }
        .lmsa-borrower-role.role-student { color: var(--lmsa-blue-dark); }
        .lmsa-borrower-role.role-faculty { color: var(--lmsa-gold-dark); }
        .lmsa-borrower-role.role-staff { color: #7c3aed; }
        .lmsa-borrower-count { font-size: 0.78rem; color: var(--lmsa-text-muted); font-weight: 600; }
        .lmsa-borrower-count b { color: var(--lmsa-navy); }

        /* ---- Ranked bar list (institutes / sections) ---- */
        .lmsa-rank-row { display: flex; align-items: center; gap: 14px; padding: 12px 0; border-bottom: 1px solid var(--lmsa-border); }
        .lmsa-rank-row:last-child { border-bottom: none; }
        .lmsa-rank-info { flex: 1; min-width: 0; }
        .lmsa-rank-label { display: flex; align-items: center; justify-content: space-between; gap: 10px; font-weight: 700; font-size: 0.9rem; color: var(--lmsa-navy-2); margin-bottom: 6px; }
        .lmsa-rank-label small { font-weight: 700; color: var(--lmsa-text-muted); }
        .lmsa-bar-track { height: 9px; background-color: #eef2f7; border-radius: 999px; overflow: hidden; }
        .lmsa-bar-fill { height: 100%; border-radius: 999px; background: linear-gradient(90deg, var(--lmsa-blue), var(--lmsa-blue-dark)); transition: width .6s ease; }
        .lmsa-bar-fill.gold { background: linear-gradient(90deg, #f5d576, var(--lmsa-gold-dark)); }

        /* ---- Resource cards ---- */
        .lmsa-resource-card { padding: 0; overflow: hidden; position: relative; }
        .lmsa-resource-cover { width: 100%; aspect-ratio: 3/4; object-fit: cover; background-color: #eef2f7; display: block; }
        .lmsa-resource-rank { position: absolute; top: 10px; left: 10px; z-index: 2; }
        .lmsa-resource-body { padding: 14px; }
        .lmsa-resource-title { font-weight: 700; font-size: 0.88rem; color: var(--lmsa-navy); line-height: 1.3; min-height: 46px; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
        .lmsa-resource-author { font-size: 0.76rem; color: var(--lmsa-text-muted); margin: 4px 0 10px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .lmsa-resource-foot { display: flex; align-items: center; justify-content: space-between; gap: 6px; }
        .lmsa-resource-copies { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-top: 8px; padding: 6px 10px; border-radius: 8px; font-size: 0.74rem; font-weight: 700; }
        .lmsa-resource-copies.has-available { background-color: #f0fdf4; color: #16a34a; }
        .lmsa-resource-copies.none-available { background-color: #fef2f2; color: #dc2626; }
        .lmsa-resource-copies i { margin-right: 3px; }

        .lmsa-resource-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(168px, 1fr)); gap: 18px; }
        @media (max-width: 575.98px) { .lmsa-resource-grid { grid-template-columns: repeat(2, 1fr); gap: 12px; } }

        /* ---- Catalog toolbar ---- */
        .lmsa-catalog-toolbar { display: flex; flex-wrap: wrap; gap: 12px; align-items: center; background: #fff; border: 1px solid var(--lmsa-border); border-radius: var(--lmsa-radius); padding: 14px 16px; margin-bottom: 24px; box-shadow: var(--lmsa-shadow); }
        .lmsa-search-box { flex: 1; min-width: 220px; position: relative; }
        .lmsa-search-box i { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); color: var(--lmsa-text-muted); }
        .lmsa-search-box input { width: 100%; border: 1.5px solid var(--lmsa-border); border-radius: 999px; padding: 10px 16px 10px 38px; font-size: 0.9rem; }
        .lmsa-search-box input:focus { outline: none; border-color: var(--lmsa-blue); box-shadow: 0 0 0 3px rgba(14,165,233,0.15); }

        .lmsa-pagination { display: flex; align-items: center; justify-content: center; gap: 10px; margin-top: 30px; }
        .lmsa-page-btn { width: 38px; height: 38px; border-radius: 50%; border: 1.5px solid var(--lmsa-border); background: #fff; display: flex; align-items: center; justify-content: center; color: var(--lmsa-navy-2); font-weight: 700; }
        .lmsa-page-btn:disabled { opacity: 0.4; }
        .lmsa-page-btn:not(:disabled):hover { border-color: var(--lmsa-blue); color: var(--lmsa-blue-dark); }
        .lmsa-page-info { font-size: 0.86rem; font-weight: 600; color: var(--lmsa-text-muted); }

        /* ---- CTA band ---- */
        .lmsa-cta-band { background: linear-gradient(135deg, var(--lmsa-navy) 0%, var(--lmsa-navy-2) 100%); border-radius: 24px; padding: 46px 40px; display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 20px; color: #fff; }
        .lmsa-cta-band h3 { font-size: 1.4rem; font-weight: 800; margin: 0 0 6px; }
        .lmsa-cta-band p { color: #cbd5e1; margin: 0; }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <!-- HERO -->
    <section class="lmsa-hero" id="top">
        <div class="container-lmsa">
            <div class="lmsa-hero-grid">
                <div>
                    <span class="lmsa-hero-eyebrow"><i class="fa-solid fa-book-open-reader"></i> SPAMAST Library | LMSA</span>
                    <h1>Discover what the <span>SPAMAST</span> community is reading right now.</h1>
                    <p class="lead">Browse the full library catalog, see the most borrowed titles and top-performing institutes, and track who's leading the reading charts - all in one place.</p>
                    <div class="lmsa-hero-actions">
                        <a href="#catalog" class="lmsa-btn-gold"><i class="fa-solid fa-magnifying-glass"></i> Browse the Catalog</a>
                        <a href="<%= ResolveUrl("~/LandingPage/Services.aspx") %>" class="lmsa-btn-ghost"><i class="fa-solid fa-hand-holding-heart"></i> Library Services</a>
                    </div>
                </div>
                <div class="lmsa-hero-visual">
                    <div class="lmsa-hero-orb"><i class="fa-solid fa-graduation-cap"></i></div>
                    <div class="lmsa-hero-float f1"><i class="fa-solid fa-trophy"></i> Top 20 Borrowers</div>
                    <div class="lmsa-hero-float f2"><i class="fa-solid fa-chart-line"></i> Live Borrowing Trends</div>
                </div>
            </div>

            <div class="lmsa-stat-strip" id="statStrip">
                <!-- filled by JS; skeleton below -->
                <div class="lmsa-stat-card"><div class="num">—</div><div class="lbl">Titles</div></div>
                <div class="lmsa-stat-card"><div class="num">—</div><div class="lbl">Available Copies</div></div>
                <div class="lmsa-stat-card"><div class="num">—</div><div class="lbl">Active Borrowers</div></div>
                <div class="lmsa-stat-card"><div class="num">—</div><div class="lbl">Sections</div></div>
                <div class="lmsa-stat-card"><div class="num">—</div><div class="lbl">Institutes Engaged</div></div>
            </div>
        </div>
    </section>

    <!-- QUICK ACCESS -->
    <section class="lmsa-section" style="padding-top:44px; padding-bottom:20px;">
        <div class="container-lmsa">
            <div class="lmsa-quick-grid">
                <a href="#catalog" class="lmsa-card lmsa-quick-tile"><div class="ic"><i class="fa-solid fa-book"></i></div><span>Browse Catalog</span></a>
                <a href="#borrowers" class="lmsa-card lmsa-quick-tile"><div class="ic"><i class="fa-solid fa-trophy"></i></div><span>Top Borrowers</span></a>
                <a href="#institutes" class="lmsa-card lmsa-quick-tile"><div class="ic"><i class="fa-solid fa-building-columns"></i></div><span>Top Institutes</span></a>
                <a href="<%= ResolveUrl("~/LandingPage/Services.aspx") %>" class="lmsa-card lmsa-quick-tile"><div class="ic"><i class="fa-solid fa-hand-holding-heart"></i></div><span>Library Services</span></a>
                <a href="<%= ResolveUrl("~/LandingPage/AboutContact.aspx") %>" class="lmsa-card lmsa-quick-tile"><div class="ic"><i class="fa-solid fa-headset"></i></div><span>Ask a Librarian</span></a>
            </div>
        </div>
    </section>

    <!-- TOP BORROWERS -->
    <section class="lmsa-section" id="borrowers">
        <div class="container-lmsa">
            <div class="lmsa-section-head">
                <div>
                    <span class="lmsa-eyebrow"><i class="fa-solid fa-trophy"></i> Reading Leaderboard</span>
                    <h2 class="lmsa-section-title">Top 20 Borrowers</h2>
                    <p class="lmsa-section-sub">The most active readers across students, faculty, and staff.</p>
                </div>
            </div>
            <div class="lmsa-scroller" id="borrowersScroller">
                <div class="lmsa-empty"><i class="fa-solid fa-spinner fa-spin"></i>Loading top borrowers...</div>
            </div>
        </div>
    </section>

    <!-- TOP INSTITUTES -->
    <section class="lmsa-section bg-soft" id="institutes">
        <div class="container-lmsa">
            <div class="lmsa-section-head">
                <div>
                    <span class="lmsa-eyebrow"><i class="fa-solid fa-building-columns"></i> Institute Engagement</span>
                    <h2 class="lmsa-section-title">Top Institutes</h2>
                    <p class="lmsa-section-sub">Ranked by borrowing activity across all institutes.</p>
                </div>
                <select id="instituteRoleFilter" class="lmsa-select">
                    <option value="All" selected>All (Students + Faculty)</option>
                    <option value="Student">Students Only</option>
                    <option value="Faculty">Faculty Only</option>
                </select>
            </div>
            <div class="lmsa-card" style="padding:22px 26px;">
                <div id="institutesList">
                    <div class="lmsa-empty"><i class="fa-solid fa-spinner fa-spin"></i>Loading top institutes...</div>
                </div>
            </div>
        </div>
    </section>

    <!-- MOST BORROWED RESOURCES -->
    <section class="lmsa-section" id="resources">
        <div class="container-lmsa">
            <div class="lmsa-section-head">
                <div>
                    <span class="lmsa-eyebrow"><i class="fa-solid fa-fire"></i> Most In-Demand</span>
                    <h2 class="lmsa-section-title">Most Borrowed Resources</h2>
                    <p class="lmsa-section-sub">Top 20 titles by total borrow count across the collection.</p>
                </div>
            </div>
            <div class="lmsa-resource-grid" id="topResourcesGrid">
                <div class="lmsa-empty"><i class="fa-solid fa-spinner fa-spin"></i>Loading most borrowed resources...</div>
            </div>
        </div>
    </section>

    <!-- MOST BORROWED BY SECTION -->
    <section class="lmsa-section bg-soft" id="sectionsRank">
        <div class="container-lmsa">
            <div class="lmsa-section-head">
                <div>
                    <span class="lmsa-eyebrow"><i class="fa-solid fa-layer-group"></i> By Collection Section</span>
                    <h2 class="lmsa-section-title">Most Borrowed Resources by Section</h2>
                    <p class="lmsa-section-sub">Top 20 library sections ranked by total borrow volume.</p>
                </div>
            </div>
            <div class="lmsa-card" style="padding:22px 26px;">
                <div id="sectionsList">
                    <div class="lmsa-empty"><i class="fa-solid fa-spinner fa-spin"></i>Loading section activity...</div>
                </div>
            </div>
        </div>
    </section>

    <!-- FULL CATALOG -->
    <section class="lmsa-section" id="catalog">
        <div class="container-lmsa">
            <div class="lmsa-section-head">
                <div>
                    <span class="lmsa-eyebrow"><i class="fa-solid fa-grip"></i> Full Collection</span>
                    <h2 class="lmsa-section-title">Browse the Library Collection</h2>
                    <p class="lmsa-section-sub">Search and filter every resource in the catalog.</p>
                </div>
            </div>

            <div class="lmsa-catalog-toolbar">
                <div class="lmsa-search-box">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <input type="text" id="catalogSearch" placeholder="Search by title, author, or publisher..." />
                </div>
                <select id="catalogTypeFilter" class="lmsa-select"><option value="All">All Types</option></select>
                <select id="catalogSectionFilter" class="lmsa-select"><option value="All">All Sections</option></select>
            </div>

            <div class="lmsa-resource-grid" id="catalogGrid">
                <div class="lmsa-empty"><i class="fa-solid fa-spinner fa-spin"></i>Loading collection...</div>
            </div>

            <div class="lmsa-pagination" id="catalogPagination"></div>
        </div>
    </section>

    <!-- CTA -->
    <section class="lmsa-section" style="padding-top:10px;">
        <div class="container-lmsa">
            <div class="lmsa-cta-band">
                <div>
                    <h3>Need help finding something?</h3>
                    <p>Visit the Circulation Desk or reach out to our librarians - we're happy to help.</p>
                </div>
                <a href="<%= ResolveUrl("~/LandingPage/AboutContact.aspx") %>" class="lmsa-btn-gold"><i class="fa-solid fa-envelope"></i> Contact the Library</a>
            </div>
        </div>
    </section>

</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="scripts" runat="server">
    <script>
        var catalogState = { q: '', type: 'All', section: 'All', page: 1, pageSize: 12 };
        var searchDebounce = null;

        function roleBadgeClass(role) {
            if (role === 'Faculty') return 'role-faculty';
            if (role === 'Staff') return 'role-staff';
            return 'role-student';
        }

        function rankClass(rank) {
            if (rank === 1) return 'gold';
            if (rank === 2) return 'silver';
            if (rank === 3) return 'bronze';
            return '';
        }

        function itemTypeIcon(type) {
            switch ((type || '').toLowerCase()) {
                case 'journal': return 'fa-newspaper';
                case 'dvd': return 'fa-compact-disc';
                case 'magazine': return 'fa-book-open';
                case 'thesis': return 'fa-file-lines';
                default: return 'fa-book';
            }
        }

        function sectionIcon(section) {
            var s = (section || '').toLowerCase();
            if (s.indexOf('period') !== -1) return 'fa-newspaper';
            if (s.indexOf('av') !== -1) return 'fa-film';
            if (s.indexOf('circulat') !== -1) return 'fa-arrows-rotate';
            if (s.indexOf('refer') !== -1) return 'fa-magnifying-glass-plus';
            return 'fa-layer-group';
        }

        // ---------- Quick stats ----------
        function loadStats() {
            lmsaApi('stats').then(function (res) {
                if (!res.success) return;
                var d = res.data;
                var html =
                    statCard(d.totalTitles, 'Titles') +
                    statCard(d.availableCopies, 'Available Copies') +
                    statCard(d.totalBorrowers, 'Active Borrowers') +
                    statCard(d.totalSections, 'Sections') +
                    statCard(d.totalInstitutes, 'Institutes Engaged');
                document.getElementById('statStrip').innerHTML = html;
            }).catch(function () { });
        }
        function statCard(num, label) {
            return '<div class="lmsa-stat-card"><div class="num">' + (num || 0) + '</div><div class="lbl">' + label + '</div></div>';
        }

        // ---------- Top borrowers ----------
        function loadTopBorrowers() {
            lmsaApi('topborrowers', { count: 20 }).then(function (res) {
                var el = document.getElementById('borrowersScroller');
                if (!res.success || !res.data || res.data.length === 0) {
                    el.innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-user-clock"></i>No borrowing activity yet - top borrowers will appear here once circulation begins.</div>';
                    return;
                }
                el.innerHTML = res.data.map(function (b) {
                    return '' +
                        '<div class="lmsa-card lmsa-borrower-card">' +
                        '  <span class="lmsa-rank-badge ' + rankClass(b.rank) + ' rank-pin">' + b.rank + '</span>' +
                        '  <img class="lmsa-borrower-avatar" src="' + assetUrl(b.profilePath) + '" alt="" onerror="this.src=appRoot+\'Assets/Profile/default-cover.png\'" />' +
                        '  <div class="lmsa-borrower-name">' + lmsaEscape(b.fullName) + '</div>' +
                        '  <div class="lmsa-borrower-role ' + roleBadgeClass(b.role) + '">' + lmsaEscape(b.role) + '</div>' +
                        '  <div class="lmsa-borrower-count"><b>' + b.borrowCount + '</b> borrow' + (b.borrowCount === 1 ? '' : 's') + '</div>' +
                        '</div>';
                }).join('');
            }).catch(function () {
                document.getElementById('borrowersScroller').innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-triangle-exclamation"></i>Could not load top borrowers.</div>';
            });
        }

        // ---------- Top institutes ----------
        function loadTopInstitutes(role) {
            var el = document.getElementById('institutesList');
            el.innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-spinner fa-spin"></i>Loading...</div>';
            lmsaApi('topinstitutes', { role: role || 'All', count: 20 }).then(function (res) {
                if (!res.success || !res.data.items || res.data.items.length === 0) {
                    el.innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-building-columns"></i>No institute borrowing activity yet.</div>';
                    return;
                }
                var maxV = res.data.maxValue || 1;
                el.innerHTML = res.data.items.map(function (it) {
                    var pct = maxV > 0 ? Math.round((it.shownCount / maxV) * 100) : 0;
                    return '' +
                        '<div class="lmsa-rank-row">' +
                        '  <span class="lmsa-rank-badge ' + rankClass(it.rank) + '">' + it.rank + '</span>' +
                        '  <div class="lmsa-rank-info">' +
                        '    <div class="lmsa-rank-label"><span>' + lmsaEscape(it.institute) + '</span><small>' + it.shownCount + ' borrow' + (it.shownCount === 1 ? '' : 's') + '</small></div>' +
                        '    <div class="lmsa-bar-track"><div class="lmsa-bar-fill gold" style="width:' + pct + '%"></div></div>' +
                        '  </div>' +
                        '</div>';
                }).join('');
            }).catch(function () {
                el.innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-triangle-exclamation"></i>Could not load top institutes.</div>';
            });
        }

        // ---------- Most borrowed resources ----------
        function loadTopResources() {
            lmsaApi('topresources', { count: 20 }).then(function (res) {
                var el = document.getElementById('topResourcesGrid');
                if (!res.success || !res.data || res.data.length === 0) {
                    el.innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-book"></i>No borrowing activity yet - the most requested titles will appear here.</div>';
                    return;
                }
                el.innerHTML = res.data.map(resourceCardHtml.bind(null, true)).join('');
            }).catch(function () {
                document.getElementById('topResourcesGrid').innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-triangle-exclamation"></i>Could not load most borrowed resources.</div>';
            });
        }

        function resourceCardHtml(showRank, r) {
            var isCatalogCard = typeof r.borrowCount === 'undefined';
            var rankHtml = showRank ? '<span class="lmsa-rank-badge ' + rankClass(r.rank) + ' lmsa-resource-rank">' + r.rank + '</span>' : '';

            var copiesStrip = '';
            if (isCatalogCard) {
                var total = r.totalCopies || 0;
                var avail = r.availableCopies || 0;
                var hasAvailable = avail > 0;
                copiesStrip =
                    '    <div class="lmsa-resource-copies ' + (hasAvailable ? 'has-available' : 'none-available') + '">' +
                    '      <span><i class="fa-solid fa-copy"></i>' + total + ' ' + (total === 1 ? 'copy' : 'copies') + '</span>' +
                    '      <span>' + (hasAvailable ? (avail + ' of ' + total + ' available') : ('All ' + total + ' borrowed')) + '</span>' +
                    '    </div>';
            }

            return '' +
                '<div class="lmsa-card lmsa-resource-card">' +
                rankHtml +
                '  <img class="lmsa-resource-cover" src="' + assetUrl(r.coverPath) + '" alt="" onerror="this.src=appRoot+\'Assets/Covers/default-cover.jpg\'" />' +
                '  <div class="lmsa-resource-body">' +
                '    <div class="lmsa-resource-title" title="' + lmsaEscape(r.title) + '">' + lmsaEscape(r.title) + '</div>' +
                '    <div class="lmsa-resource-author">' + lmsaEscape(r.author || 'Unknown author') + '</div>' +
                '    <div class="lmsa-resource-foot">' +
                '      <span class="lmsa-badge-soft"><i class="fa-solid ' + itemTypeIcon(r.itemType) + '"></i> ' + lmsaEscape(r.itemType || 'Item') + '</span>' +
                (isCatalogCard
                    ? ''
                    : '      <span class="lmsa-badge-soft"><i class="fa-solid fa-repeat"></i> ' + r.borrowCount + '</span>') +
                '    </div>' +
                copiesStrip +
                '  </div>' +
                '</div>';
        }

        // ---------- Most borrowed by section ----------
        function loadTopSections() {
            lmsaApi('topsections', { count: 20 }).then(function (res) {
                var el = document.getElementById('sectionsList');
                if (!res.success || !res.data.items || res.data.items.length === 0) {
                    el.innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-layer-group"></i>No section borrowing activity yet.</div>';
                    return;
                }
                var maxV = res.data.maxValue || 1;
                el.innerHTML = res.data.items.map(function (s) {
                    var pct = maxV > 0 ? Math.round((s.borrowCount / maxV) * 100) : 0;
                    return '' +
                        '<div class="lmsa-rank-row">' +
                        '  <span class="lmsa-rank-badge ' + rankClass(s.rank) + '"><i class="fa-solid ' + sectionIcon(s.section) + '"></i></span>' +
                        '  <div class="lmsa-rank-info">' +
                        '    <div class="lmsa-rank-label"><span>' + lmsaEscape(s.section) + '</span><small>' + s.borrowCount + ' borrow' + (s.borrowCount === 1 ? '' : 's') + ' &bull; ' + s.resourceCount + ' titles</small></div>' +
                        '    <div class="lmsa-bar-track"><div class="lmsa-bar-fill" style="width:' + pct + '%"></div></div>' +
                        '  </div>' +
                        '</div>';
                }).join('');
            }).catch(function () {
                document.getElementById('sectionsList').innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-triangle-exclamation"></i>Could not load section activity.</div>';
            });
        }

        // ---------- Catalog filters ----------
        function loadCatalogFilters() {
            lmsaApi('catalogfilters').then(function (res) {
                if (!res.success) return;
                var typeSel = document.getElementById('catalogTypeFilter');
                var secSel = document.getElementById('catalogSectionFilter');
                res.data.types.forEach(function (t) {
                    var opt = document.createElement('option'); opt.value = t; opt.textContent = t; typeSel.appendChild(opt);
                });
                res.data.sections.forEach(function (s) {
                    var opt = document.createElement('option'); opt.value = s; opt.textContent = s; secSel.appendChild(opt);
                });
            }).catch(function () { });
        }

        // ---------- Catalog grid ----------
        function loadCatalog() {
            var grid = document.getElementById('catalogGrid');
            grid.innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-spinner fa-spin"></i>Loading collection...</div>';
            lmsaApi('catalog', catalogState).then(function (res) {
                if (!res.success) { grid.innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-triangle-exclamation"></i>Could not load the catalog.</div>'; return; }
                var data = res.data;
                if (!data.items || data.items.length === 0) {
                    grid.innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-box-open"></i>No resources match your search.</div>';
                    document.getElementById('catalogPagination').innerHTML = '';
                    return;
                }
                grid.innerHTML = data.items.map(resourceCardHtml.bind(null, false)).join('');
                renderPagination(data);
            }).catch(function () {
                grid.innerHTML = '<div class="lmsa-empty"><i class="fa-solid fa-triangle-exclamation"></i>Could not load the catalog.</div>';
            });
        }

        function renderPagination(data) {
            var el = document.getElementById('catalogPagination');
            if (data.totalPages <= 1) { el.innerHTML = ''; return; }
            el.innerHTML =
                '<button class="lmsa-page-btn" id="pgPrev" ' + (data.page <= 1 ? 'disabled' : '') + '><i class="fa-solid fa-chevron-left"></i></button>' +
                '<span class="lmsa-page-info">Page ' + data.page + ' of ' + data.totalPages + ' · ' + data.total + ' items</span>' +
                '<button class="lmsa-page-btn" id="pgNext" ' + (data.page >= data.totalPages ? 'disabled' : '') + '><i class="fa-solid fa-chevron-right"></i></button>';
            var prev = document.getElementById('pgPrev'), next = document.getElementById('pgNext');
            if (prev) prev.addEventListener('click', function () { catalogState.page--; loadCatalog(); document.getElementById('catalog').scrollIntoView({ behavior: 'smooth' }); });
            if (next) next.addEventListener('click', function () { catalogState.page++; loadCatalog(); document.getElementById('catalog').scrollIntoView({ behavior: 'smooth' }); });
        }

        // ---------- Init ----------
        document.addEventListener('DOMContentLoaded', function () {
            loadStats();
            loadTopBorrowers();
            loadTopInstitutes('All');
            loadTopResources();
            loadTopSections();
            loadCatalogFilters();
            loadCatalog();

            document.getElementById('instituteRoleFilter').addEventListener('change', function (e) {
                loadTopInstitutes(e.target.value);
            });

            document.getElementById('catalogSearch').addEventListener('input', function (e) {
                clearTimeout(searchDebounce);
                var val = e.target.value;
                searchDebounce = setTimeout(function () {
                    catalogState.q = val; catalogState.page = 1; loadCatalog();
                }, 350);
            });
            document.getElementById('catalogTypeFilter').addEventListener('change', function (e) {
                catalogState.type = e.target.value; catalogState.page = 1; loadCatalog();
            });
            document.getElementById('catalogSectionFilter').addEventListener('change', function (e) {
                catalogState.section = e.target.value; catalogState.page = 1; loadCatalog();
            });
        });
    </script>
</asp:Content>
