<%@ Page Title="" Language="C#" MasterPageFile="~/Users/MasterPage/admin.master" AutoEventWireup="true" CodeBehind="LibraryContactSettings.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Settings.LibraryContactSettings" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="<%= ResolveUrl("~/Assets/Themes/library-settings.css") %>" rel="stylesheet" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="ls-child-header">
        <div>
            <a href="LibrarySettings.aspx" class="ls-back-btn"><i class="fa-solid fa-arrow-left"></i> Back to Settings</a>
            <h2 class="ls-child-title">Contact Information</h2>
            <p class="ls-child-subtitle">Manage the contact details, hours, and map shown on the public portal.</p>
        </div>
    </div>

    <div class="ls-card ls-form" style="max-width: 900px;">
        <div id="contactForm">
            <div class="row g-3">
                <div class="col-12"><label>Address</label><input type="text" class="form-control" id="ciAddress" /></div>
                <div class="col-md-6"><label>Phone</label><input type="text" class="form-control" id="ciPhone" /></div>
                <div class="col-md-6"><label>Email</label><input type="email" class="form-control" id="ciEmail" /></div>
                <div class="col-md-4"><label>Hours - Weekdays</label><input type="text" class="form-control" id="ciHoursWeekdays" placeholder="Mon - Fri: 8:00 AM - 5:00 PM" /></div>
                <div class="col-md-4"><label>Hours - Saturday</label><input type="text" class="form-control" id="ciHoursSaturday" placeholder="Saturday: 8:00 AM - 12:00 PM" /></div>
                <div class="col-md-4"><label>Hours - Sunday</label><input type="text" class="form-control" id="ciHoursSunday" placeholder="Sunday & Holidays: Closed" /></div>
                <div class="col-md-6"><label>Facebook URL <span class="text-muted fw-normal">(optional)</span></label><input type="text" class="form-control" id="ciFacebook" /></div>
                <div class="col-md-6"><label>Google Maps Embed URL</label><input type="text" class="form-control" id="ciMapUrl" placeholder="https://www.google.com/maps/embed?..." /></div>
                <div class="col-12 mt-4">
                    <button type="button" id="ciSaveBtn" class="ls-dash-btn"><i class="fa-solid fa-floppy-disk me-2"></i>Save Changes</button>
                    <span class="ls-save-note" id="ciNote"></span>
                </div>
            </div>
        </div>
    </div>

    <script src="<%= ResolveUrl("~/Assets/Script//library-settings-common.js") %>"></script>
    <script>
function loadContact() {
    LsApi.get('getcontact').then(function (res) {
        if (!res.success || !res.data) return;
        var d = res.data;
        document.getElementById('ciAddress').value = d.address || '';
        document.getElementById('ciPhone').value = d.phone || '';
        document.getElementById('ciEmail').value = d.email || '';
        document.getElementById('ciHoursWeekdays').value = d.hoursWeekdays || '';
        document.getElementById('ciHoursSaturday').value = d.hoursSaturday || '';
        document.getElementById('ciHoursSunday').value = d.hoursSunday || '';
        document.getElementById('ciFacebook').value = d.facebookUrl || '';
        document.getElementById('ciMapUrl').value = d.mapEmbedUrl || '';
    });
}

document.getElementById('ciSaveBtn').addEventListener('click', function () {
    var fd = new FormData();
    fd.append('address', document.getElementById('ciAddress').value);
    fd.append('phone', document.getElementById('ciPhone').value);
    fd.append('email', document.getElementById('ciEmail').value);
    fd.append('hoursWeekdays', document.getElementById('ciHoursWeekdays').value);
    fd.append('hoursSaturday', document.getElementById('ciHoursSaturday').value);
    fd.append('hoursSunday', document.getElementById('ciHoursSunday').value);
    fd.append('facebookUrl', document.getElementById('ciFacebook').value);
    fd.append('mapEmbedUrl', document.getElementById('ciMapUrl').value);

    LsUI.showNote('ciNote', 'Saving...', false);
    LsApi.post('savecontact', fd).then(function (res) {
        LsUI.showNote('ciNote', res.success ? 'Saved successfully.' : (res.message || 'Could not save.'), res.success);
    });
});

        document.addEventListener('DOMContentLoaded', loadContact);
    </script>
</asp:Content>