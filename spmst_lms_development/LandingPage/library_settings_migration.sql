-- ============================================================================
-- LMSA — Public Content Settings Migration
-- Adds admin-manageable tables for: Contact Info, About Us, Services, and
-- Terms & Conditions (PDF uploads), replacing the hardcoded landing-page
-- content in AboutContact.aspx / Services.aspx.
--
-- Run against: spamast_lmsv2
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Contact information (single-row settings table)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS library_contact_info (
    contact_id      INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    address         VARCHAR(255) NULL,
    phone           VARCHAR(50)  NULL,
    email           VARCHAR(100) NULL,
    hours_weekdays  VARCHAR(100) NULL,
    hours_saturday  VARCHAR(100) NULL,
    hours_sunday    VARCHAR(100) NULL,
    facebook_url    VARCHAR(255) NULL,
    map_embed_url   TEXT NULL,
    updated_at      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by      VARCHAR(20) NULL,
    CONSTRAINT fk_contact_updated_by FOREIGN KEY (updated_by) REFERENCES users(user_id) ON DELETE SET NULL
);

INSERT INTO library_contact_info (address, phone, email, hours_weekdays, hours_saturday, hours_sunday, facebook_url, map_embed_url)
SELECT 'Poblacion, Malita, Davao Occidental, Philippines 8012',
       '(082) 272-3725',
       'library@spamast.edu.ph',
       'Mon - Fri: 8:00 AM - 5:00 PM',
       'Saturday: 8:00 AM - 12:00 PM',
       'Sunday & Holidays: Closed',
       '',
       'https://www.google.com/maps/embed?pb=!1m14!1m12!1m3!1d991.2029031222396!2d125.60769499574207!3d6.41824697173699!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!5e0!3m2!1sen!2sph!4v1785921070592!5m2!1sen!2sph'
WHERE NOT EXISTS (SELECT 1 FROM library_contact_info);

-- ----------------------------------------------------------------------------
-- 2. About Us content (single-row settings table)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS library_about_us (
    about_id      INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    heading       VARCHAR(150) NULL,
    body          TEXT NULL,
    stat1_label   VARCHAR(60) NULL, stat1_value VARCHAR(30) NULL,
    stat2_label   VARCHAR(60) NULL, stat2_value VARCHAR(30) NULL,
    stat3_label   VARCHAR(60) NULL, stat3_value VARCHAR(30) NULL,
    updated_at    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by    VARCHAR(20) NULL,
    CONSTRAINT fk_about_updated_by FOREIGN KEY (updated_by) REFERENCES users(user_id) ON DELETE SET NULL
);

INSERT INTO library_about_us (heading, body, stat1_label, stat1_value, stat2_label, stat2_value, stat3_label, stat3_value)
SELECT 'Serving the SPAMAST community since day one',
       'The SPAMAST Library is the academic heart of the Southern Philippines Agri-Business and Marine and Aquatic School of Technology, supporting students, faculty, and staff across all institutes with a growing collection of books, journals, and multimedia resources. The Library Management System with Analytics (LMSA) modernizes how the community discovers and borrows materials — from real-time catalog search to transparent, data-driven insight into what the SPAMAST community is reading.',
       'Institutes Served', '7',
       'SPAMAST Founded', '1969',
       'Days a Week Open', '6'
WHERE NOT EXISTS (SELECT 1 FROM library_about_us);

-- ----------------------------------------------------------------------------
-- 3. Services (multi-row, CRUD-managed, ordered list)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS library_services (
    service_id   INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    icon_class   VARCHAR(60) NOT NULL DEFAULT 'fa-book',
    title        VARCHAR(120) NOT NULL,
    description  TEXT NULL,
    sort_order   INT NOT NULL DEFAULT 0,
    is_active    TINYINT(1) NOT NULL DEFAULT 1,
    created_at   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO library_services (icon_class, title, description, sort_order, is_active)
SELECT * FROM (SELECT 'fa-book-bookmark' AS icon_class, 'Circulation & Borrowing' AS title, 'Borrow books, journals, and other materials from the general collection with a valid SPAMAST ID. Loan periods and limits follow institute policy.' AS description, 1 AS sort_order, 1 AS is_active
    UNION ALL SELECT 'fa-calendar-check', 'Reservations', 'Reserve high-demand titles online and get notified the moment your copy is ready for pickup at the Circulation Desk.', 2, 1
    UNION ALL SELECT 'fa-magnifying-glass-plus', 'Reference & Research Assistance', 'Get one-on-one help from librarians with literature searches, citation styles, and locating the right sources for your thesis or research paper.', 3, 1
    UNION ALL SELECT 'fa-chalkboard-user', 'Information Literacy Sessions', 'Orientation and workshops on using the catalog, evaluating sources, and avoiding plagiarism — available for classes and student organizations.', 4, 1
    UNION ALL SELECT 'fa-chair', 'Reading & Study Areas', 'Quiet individual study carrels and group discussion tables across the AV Section, Periodicals area, and general reading room.', 5, 1
    UNION ALL SELECT 'fa-print', 'Printing & Photocopying', 'On-site printing and photocopying services for coursework, research output, and official requirements.', 6, 1
    UNION ALL SELECT 'fa-compact-disc', 'AV & Multimedia Access', 'Browse and view DVDs, recorded lectures, and other multimedia resources in the dedicated AV Section.', 7, 1
    UNION ALL SELECT 'fa-newspaper', 'Periodicals & Journals', 'Access current and archived journals, magazines, and newspapers curated for every institute''s field of study.', 8, 1
    UNION ALL SELECT 'fa-chart-line', 'Borrowing Analytics', 'See top borrowers, most requested titles, and institute-wide reading trends right on the library''s home page.', 9, 1
) seed
WHERE NOT EXISTS (SELECT 1 FROM library_services);

-- ----------------------------------------------------------------------------
-- 4. Terms & Conditions (PDF upload history; one row may be marked active)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS library_terms (
    terms_id       INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title          VARCHAR(150) NOT NULL,
    version_label  VARCHAR(50) NULL,
    file_path      VARCHAR(255) NOT NULL,
    is_active      TINYINT(1) NOT NULL DEFAULT 0,
    uploaded_at    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    uploaded_by    VARCHAR(20) NULL,
    CONSTRAINT fk_terms_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES users(user_id) ON DELETE SET NULL
);
-- No seed row — the public Terms & Conditions page shows a "not yet published"
-- empty state until an admin uploads a PDF from Library Settings.
