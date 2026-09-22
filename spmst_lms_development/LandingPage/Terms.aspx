<%@ Page Title="" Language="C#" MasterPageFile="~/LandingPage/LandingPage.Master" AutoEventWireup="true" CodeBehind="Terms.aspx.cs" Inherits="spmst_lms_development.LandingPage.Terms" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <title>Terms &amp; Conditions | SPAMAST Library - LMSA</title>
    <style>
        .lmsa-page-header { background: linear-gradient(135deg, var(--lmsa-navy) 0%, var(--lmsa-navy-2) 100%); color: #fff; padding: 56px 0 64px; }
        .lmsa-page-header h1 { font-size: 2.1rem; font-weight: 800; margin-bottom: 10px; }
        .lmsa-page-header p { color: #cbd5e1; max-width: 620px; font-size: 1rem; }
        .lmsa-breadcrumb { display: flex; align-items: center; gap: 8px; font-size: 0.82rem; color: #94a3b8; margin-bottom: 16px; }
        .lmsa-breadcrumb a { color: #94a3b8; }
        .lmsa-breadcrumb a:hover { color: #fff; }

        .lmsa-terms-meta { display: flex; flex-wrap: wrap; align-items: center; gap: 14px; margin-bottom: 20px; }
        .lmsa-terms-frame { width: 100%; height: 82vh; min-height: 520px; border: 0; border-radius: var(--lmsa-radius); }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <section class="lmsa-page-header">
        <div class="container-lmsa">
            <div class="lmsa-breadcrumb">
                <a href="<%= ResolveUrl("~/LandingPage/Home.aspx") %>">Home</a>
                <i class="fa-solid fa-chevron-right" style="font-size:0.65rem"></i>
                <span>Terms &amp; Conditions</span>
            </div>
            <h1><i class="fa-solid fa-file-contract me-2"></i>Terms &amp; Conditions</h1>
            <p>Please review the SPAMAST Library's current terms and conditions of use.</p>
        </div>
    </section>

    <section class="lmsa-section">
        <div class="container-lmsa">
            <div class="lmsa-terms-meta" id="termsMeta" style="display:none;">
                <span class="lmsa-badge-soft"><i class="fa-solid fa-file-pdf"></i> <span id="termsTitle"></span></span>
                <span class="lmsa-badge-soft" id="termsVersionBadge" style="display:none;"><i class="fa-solid fa-code-branch"></i> <span id="termsVersion"></span></span>
                <span class="lmsa-badge-soft"><i class="fa-solid fa-calendar"></i> Published <span id="termsDate"></span></span>
            </div>

            <div id="termsContent">
                <div class="lmsa-card" style="padding:60px 20px;">
                    <div class="lmsa-empty"><i class="fa-solid fa-spinner fa-spin"></i>Loading terms &amp; conditions...</div>
                </div>
            </div>
        </div>
    </section>

</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="scripts" runat="server">
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            lmsaApi('termsactive').then(function (res) {
                var content = document.getElementById('termsContent');

                if (!res.success || !res.data) {
                    content.innerHTML = '<div class="lmsa-card" style="padding:60px 20px;"><div class="lmsa-empty"><i class="fa-solid fa-file-circle-xmark"></i>The library has not published a Terms &amp; Conditions document yet.</div></div>';
                    return;
                }

                var d = res.data;
                document.getElementById('termsMeta').style.display = 'flex';
                document.getElementById('termsTitle').textContent = d.title || 'Terms & Conditions';
                document.getElementById('termsDate').textContent = d.uploadedAt || '';
                if (d.versionLabel) {
                    document.getElementById('termsVersionBadge').style.display = 'inline-flex';
                    document.getElementById('termsVersion').textContent = d.versionLabel;
                }

                var pdfUrl = assetUrl(d.filePath);
                // Hide toolbar, thumbnails/nav pane, and secondary toolbar; force fit-width view.
                // Note: browsers only honor these fragments when the PDF is served inline.
                var viewerUrl = pdfUrl + '#toolbar=0&navpanes=0&scrollbar=0&statusbar=0&messages=0&view=FitH';

                content.innerHTML = '<div class="lmsa-card" style="padding:10px;"><iframe class="lmsa-terms-frame" src="' + viewerUrl + '" title="Terms and Conditions" scrolling="no"></iframe></div>' +
                    '<p style="margin-top:14px;font-size:0.82rem;color:var(--lmsa-text-muted);">If the document does not display, <a href="' + pdfUrl + '" target="_blank" rel="noopener" style="color:var(--lmsa-blue-dark);font-weight:700;">open it in a new tab</a>.</p>';
            }).catch(function () {
                document.getElementById('termsContent').innerHTML = '<div class="lmsa-card" style="padding:60px 20px;"><div class="lmsa-empty"><i class="fa-solid fa-triangle-exclamation"></i>Could not load the Terms &amp; Conditions document.</div></div>';
            });
        });
    </script>
</asp:Content>