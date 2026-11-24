/* ==========================================================================
   SPAMAST LMSA - Service Worker
   Purpose : keep the UI shell (CSS, JS, fonts, icons, logos) available when the
             connection drops, and show a friendly page for navigations that fail.
   Scope   : STATIC, NON-SENSITIVE assets only.
   NEVER cached: .aspx / .ashx pages, POST requests, Login/, Users/ pages,
             uploaded profile photos, anything outside the allow-list below,
             any response marked Cache-Control: no-store.
             => no sessions, credentials or database responses are ever stored.
   Updating: bump CACHE_VERSION whenever vendor/theme/script files change
             (old caches are deleted on activate).
   ========================================================================== */
'use strict';

var CACHE_VERSION = 'lmsa-static-v1';
var OFFLINE_URL = 'offline.html';

/* Pre-cached on install (relative to the SW scope = app root). Individual
   failures are tolerated so one missing file never blocks installation. */
var PRECACHE = [
    OFFLINE_URL,
    'favicon.ico',
    'Assets/Vendor/bootstrap/5.3.3/css/bootstrap.min.css',
    'Assets/Vendor/bootstrap/5.3.3/js/bootstrap.bundle.min.js',
    'Assets/Vendor/fontawesome/6.5.2/css/all.min.css',
    'Assets/Vendor/fontawesome/6.5.2/webfonts/fa-solid-900.woff2',
    'Assets/Vendor/fontawesome/6.5.2/webfonts/fa-regular-400.woff2',
    'Assets/Vendor/fontawesome/6.5.2/webfonts/fa-brands-400.woff2',
    'Assets/Vendor/sweetalert2/11.26.25/sweetalert2.all.min.js',
    'Assets/Vendor/fonts/fonts.css',
    'Assets/Vendor/fonts/files/roboto-latin-300-normal.woff2',
    'Assets/Vendor/fonts/files/roboto-latin-400-normal.woff2',
    'Assets/Vendor/fonts/files/roboto-latin-500-normal.woff2',
    'Assets/Vendor/fonts/files/roboto-latin-700-normal.woff2',
    'Assets/Vendor/fonts/files/roboto-latin-900-normal.woff2',
    'Assets/Themes/spamast-theme.css',
    'Assets/Script/offline-guard.js',
    'Assets/Logo/spmst_logo_wbg.png',
    'Assets/Logo/lib_logo_wbg.png',
    'Assets/Logo/lmsa_logo.png',
    'Assets/Covers/default-cover.jpg'
];

/* Runtime caching allow-list. 'immutable' = version is in the path, so cache-first.
   'swr' = app-owned files that change on deploy, so serve cached + refresh in background. */
var RULES = [
    { prefix: 'Assets/Vendor/', mode: 'immutable' },
    { prefix: 'Assets/Logo/', mode: 'immutable' },
    { prefix: 'Assets/Audio/', mode: 'immutable' },
    { prefix: 'Assets/Covers/default-cover', mode: 'immutable' },
    { prefix: 'Assets/Themes/', mode: 'swr' },
    { prefix: 'Assets/Script/', mode: 'swr' },
    { prefix: 'favicon', mode: 'swr' }
];

function scopePath() { return new URL(self.registration.scope).pathname; }

self.addEventListener('install', function (event) {
    event.waitUntil(
        caches.open(CACHE_VERSION).then(function (cache) {
            return Promise.all(PRECACHE.map(function (p) {
                return cache.add(new Request(p, { cache: 'reload' })).catch(function () { /* tolerate */ });
            }));
        }).then(function () { return self.skipWaiting(); })
    );
});

self.addEventListener('activate', function (event) {
    event.waitUntil(
        caches.keys().then(function (keys) {
            return Promise.all(keys.filter(function (k) {
                return k.indexOf('lmsa-static-') === 0 && k !== CACHE_VERSION;
            }).map(function (k) { return caches.delete(k); }));
        }).then(function () { return self.clients.claim(); })
    );
});

function ruleFor(url) {
    var rel = url.pathname.indexOf(scopePath()) === 0 ? url.pathname.substring(scopePath().length) : null;
    if (rel === null) { return null; }
    for (var i = 0; i < RULES.length; i++) {
        if (rel.indexOf(RULES[i].prefix) === 0) { return RULES[i]; }
    }
    return null;
}

function cacheable(resp) {
    if (!resp || resp.status !== 200 || resp.type !== 'basic') { return false; }
    var cc = resp.headers.get('Cache-Control') || '';
    return cc.toLowerCase().indexOf('no-store') === -1;
}

self.addEventListener('fetch', function (event) {
    var req = event.request;
    if (req.method !== 'GET') { return; }
    var url = new URL(req.url);
    if (url.origin !== self.location.origin) { return; }

    /* Page navigations: always go to the network (pages are dynamic and
       authenticated). Only when the network itself fails do we show the offline page. */
    if (req.mode === 'navigate') {
        event.respondWith(
            fetch(req).catch(function () {
                return caches.match(OFFLINE_URL).then(function (r) {
                    return r || new Response('Offline', { status: 503, headers: { 'Content-Type': 'text/plain' } });
                });
            })
        );
        return;
    }

    var rule = ruleFor(url);
    if (!rule) { return; }                       // not on the allow-list => browser handles it normally

    if (rule.mode === 'immutable') {
        event.respondWith(
            caches.match(req).then(function (hit) {
                if (hit) { return hit; }
                return fetch(req).then(function (resp) {
                    if (cacheable(resp)) { var copy = resp.clone(); caches.open(CACHE_VERSION).then(function (c) { c.put(req, copy); }); }
                    return resp;
                });
            })
        );
    } else {                                      // stale-while-revalidate
        event.respondWith(
            caches.open(CACHE_VERSION).then(function (cache) {
                return cache.match(req).then(function (hit) {
                    var net = fetch(req).then(function (resp) {
                        if (cacheable(resp)) { cache.put(req, resp.clone()); }
                        return resp;
                    }).catch(function () { return hit; });
                    return hit || net;
                });
            })
        );
    }
});
