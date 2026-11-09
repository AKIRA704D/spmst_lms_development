-- ============================================================
-- Migration: Penalty Component Settlement & Book Replacement
-- Target:    SPAMAST_LMSv4
-- Safe:      Idempotent, no destructive changes to existing data
-- ============================================================
USE SPAMAST_LMSv4;

-- ------------------------------------------------------------
-- 1. Penalty_Policy — reserve table (service uses C# constants
--    but this table is available for future configurability)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Penalty_Policy (
    policy_id     INT AUTO_INCREMENT PRIMARY KEY,
    policy_key    VARCHAR(50)   NOT NULL UNIQUE,
    policy_value  DECIMAL(10,2) NOT NULL,
    description   VARCHAR(255)  NULL,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO Penalty_Policy (policy_key, policy_value, description) VALUES
  ('overdue_hourly_rate',   5.00,   'Rate per overdue hour (loan-in)'),
  ('overdue_daily_rate',    5.00,   'Rate per overdue day (loan-out)'),
  ('damaged_fixed_amount',  100.00, 'Fixed fine for damaged book'),
  ('lost_fixed_amount',     200.00, 'Fixed fine for lost book')
ON DUPLICATE KEY UPDATE policy_value = VALUES(policy_value);

-- ------------------------------------------------------------
-- 2. Penalty_Components — per-component settlement state
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Penalty_Components (
    component_id    INT AUTO_INCREMENT PRIMARY KEY,
    penalty_id      INT NOT NULL,
    component_type  ENUM('Overdue','Damaged','Lost') NOT NULL,
    amount          DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    amount_paid     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    settlement_type ENUM('Pending','Payment','Replacement') NOT NULL DEFAULT 'Pending',
    settled_at      DATETIME NULL,
    settled_by      VARCHAR(20) NULL,
    remarks         TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_comp_penalty_type (penalty_id, component_type),
    INDEX idx_comp_penalty (penalty_id),
    INDEX idx_comp_settlement (settlement_type),
    CONSTRAINT fk_comp_penalty   FOREIGN KEY (penalty_id) REFERENCES Penalties(penalty_id) ON DELETE CASCADE,
    CONSTRAINT fk_comp_settledby FOREIGN KEY (settled_by) REFERENCES Users(user_id)         ON DELETE SET NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. Penalty_Replacements — auditable replacement ledger
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Penalty_Replacements (
    replacement_id                INT AUTO_INCREMENT PRIMARY KEY,
    penalty_id                    INT NOT NULL,
    transaction_id                INT NOT NULL,
    component_type                ENUM('Damaged','Lost') NOT NULL,
    original_accession_number     VARCHAR(50) NOT NULL,
    replacement_accession_number  VARCHAR(50) NULL,
    replacement_status            ENUM('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
    replacement_book_title        VARCHAR(255) NULL,
    replacement_book_author       VARCHAR(255) NULL,
    replacement_book_isbn         VARCHAR(20)  NULL,
    remarks                       TEXT,
    processed_by                  VARCHAR(20)  NULL,
    replacement_date              DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_at                    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at                    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_repl_penalty_component (penalty_id, component_type),
    INDEX idx_repl_penalty (penalty_id),
    INDEX idx_repl_txn     (transaction_id),
    CONSTRAINT fk_repl_penalty FOREIGN KEY (penalty_id)     REFERENCES Penalties(penalty_id)      ON DELETE CASCADE,
    CONSTRAINT fk_repl_txn     FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id) ON DELETE CASCADE,
    CONSTRAINT fk_repl_staff   FOREIGN KEY (processed_by)   REFERENCES Users(user_id)              ON DELETE SET NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. Backfill components for EXISTING penalties
-- ------------------------------------------------------------
INSERT INTO Penalty_Components (penalty_id, component_type, amount, amount_paid, settlement_type)
SELECT  p.penalty_id,
        'Overdue',
        p.fine_amount,
        p.amount_paid,
        CASE p.fine_status
             WHEN 'Paid'    THEN 'Payment'
             WHEN 'Partial' THEN 'Payment'
             ELSE                'Pending'
        END
FROM Penalties p
WHERE p.penalty_type IN ('Overdue','Overdue_Damaged','Overdue_Lost','Overdue_Damaged_Lost')
  AND NOT EXISTS (SELECT 1 FROM Penalty_Components pc
                  WHERE pc.penalty_id = p.penalty_id
                    AND pc.component_type = 'Overdue');

INSERT INTO Penalty_Components (penalty_id, component_type, amount)
SELECT p.penalty_id, 'Damaged', 100.00
FROM Penalties p
WHERE p.penalty_type IN ('Damaged','Overdue_Damaged','Damaged_Lost','Overdue_Damaged_Lost')
  AND NOT EXISTS (SELECT 1 FROM Penalty_Components pc
                  WHERE pc.penalty_id = p.penalty_id
                    AND pc.component_type = 'Damaged');

INSERT INTO Penalty_Components (penalty_id, component_type, amount)
SELECT p.penalty_id, 'Lost', 200.00
FROM Penalties p
WHERE p.penalty_type IN ('Lost','Overdue_Lost','Damaged_Lost','Overdue_Damaged_Lost')
  AND NOT EXISTS (SELECT 1 FROM Penalty_Components pc
                  WHERE pc.penalty_id = p.penalty_id
                    AND pc.component_type = 'Lost');