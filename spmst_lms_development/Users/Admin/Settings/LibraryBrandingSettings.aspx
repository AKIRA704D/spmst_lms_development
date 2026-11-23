<%@ Page Title="" Language="C#" MasterPageFile="~/Users/MasterPage/admin.master" AutoEventWireup="true" CodeBehind="LibraryBrandingSettings.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Settings.LibraryBrandingSettings" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="<%= ResolveUrl("~/Assets/Themes/library-settings.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Assets/Themes/library-branding-settings.css") %>" rel="stylesheet" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="ls-child-header">
        <div>
            <a href="LibrarySettings.aspx" class="ls-back-btn"><i class="fa-solid fa-arrow-left"></i> Back to Settings</a>
            <h2 class="ls-child-title">System Branding</h2>
            <p class="ls-child-subtitle">Upload a custom logo to be used across the entire library system.</p>
        </div>
    </div>

    <div class="ls-card" style="max-width: 800px;">
        <div class="ls-branding-preview-box">
            <img id="logoPreview" src="<%= ResolveUrl("~/Assets/Logo/spmst_logo_wbg.png") %>" class="ls-branding-img" alt="Current Logo" onerror="handleImageError(this)" />
            <div class="text-muted small mt-2">Recommended size: 300x100px. Max size: 5MB (PNG, JPG, WebP)</div>
            
            <div class="ls-upload-controls">
                <input type="file" id="logoInput" accept=".png, .jpg, .jpeg, .webp" style="display: none;" onchange="previewSelectedLogo(this)" />
                <button type="button" class="btn btn-outline-secondary" onclick="document.getElementById('logoInput').click()">
                    <i class="fa-solid fa-folder-open me-2"></i>Browse Image
                </button>
                <button type="button" id="btnSaveLogo" class="ls-dash-btn" disabled>
                    <i class="fa-solid fa-cloud-arrow-up me-2"></i>Upload Logo
                </button>
                <button type="button" id="btnResetLogo" class="btn btn-outline-danger">
                    <i class="fa-solid fa-rotate-left me-2"></i>Reset to Default
                </button>
            </div>
            <div id="brandingNote" class="ls-save-note mt-3"></div>
        </div>
    </div>

    <script src="<%= ResolveUrl("~/Assets/Script//library-settings-common.js") %>"></script>
    <script>
var originalLogo = '';

function loadBranding() {
    LsApi.get('getbranding').then(function (res) {
        if (res.success && res.data) {
            originalLogo = res.data.logoPath;
            document.getElementById('logoPreview').src = LsUI.assetUrl(originalLogo);
        }
    });
}

function previewSelectedLogo(input) {
    if (input.files && input.files[0]) {
        var reader = new FileReader();
        reader.onload = function (e) {
            document.getElementById('logoPreview').src = e.target.result;
            document.getElementById('btnSaveLogo').disabled = false;
        };
        reader.readAsDataURL(input.files[0]);
    }
}

document.getElementById('btnSaveLogo').addEventListener('click', function () {
    var input = document.getElementById('logoInput');
    if (!input.files || input.files.length === 0) return;

    var fd = new FormData();
    fd.append('file', input.files[0]);

    LsUI.showNote('brandingNote', 'Uploading...', false);
    LsApi.post('uploadlogo', fd).then(function (res) {
        if (res.success) {
            LsUI.showNote('brandingNote', 'Logo updated successfully. Refresh other pages to see changes.', true);
            document.getElementById('btnSaveLogo').disabled = true;
            originalLogo = res.data.logoPath;
        } else {
            LsUI.showNote('brandingNote', res.message || 'Upload failed.', false);
            document.getElementById('logoPreview').src = LsUI.assetUrl(originalLogo);
        }
    });
});

document.getElementById('btnResetLogo').addEventListener('click', function () {
    if (!confirm('Are you sure you want to reset the logo to default?')) return;

    LsUI.showNote('brandingNote', 'Resetting...', false);
    LsApi.post('resetlogo', new FormData()).then(function (res) {
        if (res.success) {
            LsUI.showNote('brandingNote', 'Logo reset to default.', true);
            originalLogo = res.data.logoPath;
            document.getElementById('logoPreview').src = LsUI.assetUrl(originalLogo);
            document.getElementById('btnSaveLogo').disabled = true;
        } else {
            LsUI.showNote('brandingNote', 'Failed to reset logo.', false);
        }
    });
});

        document.addEventListener('DOMContentLoaded', loadBranding);
    </script>
</asp:Content>