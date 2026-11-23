var LsApi = {
    baseUrl: '/Users/Admin/Settings/LibrarySettingsData.ashx',
    get: function (action) {
        var url = this.baseUrl + '?action=' + encodeURIComponent(action) + '&_=' + Date.now();
        return fetch(url, { headers: { 'X-Requested-With': 'XMLHttpRequest' }, cache: 'no-store' }).then(function (r) { return r.json(); });
    },
    post: function (action, formData) {
        var url = this.baseUrl + '?action=' + encodeURIComponent(action);
        return fetch(url, { method: 'POST', body: formData }).then(function (r) { return r.json(); });
    }
};

var LsUI = {
    escape: function (str) {
        if (str === null || str === undefined) return '';
        return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    },
    assetUrl: function (p) {
        if (!p) return '';
        var root = '/'; // Adjust if application is in a subfolder
        return root + p.replace(/^\/+/, '');
    },
    pdfViewerUrl: function (url) {
        if (!url) return '';
        var base = url.split('#')[0];
        return base + '#toolbar=0&navpanes=0&statusbar=0&messages=0&scrollbar=1&view=FitH';
    },
    showNote: function (elementId, text, isSuccess) {
        var el = document.getElementById(elementId);
        if (!el) return;
        el.textContent = text;
        el.className = 'ls-save-note' + (isSuccess ? ' ok' : '');
        if (isSuccess) { setTimeout(function () { el.textContent = ''; }, 3000); }
    }
};

function handleImageError(imgElement) {
    imgElement.onerror = null;
    imgElement.src = LsUI.assetUrl('Assets/Covers/default-placeholder.png'); // Ensure this exists!
}