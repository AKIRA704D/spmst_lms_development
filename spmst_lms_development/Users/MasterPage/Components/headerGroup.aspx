<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="headerGroup.aspx.cs" Inherits="spmst_lms_development.Users.MasterPage.Components.headerGroup" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <base target="_top" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href='<%= ResolveUrl("~/Users/MasterPage/Components/AdminLayout.css") %>' />
</head>
<body class="component-body">

    <!-- HEADER SLOT: one responsive bar used at every screen size.
         (The old admin.Master duplicated this markup once for desktop and
         once for mobile — this single copy replaces both, and CSS media
         queries in AdminLayout.css trim it down on small screens.) -->
    <header class="header-bar">

        <div class="desktop-role-badge">
            <i class="fa-solid fa-building-user"></i>
            <span><%= RoleBadgeText %></span>
        </div>

        <div class="header-action-group">

            <div class="header-datetime-block">
                <div class="header-date-string" id="headerCurrentDate">-- -- ----</div>
                <div class="header-semester-string" id="headerAcademicTerm">Loading Term...</div>
            </div>

            <div class="dropdown">
                <button type="button" class="btn-notification-bell" data-bs-toggle="dropdown"
                    aria-expanded="false" title="System Alerts &amp; Notifications">
                    <i class="fa-regular fa-bell"></i>
                    <span id="notifCountBadge" class="badge rounded-pill bg-danger notification-count-badge" style="display:none;"></span>
                </button>
                <ul class="dropdown-menu dropdown-menu-end shadow border-0 mt-2 p-0 notification-dropdown-menu" id="notifList">
                    <li class="p-3 text-center text-muted">Loading notifications&hellip;</li>
                </ul>
            </div>

            <!-- Clickable avatar -> Profile page -->
            <a class="header-avatar-initials" href='<%= ResolveUrl("~/Users/Staff/Profile/Profile.aspx") %>' title="View Profile">
                <%= UserInitials %>
            </a>

            <a class="btn-header-logout" href='<%= ResolveUrl("~/Users/MasterPage/Handlers/Logout.ashx") %>' title="Log out">
                <i class="fa-solid fa-right-from-bracket"></i>
            </a>

        </div>
    </header>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            renderClockAndTerm();
            loadNotifications();
        });

        // 1) Clock + academic-term label
        function renderClockAndTerm() {
            var dateOptions = { weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' };
            document.getElementById('headerCurrentDate').textContent =
                new Date().toLocaleDateString('en-US', dateOptions);

            var month = new Date().getMonth(); // 0 = Jan ... 11 = Dec
            var term = "1st Semester";
            if (month >= 4 && month <= 5) {
                term = "2nd Semester";
            } else if (month >= 6 && month <= 8) {
                term = "Summer Term";
            }
            document.getElementById('headerAcademicTerm').textContent = term;
        }

        // 2) Notifications — fetched from the shared handler instead of
        //    running a database query inline on every page load.
        function loadNotifications() {
            fetch('<%= ResolveUrl("~/Users/MasterPage/Handlers/NotificationHandler.ashx") %>')
                .then(function (res) { return res.json(); })
                .then(renderNotifications)
                .catch(function () { renderNotifications({ count: 0, items: [] }); });
        }

        function renderNotifications(data) {
            var badge = document.getElementById('notifCountBadge');
            var list = document.getElementById('notifList');

            if (data.count > 0) {
                badge.textContent = data.count;
                badge.style.display = 'inline-block';
            } else {
                badge.style.display = 'none';
            }

            var header =
                '<li class="p-3 border-bottom bg-light d-flex justify-content-between align-items-center">' +
                '<span class="fw-bold text-dark">Notifications</span>' +
                '<span class="badge bg-secondary-subtle text-secondary">' + data.count + ' New</span></li>';

            if (!data.items || data.items.length === 0) {
                list.innerHTML = header +
                    '<li class="p-4 text-center text-muted">' +
                    '<i class="fa-solid fa-bell-slash fs-4 d-block mb-2 text-opacity-25"></i>' +
                    'No unread system notifications</li>';
                return;
            }

            // The handler already HTML-encodes title/message server-side,
            // so it's safe to drop these strings straight into the markup.
            var rows = data.items.map(function (item) {
                return '<li><a class="dropdown-item p-3 border-bottom d-flex flex-column gap-1 notification-item-link" href="#">' +
                    '<div class="d-flex justify-content-between align-items-start gap-2">' +
                    '<strong class="text-dark">' + item.title + '</strong>' +
                    '<small class="text-muted text-nowrap notification-timestamp">' + item.createdAt + '</small>' +
                    '</div>' +
                    '<p class="text-muted m-0 small text-wrap text-break">' + item.message + '</p>' +
                    '</a></li>';
            }).join('');

            list.innerHTML = header + rows;
        }
    </script>

</body>
</html>
