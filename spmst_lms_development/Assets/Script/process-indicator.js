/* ============================================================
   SPAMAST LMS — Reusable Process Indicator Utility
   v1.3
   - No artificial hold on loading (loads/hides in real time)
   - No artificial hold on loading (loads/hides in real time)
   - state = "final" set immediately in showSuccess/showError
     so endRequest never hides a final dialog
   - Debug logging so you can verify in DevTools what's happening
   ============================================================ */
(function (window, document) {
    "use strict";
    if (window.ProcessIndicator) { return; }

    var STATE_IDLE = "idle", STATE_LOADING = "loading", STATE_FINAL = "final";
    var DEBUG = true;
    function log() {
        if (DEBUG && window.console && console.log) {
            var args = Array.prototype.slice.call(arguments);
            args.unshift("[ProcessIndicator]");
            console.log.apply(console, args);
        }
    }

    var ProcessIndicator = {
        _state: STATE_IDLE,
        _prmHooked: false,

        _ensureSwal: function () {
            if (typeof window.Swal === "undefined" ||
                !window.Swal ||
                typeof window.Swal.fire !== "function") {
                console.warn("[ProcessIndicator] SweetAlert2 is NOT loaded. " +
                    "Load SweetAlert2 BEFORE process-indicator.js.");
                return false;
            }
            return true;
        },

        isLoading: function () { return this._state === STATE_LOADING; },

        showLoading: function (title, message) {
            if (!this._ensureSwal()) return;
            this._state = STATE_LOADING;
            log("showLoading →", title);
            window.Swal.fire({
                title: title || "Processing...",
                html: message || "",
                allowOutsideClick: false,
                allowEscapeKey: false,
                allowEnterKey: false,
                showConfirmButton: false,
                didOpen: function () {
                    window.Swal.showLoading();
                    log("loading modal painted");
                }
            });
        },

        hideLoading: function () {
            if (!this._ensureSwal()) return;
            try { window.Swal.close(); } catch (e) { /* ignore */ }
            this._state = STATE_IDLE;
        },

        showSuccess: function (title, message, options) {
            if (!this._ensureSwal()) return;
            options = options || {};
            // 🔑 CRITICAL: set state = FINAL before firing Swal,
            // so endRequest (which fires synchronously after this
            // script runs) never calls hideLoading() and closes
            // the success dialog.
            this._state = STATE_FINAL;
            log("showSuccess →", title);
            window.Swal.fire({
                icon: "success",
                title: title || "Success",
                html: message || "",
                confirmButtonColor: options.confirmButtonColor || "#14532d",
                timer: options.timer !== undefined ? options.timer : 2000,
                showConfirmButton: options.showConfirmButton === true,
                allowOutsideClick: options.allowOutsideClick === true
            }).then(function (result) {
                if (typeof options.onClose === "function") {
                    try { options.onClose(result); } catch (e) { /* ignore */ }
                }
            });
        },

        showError: function (title, message) {
            if (!this._ensureSwal()) return;
            this._state = STATE_FINAL;   // same reasoning as showSuccess
            log("showError →", title);
            window.Swal.fire({
                icon: "error",
                title: title || "Error",
                html: message || "",
                confirmButtonColor: "#14532d"
            });
        },

        handleButtonLoading: function (button, title, message) {
            this.showLoading(title, message);
            if (!button) return;
            if (button.classList && button.classList.contains("pi-loading")) return;
            try {
                button.dataset.piOriginalDisabled = button.disabled ? "1" : "0";
                button.disabled = true;
                button.classList.add("pi-loading");
            } catch (e) { /* ignore */ }
        },

        restoreButtons: function () {
            var nodes = document.querySelectorAll(".pi-loading");
            for (var i = 0; i < nodes.length; i++) {
                var el = nodes[i];
                el.classList.remove("pi-loading");
                try {
                    var orig = el.dataset ? el.dataset.piOriginalDisabled : null;
                    el.disabled = (orig === "1");
                } catch (e) { el.disabled = false; }
            }
        },

        hookPageRequestManager: function () {
            if (this._prmHooked) return;
            if (typeof window.Sys === "undefined" ||
                !window.Sys.WebForms ||
                !window.Sys.WebForms.PageRequestManager) return;
            var manager = window.Sys.WebForms.PageRequestManager.getInstance();
            if (!manager) return;
            this._prmHooked = true;
            var self = this;

            manager.add_initializeRequest(function (sender, args) {
                try {
                    var el = args.get_postBackElement();
                    if (el && el.getAttribute) {
                        var t = el.getAttribute("data-pi-loading-title");
                        if (t && self._state !== STATE_LOADING) {
                            self.showLoading(
                                t,
                                el.getAttribute("data-pi-loading-message") || "Please wait..."
                            );
                        }
                    }
                } catch (e) { /* ignore */ }
            });

            manager.add_endRequest(function (sender, args) {
                try {
                    // Check if the server threw a 500 error
                    if (args.get_error() != undefined) {
                        var errorMessage = args.get_error().message;
                        args.set_errorHandled(true); // Prevent default alert
                        log("endRequest → AJAX error:", errorMessage);
                        self.showError("Server Error", "An unexpected server error occurred. Please try again.");
                        return;
                    }

                    if (self._state === STATE_LOADING) {
                        log("endRequest → hiding stale loading");
                        self.hideLoading();
                    } else {
                        log("endRequest → state=" + self._state + ", leaving dialog alone");
                    }
                } catch (e) { /* ignore */ }
                self.restoreButtons();
                window.__piSubmitInFlight = false;
            });
        }
    };

    window.ProcessIndicator = ProcessIndicator;
    log("v1.3 loaded");

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", function () {
            ProcessIndicator.hookPageRequestManager();
        });
    } else {
        ProcessIndicator.hookPageRequestManager();
    }
    window.addEventListener("load", function () {
        ProcessIndicator.hookPageRequestManager();
    });
})(window, document);