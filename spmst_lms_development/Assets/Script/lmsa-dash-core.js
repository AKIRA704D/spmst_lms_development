/* ==========================================================================
   LmsaDash - tiny shared helpers for the Admin Dashboard scripts.
   - api(): GET to DashboardData.ashx, always resolves JSON data or rejects with {status, message}
   - request de-duplication helper (latest-wins) so a slow older response can never overwrite a newer one
   - esc(), date/time formatters that never use the browser time zone (values are plain strings from the server)
   ========================================================================== */
(function (global) {
    'use strict';

    var endpoint = '';

    function setEndpoint(url) { endpoint = url; }

    function qs(params) {
        var parts = [];
        Object.keys(params || {}).forEach(function (k) {
            var v = params[k];
            if (v === undefined || v === null || v === '') return;
            parts.push(encodeURIComponent(k) + '=' + encodeURIComponent(v));
        });
        return parts.join('&');
    }

    function url(action, params) {
        var p = {}; p.action = action;
        Object.keys(params || {}).forEach(function (k) { p[k] = params[k]; });
        return endpoint + '?' + qs(p);
    }

    function api(action, params) {
        return fetch(url(action, params), { credentials: 'same-origin', headers: { 'Accept': 'application/json' }, cache: 'no-store' })
            .then(function (res) {
                return res.json().catch(function () { return { success: false, message: 'Unexpected response.' }; })
                    .then(function (body) {
                        if (res.ok && body && body.success) return body.data;
                        var err = { status: res.status, message: (body && body.message) || 'The data could not be loaded.' };
                        if (res.status === 401) err.message = 'Your session has expired. Please sign in again.';
                        throw err;
                    });
            });
    }

    /** Creates a gate: gate.next() returns a token; gate.isCurrent(token) tells whether it is still the latest request. */
    function gate() {
        var n = 0;
        return { next: function () { return ++n; }, isCurrent: function (t) { return t === n; } };
    }

    function esc(s) {
        return String(s === null || s === undefined ? '' : s)
            .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
    }

    /** '2026-11-24T13:05:00' | '2026-11-24' -> '11.24.2026' ; anything else is returned unchanged ('Never', '') */
    function fmtDate(v) {
        if (!v) return '-';
        var m = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(v));
        return m ? m[2] + '.' + m[3] + '.' + m[1] : String(v);
    }

    /** '2026-11-24T13:05:00' -> '01:05 PM' (no Date object, so no time-zone shift is possible) */
    function fmtTime(v) {
        if (!v) return '-';
        var m = /T(\d{2}):(\d{2})/.exec(String(v));
        if (!m) return String(v);
        var h = parseInt(m[1], 10), ap = h >= 12 ? 'PM' : 'AM';
        h = h % 12; if (h === 0) h = 12;
        return (h < 10 ? '0' : '') + h + ':' + m[2] + ' ' + ap;
    }

    function fmtHour(h) { return (h < 10 ? '0' : '') + h + ':00'; }

    function money(n) { return '\u20B1' + Number(n || 0).toLocaleString('en-PH', { minimumFractionDigits: 2, maximumFractionDigits: 2 }); }

    function emptyHtml(msg, icon) {
        return '<div class="dash-empty"><i class="fa-regular ' + (icon || 'fa-circle-question') + '"></i><div>' + esc(msg) + '</div></div>';
    }

    function errorHtml(err, retryAttr) {
        return '<div class="dash-empty dash-empty-error"><i class="fa-solid fa-triangle-exclamation"></i><div>' +
            esc(err && err.message ? err.message : 'The data could not be loaded.') + '</div>' +
            (retryAttr ? '<button type="button" class="btn btn-sm btn-outline-secondary mt-2" ' + retryAttr + '>Try again</button>' : '') + '</div>';
    }

    /** Destroys the Chart.js instance stored in registry[key] (if any) so no chart is ever created twice on a canvas. */
    function destroyChart(registry, key) {
        if (registry[key]) { try { registry[key].destroy(); } catch (e) { } registry[key] = null; }
    }

    /** True when the canvas can be measured (visible and attached). Prevents zero-size / blank charts. */
    function canDraw(canvas) {
        if (!canvas || !canvas.isConnected) return false;
        var box = canvas.parentElement ? canvas.parentElement.getBoundingClientRect() : null;
        return !!box && box.width > 0 && box.height > 0;
    }

    global.LmsaDash = {
        setEndpoint: setEndpoint, api: api, gate: gate, esc: esc,
        fmtDate: fmtDate, fmtTime: fmtTime, fmtHour: fmtHour, money: money,
        emptyHtml: emptyHtml, errorHtml: errorHtml, destroyChart: destroyChart, canDraw: canDraw
    };
})(window);
