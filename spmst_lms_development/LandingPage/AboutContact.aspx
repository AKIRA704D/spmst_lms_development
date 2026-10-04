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
        .lmsa-contact-row .ic.fb { background: #e7f3ff; color: #1877f2; }
        .lmsa-contact-row h4 { font-size: 0.88rem; font-weight: 700; color: var(--lmsa-navy); margin: 0 0 3px; }
        .lmsa-contact-row p { font-size: 0.86rem; color: var(--lmsa-text-muted); margin: 0; }

        .lmsa-form-card { padding: 30px 28px; }
        .lmsa-form-card label { font-weight: 700; font-size: 0.84rem; color: var(--lmsa-navy-2); margin-bottom: 6px; display: block; }
        .lmsa-form-card .form-control { border: 1.5px solid var(--lmsa-border); border-radius: var(--lmsa-radius-sm); padding: 10px 14px; font-size: 0.9rem; }
        .lmsa-form-card .form-control:focus { box-shadow: 0 0 0 3px rgba(14,165,233,0.15); border-color: var(--lmsa-blue); }
        .lmsa-form-success { display: none; align-items: center; gap: 10px; background: #f0fdf4; color: #16a34a; padding: 12px 16px; border-radius: var(--lmsa-radius-sm); font-weight: 600; font-size: 0.86rem; margin-top: 14px; }
        .lmsa-form-success.show { display: flex; }

        .lmsa-map-frame { width: 100%; height: 320px; border: 0; border-radius: var(--lmsa-radius); }

        .lmsa-form-error { display: none; align-items: center; gap: 10px; background: #fef2f2; color: #dc2626; padding: 12px 16px; border-radius: var(--lmsa-radius-sm); font-weight: 600; font-size: 0.86rem; margin-top: 14px; }
        .lmsa-form-error.show { display: flex; }
        .form-check-label { font-weight: 500; font-size: 0.86rem; color: var(--lmsa-navy-2); }
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
                    <h2 id="aboutHeading">About the SPAMAST Library</h2>
                    <div id="aboutBody">
                        <p>
                            The SPAMAST Library supports the instruction, research, and extension programs of the
                            Southern Philippines Agri-Business and Marine and Aquatic School of Technology. It houses
                            a growing collection of print and electronic resources covering agriculture, fisheries,
                            education, information technology, and allied fields.
                        </p>
                        <p>
                            Our staff are committed to providing equitable access to information and to helping
                            students, faculty, and researchers make the most of the resources available to them.
                        </p>
                    </div>
                    <div class="lmsa-mini-stats" id="aboutStats">
                        <div class="lmsa-card lmsa-mini-stat"><div class="num">10,000+</div><div class="lbl">Book Titles</div></div>
                        <div class="lmsa-card lmsa-mini-stat"><div class="num">5</div><div class="lbl">Campuses</div></div>
                        <div class="lmsa-card lmsa-mini-stat"><div class="num">1,200+</div><div class="lbl">Active Members</div></div>
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
                        <div><h4>Address</h4><p id="cAddress">Poblacion, Malita, Davao Occidental, Philippines</p></div>
                    </div>
                    <div class="lmsa-contact-row">
                        <div class="ic"><i class="fa-solid fa-phone"></i></div>
                        <div><h4>Phone</h4><p id="cPhone">(082) 237-3166</p></div>
                    </div>
                    <div class="lmsa-contact-row">
                        <div class="ic"><i class="fa-solid fa-envelope"></i></div>
                        <div><h4>Email</h4><p id="cEmail">library@spamast.edu.ph</p></div>
                    </div>
                    <div class="lmsa-contact-row">
                        <div class="ic fb"><i class="fa-brands fa-facebook-f"></i></div>
                        <div>
                            <h4>Facebook</h4>
                            <p id="cFacebook">
                                <a href="https://www.facebook.com/SPAMASTLibrary" target="_blank" rel="noopener noreferrer">SPAMAST Library</a>
                            </p>
                        </div>
                    </div>
                    <div class="lmsa-contact-row">
                        <div class="ic"><i class="fa-solid fa-clock"></i></div>
                        <div>
                            <h4>Library Hours</h4>
                            <p id="cHours">Monday - Friday: 8:00 AM - 5:00 PM<br />Saturday: 8:00 AM - 12:00 NN<br />Sunday &amp; Holidays: Closed</p>
                        </div>
                    </div>
                    <div class="lmsa-contact-row">
                        <div class="ic"><i class="fa-solid fa-right-to-bracket"></i></div>
                        <div><h4>Already a member?</h4><p><a href="<%= ResolveUrl("~/Login/login.aspx") %>" style="color:var(--lmsa-blue-dark);font-weight:700;">Log in to your account &rarr;</a></p></div>
                    </div>
                </div>

                <div class="lmsa-card lmsa-form-card">
                    <h3 style="font-weight: 800; color: var(--lmsa-navy); margin-bottom: 4px;">Send us a message</h3>
                    <p style="color: var(--lmsa-text-muted); font-size: 0.86rem; margin-bottom: 20px;">We usually respond within one to two business days.</p>

                    <div id="lmsaContactForm" class="lmsa-contact-form" novalidate>
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label for="cfName">Full Name</label>
                                <input type="text" id="cfName" class="form-control" data-required="true" maxlength="100" />
                            </div>
                            <div class="col-md-6">
                                <label for="cfEmail">Email Address</label>
                                <input type="email" id="cfEmail" class="form-control" data-required="true" maxlength="150" />
                            </div>
                            <div class="col-md-6">
                                <label for="cfType">Type</label>
                                <select id="cfType" class="form-control" data-required="true">
                                    <option value="Inquiry">Inquiry</option>
                                    <option value="Feedback">Feedback</option>
                                    <option value="Request">Request</option>
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label for="cfSubject">Subject</label>
                                <input type="text" id="cfSubject" class="form-control"
                                    placeholder="e.g. Book reservation inquiry" data-required="true" maxlength="150" />
                            </div>
                            <div class="col-12">
                                <label for="cfMessage">Message</label>
                                <textarea id="cfMessage" class="form-control" rows="4"
                                    data-required="true" maxlength="5000"></textarea>
                            </div>
                            <div class="col-12">
                                <div class="form-check">
                                    <input type="checkbox" id="cfRestock" class="form-check-input" />
                                    <label class="form-check-label" for="cfRestock">
                                        This is a suggestion to restock a book or resource
                                    </label>
                                </div>
                            </div>
                            <div class="col-12">
                                <button type="button" id="cfSubmit" class="lmsa-btn-gold" style="border: none;">
                                    <i class="fa-solid fa-paper-plane"></i>Send Message
                                </button>

                                <div class="lmsa-form-success" id="cfSuccess">
                                    <i class="fa-solid fa-circle-check"></i>
                                    <span id="cfSuccessText">Thanks! Your message has been received.</span>
                                </div>

                                <div class="lmsa-form-error" id="cfError">
                                    <i class="fa-solid fa-circle-exclamation"></i>
                                    <span id="cfErrorText">Something went wrong.</span>
                                </div>
                            </div>
                        </div>
                    </div>
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
        (function () {
            'use strict';

            // ---------------------------------------------------------------
            // Fallbacks — shown immediately, replaced by API data when present.
            // ---------------------------------------------------------------
            var FALLBACK_CONTACT = {
                address: 'Poblacion, Malita, Davao Occidental, Philippines',
                phone: '(082) 237-3166',
                email: 'library@spamast.edu.ph',
                facebookLabel: 'SPAMAST Library',
                facebookUrl: 'https://www.facebook.com/SPAMASTLibrary',
                hoursWeekdays: 'Monday - Friday: 8:00 AM - 5:00 PM',
                hoursSaturday: 'Saturday: 8:00 AM - 12:00 NN',
                hoursSunday: 'Sunday & Holidays: Closed'
            };

            var FALLBACK_ABOUT = {
                heading: 'About the SPAMAST Library',
                body: 'The SPAMAST Library supports the instruction, research, and extension programs of the ' +
                    'Southern Philippines Agri-Business and Marine and Aquatic School of Technology. It houses ' +
                    'a growing collection of print and electronic resources covering agriculture, fisheries, ' +
                    'education, information technology, and allied fields.\n\n' +
                    'Our staff are committed to providing equitable access to information and to helping ' +
                    'students, faculty, and researchers make the most of the resources available to them.',
                stat1Label: 'Book Titles', stat1Value: '10,000+',
                stat2Label: 'Campuses', stat2Value: '5',
                stat3Label: 'Active Members', stat3Value: '1,200+'
            };

            var FALLBACK_MAP_URL =
                'https://maps.google.com/maps?q=6.417639,125.607639&z=19&output=embed'; 

            // ---------------------------------------------------------------
            // Helpers
            // ---------------------------------------------------------------
            function escapeHtml(s) {
                if (s === null || s === undefined) return '';
                return String(s).replace(/[&<>"']/g, function (c) {
                    return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
                });
            }

            function esc(v) {
                if (typeof window.lmsaEscape === 'function') {
                    try { return window.lmsaEscape(v); } catch (e) { /* fall through */ }
                }
                return escapeHtml(v);
            }

            function setText(id, val) {
                var el = document.getElementById(id);
                if (el) el.textContent = (val === null || val === undefined || val === '') ? '' : val;
            }

            function setHtml(id, html) {
                var el = document.getElementById(id);
                if (el) el.innerHTML = html;
            }

            function hasValue(v) {
                return v !== null && v !== undefined && String(v).trim() !== '';
            }

            function safeUrl(url) {
                if (!url) return '';
                var s = String(url).trim();
                if (/^https?:\/\//i.test(s)) return s;
                if (/^www\./i.test(s)) return 'https://' + s;
                // Treat as a Facebook page handle/username
                return 'https://www.facebook.com/' + s.replace(/^\/+/, '');
            }

            // ---------------------------------------------------------------
            // Contact info rendering
            // ---------------------------------------------------------------
            function applyContact(d) {
                d = d || {};

                setText('cAddress', hasValue(d.address) ? d.address : FALLBACK_CONTACT.address);
                setText('cPhone', hasValue(d.phone) ? d.phone : FALLBACK_CONTACT.phone);
                setText('cEmail', hasValue(d.email) ? d.email : FALLBACK_CONTACT.email);

                // Facebook — support several possible API field names
                var fbRaw =
                    hasValue(d.facebookUrl) ? d.facebookUrl :
                        hasValue(d.facebook) ? d.facebook :
                            hasValue(d.fbUrl) ? d.fbUrl :
                                FALLBACK_CONTACT.facebookUrl;

                var fbLabel =
                    hasValue(d.facebookLabel) ? d.facebookLabel :
                        hasValue(d.facebookName) ? d.facebookName :
                            FALLBACK_CONTACT.facebookLabel;

                var fbEl = document.getElementById('cFacebook');
                if (fbEl) {
                    if (hasValue(fbRaw)) {
                        fbEl.innerHTML =
                            '<a href="' + esc(safeUrl(fbRaw)) + '" target="_blank" rel="noopener noreferrer">' +
                            esc(fbLabel) +
                            '</a>';
                    } else {
                        fbEl.textContent = 'Not yet set';
                    }
                }

                var hoursParts = [
                    hasValue(d.hoursWeekdays) ? d.hoursWeekdays : FALLBACK_CONTACT.hoursWeekdays,
                    hasValue(d.hoursSaturday) ? d.hoursSaturday : FALLBACK_CONTACT.hoursSaturday,
                    hasValue(d.hoursSunday) ? d.hoursSunday : FALLBACK_CONTACT.hoursSunday
                ].filter(Boolean);

                setHtml('cHours', hoursParts.map(esc).join('<br />'));

                // Map — prefer the DB value (map_embed_url)
                var mapUrl =
                    hasValue(d.mapEmbedUrl) ? d.mapEmbedUrl :
                        hasValue(d.mapUrl) ? d.mapUrl :
                            FALLBACK_MAP_URL;

                var frame = document.getElementById('mapFrame');
                if (frame && frame.getAttribute('src') !== mapUrl) {
                    frame.src = mapUrl;
                }
            }

            // ---------------------------------------------------------------
            // About us rendering
            // ---------------------------------------------------------------
            function applyAbout(d) {
                d = d || {};

                setText('aboutHeading', hasValue(d.heading) ? d.heading : FALLBACK_ABOUT.heading);

                var body = hasValue(d.body) ? String(d.body).trim() : FALLBACK_ABOUT.body;
                var paras = body.split(/\n{2,}/).map(function (p) { return p.trim(); }).filter(Boolean);
                if (!paras.length) paras = [body];
                setHtml('aboutBody', paras.map(function (p) { return '<p>' + esc(p) + '</p>'; }).join(''));

                var stats = [
                    {
                        label: hasValue(d.stat1Label) ? d.stat1Label : FALLBACK_ABOUT.stat1Label,
                        value: hasValue(d.stat1Value) ? d.stat1Value : FALLBACK_ABOUT.stat1Value
                    },
                    {
                        label: hasValue(d.stat2Label) ? d.stat2Label : FALLBACK_ABOUT.stat2Label,
                        value: hasValue(d.stat2Value) ? d.stat2Value : FALLBACK_ABOUT.stat2Value
                    },
                    {
                        label: hasValue(d.stat3Label) ? d.stat3Label : FALLBACK_ABOUT.stat3Label,
                        value: hasValue(d.stat3Value) ? d.stat3Value : FALLBACK_ABOUT.stat3Value
                    }
                ].filter(function (s) { return s.label || s.value; });

                var statsEl = document.getElementById('aboutStats');
                if (statsEl) {
                    if (stats.length) {
                        statsEl.style.display = '';
                        statsEl.innerHTML = stats.map(function (s) {
                            return '<div class="lmsa-card lmsa-mini-stat">' +
                                '<div class="num">' + esc(s.value) + '</div>' +
                                '<div class="lbl">' + esc(s.label) + '</div>' +
                                '</div>';
                        }).join('');
                    } else {
                        statsEl.style.display = 'none';
                    }
                }
            }

            // ---------------------------------------------------------------
            // API wrapper — safe if lmsaApi is missing or throws
            // ---------------------------------------------------------------
            function apiCall(endpoint) {
                if (typeof window.lmsaApi !== 'function') {
                    return Promise.reject(new Error('lmsaApi is not defined'));
                }
                try {
                    return Promise.resolve(window.lmsaApi(endpoint));
                } catch (err) {
                    return Promise.reject(err);
                }
            }

            // ---------------------------------------------------------------
            // Boot
            // ---------------------------------------------------------------
            document.addEventListener('DOMContentLoaded', function () {
                // Show real fallback content right away
                applyContact(null);
                applyAbout(null);

                // Then upgrade to live data if the API responds
                apiCall('contactinfo')
                    .then(function (res) {
                        if (res && res.success && res.data) applyContact(res.data);
                    })
                    .catch(function (err) {
                        if (window.console && console.warn) console.warn('contactinfo failed:', err);
                    });

                apiCall('aboutus')
                    .then(function (res) {
                        if (res && res.success && res.data) applyAbout(res.data);
                    })
                    .catch(function (err) {
                        if (window.console && console.warn) console.warn('aboutus failed:', err);
                    });

                // Contact form — AJAX submit, updates only this card
                (function initContactForm() {
                    var container = document.getElementById('lmsaContactForm');
                    var btn = document.getElementById('cfSubmit');
                    var successEl = document.getElementById('cfSuccess');
                    var errorEl = document.getElementById('cfError');
                    var successText = document.getElementById('cfSuccessText');
                    var errorText = document.getElementById('cfErrorText');

                    if (!container || !btn) return;

                    // --- simple validation (replaces native form validation) ---
                    function validate() {
                        var fields = container.querySelectorAll('[data-required="true"]');
                        for (var i = 0; i < fields.length; i++) {
                            var f = fields[i];
                            var val = (f.value || '').trim();

                            if (!val) {
                                f.focus();
                                return 'Please fill in all required fields.';
                            }
                            if (f.type === 'email' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val)) {
                                f.focus();
                                return 'Please enter a valid email address.';
                            }
                        }
                        return null;
                    }

                    function clearFeedback() {
                        successEl.classList.remove('show');
                        errorEl.classList.remove('show');
                    }

                    btn.addEventListener('click', function() {
                        clearFeedback();

                        var validationError = validate();
                        if (validationError) {
                            errorText.textContent = validationError;
                            errorEl.classList.add('show');
                            return;
                        }

                        // Disable button + spinner
                        var originalBtnHtml = btn.innerHTML;
                        btn.disabled = true;
                        btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Sending...';

                        var payload = {
                            name: document.getElementById('cfName').value,
                            email: document.getElementById('cfEmail').value,
                            subject: document.getElementById('cfSubject').value,
                            message: document.getElementById('cfMessage').value,
                            type: document.getElementById('cfType').value,
                            isRestock: document.getElementById('cfRestock').checked
                        };

                        fetch('AboutContact.aspx/SubmitMessage', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json; charset=utf-8',
                                'X-Requested-With': 'XMLHttpRequest'
                            },
                            body: JSON.stringify(payload)
                        })
                            .then(function(r) {
                                if (!r.ok) throw new Error('HTTP ' + r.status);
                                return r.json();
                            })
                            .then(function(res) {
                                // ASP.NET WebMethod wraps the response in { d: ... }
                                var data = (res && res.d) ? res.d : res;

                                if (data && data.success) {
                                    successText.textContent = data.message || 'Thanks! Your message has been received.';
                                    successEl.classList.add('show');
                                    resetForm();
                                } else {
                                    errorText.textContent = (data && data.reason)
                                        ? data.reason
                                        : 'We could not send your message. Please try again.';
                                    errorEl.classList.add('show');
                                }
                            })
                            .catch(function(err) {
                                if (window.console && console.warn) console.warn('submit failed:', err);
                                errorText.textContent = 'Network error. Please check your connection and try again.';
                                errorEl.classList.add('show');
                            })
                            .finally(function() {
                                btn.disabled = false;
                                btn.innerHTML = originalBtnHtml;
                            });
                    });

                    // Manual reset (since there's no <form> anymore)
                    function resetForm() {
                        container.querySelectorAll('input, textarea, select').forEach(function(el) {
                            if (el.type === 'checkbox') {
                                el.checked = false;
                            } else if (el.tagName === 'SELECT') {
                                el.selectedIndex = 0;
                            } else {
                                el.value = '';
                            }
                        });
                    }
                })();
            });
        })();
    </script>
</asp:Content>