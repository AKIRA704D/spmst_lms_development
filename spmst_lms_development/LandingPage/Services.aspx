<%@ Page Title="" Language="C#" MasterPageFile="~/LandingPage/LandingPage.Master" AutoEventWireup="true" CodeBehind="Services.aspx.cs" Inherits="spmst_lms_development.LandingPage.Services" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <title>Library Services | SPAMAST Library — LMSA</title>
    <style>
        .lmsa-page-header { background: linear-gradient(135deg, var(--lmsa-navy) 0%, var(--lmsa-navy-2) 100%); color: #fff; padding: 56px 0 64px; }
        .lmsa-page-header h1 { font-size: 2.1rem; font-weight: 800; margin-bottom: 10px; }
        .lmsa-page-header p { color: #cbd5e1; max-width: 620px; font-size: 1rem; }
        .lmsa-breadcrumb { display: flex; align-items: center; gap: 8px; font-size: 0.82rem; color: #94a3b8; margin-bottom: 16px; }
        .lmsa-breadcrumb a { color: #94a3b8; }
        .lmsa-breadcrumb a:hover { color: #fff; }

        .lmsa-service-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 22px; }
        @media (max-width: 991.98px) { .lmsa-service-grid { grid-template-columns: repeat(2, 1fr); } }
        @media (max-width: 575.98px) { .lmsa-service-grid { grid-template-columns: 1fr; } }

        .lmsa-service-card { padding: 28px 24px; }
        .lmsa-service-card .ic { width: 54px; height: 54px; border-radius: 14px; background: linear-gradient(135deg,#eef6ff,#e0f2fe); color: var(--lmsa-blue-dark); display: flex; align-items: center; justify-content: center; font-size: 1.3rem; margin-bottom: 16px; }
        .lmsa-service-card h3 { font-size: 1.05rem; font-weight: 700; color: var(--lmsa-navy); margin-bottom: 8px; }
        .lmsa-service-card p { font-size: 0.88rem; color: var(--lmsa-text-muted); margin: 0; line-height: 1.6; }

        .lmsa-steps { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; }
        @media (max-width: 767.98px) { .lmsa-steps { grid-template-columns: 1fr 1fr; } }
        .lmsa-step { text-align: center; padding: 24px 16px; position: relative; }
        .lmsa-step .step-num { width: 36px; height: 36px; border-radius: 50%; background: var(--lmsa-navy); color: #fff; font-weight: 800; display: flex; align-items: center; justify-content: center; margin: 0 auto 14px; }
        .lmsa-step h4 { font-size: 0.94rem; font-weight: 700; color: var(--lmsa-navy); margin-bottom: 6px; }
        .lmsa-step p { font-size: 0.82rem; color: var(--lmsa-text-muted); margin: 0; }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <section class="lmsa-page-header">
        <div class="container-lmsa">
            <div class="lmsa-breadcrumb">
                <a href="<%= ResolveUrl("~/LandingPage/Home.aspx") %>">Home</a>
                <i class="fa-solid fa-chevron-right" style="font-size:0.65rem"></i>
                <span>Services</span>
            </div>
            <h1><i class="fa-solid fa-hand-holding-heart me-2"></i>Library Services</h1>
            <p>Everything the SPAMAST Library offers to students, faculty, and staff - from borrowing and research help to digital access and quiet study spaces.</p>
        </div>
    </section>

    <section class="lmsa-section">
        <div class="container-lmsa">
            <div class="lmsa-section-head">
                <div>
                    <span class="lmsa-eyebrow"><i class="fa-solid fa-list-check"></i> What We Offer</span>
                    <h2 class="lmsa-section-title">Core Library Services</h2>
                </div>
            </div>

            <div class="lmsa-service-grid" id="servicesGrid">
                <div class="lmsa-empty" style="grid-column:1/-1;"><i class="fa-solid fa-spinner fa-spin"></i>Loading services...</div>
            </div>
        </div>
    </section>

    <section class="lmsa-section bg-soft">
        <div class="container-lmsa">
            <div class="lmsa-section-head">
                <div>
                    <span class="lmsa-eyebrow"><i class="fa-solid fa-route"></i> Getting Started</span>
                    <h2 class="lmsa-section-title">How to Borrow a Book</h2>
                    <p class="lmsa-section-sub">A quick walkthrough for first-time borrowers.</p>
                </div>
            </div>
            <div class="lmsa-steps">
                <div class="lmsa-card lmsa-step">
                    <div class="step-num">1</div>
                    <h4>Search the Catalog</h4>
                    <p>Find your title on the home page catalog or ask a librarian for help.</p>
                </div>
                <div class="lmsa-card lmsa-step">
                    <div class="step-num">2</div>
                    <h4>Present Your ID</h4>
                    <p>Bring your valid SPAMAST student, faculty, or staff ID to the Circulation Desk.</p>
                </div>
                <div class="lmsa-card lmsa-step">
                    <div class="step-num">3</div>
                    <h4>Check Out</h4>
                    <p>Library staff record the transaction and set your due date.</p>
                </div>
                <div class="lmsa-card lmsa-step">
                    <div class="step-num">4</div>
                    <h4>Return or Renew</h4>
                    <p>Return on time, or renew if no one else has reserved the title.</p>
                </div>
            </div>
        </div>
    </section>

    <section class="lmsa-section" style="padding-top:10px;">
        <div class="container-lmsa">
            <div class="lmsa-cta-band" style="background: linear-gradient(135deg, var(--lmsa-navy) 0%, var(--lmsa-navy-2) 100%); border-radius:24px; padding:46px 40px; display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:20px; color:#fff;">
                <div>
                    <h3 style="font-size:1.4rem;font-weight:800;margin:0 0 6px;">Ready to explore the collection?</h3>
                    <p style="color:#cbd5e1;margin:0;">Head back to the catalog and find your next read.</p>
                </div>
                <a href="<%= ResolveUrl("~/LandingPage/Home.aspx") %>#catalog" class="lmsa-btn-gold"><i class="fa-solid fa-magnifying-glass"></i> Browse the Catalog</a>
            </div>
        </div>
    </section>

</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="scripts" runat="server">
    <script>
        function serviceCardHtml(s) {
            return '' +
                '<div class="lmsa-card lmsa-service-card">' +
                '  <div class="ic"><i class="fa-solid ' + lmsaEscape(s.iconClass || 'fa-book') + '"></i></div>' +
                '  <h3>' + lmsaEscape(s.title) + '</h3>' +
                '  <p>' + lmsaEscape(s.description) + '</p>' +
                '</div>';
        }

        document.addEventListener('DOMContentLoaded', function () {
            lmsaApi('services').then(function (res) {
                var grid = document.getElementById('servicesGrid');
                if (!res.success || !res.data || res.data.length === 0) {
                    grid.innerHTML = '<div class="lmsa-empty" style="grid-column:1/-1;"><i class="fa-solid fa-hand-holding-heart"></i>Service listings haven\'t been published yet - check back soon.</div>';
                    return;
                }
                grid.innerHTML = res.data.map(serviceCardHtml).join('');
            }).catch(function () {
                document.getElementById('servicesGrid').innerHTML = '<div class="lmsa-empty" style="grid-column:1/-1;"><i class="fa-solid fa-triangle-exclamation"></i>Could not load services.</div>';
            });
        });
    </script>
</asp:Content>
