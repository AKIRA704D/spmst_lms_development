DROP DATABASE IF EXISTS SPAMAST_LMSv3;
CREATE DATABASE SPAMAST_LMSv3;
USE SPAMAST_LMSv3;

-- =============================================
-- 1. PERSON TABLES
-- =============================================
CREATE TABLE Students (
    student_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    last_name VARCHAR(50) NOT NULL,
    extension_name VARCHAR(10),
    gender ENUM('Male', 'Female'),
    mobile_number VARCHAR(15),
    email VARCHAR(100) NOT NULL UNIQUE,
    institute VARCHAR(50),
    course VARCHAR(50),
    section VARCHAR(10),
    year_level VARCHAR(20),
    address TEXT,
    profile_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE Faculty (
    faculty_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    last_name VARCHAR(50) NOT NULL,
    extension_name VARCHAR(10),
    gender ENUM('Male', 'Female'),
    mobile_number VARCHAR(15),
    email VARCHAR(100) NOT NULL UNIQUE,
    institute VARCHAR(50),
    address TEXT,
    profile_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE Staff (
    staff_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    last_name VARCHAR(50) NOT NULL,
    extension_name VARCHAR(10),
    gender ENUM('Male', 'Female'),
    mobile_number VARCHAR(15),
    email VARCHAR(100) NOT NULL UNIQUE,
    office_department VARCHAR(100) DEFAULT 'Circulation Area',
    is_head_librarian TINYINT NOT NULL DEFAULT 0 COMMENT '0=false, 1=true',
    address TEXT,
    profile_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =============================================
-- 2. USERS
-- =============================================
CREATE TABLE Users (
    user_id VARCHAR(20) PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NULL,
    role ENUM('student', 'faculty', 'staff', 'admin') NOT NULL,
    is_active TINYINT NOT NULL DEFAULT 0 COMMENT '0=pending, 1=active, 2=deactivated, 3=archived',
    last_login TIMESTAMP NULL,
    archived_at TIMESTAMP NULL,
    archived_reason VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =============================================
-- 3. INVENTORY
-- =============================================
CREATE TABLE Library_Resources (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    item_type VARCHAR(100),
    isbn VARCHAR(20),
    issn VARCHAR(20),
    call_number VARCHAR(100),
    dewey_decimal VARCHAR(20),
    genre VARCHAR(20),
    title VARCHAR(255) NOT NULL,
    author TEXT,
    section VARCHAR(100),
    publisher VARCHAR(100),
    place_of_publication VARCHAR(100),
    series VARCHAR(100),
    edition VARCHAR(50),
    pub_year INT,
    copyright_year INT,
    pages_numeric VARCHAR(320),
    height_cm DECIMAL(5,2),
    width_cm DECIMAL(5,2),
    accompanying_material TEXT,
    description TEXT,
    cover_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE Item_Copies (
    accession_number VARCHAR(50) PRIMARY KEY,
    resource_id INT,
    volume_no VARCHAR(20),
    issue_no VARCHAR(20),
    binding_type VARCHAR(50),
    campus VARCHAR(100) DEFAULT 'Malita Campus',
    specific_location VARCHAR(100) DEFAULT 'Circulation Desk',
    status_condition ENUM('Good', 'Damage', 'Lost', 'Reserved') DEFAULT 'Good',
    is_available TINYINT NOT NULL DEFAULT 1 COMMENT '0=false, 1=true',
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_resource_id (resource_id),
    FOREIGN KEY (resource_id) REFERENCES Library_Resources(resource_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =============================================
-- 4. TRANSACTIONS  (overdue is derived, not stored)
-- =============================================
CREATE TABLE Transactions (
    transaction_id    INT AUTO_INCREMENT PRIMARY KEY,
    user_id           VARCHAR(20) NOT NULL,
    accession_number  VARCHAR(50) NOT NULL,
    borrow_date       DATE NOT NULL,
    due_date          DATE NOT NULL,
    return_date       DATE NULL,
    penalty_id        INT NULL,
    status            ENUM(
                          'Borrowed',
                          'Returned',
                          'Reserved',
                          'Ready',
                          'Cancelled',
                          'Renewal',    -- patron submitted, awaiting staff
                          'Renewed'     -- closed by an approved renewal
                      ) DEFAULT 'Borrowed',
    is_damaged        TINYINT NOT NULL DEFAULT 0,
    is_lost           TINYINT NOT NULL DEFAULT 0,
    remarks           TEXT,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id          (user_id),
    INDEX idx_accession_number (accession_number),
    INDEX idx_status           (status),
    INDEX idx_due_date         (due_date),
    CONSTRAINT chk_txn_is_damaged CHECK (is_damaged IN (0,1)),
    CONSTRAINT chk_txn_is_lost    CHECK (is_lost    IN (0,1)),
    CONSTRAINT fk_txn_user
        FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_txn_item
        FOREIGN KEY (accession_number) REFERENCES Item_Copies(accession_number) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =============================================
-- 5. PENALTIES  (source of truth for fines)
-- =============================================
CREATE TABLE Penalties (
    penalty_id        INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id    INT NOT NULL,
    user_id           VARCHAR(20) NOT NULL,
    accession_number  VARCHAR(50) NULL,
    penalty_type      ENUM(
                          'Overdue',
                          'Damaged',
                          'Lost',
                          'Overdue_Damaged',
                          'Overdue_Lost',
                          'Damaged_Lost',
                          'Overdue_Damaged_Lost',
                          'Other'
                      ) NOT NULL DEFAULT 'Overdue',
    reason            VARCHAR(255) NOT NULL,
    fine_amount       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    amount_paid       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    fine_status       ENUM('Unpaid','Partial','Paid') NOT NULL DEFAULT 'Unpaid',
    paid_date         DATETIME NULL,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_penalty_transaction (transaction_id),
    INDEX idx_penalty_user   (user_id),
    INDEX idx_penalty_status (fine_status),
    CONSTRAINT fk_penalty_transaction
        FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_penalty_user
        FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =============================================
-- 6. PENALTY_PAYMENTS
-- =============================================
CREATE TABLE Penalty_Payments (
    payment_id         INT AUTO_INCREMENT PRIMARY KEY,
    penalty_id         INT NOT NULL,
    amount             DECIMAL(10,2) NOT NULL,
    cash_tendered      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    change_given       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    payment_method     VARCHAR(50) NOT NULL,
    payment_reference  VARCHAR(100) NULL,
    payment_notes      TEXT NULL,
    received_by        VARCHAR(20) NULL,
    payment_date       DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_pp_penalty (penalty_id),
    INDEX idx_pp_date    (payment_date),
    CONSTRAINT fk_pp_penalty
        FOREIGN KEY (penalty_id) REFERENCES Penalties(penalty_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_pp_staff
        FOREIGN KEY (received_by) REFERENCES Users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =============================================
-- 7. RENEWALS  (audit trail)
-- =============================================
CREATE TABLE Renewals (
    renewal_id       INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id   INT NOT NULL,
    old_due_date     DATE NOT NULL,
    new_due_date     DATE NOT NULL,
    renewed_by       VARCHAR(20) NULL,
    renewal_type     ENUM('WalkIn','Online') NOT NULL DEFAULT 'WalkIn',
    status           ENUM('Pending','Approved','Denied') NOT NULL DEFAULT 'Approved',
    remarks          TEXT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_renewal_txn    (transaction_id),
    INDEX idx_renewal_status (status),
    CONSTRAINT fk_renewal_txn
        FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_renewal_staff
        FOREIGN KEY (renewed_by) REFERENCES Users(user_id)
        ON DELETE SET NULL
) ENGINE=InnoDB;

-- =============================================
-- 8. NOTIFICATIONS & FEEDBACK
-- =============================================
CREATE TABLE Notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(20),
    title VARCHAR(100),
    message TEXT,
    is_read TINYINT NOT NULL DEFAULT 0 COMMENT '0=false, 1=true',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE User_Submissions (
    submission_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(20),
    type ENUM('Inquiry','Feedback', 'Request'),
    message TEXT,
    is_restock_suggestion TINYINT NOT NULL DEFAULT 0 COMMENT '0=false, 1=true',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =============================================
-- 9. ATTENDANCE
-- =============================================
CREATE TABLE Library_Attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(20),
    time_in TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    time_out TIMESTAMP NULL,
    purpose VARCHAR(100),
    entry_method ENUM('QR_SCAN', 'MANUAL_ENTRY') DEFAULT 'QR_SCAN',
    session_type ENUM('STAFF_ASSISTED', 'KIOSK_SELF_SERVICE') NOT NULL,
    encoded_by VARCHAR(20) NULL,
    attendance_status ENUM('Entry', 'Exited') DEFAULT 'Entry',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =============================================
-- 10. AUDIT LOGS
-- =============================================
CREATE TABLE Audit_Logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(20),
    action_type VARCHAR(20) NULL,
    table_affected VARCHAR(50) NULL,
    action_details TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

insert into staff ( staff_id, first_name, middle_name, last_name, extension_name, gender, mobile_number, email, office_department, is_head_librarian, address, profile_path, created_at, updated_at)
values ('2023-114000', 'Mary Claire', 'Lumansoc', 'Fernandez', '', 'Female', '09569135784', 'mc.fernandez@spamast.edu.ph', 'Head Office', '1', 'Poblacion, Malita, Davao Occidental', 'Assets/Profile/2023-113941_20260923095546365.jpg', current_date(), current_date());

insert into users ( user_id, email, password_hash, role, is_active, last_login, archived_at, archived_reason, created_at, updated_at)
values ('2023-114000', 'mc.fernandez@spamast.edu.ph', '', 'admin', '0', current_date(), null, null, current_date(), current_date());

-- ----------------------------------------------------------------------------
-- 11. Contact information (single-row settings table)
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

-- ----------------------------------------------------------------------------
-- 12. About Us content (single-row settings table)
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

-- ----------------------------------------------------------------------------
-- 13. Services (multi-row, CRUD-managed, ordered list)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS library_services (
    service_id   INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    icon_class   VARCHAR(60) NOT NULL DEFAULT 'fa-book',
    title        VARCHAR(120) NOT NULL,
    description  TEXT NULL,
    sort_order   INT NOT NULL DEFAULT 0,
    is_active    TINYINT NOT NULL DEFAULT 1 COMMENT '0=false, 1=true',
    created_at   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 14. Terms & Conditions (PDF upload history; one row may be marked active)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS library_terms (
    terms_id       INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title          VARCHAR(150) NOT NULL,
    version_label  VARCHAR(50) NULL,
    file_path      VARCHAR(255) NOT NULL,
    is_active      TINYINT NOT NULL DEFAULT 0 COMMENT '0=false, 1=true',
    uploaded_at    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    uploaded_by    VARCHAR(20) NULL,
    CONSTRAINT fk_terms_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- DELIMETER for auto updates in the database
-- ----------------------------------------------------------------------------
SET GLOBAL event_scheduler = ON;

DELIMITER $$

CREATE EVENT IF NOT EXISTS auto_cancel_ready_transactions
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    UPDATE Transactions t
    INNER JOIN item_copies ic ON t.accession_number = ic_accession_number
    SET t.status = 'Cancelled',
		ic.is_available = 1
    WHERE status = 'Ready'
      AND updated_at <= NOW() - INTERVAL 1 HOUR;
END$$

DELIMITER ;

-- DROP EVENT IF EXISTS auto_cancel_ready_transactions;
-- show events from spamast_lmsv3 ;