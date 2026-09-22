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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;
alter table Staff 
add address text after is_head_librarian,
add profile_path VARCHAR(255) after address;

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
-- 4. TRANSACTIONS
-- =============================================

CREATE TABLE Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(20),
    accession_number VARCHAR(50),
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    fine_amount DECIMAL(10,2) DEFAULT 0.00,
    amount_paid DECIMAL(10,2) DEFAULT 0.00,
    balance DECIMAL(10,2) DEFAULT 0.00,
    fine_status ENUM('Unpaid', 'Partial', 'Paid') DEFAULT 'Unpaid',
    paid_date DATETIME NULL,
    status ENUM('Borrowed', 'Returned', 'Overdue', 'Reserved', 'Ready', 'Cancelled') DEFAULT 'Borrowed',
    is_damaged TINYINT(1) DEFAULT 0,
    is_lost TINYINT(1) DEFAULT 0,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_accession_number (accession_number),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (accession_number) REFERENCES Item_Copies(accession_number) ON DELETE RESTRICT
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

-- =============================================
-- 8. SAMPLE DATA
-- =============================================

INSERT INTO Staff (staff_id, first_name, last_name, email, office_department, is_head_librarian) 
VALUES ('STAFF-001', 'John', 'Smith', 'mc.fernandez@spamast.edu.ph', 'Head Office', 0);

-- INSERT INTO Staff (staff_id, first_name, last_name, email, office_department, is_head_librarian) 
-- VALUES ('STAFF-002', 'Jane', 'Doe', 'circulation@lmsa.edu.ph', 'Circulation Area', 0);

-- INSERT INTO Staff (staff_id, first_name, last_name, email, office_department, is_head_librarian) 
-- VALUES ('STAFF-003', 'Bob', 'Johnson', 'management@lmsa.edu.ph', 'Management Area', 0);

-- INSERT INTO Students (student_id, first_name, last_name, email, course, year_level) 
-- VALUES ('2024-0001', 'Maria', 'Santos', 'student@lmsa.edu.ph', 'BSIT', '2nd Year');

-- INSERT INTO Faculty (faculty_id, first_name, last_name, email, institute) 
-- VALUES ('FAC-001', 'Dr. Jose', 'Reyes', 'rizenakishin@gmail.com', 'College of ICT');

INSERT INTO Users (user_id, email, password_hash, role, is_active) VALUES
('STAFF-001', 'fernandezmaryclaire79@gmail.com', NULL, 'admin', 0);
-- ('STAFF-002', 'circulation@lmsa.edu.ph', NULL, 'staff', 1),
-- ('STAFF-003', 'management@lmsa.edu.ph', NULL, 'staff', 1),
-- ('2024-0001', 'student@lmsa.edu.ph', NULL, 'student', 0),
-- ('FAC-001', 'faculty@lmsa.edu.ph', NULL, 'faculty', 0);

-- Verify everything
-- SHOW TABLES;