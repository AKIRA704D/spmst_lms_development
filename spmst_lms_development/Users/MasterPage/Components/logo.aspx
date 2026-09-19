<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="logo.aspx.cs" Inherits="spmst_lms_development.Users.MasterPage.Components.logo" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <!-- Every link on this page opens in the PARENT window (this page only
         ever lives inside an <iframe> in admin.Master), so we set it once
         here instead of tagging target="_top" on every single link. -->
    <base target="_top" />
    <link rel="stylesheet" href='<%= ResolveUrl("~/Users/MasterPage/Components/AdminLayout.css") %>' />
</head>
<body class="component-body">

    <!-- SIDEBAR TOP SLOT: brand logo, system title, version -->
    <div class="sidebar-brand-header">
        <img src='<%= ResolveUrl("~/Assests/img/lmsa_logo.png") %>' alt="LMSA Logo" class="brand-logo" />
        <div class="brand-text-wrapper">
            <div class="brand-title">SPAMAST</div>
            <div class="brand-subtitle">Library Management System</div>
            <div class="brand-version"><%= AppVersionLabel %></div>
        </div>
    </div>

</body>
</html>
