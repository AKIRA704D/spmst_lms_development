/* ==========================================================================
   LmsaAnalytics - the four "Descriptive and Diagnostic Analytics" tables
   (Trending Books, Low Circulation, Peak Hours, Overdue Patterns).

   * Every table has its OWN state {page} and its OWN pager (LmsaPager = Home pagination),
     so switching tabs never mixes pages.
   * Data comes from DashboardData.ashx?action=analytics&kind=...&page=N (server-side paging,
     10 rows/page). Nothing is fetched until a pane is first shown.
   * Used inline by adminDashC.aspx and by the Analytics_*.aspx pages (still used by CirDash.aspx).

   Requires: lmsa-dash-core.js, lmsa-pager.js (and Chart.js for Peak Hours).
   ========================================================================== */
(function (global) {
    'use strict';
    var D = global.LmsaDash;

    var TABLES = {
        trending: {
            noun: 'books', empty: 'No trending books yet. Borrowing activity will appear here.',
            cols: [
                { h: 'Title', f: function (r) { return '<div class="fw-semibold">' + D.esc(r.Title) + '</div><div class="small text-muted">' + D.esc(r.Author || '') + '</div>'; } },
                { h: 'Section', f: function (r) { return D.esc(r.Section || '-'); } },
                { h: 'Borrows', cls: 'text-center', f: function (r) { return '<span class="fw-bold">' + D.esc(r.Borrows) + '</span>'; } },
                { h: 'Last Borrowed', f: function (r) { return D.esc(D.fmtDate(r.LastBorrowed)); } },
                { h: 'Reason', f: reasonCell, cls: 'dash-col-reason' }
            ]
        },
        lowcirc: {
            noun: 'books', empty: 'No low-circulation books found.',
            cols: [
                { h: 'Title', f: function (r) { return '<div class="fw-semibold">' + D.esc(r.Title) + '</div>'; } },
                { h: 'Category', f: function (r) { return D.esc(r.Category || '-'); } },
                { h: 'Borrows', cls: 'text-center', f: function (r) { return '<span class="fw-bold">' + D.esc(r.Borrows) + '</span>'; } },
                { h: 'Last Borrowed', f: function (r) { return D.esc(D.fmtDate(r.LastBorrowed)); } },
                { h: 'Reason', f: reasonCell, cls: 'dash-col-reason' }
            ]
        },
        overdue: {
            noun: 'books', empty: 'No overdue patterns detected.',
            cols: [
                { h: 'Title', f: function (r) { return '<div class="fw-semibold">' + D.esc(r.Title) + '</div><div class="small text-muted">' + D.esc(r.Author || '') + '</div>'; } },
                { h: 'Section', f: function (r) { return D.esc(r.Section || '-'); } },
                { h: 'Overdue', cls: 'text-center', f: function (r) { return '<span class="fw-bold">' + D.esc(r.OverdueCount) + '</span>'; } },
                { h: 'Avg. Days Late', cls: 'text-center', f: function (r) { return D.esc(r.AvgDaysOverdue); } },
                { h: 'Last Due', f: function (r) { return D.esc(D.fmtDate(r.LastOverdueDate)); } },
                { h: 'Total Borrows', cls: 'text-center', f: function (r) { return D.esc(r.TotalBorrows); } },
                { h: 'Reason', f: reasonCell, cls: 'dash-col-reason' }
            ]
        },
        peakentries: {
            noun: 'hours', empty: 'No entry records in the last 30 days.',
            cols: [
                { h: 'Hour', f: function (r) { return D.esc(D.fmtHour(r.Hr)); } },
                { h: 'Entries', cls: 'text-center', f: function (r) { return '<span class="fw-bold">' + D.esc(r.Cnt) + '</span>'; } }
            ]
        },
        peakexits: {
            noun: 'hours', empty: 'No exit records in the last 30 days.',
            cols: [
                { h: 'Hour', f: function (r) { return D.esc(D.fmtHour(r.Hr)); } },
                { h: 'Exits', cls: 'text-center', f: function (r) { return '<span class="fw-bold">' + D.esc(r.Cnt) + '</span>'; } }
            ]
        }
    };

    function reasonCell(r) {
        return '<span class="dash-reason-badge">' + D.esc(r.Reason) + '</span>' +
            '<div class="small text-muted mt-1">' + D.esc(r.Explanation || '') + '</div>';
    }

    // ---- one paged table ------------------------------------------------
    // host: element that will receive  <div class="dash-table-wrap"></div><div class="dash-pager lmsa-pagination"></div>
    function PagedTable(host, kind) {
        this.kind = kind;
        this.def = TABLES[kind];
        this.page = 1;
        this.loaded = false;
        this.gate = D.gate();
        host.innerHTML = '<div class="dash-table-wrap"></div><div class="dash-pager lmsa-pagination"></div>';
        this.wrap = host.querySelector('.dash-table-wrap');
        this.pager = host.querySelector('.dash-pager');
    }

    PagedTable.prototype.load = function (page) {
        var self = this, token = this.gate.next();
        if (page) this.page = page;
        this.wrap.classList.add('is-loading');
        return D.api('analytics', { kind: this.kind, page: this.page }).then(function (data) {
            if (!self.gate.isCurrent(token)) return;
            self.loaded = true;
            self.page = data.page;                    // server clamps out-of-range pages
            self.wrap.classList.remove('is-loading');
            self.render(data);
        }).catch(function (err) {
            if (!self.gate.isCurrent(token)) return;
            self.wrap.classList.remove('is-loading');
            self.pager.innerHTML = '';
            self.wrap.innerHTML = D.errorHtml(err, 'data-retry="1"');
            var b = self.wrap.querySelector('[data-retry]');
            if (b) b.addEventListener('click', function () { self.load(); });
        });
    };

    PagedTable.prototype.render = function (data) {
        var self = this, def = this.def;
        if (!data.items || data.items.length === 0) {
            this.wrap.innerHTML = D.emptyHtml(def.empty);
            this.pager.innerHTML = '';
            return;
        }
        var html = '<div class="table-responsive"><table class="table table-hover align-middle dash-table"><thead><tr>';
        def.cols.forEach(function (c) { html += '<th class="' + (c.cls || '') + '">' + D.esc(c.h) + '</th>'; });
        html += '</tr></thead><tbody>';
        data.items.forEach(function (row) {
            html += '<tr>';
            def.cols.forEach(function (c) { html += '<td class="' + (c.cls || '') + '">' + c.f(row) + '</td>'; });
            html += '</tr>';
        });
        html += '</tbody></table></div>';
        this.wrap.innerHTML = html;
        global.LmsaPager.render(this.pager, data, { noun: def.noun, onPage: function (p) { self.load(p); } });
    };

    // ---- Peak Hours pane: chart + insights + two independent paged tables ----
    function PeakPane(host) {
        this.host = host;
        this.chart = null;
        this.loaded = false;
        this.gate = D.gate();
        host.innerHTML =
            '<div class="row g-3 mb-3 dash-peak-insights"></div>' +
            '<div class="dash-peak-chart-box"><canvas></canvas></div>' +
            '<div class="row g-4 mt-1">' +
            '  <div class="col-lg-6"><h6 class="dash-subhead">Peak Entry Hours</h6><div class="dash-peak-entries"></div></div>' +
            '  <div class="col-lg-6"><h6 class="dash-subhead">Peak Exit Hours</h6><div class="dash-peak-exits"></div></div>' +
            '</div>';
        this.insights = host.querySelector('.dash-peak-insights');
        this.box = host.querySelector('.dash-peak-chart-box');
        this.canvas = host.querySelector('canvas');
        this.entries = new PagedTable(host.querySelector('.dash-peak-entries'), 'peakentries');
        this.exits = new PagedTable(host.querySelector('.dash-peak-exits'), 'peakexits');
    }

    PeakPane.prototype.load = function () {
        var self = this, token = this.gate.next();
        this.entries.load(); this.exits.load();
        return D.api('peakchart').then(function (d) {
            if (!self.gate.isCurrent(token)) return;
            self.loaded = true;
            self.data = d;
            self.draw();
        }).catch(function (err) {
            if (!self.gate.isCurrent(token)) return;
            D.destroyChart(self, 'chart');
            self.box.innerHTML = D.errorHtml(err);
        });
    };

    PeakPane.prototype.draw = function () {
        var d = this.data;
        if (!d) return;

        this.insights.innerHTML =
            insight('Busiest entry hour', d.hasData && d.peakEntryCount > 0 ? D.fmtHour(d.peakEntryHour) + ' (' + d.peakEntryCount + ')' : '-') +
            insight('Busiest exit hour', d.hasData && d.peakExitCount > 0 ? D.fmtHour(d.peakExitHour) + ' (' + d.peakExitCount + ')' : '-') +
            insight('Entries (30 days)', d.totalEntries) + insight('Exits (30 days)', d.totalExits);

        if (!d.hasData) {
            D.destroyChart(this, 'chart');
            this.box.innerHTML = D.emptyHtml('No attendance records in the last 30 days.');
            this.canvas = null;
            return;
        }
        if (!this.canvas || !this.canvas.isConnected) {
            this.box.innerHTML = '<canvas></canvas>';
            this.canvas = this.box.querySelector('canvas');
        }
        if (!D.canDraw(this.canvas)) return;      // hidden tab: drawn again by resize() when shown
        D.destroyChart(this, 'chart');
        this.chart = new Chart(this.canvas, {
            type: 'bar',
            data: {
                labels: d.labels,
                datasets: [
                    { label: 'Entries', data: d.entries, backgroundColor: '#14532d', borderRadius: 4 },
                    { label: 'Exits', data: d.exits, backgroundColor: '#d4a017', borderRadius: 4 }
                ]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 11 } } } },
                scales: { y: { beginAtZero: true, ticks: { precision: 0 } } }
            }
        });
    };

    PeakPane.prototype.resize = function () {
        if (!this.loaded) return;
        if (this.chart) { try { this.chart.resize(); } catch (e) { } }
        else this.draw();
    };

    function insight(label, value) {
        return '<div class="col-6 col-md-3"><div class="dash-insight"><div class="dash-insight-label">' + D.esc(label) +
            '</div><div class="dash-insight-value">' + D.esc(value) + '</div></div></div>';
    }

    // ---- public API -------------------------------------------------------
    var panes = {};

    /**
     * mount(hostEl, kind): creates the paged table / peak pane inside hostEl (once).
     * ensure(kind): loads it the first time it becomes visible.
     */
    function mount(host, kind) {
        if (panes[kind] && panes[kind].host === host) return panes[kind];
        var inst = kind === 'peak' ? new PeakPane(host) : new PagedTable(host, kind);
        inst.host = host;
        panes[kind] = inst;
        return inst;
    }

    function ensure(kind) {
        var p = panes[kind];
        if (!p) return;
        if (!p.loaded) { if (kind === 'peak') p.load(); else p.load(); }
        else if (kind === 'peak') p.resize();
    }

    function reloadAll() {
        Object.keys(panes).forEach(function (k) { if (panes[k].loaded) panes[k].load(); });
    }

    global.LmsaAnalytics = { mount: mount, ensure: ensure, reloadAll: reloadAll };
})(window);
