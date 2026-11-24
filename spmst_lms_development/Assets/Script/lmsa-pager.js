/* ==========================================================================
   LmsaPager - shared pagination renderer.
   Produces EXACTLY the markup of the Landing Page "Home" catalog pager
   (Prev button | "Page X of Y / Showing a-b of N / n items on this page" | Next button)
   so every dashboard table looks and behaves like the Home pagination.

   Usage:
     LmsaPager.render(containerEl, { page, pageSize, total, totalPages, items }, {
         noun: 'records',            // plural noun, e.g. 'records'
         nounSingular: 'record',     // optional
         onPage: function (newPage) { ...load that page... }
     });

   Each call re-renders the container and attaches ONE handler per button
   (the old buttons are discarded with the old innerHTML), so handlers never stack up.
   ========================================================================== */
(function (global) {
    'use strict';

    function render(el, data, opts) {
        if (!el) return;
        opts = opts || {};
        var noun = opts.noun || 'records';
        var nounOne = opts.nounSingular || (noun.charAt(noun.length - 1) === 's' ? noun.slice(0, -1) : noun);

        if (!data || !data.items || data.items.length === 0) { el.innerHTML = ''; return; }

        var startIdx = (data.page - 1) * data.pageSize + 1;
        var endIdx = startIdx + data.items.length - 1;
        var itemWord = data.items.length === 1 ? 'item' : 'items';
        var resWord = data.total === 1 ? nounOne : noun;

        var infoHtml =
            '<div class="lmsa-page-info">' +
            '  <div class="lmsa-page-headline">Page ' + data.page + ' of ' + data.totalPages + '</div>' +
            '  <div class="lmsa-page-detail">Showing ' + startIdx + '\u2013' + endIdx + ' of ' + data.total + ' ' + resWord + '</div>' +
            '  <div class="lmsa-page-detail">' + data.items.length + ' ' + itemWord + ' on this page</div>' +
            '</div>';

        if (data.totalPages <= 1) { el.innerHTML = infoHtml; return; }

        // type="button": the page sits inside the ASP.NET <form>; a submit button would cause a postback.
        el.innerHTML =
            '<button type="button" class="lmsa-page-btn" data-dir="prev" aria-label="Previous page" ' + (data.page <= 1 ? 'disabled' : '') + '><i class="fa-solid fa-chevron-left"></i></button>' +
            infoHtml +
            '<button type="button" class="lmsa-page-btn" data-dir="next" aria-label="Next page" ' + (data.page >= data.totalPages ? 'disabled' : '') + '><i class="fa-solid fa-chevron-right"></i></button>';

        var prev = el.querySelector('[data-dir="prev"]');
        var next = el.querySelector('[data-dir="next"]');
        if (prev) prev.addEventListener('click', function (e) {
            e.preventDefault();
            if (data.page > 1 && opts.onPage) opts.onPage(data.page - 1);
        });
        if (next) next.addEventListener('click', function (e) {
            e.preventDefault();
            if (data.page < data.totalPages && opts.onPage) opts.onPage(data.page + 1);
        });
    }

    global.LmsaPager = { render: render };
})(window);
