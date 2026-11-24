/* ==========================================================================
   SPAMAST LMSA - offline-guard.js
   Shared, dependency-free resilience layer. Load it once per page, AFTER the
   local vendor scripts (SweetAlert2 / Chart.js) and BEFORE page scripts.

   What it does
   1. Safety-net shims  - if SweetAlert2 or Chart.js failed to load, pages keep
                          working (plain alert/confirm, "chart unavailable"
                          note) instead of throwing and freezing the page.
   2. Image fallback    - any <img> that fails to load gets a local placeholder
                          (no broken-image icon, original box size preserved).
   3. Connectivity bar  - small, non-blocking notice when the browser is
                          offline or the server cannot be reached. It does NOT
                          pretend database work is possible offline.
   4. WebForms hooks    - blocks duplicate UpdatePanel submissions while one is
                          in flight, and turns timeouts / network / server
                          failures into a clear message (never a silent hang or
                          the raw "Sys.WebForms..." alert box).
   5. Helpers           - LMSA.fetchWithTimeout(), LMSA.reportServerReachable().

   It never touches authentication, sessions or cached data.
   ========================================================================== */
(function (w, d) {
    'use strict';
    if (w.LMSA) { return; }

    /* ---- app root (works under any virtual directory) ---------------------- */
    var appRoot = '/';
    try {
        var cs = d.currentScript;
        if (cs && cs.src) {
            appRoot = cs.src.replace(/[?#].*$/, '').replace(/Assets\/Script\/offline-guard\.js$/i, '');
            appRoot = appRoot.replace(/^https?:\/\/[^\/]+/i, '');
            if (appRoot.charAt(appRoot.length - 1) !== '/') { appRoot += '/'; }
        }
    } catch (e) { /* keep '/' */ }

    var LMSA = w.LMSA = {
        appRoot: appRoot,
        version: '1.0.0'
    };

    /* ======================================================================
       1. SAFETY-NET SHIMS
       ====================================================================== */
    if (typeof w.Swal === 'undefined') {
        var plain = function (a, b, c) {
            var o = (a && typeof a === 'object') ? a : { title: a, text: b, icon: c };
            var msg = [o.title, o.text || o.html].filter(Boolean).join('\n').replace(/<[^>]+>/g, '');
            if (o.showCancelButton || o.showDenyButton) {
                return Promise.resolve({ isConfirmed: w.confirm(msg), isDismissed: false });
            }
            if (msg) { w.alert(msg); }
            return Promise.resolve({ isConfirmed: true, isDismissed: false });
        };
        w.Swal = {
            __lmsaShim: true,
            fire: plain,
            close: function () { },
            showLoading: function () { },
            hideLoading: function () { },
            isVisible: function () { return false; },
            mixin: function () { return w.Swal; }
        };
        if (w.console) { console.warn('[LMSA] SweetAlert2 not loaded - using basic dialog fallback.'); }
    }

    if (typeof w.Chart === 'undefined') {
        var ChartShim = function (ctx) {
            try {
                var canvas = ctx && ctx.canvas ? ctx.canvas : ctx;
                if (canvas && canvas.parentNode) {
                    var note = d.createElement('div');
                    note.className = 'text-muted small text-center py-3';
                    note.textContent = 'Chart unavailable (script could not be loaded).';
                    canvas.style.display = 'none';
                    canvas.parentNode.insertBefore(note, canvas);
                }
            } catch (e) { /* ignore */ }
            this.destroy = this.update = this.resize = function () { };
        };
        ChartShim.__lmsaShim = true;
        ChartShim.register = function () { };
        ChartShim.defaults = { font: {}, plugins: {} };
        w.Chart = ChartShim;
    }

    /* ======================================================================
       2. IMAGE FALLBACK  (capture phase: 'error' does not bubble)
       ====================================================================== */
    var PLACEHOLDER = 'data:image/svg+xml;utf8,' + encodeURIComponent(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 160" preserveAspectRatio="xMidYMid slice">' +
        '<rect width="120" height="160" fill="#e9efe9"/><rect x="26" y="34" width="68" height="92" rx="5" fill="#14532d" opacity=".85"/>' +
        '<rect x="34" y="42" width="52" height="5" rx="2" fill="#d4a017"/><rect x="34" y="54" width="40" height="4" rx="2" fill="#fff" opacity=".7"/>' +
        '<rect x="34" y="63" width="46" height="4" rx="2" fill="#fff" opacity=".5"/></svg>');

    d.addEventListener('error', function (ev) {
        var t = ev.target;
        if (!t || t.tagName !== 'IMG' || t.getAttribute('data-lmsa-fallback') === '1') { return; }
        t.setAttribute('data-lmsa-fallback', '1');
        var custom = t.getAttribute('data-fallback-src');
        t.src = custom || PLACEHOLDER;     // keeps layout box; CSS sizing on the <img> still applies
        if (!t.alt) { t.alt = ''; }
    }, true);

    /* ======================================================================
       3. CONNECTIVITY BAR
       ====================================================================== */
    var bar = null, hideTimer = null, state = 'ok';
    function ensureBar() {
        if (bar || !d.body) { return bar; }
        bar = d.createElement('div');
        bar.setAttribute('role', 'status');
        bar.setAttribute('aria-live', 'polite');
        bar.style.cssText = 'position:fixed;left:50%;bottom:18px;transform:translateX(-50%);z-index:2147483000;' +
            'max-width:min(92vw,560px);padding:10px 16px;border-radius:10px;font:500 13px/1.4 Roboto,"Helvetica Neue",Arial,sans-serif;' +
            'box-shadow:0 6px 22px rgba(0,0,0,.28);display:none;text-align:center;pointer-events:none;';
        d.body.appendChild(bar);
        return bar;
    }
    function show(kind, text) {
        var b = ensureBar(); if (!b) { return; }
        clearTimeout(hideTimer);
        b.textContent = text;
        b.style.background = kind === 'ok' ? '#14532d' : '#7a1f1f';
        b.style.color = '#fff';
        b.style.border = '1px solid ' + (kind === 'ok' ? '#d4a017' : '#e4b94a');
        b.style.display = 'block';
        if (kind === 'ok') { hideTimer = setTimeout(function () { b.style.display = 'none'; }, 2500); }
    }
    function setState(next) {
        if (next === state) { return; }
        var prev = state; state = next;
        if (next === 'offline') {
            show('warn', 'You are offline. The page stays visible, but loading, searching and saving need a connection.');
        } else if (next === 'server-down') {
            show('warn', 'The server cannot be reached right now. Please check the connection and try again.');
        } else if (prev !== 'ok') {
            show('ok', 'Connection restored.');
        }
    }
    function evaluate() {
        if (w.navigator && w.navigator.onLine === false) { setState('offline'); }
        else if (state === 'offline') { setState('ok'); }
    }
    w.addEventListener('offline', evaluate);
    w.addEventListener('online', function () { evaluate(); });
    if (d.readyState === 'loading') { d.addEventListener('DOMContentLoaded', evaluate); } else { evaluate(); }

    LMSA.isOnline = function () { return state === 'ok'; };
    /* Called by pollers/handlers: true = got a response, false = request failed. */
    LMSA.reportServerReachable = function (ok) {
        if (ok) { if (state === 'server-down') { setState('ok'); } }
        else if (w.navigator && w.navigator.onLine === false) { setState('offline'); }
        else { setState('server-down'); }
    };

    /* ======================================================================
       5. HELPERS
       ====================================================================== */
    LMSA.fetchWithTimeout = function (url, opts, ms) {
        opts = opts || {};
        ms = ms || 8000;
        var ctrl = (typeof w.AbortController === 'function') ? new w.AbortController() : null;
        var timer = null;
        if (ctrl) { opts.signal = ctrl.signal; timer = setTimeout(function () { ctrl.abort(); }, ms); }
        return w.fetch(url, opts).then(
            function (r) { clearTimeout(timer); return r; },
            function (e) { clearTimeout(timer); throw e; });
    };

    /* ======================================================================
       4. WEBFORMS (ASP.NET AJAX) HOOKS
       ====================================================================== */
    function friendly(err, args) {
        var name = (err && err.name) || '';
        var code = 0;
        try { code = args.get_response().get_statusCode(); } catch (e) { /* ignore */ }
        if (w.navigator && w.navigator.onLine === false) {
            return ['You are offline', 'This action needs a connection to the server. Please reconnect and try again.'];
        }
        if (/TimeoutException/i.test(name)) {
            return ['Request timed out', 'The server took too long to respond. Please try again in a moment.'];
        }
        if (code === 0) {
            return ['Server unreachable', 'Could not reach the server. Please check the connection and try again.'];
        }
        return ['Something went wrong', 'The server could not complete the request (error ' + code + '). Please try again.'];
    }

    var hooked = false;
    function hookWebForms() {
        if (hooked) { return; }
        if (!w.Sys || !w.Sys.WebForms || !w.Sys.WebForms.PageRequestManager) { return; }
        var prm = w.Sys.WebForms.PageRequestManager.getInstance();
        if (!prm) { return; }
        hooked = true;

        /* Block a second UpdatePanel request while one is still running. Without
           this, the browser abandons the first call but the SERVER still finishes
           it - so a double click could borrow/return/pay twice. */
        prm.add_initializeRequest(function (sender, args) {
            if (prm.get_isInAsyncPostBack()) {
                args.set_cancel(true);
            }
        });

        prm.add_endRequest(function (sender, args) {
            var err = args.get_error();
            if (!err) { LMSA.reportServerReachable(true); return; }
            if (args.get_errorHandled && args.get_errorHandled()) { return; }   // e.g. ProcessIndicator already did
            args.set_errorHandled(true);
            if (w.console) { console.error('[LMSA] async postback failed:', err); }
            var m = friendly(err, args);
            LMSA.reportServerReachable(false);
            try { if (w.ProcessIndicator && w.ProcessIndicator.restoreButtons) { w.ProcessIndicator.restoreButtons(); } } catch (e) { /* ignore */ }
            try {
                if (w.Swal && w.Swal.close) { w.Swal.close(); }
                w.Swal.fire({ icon: 'error', title: m[0], text: m[1], confirmButtonColor: '#14532d' });
            } catch (e) { w.alert(m[0] + '\n' + m[1]); }
        });
    }
    if (d.readyState === 'loading') { d.addEventListener('DOMContentLoaded', hookWebForms); } else { hookWebForms(); }
    w.addEventListener('load', hookWebForms);

    /* ======================================================================
       SERVICE WORKER (static assets only - see /sw.js). Optional: requires
       HTTPS or localhost; the site works the same without it.
       ====================================================================== */
    if ('serviceWorker' in w.navigator) {
        w.addEventListener('load', function () {
            try {
                w.navigator.serviceWorker.register(appRoot + 'sw.js', { scope: appRoot })
                    .catch(function (e) { if (w.console) { console.warn('[LMSA] service worker not registered:', e && e.message); } });
            } catch (e) { /* ignore */ }
        });
    }
})(window, document);
