-- ===========================================================
SET GLOBAL event_scheduler = ON;
-- ===========================================================
-- EVENTS
-- ===========================================================
DROP EVENT IF EXISTS auto_cancel_ready_transactions;
DELIMITER $$
CREATE EVENT IF NOT EXISTS auto_cancel_ready_transactions
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    UPDATE Transactions t
    INNER JOIN item_copies ic ON t.accession_number = ic.accession_number
    SET t.status = 'Cancelled',
		ic.is_available = 1
    WHERE status = 'Ready'
      AND updated_at <= NOW() - INTERVAL 1 HOUR;
END$$
DELIMITER ;
-- ===========================================================
DROP EVENT IF EXISTS auto_update_overdue_penalties;
DELIMITER $$
CREATE EVENT auto_update_overdue_penalties
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    /*
     * =====================================================
     * LOAN-IN
     * borrow_date = due_date
     *
     * ₱5.00 per overdue hour
     * =====================================================
     */
    INSERT INTO Penalties (
        transaction_id,
        user_id,
        accession_number,
        penalty_type,
        reason,
        fine_amount
    )
    SELECT
        t.transaction_id,
        t.user_id,
        t.accession_number,
        'Overdue',
        'Overdue loan-in',
        TIMESTAMPDIFF(
            HOUR,
            t.created_at,
            CURRENT_TIMESTAMP
        ) * 5.00
    FROM Transactions t
    WHERE t.status = 'Borrowed'
      AND t.borrow_date = t.due_date
      AND CURRENT_TIMESTAMP > t.created_at
      AND t.penalty_id IS NULL
      AND TIMESTAMPDIFF(
            HOUR,
            t.created_at,
            CURRENT_TIMESTAMP
          ) > 0;
    /*
     * =====================================================
     * LOAN-OUT
     * borrow_date < due_date
     *
     * ₱5.00 per overdue day
     * =====================================================
     */
    INSERT INTO Penalties (
        transaction_id,
        user_id,
        accession_number,
        penalty_type,
        reason,
        fine_amount
    )
    SELECT
        t.transaction_id,
        t.user_id,
        t.accession_number,
        'Overdue',
        'Overdue loan-out',
        DATEDIFF(
            CURRENT_DATE,
            t.due_date
        ) * 5.00
    FROM Transactions t
    WHERE t.status = 'Borrowed'
      AND t.borrow_date < t.due_date
      AND t.return_date IS NULL
      AND CURRENT_DATE > t.due_date
      AND t.penalty_id IS NULL;
    /*
     * =====================================================
     * LINK PENALTY TO TRANSACTION
     * =====================================================
     */
    UPDATE Transactions t
    INNER JOIN Penalties p
        ON p.transaction_id = t.transaction_id
    SET t.penalty_id = p.penalty_id
    WHERE t.penalty_id IS NULL
      AND p.penalty_type = 'Overdue';
    /*
     * =====================================================
     * UPDATE EXISTING LOAN-IN PENALTY
     *
     * This allows the fine to increase every hour
     * even though the event runs every minute.
     * =====================================================
     */
    UPDATE Penalties p
    INNER JOIN Transactions t
        ON t.transaction_id = p.transaction_id
    SET p.fine_amount =
        TIMESTAMPDIFF(
            HOUR,
            t.created_at,
            CURRENT_TIMESTAMP
        ) * 5.00
    WHERE t.status = 'Borrowed'
      AND t.borrow_date = t.due_date
      AND t.return_date IS NULL
      AND p.penalty_type = 'Overdue'
      AND TIMESTAMPDIFF(
            HOUR,
            t.created_at,
            CURRENT_TIMESTAMP
          ) > 0;
    /*
     * =====================================================
     * UPDATE EXISTING LOAN-OUT PENALTY
     *
     * Fine increases once per overdue day.
     * =====================================================
     */
    UPDATE Penalties p
    INNER JOIN Transactions t
        ON t.transaction_id = p.transaction_id
    SET p.fine_amount =
        DATEDIFF(
            CURRENT_DATE,
            t.due_date
        ) * 5.00
    WHERE t.status = 'Borrowed'
      AND t.borrow_date < t.due_date
      AND t.return_date IS NULL
      AND CURRENT_DATE > t.due_date
      AND p.penalty_type = 'Overdue';
END$$
DELIMITER ;
-- ===========================================================
-- TRIGGERS
-- ===========================================================
DROP TRIGGER IF EXISTS trg_staff_users;
DROP TRIGGER IF EXISTS trg_students_users;
DROP TRIGGER IF EXISTS trg_faculty_users;
DELIMITER $$
CREATE TRIGGER trg_staff_users
AFTER INSERT ON Staff
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = NEW.staff_id) THEN
        INSERT INTO Users (user_id, email, role, is_active)
        VALUES (
            NEW.staff_id,
            NEW.email,
            CASE WHEN NEW.is_head_librarian = 1 THEN 'admin' ELSE 'staff' END,
            0
        );
    END IF;
END$$

CREATE TRIGGER trg_students_users
AFTER INSERT ON Students
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = NEW.student_id) THEN
        INSERT INTO Users (user_id, email, role, is_active)
        VALUES (NEW.student_id, NEW.email, 'student', 0);
    END IF;
END$$

CREATE TRIGGER trg_faculty_users
AFTER INSERT ON Faculty
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = NEW.faculty_id) THEN
        INSERT INTO Users (user_id, email, role, is_active)
        VALUES (NEW.faculty_id, NEW.email, 'faculty', 0);
    END IF;
END$$
DELIMITER ;
-- ===========================================================
DROP TRIGGER IF EXISTS trg_staff_users_upd;
DROP TRIGGER IF EXISTS trg_students_users_upd;
DROP TRIGGER IF EXISTS trg_faculty_users_upd;

DELIMITER $$

CREATE TRIGGER trg_staff_users_upd
AFTER UPDATE ON Staff
FOR EACH ROW
BEGIN
    UPDATE Users
    SET email = NEW.email,
        role  = CASE WHEN NEW.is_head_librarian = 1 THEN 'admin' ELSE 'staff' END
    WHERE user_id = OLD.staff_id;
END$$

CREATE TRIGGER trg_students_users_upd
AFTER UPDATE ON Students
FOR EACH ROW
BEGIN
    UPDATE Users SET email = NEW.email WHERE user_id = OLD.student_id;
END$$

CREATE TRIGGER trg_faculty_users_upd
AFTER UPDATE ON Faculty
FOR EACH ROW
BEGIN
    UPDATE Users SET email = NEW.email WHERE user_id = OLD.faculty_id;
END$$

DELIMITER ;
-- ===========================================================
DROP TRIGGER IF EXISTS trg_transaction_reserved_item_unavailable;
DELIMITER $$
CREATE TRIGGER trg_transaction_reserved_item_unavailable
AFTER UPDATE ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.status = 'Reserved' THEN
        UPDATE item_copies
        SET is_available = 0
        WHERE accession_number = NEW.accession_number;
    END IF;
END$$
DELIMITER ;
-- ===========================================================
DROP TRIGGER IF EXISTS trg_transaction_borrowed_item_unavailable;
DELIMITER $$
CREATE TRIGGER trg_transaction_borrowed_item_unavailable
AFTER UPDATE ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.status = 'Borrowed' THEN
        UPDATE item_copies
        SET is_available = 0
        WHERE accession_number = NEW.accession_number;
    END IF;
END$$
DELIMITER ;
-- ===========================================================
DROP TRIGGER IF EXISTS trg_transaction_update_item_availability;
DELIMITER $$
CREATE TRIGGER trg_transaction_update_item_availability
AFTER UPDATE ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.status IN ('Returned', 'Cancelled') THEN
        IF NEW.is_damaged = 0 AND NEW.is_lost = 0 THEN
            UPDATE item_copies
            SET is_available = 1,
                status_condition = 'Good'
            WHERE accession_number = NEW.accession_number;
        ELSEIF NEW.is_damaged = 1 AND NEW.is_lost = 0 THEN
            UPDATE item_copies
            SET is_available = 0,
                status_condition = 'Damage'
            WHERE accession_number = NEW.accession_number;
        ELSEIF NEW.is_damaged = 0 AND NEW.is_lost = 1 THEN
            UPDATE item_copies
            SET is_available = 0,
                status_condition = 'Lost'
            WHERE accession_number = NEW.accession_number;
        ELSEIF NEW.is_damaged = 1 AND NEW.is_lost = 1 THEN
            UPDATE item_copies
            SET is_available = 0,
                status_condition = 'Combination'
            WHERE accession_number = NEW.accession_number;
        END IF;
    END IF;
END$$
DELIMITER ;
-- ===========================================================
-- ----------------------------------------------------------------------------
-- 1. Students → archive matching Users row
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_students_archive_user;
DELIMITER $$
CREATE TRIGGER trg_students_archive_user
AFTER DELETE ON Students
FOR EACH ROW
BEGIN
    UPDATE Users
       SET is_active       = 3,
           archived_at     = COALESCE(archived_at, CURRENT_TIMESTAMP),
           archived_reason = COALESCE(archived_reason,
                                      'Student record deleted; associated account archived.')
     WHERE user_id  = OLD.student_id
       AND is_active <> 3;
END$$
DELIMITER ;

-- ----------------------------------------------------------------------------
-- 2. Faculty → archive matching Users row
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_faculty_archive_user;
DELIMITER $$
CREATE TRIGGER trg_faculty_archive_user
AFTER DELETE ON Faculty
FOR EACH ROW
BEGIN
    UPDATE Users
       SET is_active       = 3,
           archived_at     = COALESCE(archived_at, CURRENT_TIMESTAMP),
           archived_reason = COALESCE(archived_reason,
                                      'Faculty record deleted; associated account archived.')
     WHERE user_id  = OLD.faculty_id
       AND is_active <> 3;
END$$
DELIMITER ;

-- ----------------------------------------------------------------------------
-- 3. Staff → archive matching Users row
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_staff_archive_user;
DELIMITER $$
CREATE TRIGGER trg_staff_archive_user
AFTER DELETE ON Staff
FOR EACH ROW
BEGIN
    UPDATE Users
       SET is_active       = 3,
           archived_at     = COALESCE(archived_at, CURRENT_TIMESTAMP),
           archived_reason = COALESCE(archived_reason,
                                      'Staff record deleted; associated account archived.')
     WHERE user_id  = OLD.staff_id
       AND is_active <> 3;
END$$
DELIMITER ;

-- ----------------------------------------------------------------------------
-- 4. Verification queries (run after deployment)
-- ----------------------------------------------------------------------------
SHOW TRIGGERS FROM SPAMAST_LMSv4
WHERE `Trigger` IN
      ('trg_students_archive_user',
       'trg_faculty_archive_user',
       'trg_staff_archive_user');

-- Sanity check: no schema additions required — is_active / archived_at /
-- archived_reason already exist in the shipped schema.
SELECT column_name, column_type, is_nullable
  FROM information_schema.columns
 WHERE table_schema = 'SPAMAST_LMSv3'
   AND table_name   = 'Users'
   AND column_name IN ('is_active','archived_at','archived_reason');
-- SHOW EXISTING EVENTS AND TRIGGERS FOR spamast_lmsv3
-- ===========================================================
-- ===========================================================
show events from spamast_lmsv3 ;
show triggers from spamast_lmsv3 ;
-- ===========================================================
-- Insert Data
-- ===========================================================
-- insert into staff ( staff_id, first_name, middle_name, last_name, extension_name, gender, mobile_number, email, office_department, is_head_librarian, address, profile_path, created_at, updated_at)
-- values ('2023-114000', 'Mary Claire', 'Lumansoc', 'Fernandez', '', 'Female', '09932960062', 'mc.fernandez@spamast.edu.ph', 'Head Office', '1', 'Poblacion, Malita, Davao Occidental', 'Assets/Profile/2023-114000_20260923170216256.jpg', current_date(), current_date());
