/* ==========================================================================
   Admin Dashboard (Circulation / Patrons / Attendance)
   Everything is loaded with fetch() from DashboardData.ashx - no postbacks, so a card
   refreshes by itself and never reloads the page or any other card.

   window.LMSA_DASH = { endpoint, initialTab, fallbackLogo, tabs: {circ:bool, patron:bool, attend:bool} }
   Requires: lmsa-dash-core.js, lmsa-pager.js, lmsa-analytics.js, Chart.js, Bootstrap 5.

   NOTE: the server (DashboardData.ashx) re-checks the user's role on every request.
   The "tabs" flags only decide which panels are rendered/initialised on the client.
   ========================================================================== */
(function () {
    'use strict';

    var D = window.LmsaDash;
    var CFG = window.LMSA_DASH || {};
    D.setEndpoint(CFG.endpoint);

    function $(id) { return document.getElementById(id); }
    function debounce(fn, ms) { var t; return function () { var a = arguments, c = this; clearTimeout(t); t = setTimeout(function () { fn.apply(c, a); }, ms); }; }

    var charts = {};   // every Chart.js instance lives here and is destroyed before being replaced

    // ---------- inline alert (used for errors, e.g. export failures) ----------
    function showAlert(msg, kind) {
        var box = $('dashAlert');
        if (!box) return;
        box.className = 'alert alert-' + (kind || 'danger') + ' alert-dismissible fade show dash-alert';
        box.innerHTML = D.esc(msg) + '<button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>';
        box.classList.remove('d-none');
    }

    // ---------- shared chart helpers ----------
    var PALETTE = ['#14532d', '#1b7a3d', '#0f452d', '#d4a017', '#2e7d32', '#e4b94a', '#0b3d2c', '#a67c00', '#4a9e6a', '#c8a415', '#6ba383', '#388e3c', '#7cb342', '#f9a825', '#6b8e23'];
    function getColor(i) { return PALETTE[i % PALETTE.length]; }

    function abbreviate(input, maxLength) {
        maxLength = maxLength || 4;
        if (!input || String(input).trim() === '') return 'UNK';
        input = String(input).trim();
        var special = { 'unknown': 'UNK', 'faculty / non-student': 'FNS' };
        if (special[input.toLowerCase()]) return special[input.toLowerCase()];
        var words = input.replace(/[.,\/#!$%\^&\*;:{}=\-_`~()]/g, '').split(/\s+/).filter(function (w) { return w.length > 0; });
        if (words.length === 0) return 'UNK';
        if (words.length === 1) return words[0].substring(0, maxLength).toUpperCase();
        var skip = { of: 1, and: 1, 'in': 1, 'for': 1, the: 1, to: 1 }, acr = '';
        words.forEach(function (w) { if (!skip[w.toLowerCase()]) acr += w[0].toUpperCase(); });
        return acr.length > 0 ? acr : 'UNK';
    }

    function getStepSize(max) {
        if (max === 0) return 1;
        var step = Math.ceil(max / 8);
        if (step <= 5) return 5; if (step <= 10) return 10; if (step <= 20) return 20; if (step <= 50) return 50;
        return Math.ceil(step / 50) * 50;
    }

    /**
     * Draws a chart into the box that owns canvas `id`, or an empty-state message when there is no
     * valid data. Returns true when drawn, false when skipped (empty / hidden / no Chart.js).
     * The old Chart instance is ALWAYS destroyed first, so no canvas ever holds two charts.
     */
    function drawChart(id, hasData, emptyMsg, buildConfig) {
        var canvas = $(id), box = canvas ? canvas.parentElement : document.querySelector('[data-chart="' + id + '"]');
        if (!box) return false;
        D.destroyChart(charts, id);

        if (!hasData) {
            box.innerHTML = D.emptyHtml(emptyMsg, 'fa-chart-simple');
            box.classList.add('is-empty');
            return false;
        }
        if (!box.querySelector('canvas')) box.innerHTML = '<canvas id="' + id + '"></canvas>';
        box.classList.remove('is-empty');
        canvas = $(id);
        if (typeof Chart === 'undefined') { box.innerHTML = D.emptyHtml('Charts are unavailable.', 'fa-chart-simple'); return false; }
        if (!D.canDraw(canvas)) return false;            // tab is hidden - drawn when the tab is shown
        charts[id] = new Chart(canvas, buildConfig());
        return true;
    }

    var COMMON = { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 11 } } } } };
    function sum(arr) { return (arr || []).reduce(function (a, b) { return a + Number(b || 0); }, 0); }

    // ======================================================================
    // CIRCULATION  -  Library Trends Overview
    // ======================================================================
    var circ = { data: null, gate: D.gate(), drawnVisible: false };

    function loadTrends() {
        var from = $('trFrom'), to = $('trTo'), btn = $('btnTrendsApply'), token = circ.gate.next();
        if (btn) btn.disabled = true;
        return D.api('trends', { from: from && from.value, to: to && to.value }).then(function (d) {
            if (!circ.gate.isCurrent(token)) return;
            circ.data = d;
            if (from) from.value = d.from;
            if (to) to.value = d.to;
            $('litTotalPenalties').textContent = d.totals.penalties;
            $('litTotalPaid').textContent = d.totals.paid;
            $('litTotalBalance').textContent = d.totals.balance;
            drawTrends();
        }).catch(function (err) {
            if (!circ.gate.isCurrent(token)) return;
            circ.data = null;
            ['chartSections', 'chartSubjects', 'chartFines', 'chartInstitutes', 'chartPrograms'].forEach(function (id) {
                D.destroyChart(charts, id);
                var box = $(id) ? $(id).parentElement : document.querySelector('[data-chart="' + id + '"]');
                if (box) box.innerHTML = D.errorHtml(err);
            });
        }).then(function () { if (btn) btn.disabled = false; });
    }

    function stackedConfig(d, colors) {
        var max = Math.max.apply(null, [0].concat(d.borrowed || [], d.returned || [], d.reserved || []));
        var step = getStepSize(max), roles = d.borrowedRoles || [];
        return {
            type: 'bar',
            data: {
                labels: d.labels.map(function (l) { return abbreviate(l); }),
                datasets: [
                    { label: 'Borrowed', data: d.borrowed, backgroundColor: colors[0] },
                    { label: 'Returned', data: d.returned, backgroundColor: colors[1] },
                    { label: 'Reserved/Ready', data: d.reserved, backgroundColor: colors[2] }
                ]
            },
            options: {
                indexAxis: 'y', responsive: true, maintainAspectRatio: false,
                plugins: {
                    legend: COMMON.plugins.legend,
                    tooltip: {
                        callbacks: {
                            title: function (items) { return items.length ? d.labels[items[0].dataIndex] : ''; },
                            label: function (c) {
                                var r = (c.dataset.label || '') + ': ' + c.raw;
                                if (c.datasetIndex === 0 && roles[c.dataIndex]) {
                                    var x = roles[c.dataIndex];
                                    r += ' (Student: ' + x.student + ', Faculty: ' + x.faculty + ', Staff: ' + x.staff + ')';
                                }
                                return r;
                            }
                        }
                    }
                },
                scales: { x: { beginAtZero: true, ticks: { stepSize: step, callback: function (v) { return Number.isInteger(v) ? v : ''; } } } }
            }
        };
    }

    function drawTrends() {
        var d = circ.data;
        if (!d) return;
        var sec = d.section || {}, sub = d.subject || {};

        drawChart('chartSections', (sec.labels || []).length > 0 && sum(sec.values) > 0, 'No circulation records for this period.', function () {
            return { type: 'doughnut', data: { labels: sec.labels, datasets: [{ data: sec.values, backgroundColor: sec.labels.map(function (_, i) { return getColor(i); }), borderColor: '#fff', borderWidth: 2 }] }, options: Object.assign({ cutout: '70%' }, COMMON) };
        });
        drawChart('chartSubjects', (sub.labels || []).length > 0 && sum(sub.values) > 0, 'No circulation records for this period.', function () {
            return { type: 'doughnut', data: { labels: sub.labels, datasets: [{ data: sub.values, backgroundColor: sub.labels.map(function (_, i) { return getColor(i + 3); }), borderColor: '#fff', borderWidth: 2 }] }, options: Object.assign({ cutout: '70%' }, COMMON) };
        });

        var amounts = (d.penalty && d.penalty.amounts) || [], counts = (d.penalty && d.penalty.counts) || [];
        drawChart('chartFines', sum(amounts) > 0 || sum(counts) > 0, 'No penalties recorded for this period.', function () {
            var step = sum(amounts) >= 500 ? 100 : 50;
            return {
                type: 'bar',
                data: { labels: ['Damage', 'Lost', 'Overdue'], datasets: [{ label: '\u20B1 Amount', data: amounts, backgroundColor: [getColor(0), getColor(1), getColor(2)], borderRadius: 5 }] },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    plugins: { legend: { display: false }, tooltip: { callbacks: { label: function (c) { return (c.dataset.label || '') + ': \u20B1' + c.raw + ' (' + counts[c.dataIndex] + ' copies)'; } } } },
                    scales: { y: { beginAtZero: true, ticks: { stepSize: step, callback: function (v) { return '\u20B1' + v; } } } }
                }
            };
        });

        var inst = d.institutes || {}, prog = d.programs || {};
        drawChart('chartInstitutes', (inst.labels || []).length > 0, 'No borrowing activity for this period.', function () { return stackedConfig(inst, [getColor(0), getColor(1), getColor(2)]); });
        drawChart('chartPrograms', (prog.labels || []).length > 0, 'No borrowing activity for this period.', function () { return stackedConfig(prog, [getColor(3), getColor(4), getColor(5)]); });
    }

    // ======================================================================
    // CIRCULATION  -  Top Borrowed Books (View All refreshes only this card)
    // ======================================================================
    var topBk = { items: [], expanded: false, gate: D.gate() };
    var TOP_COLLAPSED = 5;

    function loadTopBooks() {
        var token = topBk.gate.next(), list = $('topBooksList');
        if (list) list.classList.add('is-loading');
        return D.api('topbooks', { limit: 20 }).then(function (d) {   // one query; View All just reveals what was fetched
            if (!topBk.gate.isCurrent(token)) return;
            topBk.items = d.items || [];
            topBk.fallback = d.fallbackLogo;
            renderTopBooks();
        }).catch(function (err) {
            if (!topBk.gate.isCurrent(token)) return;
            list.classList.remove('is-loading');
            list.innerHTML = D.errorHtml(err, 'data-retry="topBk"');
            var b = list.querySelector('[data-retry]'); if (b) b.addEventListener('click', loadTopBooks);
            $('btnTopViewAll').classList.add('d-none');
        });
    }

    function renderTopBooks() {
        var list = $('topBooksList'), btn = $('btnTopViewAll'), meta = $('topBooksMeta');
        list.classList.remove('is-loading');
        var total = topBk.items.length;
        if (total === 0) {
            list.innerHTML = D.emptyHtml('No borrowing records yet.', 'fa-circle-info');
            btn.classList.add('d-none'); meta.textContent = '';
            return;
        }
        var shown = topBk.expanded ? total : Math.min(total, TOP_COLLAPSED);
        var html = '';
        for (var i = 0; i < shown; i++) {
            var b = topBk.items[i];
            html += '<div class="top-book-row">' +
                '<div class="top-book-rank">' + b.rank + '</div>' +
                '<div class="book-cover-frame"><img class="book-cover-img" alt="" loading="lazy" data-src="' + D.esc(b.cover || '') + '"></div>' +
                '<div class="top-book-info"><div class="fw-bold text-dark top-book-title">' + D.esc(b.title) + '</div>' +
                '<div class="text-secondary small">' + D.esc(b.author) + '</div>' +
                (b.category ? '<span class="badge bg-light text-dark small">' + D.esc(b.category) + '</span>' : '') + '</div>' +
                '<div class="top-book-count text-end"><div class="fw-bold text-dark fs-5">' + b.checkouts + '</div>' +
                '<div class="text-secondary small">checkouts</div>' +
                '<div class="waiting-badge mt-1"><i class="far fa-clock me-1"></i>' + b.waiting + ' waiting</div></div>' +
                '</div>';
        }
        list.innerHTML = html;
        wireCovers(list);

        meta.textContent = 'Showing ' + shown + ' of ' + total;
        if (total <= TOP_COLLAPSED) btn.classList.add('d-none');
        else { btn.classList.remove('d-none'); btn.textContent = topBk.expanded ? 'Show Top ' + TOP_COLLAPSED : 'View All'; }
    }

    /** cover -> (broken/missing) school logo -> (also broken) empty neutral frame. Never a book icon. */
    function wireCovers(root) {
        root.querySelectorAll('img.book-cover-img').forEach(function (img) {
            var primary = img.getAttribute('data-src'), fallback = topBk.fallback || '';
            var stage = 0;
            function useFallback() {
                if (stage === 0 && fallback) { stage = 1; img.classList.add('is-logo'); img.src = fallback; }
                else { img.removeAttribute('src'); img.classList.add('is-blank'); }
            }
            img.addEventListener('error', useFallback);
            if (primary) img.src = primary; else useFallback();
        });
    }

    // ======================================================================
    // CIRCULATION  -  Descriptive & Diagnostic analytics tabs
    // ======================================================================
    function initAnalytics() {
        var tabs = document.querySelectorAll('#analyticsTabs [data-kind]');
        if (!tabs.length || !window.LmsaAnalytics) return;
        tabs.forEach(function (t) {
            var kind = t.getAttribute('data-kind');
            LmsaAnalytics.mount($('anPane-' + kind), kind);
            t.addEventListener('click', function () {
                tabs.forEach(function (x) { x.classList.remove('active'); });
                t.classList.add('active');
                document.querySelectorAll('.an-pane').forEach(function (p) { p.classList.add('d-none'); });
                $('anPane-' + kind).classList.remove('d-none');
                LmsaAnalytics.ensure(kind);
            });
        });
        var active = document.querySelector('#analyticsTabs .active[data-kind]') || tabs[0];
        active.click();
    }

    // ======================================================================
    // PATRONS
    // ======================================================================
    var pat = { f: { institute: '', program: '', ptype: '', gender: '' }, overview: null, loaded: false, gate: D.gate(), pen: { page: 1, q: '', gate: D.gate() } };
    var SEL = { institute: 'fInstitute', program: 'fProgram', ptype: 'fPtype', gender: 'fGender' };
    var ALL_LABEL = { institute: 'All Institutes', program: 'All Programs', ptype: 'All Patrons', gender: 'All Genders' };

    function filterParams() { return { institute: pat.f.institute, program: pat.f.program, ptype: pat.f.ptype, gender: pat.f.gender }; }

    function fillSelect(facet, options) {
        var sel = $(SEL[facet]); if (!sel) return;
        var html = '<option value="">' + ALL_LABEL[facet] + '</option>';
        options.forEach(function (o) { html += '<option value="' + D.esc(o.value) + '">' + D.esc(o.value) + ' (' + o.count + ')</option>'; });
        sel.innerHTML = html;
        sel.value = pat.f[facet] || '';
    }

    /** Re-reads the four dropdowns (options are computed from the OTHER filters), then refreshes the cards. */
    function applyPatronFilters(changed) {
        var token = pat.gate.next();
        var params = filterParams(); params.changed = changed || '';
        var wrapper = $('patronPanel'); if (wrapper) wrapper.classList.add('is-busy');

        return D.api('patronfilters', params).then(function (d) {
            if (!pat.gate.isCurrent(token)) return null;
            pat.f = { institute: d.selected.institute, program: d.selected.program, ptype: d.selected.ptype, gender: d.selected.gender };
            fillSelect('institute', d.institutes); fillSelect('program', d.programs);
            fillSelect('ptype', d.ptypes); fillSelect('gender', d.genders);
            $('btnResetFilters').disabled = !(pat.f.institute || pat.f.program || pat.f.ptype || pat.f.gender);
            pat.loaded = true;
            return Promise.all([loadPatronOverview(token), loadPenalties(1, token)]);
        }).catch(function (err) {
            if (!pat.gate.isCurrent(token)) return;
            showAlert(err.message || 'The patron data could not be loaded.');
        }).then(function () { if (wrapper && pat.gate.isCurrent(token)) wrapper.classList.remove('is-busy'); });
    }

    function loadPatronOverview(token) {
        return D.api('patronoverview', filterParams()).then(function (d) {
            if (!pat.gate.isCurrent(token)) return;
            pat.overview = d;
            renderPatronOverview();
        });
    }

    function barList(id, rows, offset, emptyMsg) {
        var el = $(id);
        if (!rows || rows.length === 0) { el.innerHTML = D.emptyHtml(emptyMsg, 'fa-circle-info'); return; }
        el.innerHTML = rows.map(function (r, i) {
            return '<div class="mb-3"><div class="d-flex justify-content-between mb-1 gap-2">' +
                '<span class="small fw-bold text-truncate" title="' + D.esc(r.name) + '">' + D.esc(r.name) + '</span>' +
                '<span class="small text-muted text-nowrap">' + r.count + ' &middot; ' + r.percentage + '%</span></div>' +
                '<div class="progress"><div class="progress-bar" role="progressbar" style="width:' + r.percentage + '%;background-color:' + getColor(i + offset) + ';"></div></div></div>';
        }).join('');
    }

    function legend(id, items) {
        $(id).innerHTML = items.map(function (it) {
            return '<div class="small mb-1"><span class="legend-dot" style="background-color:' + it.color + ';"></span>' + D.esc(it.label) + ' <span class="text-muted">(' + it.value + ')</span></div>';
        }).join('');
    }

    function renderPatronOverview() {
        var d = pat.overview; if (!d) return;
        $('patronTotal').textContent = d.total;
        barList('topPrograms', d.programs, 0, 'No program data for the selected filters.');
        barList('topInstitutes', d.institutes, 2, 'No institute data for the selected filters.');

        var p = d.patron, g = d.gender;
        var pItems = [{ label: 'Faculty', value: p.faculty, color: '#14532d' }, { label: 'Student', value: p.student, color: '#1b7a3d' }, { label: 'Staff', value: p.staff, color: '#d4a017' }];
        var gItems = [{ label: 'Male', value: g.male, color: '#2e7d32' }, { label: 'Female', value: g.female, color: '#d4a017' }];
        if (g.unspecified > 0) gItems.push({ label: 'Unspecified', value: g.unspecified, color: '#9aa5a0' });
        legend('patronLegend', pItems); legend('genderLegend', gItems);
        drawPatronCharts();
    }

    function drawPatronCharts() {
        var d = pat.overview; if (!d) return;
        var opts = { responsive: true, maintainAspectRatio: false, cutout: '70%', plugins: { legend: { display: false } } };
        var p = d.patron, g = d.gender;
        drawChart('patronDistChart', d.total > 0, 'No patrons match the selected filters.', function () {
            return { type: 'doughnut', data: { labels: ['Faculty', 'Student', 'Staff'], datasets: [{ data: [p.faculty, p.student, p.staff], backgroundColor: ['#14532d', '#1b7a3d', '#d4a017'], borderWidth: 0 }] }, options: opts };
        });
        var gl = ['Male', 'Female'], gd = [g.male, g.female], gc = ['#2e7d32', '#d4a017'];
        if (g.unspecified > 0) { gl.push('Unspecified'); gd.push(g.unspecified); gc.push('#9aa5a0'); }
        drawChart('genderDistChart', d.total > 0, 'No patrons match the selected filters.', function () {
            return { type: 'doughnut', data: { labels: gl, datasets: [{ data: gd, backgroundColor: gc, borderWidth: 0 }] }, options: opts };
        });
    }

    // ---- Penalty Tracking (paged, honours the patron filters) ----
    function loadPenalties(page, filterToken) {
        var s = pat.pen, token = s.gate.next();
        if (page) s.page = page;
        var body = $('penBody'); body.classList.add('is-loading');
        var params = filterParams(); params.q = s.q; params.page = s.page;
        return D.api('penalties', params).then(function (d) {
            if (!s.gate.isCurrent(token) || (filterToken && !pat.gate.isCurrent(filterToken))) return;
            body.classList.remove('is-loading');
            s.page = d.page;
            if (!d.items.length) {
                body.innerHTML = D.emptyHtml(s.q || pat.f.institute || pat.f.program || pat.f.ptype || pat.f.gender ? 'No penalty records match your search or filters.' : 'No penalty records found.', 'fa-circle-info');
                $('penPager').innerHTML = '';
                return;
            }
            var html = '<div class="table-responsive"><table class="table table-hover align-middle dash-table"><thead><tr>' +
                '<th>Date</th><th>Patron</th><th>Program</th><th>Book Title</th><th>Penalty</th><th class="text-end">Amount</th><th>Status</th></tr></thead><tbody>';
            d.items.forEach(function (r) {
                var st = String(r.Status || '');
                html += '<tr><td class="text-nowrap">' + D.esc(D.fmtDate(r.PenaltyDate)) + '</td>' +
                    '<td><div class="fw-semibold">' + D.esc(r.FullName) + '</div><div class="small text-muted">' + D.esc(r.PatronID) + '</div></td>' +
                    '<td>' + D.esc(r.Program || 'N/A') + '</td><td>' + D.esc(r.BookTitle || '-') + '</td>' +
                    '<td>' + D.esc(String(r.PenaltyType || '').replace(/_/g, ' + ')) + '</td>' +
                    '<td class="text-end text-nowrap">' + D.money(r.Amount) + '</td>' +
                    '<td><span class="dash-status dash-status-' + D.esc(st.toLowerCase()) + '">' + D.esc(st) + '</span></td></tr>';
            });
            body.innerHTML = html + '</tbody></table></div>';
            LmsaPager.render($('penPager'), d, { noun: 'records', onPage: function (p) { loadPenalties(p); } });
        }).catch(function (err) {
            if (!s.gate.isCurrent(token)) return;
            body.classList.remove('is-loading');
            body.innerHTML = D.errorHtml(err, 'data-retry="pen"');
            $('penPager').innerHTML = '';
            var b = body.querySelector('[data-retry]'); if (b) b.addEventListener('click', function () { loadPenalties(); });
        });
    }

    function initPatrons() {
        Object.keys(SEL).forEach(function (facet) {
            $(SEL[facet]).addEventListener('change', function () { pat.f[facet] = this.value; applyPatronFilters(facet); });
        });
        $('btnResetFilters').addEventListener('click', function () {
            pat.f = { institute: '', program: '', ptype: '', gender: '' };
            pat.pen.q = ''; $('penSearch').value = '';
            applyPatronFilters('');
        });
        $('penSearch').addEventListener('input', debounce(function () { pat.pen.q = $('penSearch').value.trim(); loadPenalties(1); }, 300));
    }

    // ======================================================================
    // ATTENDANCE  (ONE date drives Occupancy, the Attendance table and the export)
    // ======================================================================
    var att = { date: '', role: '', q: '', page: 1, loaded: false, gate: D.gate(), occ: null };

    function setDate(v) { att.date = v || ''; $('attDate').value = att.date; }

    function loadAttendanceAll(resetPage) {
        if (resetPage) att.page = 1;
        var token = att.gate.next();
        var panel = $('attendPanel'); if (panel) panel.classList.add('is-busy');

        // With no explicit date the SERVER decides "today" (database clock), then both cards use that exact date.
        var first = att.date
            ? Promise.resolve(null)
            : D.api('attendance', { role: att.role, q: att.q, page: att.page });

        return first.then(function (firstResult) {
            if (!att.gate.isCurrent(token)) return;
            if (firstResult) setDate(firstResult.date);

            var tableP = firstResult ? Promise.resolve(firstResult) : D.api('attendance', { date: att.date, role: att.role, q: att.q, page: att.page });
            var occP = D.api('occupancy', { date: att.date });
            return Promise.all([tableP, occP]);
        }).then(function (res) {
            if (!res || !att.gate.isCurrent(token)) return;
            att.loaded = true;
            setDate(res[0].date);
            att.page = res[0].page;
            renderAttendance(res[0]);
            renderOccupancy(res[1]);
        }).catch(function (err) {
            if (!att.gate.isCurrent(token)) return;
            $('attBody').innerHTML = D.errorHtml(err, 'data-retry="att"');
            $('attPager').innerHTML = '';
            var b = $('attBody').querySelector('[data-retry]'); if (b) b.addEventListener('click', function () { loadAttendanceAll(false); });
        }).then(function () { if (panel && att.gate.isCurrent(token)) panel.classList.remove('is-busy'); });
    }

    /** Page change only refetches the table (occupancy is unchanged for the same date). */
    function loadAttendancePage(page) {
        var token = att.gate.next(); att.page = page;
        $('attBody').classList.add('is-loading');
        return D.api('attendance', { date: att.date, role: att.role, q: att.q, page: att.page }).then(function (d) {
            if (!att.gate.isCurrent(token)) return;
            att.page = d.page; renderAttendance(d);
        }).catch(function (err) {
            if (!att.gate.isCurrent(token)) return;
            $('attBody').classList.remove('is-loading');
            $('attBody').innerHTML = D.errorHtml(err);
        });
    }

    function renderAttendance(d) {
        var body = $('attBody'); body.classList.remove('is-loading');
        $('attCount').textContent = d.total;
        if (!d.items.length) {
            body.innerHTML = D.emptyHtml(att.q || att.role ? 'No attendance records match your search or filter for ' + D.fmtDate(d.date) + '.' : 'No attendance records for ' + D.fmtDate(d.date) + '.', 'fa-calendar-xmark');
            $('attPager').innerHTML = '';
            return;
        }
        var html = '<div class="table-responsive"><table class="table table-hover align-middle dash-table"><thead><tr>' +
            '<th>Name</th><th>Type</th><th>Institute</th><th>Program</th><th>Purpose</th><th>Year</th><th>Login</th><th>Logout</th><th>Status</th></tr></thead><tbody>';
        d.items.forEach(function (r) {
            html += '<tr><td><span class="name-main">' + D.esc(r.FullName) + '</span><span class="id-sub">' + D.esc(r.UserID) + '</span></td>' +
                '<td>' + D.esc(r.Role) + '</td><td>' + D.esc(r.Institute) + '</td><td>' + D.esc(r.Program) + '</td>' +
                '<td>' + D.esc(r.Purpose) + '</td><td>' + D.esc(r.Year) + '</td>' +
                '<td class="text-nowrap">' + D.esc(D.fmtTime(r.Login)) + '</td><td class="text-nowrap">' + D.esc(r.Logout ? D.fmtTime(r.Logout) : '-') + '</td>' +
                '<td><span class="' + (r.Status === 'IN' ? 'badge-in' : 'badge-out') + '">' + D.esc(r.Status) + '</span></td></tr>';
        });
        body.innerHTML = html + '</tbody></table></div>';
        LmsaPager.render($('attPager'), d, { noun: 'records', onPage: loadAttendancePage });
    }

    function pct(v, cap) { return cap > 0 ? Math.min(100, Math.round(v * 100 / cap)) : 0; }

    function renderOccupancy(o) {
        att.occ = o;
        $('occDateLabel').textContent = D.fmtDate(o.date);
        $('occVisits').textContent = o.visits;
        $('occInside').textContent = o.stillInside;

        $('occTotalText').textContent = o.total.value + '/' + o.total.capacity;
        $('occTotalBar').style.width = pct(o.total.value, o.total.capacity) + '%';
        $('occTotalPct').textContent = pct(o.total.value, o.total.capacity) + '%';
        $('occStudyText').textContent = o.study.value + '/' + o.study.capacity;
        $('occStudyBar').style.width = pct(o.study.value, o.study.capacity) + '%';
        $('occResearchText').textContent = o.research.value + '/' + o.research.capacity;
        $('occResearchBar').style.width = pct(o.research.value, o.research.capacity) + '%';

        var f = o.avgFacultyMinutes, s = o.avgStudentMinutes, tot = f + s, circle = $('occCircle');
        $('occFacAvg').textContent = Math.round(f) + 'm';
        $('occStuAvg').textContent = Math.round(s) + 'm';
        if (tot > 0) {
            var deg = Math.round(f / tot * 360);
            circle.style.background = 'conic-gradient(#14532d 0deg ' + deg + 'deg, #1b7a3d ' + deg + 'deg 360deg)';
        } else circle.style.background = '#e4e9e5';
        $('occNoData').classList.toggle('d-none', o.visits > 0);
    }

    function exportAttendance() {
        var btn = $('btnAttExport'); btn.disabled = true;
        var q = { date: att.date, role: att.role, q: att.q };
        var parts = ['action=export'];
        Object.keys(q).forEach(function (k) { if (q[k]) parts.push(k + '=' + encodeURIComponent(q[k])); });
        fetch(CFG.endpoint + '?' + parts.join('&'), { credentials: 'same-origin', cache: 'no-store' }).then(function (res) {
            if (!res.ok) return res.text().then(function (t) { throw new Error(t || 'The export could not be created.'); });
            var cd = res.headers.get('Content-Disposition') || '', m = /filename="?([^";]+)"?/i.exec(cd);
            var name = m ? m[1] : 'LMSA_Occupancy_Attendance_' + (att.date || 'today') + '.xlsx';
            return res.blob().then(function (blob) {
                var a = document.createElement('a');
                a.href = URL.createObjectURL(blob); a.download = name;
                document.body.appendChild(a); a.click();
                setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 1000);
            });
        }).catch(function (e) { showAlert(e.message || 'The export could not be created.'); })
          .then(function () { btn.disabled = false; });
    }

    function initAttendance() {
        $('attDate').addEventListener('change', function () { att.date = this.value; loadAttendanceAll(true); });
        $('btnAttToday').addEventListener('click', function () { att.date = ''; $('attDate').value = ''; loadAttendanceAll(true); });
        $('attSearch').addEventListener('input', debounce(function () { att.q = $('attSearch').value.trim(); loadAttendancePage(1); }, 300));
        document.querySelectorAll('.att-role').forEach(function (b) {
            b.addEventListener('click', function () {
                document.querySelectorAll('.att-role').forEach(function (x) { x.classList.remove('active'); });
                b.classList.add('active'); att.role = b.getAttribute('data-role') || '';
                loadAttendancePage(1);
            });
        });
        $('btnAttExport').addEventListener('click', exportAttendance);
    }

    // ======================================================================
    // TABS (lazy load + resize charts when a hidden tab is revealed)
    // ======================================================================
    var started = {};
    function onTabShown(key) {
        if (key === 'circ') {
            if (!started.circ) { started.circ = true; loadTrends(); loadTopBooks(); initAnalytics(); }
            else { drawTrends(); if (window.LmsaAnalytics) { var a = document.querySelector('#analyticsTabs .active[data-kind]'); if (a) LmsaAnalytics.ensure(a.getAttribute('data-kind')); } }
        } else if (key === 'patron') {
            if (!started.patron) { started.patron = true; initPatrons(); applyPatronFilters(''); }
            else drawPatronCharts();
        } else if (key === 'attend') {
            if (!started.attend) { started.attend = true; initAttendance(); loadAttendanceAll(true); }
        }
    }

    var booted = false;
    document.addEventListener('DOMContentLoaded', function () {
        if (booted) return;          // never bind the handlers twice
        booted = true;
        if (CFG.tabs && CFG.tabs.circ) { var ap = $('btnTrendsApply'); if (ap) ap.addEventListener('click', loadTrends); var va = $('btnTopViewAll'); if (va) va.addEventListener('click', function () { topBk.expanded = !topBk.expanded; renderTopBooks(); }); }

        document.querySelectorAll('#mainTabs [data-tab-key]').forEach(function (btn) {
            btn.addEventListener('shown.bs.tab', function () { onTabShown(btn.getAttribute('data-tab-key')); });
        });
        if (CFG.initialTab) onTabShown(CFG.initialTab);
    });
})();
