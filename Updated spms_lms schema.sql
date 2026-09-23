CREATE DATABASE IF NOT EXISTS SPAMAST_LMSv2;
USE SPAMAST_LMSv2;

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
    address text,
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
    address text,
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
    is_head_librarian TINYINT(1) DEFAULT 0,
    address text,
    profile_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =============================================
-- 2. USERS TABLE
-- =============================================

CREATE TABLE Users (
    user_id VARCHAR(20) PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NULL,
    role ENUM('student', 'faculty', 'staff', 'admin') NOT NULL,
    is_active TINYINT(1) DEFAULT 0 COMMENT '0=pending, 1=active, 2=deactivated, 3=archived',
    last_login TIMESTAMP NULL,
    archived_at TIMESTAMP NULL,
    archived_reason VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =============================================
-- 3. INVENTORY TABLES
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
    is_available TINYINT(1) DEFAULT 1,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_resource_id (resource_id),
    FOREIGN KEY (resource_id) REFERENCES Library_Resources(resource_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =============================================
-- 4. NORMALIZED TRANSACTIONS TABLES
-- =============================================
-- ---------------------------------------------------------------------
-- 1. TRANSACTIONS  (event only — no fine data)
-- ---------------------------------------------------------------------
CREATE TABLE Transactions (
    transaction_id    INT AUTO_INCREMENT PRIMARY KEY,
    user_id           VARCHAR(20) NOT NULL,
    accession_number  VARCHAR(50) NOT NULL,
    borrow_date       DATE NOT NULL,
    due_date          DATE NOT NULL,
    return_date       DATE NULL,
    penalty_id        INT NULL,
    status            ENUM('Borrowed','Returned','Reserved','Ready','Cancelled')
                          DEFAULT 'Borrowed',
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

-- ---------------------------------------------------------------------
-- 2. PENALTIES  (source of truth for fines)
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- 3. PENALTY_PAYMENTS  (cashier audit trail)
-- ---------------------------------------------------------------------
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
-- 5. NOTIFICATIONS & FEEDBACK
-- =============================================

CREATE TABLE Notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(20),
    title VARCHAR(100),
    message TEXT,
    is_read TINYINT(1) DEFAULT 0,
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
    is_restock_suggestion TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =============================================
-- 6. ATTENDANCE
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
-- 7. AUDIT LOGS
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