<%@ Page Title="" Language="C#" MasterPageFile="~/Users/MasterPage/admin.master" AutoEventWireup="true" CodeBehind="LibraryAboutSettings.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Settings.LibraryAboutSettings" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="<%= ResolveUrl("~/Assets/Themes/library-settings.css") %>" rel="stylesheet" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="ls-child-header">
        <div>
            <a href="LibrarySettings.aspx" class="ls-back-btn"><i class="fa-solid fa-arrow-left"></i> Back to Settings</a>
            <h2 class="ls-child-title">About Us</h2>
            <p class="ls-child-subtitle">Manage the content displayed on the public About page.</p>
        </div>
    </div>

    <div class="ls-card ls-form" style="max-width: 900px;">
        <div id="aboutForm">
            <div class="row g-3">
                <div class="col-12"><label>Heading</label><input type="text" class="form-control" id="auHeading" /></div>
                <div class="col-12"><label>Body <span class="text-muted fw-normal">(separate paragraphs with a blank line)</span></label><textarea class="form-control" id="auBody" rows="6"></textarea></div>
                <div class="col-md-4"><label>Stat 1 Label</label><input type="text" class="form-control" id="auStat1Label" placeholder="Institutes Served" /></div>
                <div class="col-md-2"><label>Value</label><input type="text" class="form-control" id="auStat1Value" placeholder="7" /></div>
                <div class="col-md-4"><label>Stat 2 Label</label><input type="text" class="form-control" id="auStat2Label" placeholder="SPAMAST Founded" /></div>
                <div class="col-md-2"><label>Value</label><input type="text" class="form-control" id="auStat2Value" placeholder="1969" /></div>
                <div class="col-md-4"><label>Stat 3 Label</label><input type="text" class="form-control" id="auStat3Label" placeholder="Days a Week Open" /></div>
                <div class="col-md-2"><label>Value</label><input type="text" class="form-control" id="auStat3Value" placeholder="6" /></div>
                <div class="col-12 mt-4">
                    <button type="button" id="auSaveBtn" class="ls-dash-btn"><i class="fa-solid fa-floppy-disk me-2"></i>Save Changes</button>
                    <span class="ls-save-note" id="auNote"></span>
                </div>
            </div>
        </div>
    </div>

    <script src="<%= ResolveUrl("~/Assets/Script//library-settings-common.js") %>"></script>
    <script>
function loadAbout() {
    LsApi.get('getabout').then(function (res) {
        if (!res.success || !res.data) return;
        var d = res.data;
        document.getElementById('auHeading').value = d.heading || '';
        document.getElementById('auBody').value = d.body || '';
        document.getElementById('auStat1Label').value = d.stat1Label || '';
        document.getElementById('auStat1Value').value = d.stat1Value || '';
        document.getElementById('auStat2Label').value = d.stat2Label || '';
        document.getElementById('auStat2Value').value = d.stat2Value || '';
        document.getElementById('auStat3Label').value = d.stat3Label || '';
        document.getElementById('auStat3Value').value = d.stat3Value || '';
    });
}

document.getElementById('auSaveBtn').addEventListener('click', function () {
    var fd = new FormData();
    fd.append('heading', document.getElementById('auHeading').value);
    fd.append('body', document.getElementById('auBody').value);
    fd.append('stat1Label', document.getElementById('auStat1Label').value);
    fd.append('stat1Value', document.getElementById('auStat1Value').value);
    fd.append('stat2Label', document.getElementById('auStat2Label').value);
    fd.append('stat2Value', document.getElementById('auStat2Value').value);
    fd.append('stat3Label', document.getElementById('auStat3Label').value);
    fd.append('stat3Value', document.getElementById('auStat3Value').value);

    LsUI.showNote('auNote', 'Saving...', false);
    LsApi.post('saveabout', fd).then(function (res) {
        LsUI.showNote('auNote', res.success ? 'Saved successfully.' : (res.message || 'Could not save.'), res.success);
    });
});

        document.addEventListener('DOMContentLoaded', loadAbout);
    </script>
</asp:Content>