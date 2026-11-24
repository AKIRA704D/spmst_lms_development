-- ============================================================================
-- Reservation_Notification_Log   (NOT applied automatically)
--
-- WHY: Assets/Helper/Reservations/ReservationNotificationLog.cs reads/writes this
-- table (duplicate-send protection for reservation SMS / Email / Push notices),
-- but it is not defined in OnlineDB.sql or any other .sql file in the project.
-- If it is missing in the live database, notices still send, but "already sent?"
-- checks always say "no", so the same notice can be re-sent on every scheduled run.
--
-- STEP 1: check whether it already exists in your live DB:
--     SHOW TABLES LIKE 'reservation_notification_log';
-- STEP 2: if it exists, DO NOT run this file (compare its columns with the block below).
--         If it does not exist, run the CREATE below.
--
-- NOTE: This definition is RECONSTRUCTED from the INSERT / SELECT / ON DUPLICATE KEY
-- statements in the code and modeled on penalty_notification_log. It is not an export
-- of your real table - review it before running. The UNIQUE key is required: the code
-- uses ON DUPLICATE KEY UPDATE and expects one row per (transaction, channel, event).
-- No foreign key is declared (to avoid blocking transaction deletes); add one if you want.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `reservation_notification_log` (
  `notification_log_id` int NOT NULL AUTO_INCREMENT,
  `transaction_id`      int NOT NULL,
  `channel`             enum('SMS','Email','Push') COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_type`          varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status`              enum('Sent','Failed') COLLATE utf8mb4_unicode_ci NOT NULL,
  `attempt_count`       int NOT NULL DEFAULT '1',
  `recipient_masked`    varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `message_id`          varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `error_details`       varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at`          timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`notification_log_id`),
  UNIQUE KEY `uk_rnl_txn_channel_event` (`transaction_id`,`channel`,`event_type`),
  KEY `idx_rnl_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ROLLBACK:  DROP TABLE `reservation_notification_log`;
