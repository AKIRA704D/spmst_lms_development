<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="logout.aspx.cs" Inherits="spmst_lms_development.Users.MasterPage.Components.Logout" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <base target="_top" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href='<%= ResolveUrl("~/Users/MasterPage/Components/AdminLayout.css") %>' />
</head>
<body class="component-body">

    <!-- SIDEBAR BOTTOM SLOT: current user's avatar, name, role + logout -->
    <div class="sidebar-user-footer">
        <div class="user-profile-avatar-initials"><%= UserInitials %></div>

        <div class="user-meta-info">
            <p class="user-name"><%= UserFullName %></p>
            <p class="user-role"><%= UserRoleLabel %></p>
        </div>

        <!-- Logout goes through one shared handler (see /Handlers/Logout.ashx)
             instead of each page clearing the session on its own. -->
        <a class="btn-sidebar-logout" href='<%= ResolveUrl("~/Handlers/Logout.ashx") %>' title="Log out">
            <i class="fa-solid fa-power-off"></i>
        </a>
    </div>

</body>
</html>
