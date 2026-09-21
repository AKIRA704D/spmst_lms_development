<%@ Page Title="" Language="C#" MasterPageFile="~/LandingPage/LandingPage.Master" AutoEventWireup="true" CodeBehind="AboutContact.aspx.cs" Inherits="spmst_lms_development.LandingPage.AboutContact" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <title>About &amp; Contact | SPAMAST Library — LMSA</title>
    <style>
        .lmsa-page-header { background: linear-gradient(135deg, var(--lmsa-navy) 0%, var(--lmsa-navy-2) 100%); color: #fff; padding: 56px 0 64px; }
        .lmsa-page-header h1 { font-size: 2.1rem; font-weight: 800; margin-bottom: 10px; }
        .lmsa-page-header p { color: #cbd5e1; max-width: 620px; font-size: 1rem; }
        .lmsa-breadcrumb { display: flex; align-items: center; gap: 8px; font-size: 0.82rem; color: #94a3b8; margin-bottom: 16px; }
        .lmsa-breadcrumb a { color: #94a3b8; }
        .lmsa-breadcrumb a:hover { color: #fff; }

        .lmsa-about-grid { display: grid; grid-template-columns: 1.1fr 0.9fr; gap: 40px; align-items: center; }
        @media (max-width: 991.98px) { .lmsa-about-grid { grid-template-columns: 1fr; } }
        .lmsa-about-grid h2 { font-size: 1.6rem; font-weight: 800; color: var(--lmsa-navy); margin-bottom: 14px; }
        .lmsa-about-grid p { color: var(--lmsa-text-muted); line-height: 1.75; margin-bottom: 14px; }
        .lmsa-mini-stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; margin-top: 20px; }
        .lmsa-mini-stat { text-align: center; padding: 18px 10px; }
        .lmsa-mini-stat .num { font-size: 1.5rem; font-weight: 800; color: var(--lmsa-navy); }
        .lmsa-mini-stat .lbl { font-size: 0.74rem; color: var(--lmsa-text-muted); font-weight: 600; text-transform: uppercase; letter-spacing: .4px; }
        .lmsa-about-badge { width: 100%; border-radius: var(--lmsa-radius); background: linear-gradient(135deg, var(--lmsa-navy) 0%, var(--lmsa-navy-2) 100%); color: #fff; padding: 40px 30px; text-align: center; }
        .lmsa-about-badge i { font-size: 3rem; color: var(--lmsa-gold); margin-bottom: 14px; }
        .lmsa-about-badge h3 { font-weight: 800; font-size: 1.2rem; margin-bottom: 6px; }
        .lmsa-about-badge p { color: #cbd5e1; font-size: 0.88rem; margin: 0; }

        .lmsa-contact-grid { display: grid; grid-template-columns: 0.9fr 1.1fr; gap: 30px; }
        @media (max-width: 991.98px) { .lmsa-contact-grid { grid-template-columns: 1fr; } }

        .lmsa-contact-info-card { padding: 30px 28px; }
        .lmsa-contact-row { display: flex; align-items: flex-start; gap: 14px; padding: 14px 0; border-bottom: 1px solid var(--lmsa-border); }
        .lmsa-contact-row:last-child { border-bottom: none; }
        .lmsa-contact-row .ic { width: 42px; height: 42px; border-radius: 12px; background: #eef6ff; color: var(--lmsa-blue-dark); display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
        .lmsa-contact-row h4 { font-size: 0.88rem; font-weight: 700; color: var(--lmsa-navy); margin: 0 0 3px; }
        .lmsa-contact-row p { font-size: 0.86rem; color: var(--lmsa-text-muted); margin: 0; }

        .lmsa-form-card { padding: 30px 28px; }
        .lmsa-form-card label { font-weight: 700; font-size: 0.84rem; color: var(--lmsa-navy-2); margin-bottom: 6px; display: block; }
        .lmsa-form-card .form-control { border: 1.5px solid var(--lmsa-border); border-radius: var(--lmsa-radius-sm); padding: 10px 14px; font-size: 0.9rem; }
        .lmsa-form-card .form-control:focus { box-shadow: 0 0 0 3px rgba(14,165,233,0.15); border-color: var(--lmsa-blue); }
        .lmsa-form-success { display: none; align-items: center; gap: 10px; background: #f0fdf4; color: #16a34a; padding: 12px 16px; border-radius: var(--lmsa-radius-sm); font-weight: 600; font-size: 0.86rem; margin-top: 14px; }
        .lmsa-form-success.show { display: flex; }

        .lmsa-map-frame { width: 100%; height: 320px; border: 0; border-radius: var(--lmsa-radius); }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <section class="lmsa-page-header">
        <div class="container-lmsa">
            <div class="lmsa-breadcrumb">
                <a href="<%= ResolveUrl("~/LandingPage/Home.aspx") %>">Home</a>
                <i class="fa-solid fa-chevron-right" style="font-size:0.65rem"></i>
                <span>About &amp; Contact</span>
            </div>
            <h1><i class="fa-solid fa-circle-info me-2"></i>About &amp; Contact</h1>
            <p>Learn more about the SPAMAST Library and get in touch with our team.</p>
        </div>
    </section>

    <!-- ABOUT -->
    <section class="lmsa-section">
        <div class="container-lmsa">
            <div class="lmsa-about-grid">
                <div>
                    <span class="lmsa-eyebrow"><i class="fa-solid fa-book-open"></i> About the Library</span>
                    <h2 id="aboutHeading">Loading...</h2>
                    <div id="aboutBody"><p class="lmsa-skeleton" style="height:60px;"></p></div>
                    <div class="lmsa-mini-stats" id="aboutStats">
                        <div class="lmsa-card lmsa-mini-stat"><div class="num">-</div><div class="lbl">&nbsp;</div></div>
                        <div class="lmsa-card lmsa-mini-stat"><div class="num">-</div><div class="lbl">&nbsp;</div></div>
                        <div class="lmsa-card lmsa-mini-stat"><div class="num">-</div><div class="lbl">&nbsp;</div></div>
                    </div>
                </div>
                <div class="lmsa-about-badge">
                    <i class="fa-solid fa-book-open-reader"></i>
                    <h3>Malita, Davao Occidental</h3>
                    <p>Main Campus Library | Poblacion, Malita<br />Southern Philippines Agri-Business and Marine and Aquatic School of Technology</p>
                </div>
            </div>
        </div>
    </section>

    <!-- CONTACT -->
    <section class="lmsa-section bg-soft">
        <div class="container-lmsa">
            <div class="lmsa-section-head">
                <div>
                    <span class="lmsa-eyebrow"><i class="fa-solid fa-headset"></i> Get in Touch</span>
                    <h2 class="lmsa-section-title">Contact the Library</h2>
                    <p class="lmsa-section-sub">Have a question about the catalog, a reservation, or your account? Reach out below.</p>
                </div>
            </div>

            <div class="lmsa-contact-grid">
                <div class="lmsa-card lmsa-contact-info-card">
                    <div class="lmsa-contact-row">
                        <div class="ic"><i class="fa-solid fa-location-dot"></i></div>
                        <div><h4>Address</h4><p id="cAddress">Loading...</p></div>
                    </div>
                    <div class="lmsa-contact-row">
                        <div class="ic"><i class="fa-solid fa-phone"></i></div>
                        <div><h4>Phone</h4><p id="cPhone">Loading...</p></div>
                    </div>
                    <div class="lmsa-contact-row">
                        <div class="ic"><i class="fa-solid fa-envelope"></i></div>
                        <div><h4>Email</h4><p id="cEmail">Loading...</p></div>
                    </div>
                    <div class="lmsa-contact-row">
                        <div class="ic"><i class="fa-solid fa-clock"></i></div>
                        <div>
                            <h4>Library Hours</h4>
                            <p id="cHours">Loading...</p>
                        </div>
                    </div>
                    <div class="lmsa-contact-row">
                        <div class="ic"><i class="fa-solid fa-right-to-bracket"></i></div>
                        <div><h4>Already a member?</h4><p><a href="<%= ResolveUrl("~/Login/login.aspx") %>" style="color:var(--lmsa-blue-dark);font-weight:700;">Log in to your account &rarr;</a></p></div>
                    </div>
                </div>

                <div class="lmsa-card lmsa-form-card">
                    <h3 style="font-weight:800;color:var(--lmsa-navy);margin-bottom:4px;">Send us a message</h3>
                    <p style="color:var(--lmsa-text-muted);font-size:0.86rem;margin-bottom:20px;">We usually respond within one to two business days.</p>
                    <form id="lmsaContactForm" onsubmit="return false;">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label for="cfName">Full Name</label>
                                <input type="text" id="cfName" class="form-control" required />
                            </div>
                            <div class="col-md-6">
                                <label for="cfEmail">Email Address</label>
                                <input type="email" id="cfEmail" class="form-control" required />
                            </div>
                            <div class="col-12">
                                <label for="cfSubject">Subject</label>
                                <input type="text" id="cfSubject" class="form-control" placeholder="e.g. Book reservation inquiry" required />
                            </div>
                            <div class="col-12">
                                <label for="cfMessage">Message</label>
                                <textarea id="cfMessage" class="form-control" rows="4" required></textarea>
                            </div>
                            <div class="col-12">
                                <button type="submit" id="cfSubmit" class="lmsa-btn-gold" style="border:none;"><i class="fa-solid fa-paper-plane"></i> Send Message</button>
                                <div class="lmsa-form-success" id="cfSuccess"><i class="fa-solid fa-circle-check"></i> Thanks! Your message has been noted — the library team will get back to you soon.</div>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </section>

    <!-- MAP -->
    <section class="lmsa-section">
        <div class="container-lmsa">
            <div class="lmsa-section-head">
                <div>
                    <span class="lmsa-eyebrow"><i class="fa-solid fa-map-location-dot"></i> Find Us</span>
                    <h2 class="lmsa-section-title">SPAMAST Main Campus</h2>
                </div>
            </div>
            <div class="lmsa-card" style="padding:10px;">
                <iframe id="mapFrame" class="lmsa-map-frame" loading="lazy" referrerpolicy="no-referrer-when-downgrade"
                    src="https://www.google.com/maps/embed?pb=!1m14!1m12!1m3!1d991.2029031222396!2d125.60769499574207!3d6.41824697173699!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!5e0!3m2!1sen!2sph!4v1785921070592!5m2!1sen!2sph">
                </iframe>
            </div>
        </div>
    </section>

</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="scripts" runat="server">
    <script>
        // Client-side only: shows a confirmation message. Wire this up to a
        // feedback/contact handler (e.g. a dedicated .ashx endpoint) if the
        // team wants submissions persisted to the database.
        document.getElementById('lmsaContactForm').addEventListener('submit', function () {
            var form = this;
            if (!form.checkValidity()) { form.reportValidity(); return; }
            document.getElementById('cfSuccess').classList.add('show');
            form.reset();
        });

        function loadContactInfo() {
            lmsaApi('contactinfo').then(function (res) {
                if (!res.success || !res.data) return;
                var d = res.data;
                document.getElementById('cAddress').textContent = d.address || 'Not yet set';
                document.getElementById('cPhone').textContent = d.phone || 'Not yet set';
                document.getElementById('cEmail').textContent = d.email || 'Not yet set';

                var hoursParts = [d.hoursWeekdays, d.hoursSaturday, d.hoursSunday].filter(Boolean);
                document.getElementById('cHours').innerHTML = hoursParts.length
                    ? hoursParts.map(lmsaEscape).join('<br />')
                    : 'Not yet set';

                if (d.mapEmbedUrl) {
                    document.getElementById('mapFrame').src = d.mapEmbedUrl;
                }
            }).catch(function () { });
        }

        function loadAboutUs() {
            lmsaApi('aboutus').then(function (res) {
                if (!res.success || !res.data) return;
                var d = res.data;
                document.getElementById('aboutHeading').textContent = d.heading || 'About the SPAMAST Library';
                document.getElementById('aboutBody').innerHTML = (d.body || '')
                    .split(/\n{2,}/)
                    .filter(Boolean)
                    .map(function (para) { return '<p>' + lmsaEscape(para) + '</p>'; })
                    .join('');

                var stats = [
                    { label: d.stat1Label, value: d.stat1Value },
                    { label: d.stat2Label, value: d.stat2Value },
                    { label: d.stat3Label, value: d.stat3Value }
                ].filter(function (s) { return s.label || s.value; });

                if (stats.length) {
                    document.getElementById('aboutStats').innerHTML = stats.map(function (s) {
                        return '<div class="lmsa-card lmsa-mini-stat"><div class="num">' + lmsaEscape(s.value) + '</div><div class="lbl">' + lmsaEscape(s.label) + '</div></div>';
                    }).join('');
                } else {
                    document.getElementById('aboutStats').style.display = 'none';
                }
            }).catch(function () { });
        }

        document.addEventListener('DOMContentLoaded', function () {
            loadContactInfo();
            loadAboutUs();
        });
    </script>
</asp:Content>
