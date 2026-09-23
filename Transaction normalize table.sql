-- =====================================================================
-- Clean rebuild of the normalized fine-tracking schema
-- =====================================================================

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Penalty_Payments;
DROP TABLE IF EXISTS Penalties;
DROP TABLE IF EXISTS Transactions;
SET FOREIGN_KEY_CHECKS = 1;

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

SHOW WARNINGS;   -- should be "No warnings"

SHOW CREATE TABLE Transactions;
SHOW CREATE TABLE Penalties;
SHOW CREATE TABLE Penalty_Payments;

SELECT TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
  AND REFERENCED_TABLE_NAME IS NOT NULL
  AND TABLE_NAME IN ('Transactions','Penalties','Penalty_Payments')
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

ALTER TABLE Transactions
    ADD CONSTRAINT fk_txn_penalty
        FOREIGN KEY (penalty_id) REFERENCES Penalties(penalty_id)
        ON DELETE SET NULL;
        
        -- 1. Overdue only
INSERT INTO Transactions (user_id, accession_number, borrow_date, due_date, return_date)
VALUES ('2023-114000', '100001',
        CURDATE() - INTERVAL 14 DAY, CURDATE() - INTERVAL 7 DAY, CURDATE() - INTERVAL 5 DAY);

-- 2. Lost, on time (no return date since it's gone)
INSERT INTO Transactions (user_id, accession_number, borrow_date, due_date, is_lost)
VALUES ('2023-114000', '100002',
        CURDATE() - INTERVAL 3 DAY, CURDATE() + INTERVAL 4 DAY, 1);

-- 3. Damaged, on time
INSERT INTO Transactions (user_id, accession_number, borrow_date, due_date, return_date, is_damaged)
VALUES ('2023-114000', '100003',
        CURDATE() - INTERVAL 10 DAY, CURDATE() - INTERVAL 3 DAY, CURDATE() - INTERVAL 3 DAY, 1);

-- 4. Damaged + overdue
INSERT INTO Transactions (user_id, accession_number, borrow_date, due_date, return_date, is_damaged)
VALUES ('2023-114000', '100004',
        CURDATE() - INTERVAL 14 DAY, CURDATE() - INTERVAL 7 DAY, CURDATE() - INTERVAL 4 DAY, 1);

-- 5. Lost + overdue (lost 5 days ago, still not returned)
INSERT INTO Transactions (user_id, accession_number, borrow_date, due_date, is_lost)
VALUES ('2023-114000', '100005',
        CURDATE() - INTERVAL 12 DAY, CURDATE() - INTERVAL 5 DAY, 1);