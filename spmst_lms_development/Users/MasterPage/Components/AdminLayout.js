/* AdminLayout.js
   Belongs to admin.Master. Its only job is opening/closing the mobile
   sidebar drawer when the hamburger button (or the backdrop) is clicked.

   Per-component behaviour — the clock, notifications, active-link
   highlighting — lives inside each component page's own <script>, right
   next to the markup it controls, instead of being crammed in here. */
window.AdminLayout = (function () {
    function toggleSidebar() {
        var sidebar = document.getElementById('lmsSidebar');
        var backdrop = document.getElementById('sidebarBackdrop');
        if (!sidebar || !backdrop) return;

        sidebar.classList.toggle('drawer-open');
        backdrop.classList.toggle('show-backdrop');
    }

    return {
        toggleSidebar: toggleSidebar
    };
})();
