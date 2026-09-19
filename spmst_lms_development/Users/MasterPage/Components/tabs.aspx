<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="tabs.aspx.cs" Inherits="spmst_lms_development.Users.MasterPage.Components.tabs" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <base target="_top" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href='<%= ResolveUrl("~/Users/MasterPage/Components/AdminLayout.css") %>' />
</head>
<body class="component-body">

    <!-- SIDEBAR MIDDLE SLOT: the tab-switching navigation list.
         Because of <base target="_top"> above, clicking any link here
         reloads the WHOLE top-level page (admin.Master + the requested
         content page) — that IS the "tab switch". -->
    <nav class="sidebar-menu-scroller">

        <!-- ---- Core Operations ---- -->
        <div class="menu-category-label">Core Operations</div>
        <a id="navDashboard" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/Dashboard/adminDashC.aspx") %>'>
            <i class="fa-solid fa-chart-pie"></i><span>Dashboard</span>
        </a>
        <a id="navCirculation" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/Transactions/Book_Borrow.aspx") %>'>
            <i class="fa-solid fa-handshake"></i><span>Circulation / Loans</span>
        </a>
        <a id="navCatalog" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/Catalog.aspx") %>'>
            <i class="fa-solid fa-book"></i><span>Catalog</span>
        </a>
        <a id="navReserves" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/Reserves.aspx") %>'>
            <i class="fa-solid fa-calendar-days"></i><span>Reserves</span>
        </a>
        <a id="navReservations" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/Reservations.aspx") %>'>
            <i class="fa-solid fa-calendar-days"></i><span>Reservations</span>
        </a>
        <a id="navPenalties" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/Penalties.aspx") %>'>
            <i class="fa-solid fa-calendar-days"></i><span>Penalties</span>
        </a>
        <a id="navAttendance" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/AttendanceMonitor.aspx") %>'>
            <i class="fa-solid fa-calendar-days"></i><span>Attendance Monitor</span>
        </a>

        <!-- ---- Management ---- -->
        <div class="menu-category-label">Management</div>
        <a id="navInventory" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/bookInventory.aspx") %>'>
            <i class="fa-solid fa-book"></i><span>Book Inventory</span>
        </a>
        <a id="navAccounts" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/userAcc.aspx") %>'>
            <i class="fa-solid fa-tags"></i><span>Accounts</span>
        </a>
        <a id="navProfile" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/Profile.aspx") %>'>
            <i class="fa-solid fa-person"></i><span>Profile</span>
        </a>
        <a id="navNotifications" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/Notifications.aspx") %>'>
            <i class="fa-solid fa-bell"></i><span>Notifications</span>
        </a>

        <!-- ---- System Registry ---- -->
        <div class="menu-category-label">System Registry</div>
        <a id="navFeedback" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/FeedbackRequest.aspx") %>'>
            <i class="fa-solid fa-comment-dots"></i><span>Feedback &amp; Request</span>
        </a>
        <a id="navReports" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/Reports/adminReports.aspx") %>'>
            <i class="fa-solid fa-users-gear"></i><span>Reports</span>
        </a>
        <a id="navSystemLogs" class="nav-menu-item" href='<%= ResolveUrl("~/Users/Admin/SystemLogs.aspx") %>'>
            <i class="fa-solid fa-sliders"></i><span>System Logs</span>
        </a>

    </nav>

    <script>
        // Highlight whichever link matches the PARENT page's URL, since the
        // real content page (not this iframe) is where the user actually is.
        document.addEventListener('DOMContentLoaded', function () {
            var currentPath = window.top.location.pathname.toLowerCase();
            var links = document.querySelectorAll('.nav-menu-item');

            links.forEach(function (link) {
                var linkPath = new URL(link.href, window.location.href).pathname.toLowerCase();
                if (linkPath !== '' && currentPath.indexOf(linkPath) !== -1) {
                    link.classList.add('active');
                }
            });
        });
    </script>

</body>
</html>
