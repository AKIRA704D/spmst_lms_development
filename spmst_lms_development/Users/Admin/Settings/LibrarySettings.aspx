<%@ Page Title="" Language="C#" MasterPageFile="~/Users/MasterPage/admin.master" AutoEventWireup="true" CodeBehind="LibrarySettings.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Settings.LibrarySettings" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="<%= ResolveUrl("~/Assets/Themes/library-settings.css") %>" rel="stylesheet" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="ls-dashboard-header">
        <h2><i class="fa-solid fa-sliders me-2" style="color: var(--sp-green-600);"></i>Library Settings</h2>
        <p>Manage library information, content, branding, and other configurations.</p>
    </div>

    <div class="ls-card-grid">
        <div class="ls-dash-card">
            <div class="ls-dash-icon"><i class="fa-solid fa-address-card"></i></div>
            <h5>Contact Information</h5>
            <p>Manage library contact details, operating hours, Facebook URL, and map embed.</p>
            <a href="LibraryContactSettings.aspx" class="ls-dash-btn">Manage Settings</a>
        </div>

        <div class="ls-dash-card">
            <div class="ls-dash-icon"><i class="fa-solid fa-circle-info"></i></div>
            <h5>About Us</h5>
            <p>Manage the About Us heading, description body, and statistics shown to visitors.</p>
            <a href="LibraryAboutSettings.aspx" class="ls-dash-btn">Manage Settings</a>
        </div>

        <div class="ls-dash-card">
            <div class="ls-dash-icon"><i class="fa-solid fa-hand-holding-heart"></i></div>
            <h5>Library Services</h5>
            <p>Configure service cards, icons, descriptions, visibility, and display order.</p>
            <a href="LibraryServicesSettings.aspx" class="ls-dash-btn">Manage Settings</a>
        </div>

        <div class="ls-dash-card">
            <div class="ls-dash-icon"><i class="fa-solid fa-file-contract"></i></div>
            <h5>Terms &amp; Conditions</h5>
            <p>Upload and manage PDF documents. Control which version is currently active.</p>
            <a href="LibraryTermsSettings.aspx" class="ls-dash-btn">Manage Settings</a>
        </div>

        <div class="ls-dash-card">
            <div class="ls-dash-icon"><i class="fa-solid fa-image"></i></div>
            <h5>System Branding</h5>
            <p>Upload and manage the system logo displayed throughout the LMS application.</p>
            <a href="LibraryBrandingSettings.aspx" class="ls-dash-btn">Manage Settings</a>
        </div>
    </div>
</asp:Content>