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
DROP EVENT IF EXISTS trg_transaction_update_item_availability
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
-- TRIGGEERS
-- ===========================================================
DELIMITER $$
CREATE TRIGGER trg_staff_users
AFTER INSERT ON Staff
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Users
        WHERE user_id = NEW.staff_id
    ) THEN
        INSERT INTO Users (
            user_id,
            email,
            role,
            is_active,
            last_login, 
            archived_at, 
            archived_reason, 
            created_at, 
            updated_at
        )
        VALUES (
            NEW.staff_id,
            NEW.email,
            CASE
                WHEN NEW.is_head_librarian = 1 THEN 'admin'
                ELSE 'staff'
            END,
            0,
            null,
            null,
            null,
            current_date(), 
            current_date()
        );
    END IF;
END$$
DELIMITER ;
-- ===========================================================
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
DELIMITER $$
CREATE TRIGGER trg_staff_users
AFTER UPDATE ON Staff
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
-- SHOW EXISTING EVENTS AND TRIGGERS FOR spamast_lmsv3
-- ===========================================================
show events from spamast_lmsv3 ;
show triggers from spamast_lmsv3 ;
-- ===========================================================