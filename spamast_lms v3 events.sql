-- ===========================================================
SET GLOBAL event_scheduler = ON;
-- ===========================================================

-- ===========================================================
DROP EVENT IF EXISTS auto_cancel_ready_transactions;
DELIMITER $$
CREATE EVENT IF NOT EXISTS auto_cancel_ready_transactions
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    UPDATE Transactions
    SET status = 'Cancelled'
    WHERE status = 'Ready'
      AND updated_at <= NOW() - INTERVAL 1 HOUR;
END$$
DELIMITER ;
-- ===========================================================

-- ===========================================================
show events from spamast_lmsv3 ;
-- ===========================================================