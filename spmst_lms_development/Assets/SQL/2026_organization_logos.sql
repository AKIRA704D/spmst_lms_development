-- ============================================================
-- Migration: organization_logos
-- Compatible with MySQL 8.x (SmarterASP.NET)
-- Safe to run repeatedly (idempotent).
--
-- Design note:
--   The unique key covers (entity_type, entity_name, is_active) so a
--   single entity can have ONE active logo at a time, while historical
--   (inactive) logos are retained for audit and rollback purposes.
-- ============================================================

USE db_ad0eb7_libraryspamast;

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `organization_logos` (
    `logo_id`     int          NOT NULL AUTO_INCREMENT,
    `entity_type` enum('School','Institute','Department','Library','Other') NOT NULL,
    `entity_name` varchar(150) NOT NULL,
    `logo_path`   varchar(255) NOT NULL,
    `is_active`   tinyint      NOT NULL DEFAULT '1' COMMENT '0=false, 1=true',
    `sort_order`  int          NOT NULL DEFAULT '0',
    `created_at`  timestamp    NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  timestamp    NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`logo_id`),
    UNIQUE KEY `uk_logo_active_entity` (`entity_type`, `entity_name`, `is_active`),
    KEY `idx_logo_active_sort`  (`is_active`, `sort_order`),
    KEY `idx_logo_entity_type`  (`entity_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed defaults (only if table is empty).
INSERT INTO `organization_logos` (`entity_type`, `entity_name`, `logo_path`, `is_active`, `sort_order`)
SELECT * FROM (
    SELECT 'School'  AS entity_type, 'SPAMAST'          AS entity_name, 'Assets/Logo/spamast_logo_wbg.png' AS logo_path, 1 AS is_active, 1 AS sort_order
    UNION ALL SELECT 'Library', 'SPAMAST Library', 'Assets/Logo/lib_logo_wbg.png',  1, 2
    UNION ALL SELECT 'Library', 'LMSA',            'Assets/Logo/lmsa_logo.png',     1, 3
) seed
WHERE NOT EXISTS (SELECT 1 FROM `organization_logos`);