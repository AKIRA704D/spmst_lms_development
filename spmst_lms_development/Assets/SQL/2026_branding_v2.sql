-- ============================================================================
-- 2026_branding_v2.sql  --  Branding v2 + organization lookup tables
-- MySQL 8.0.16+ (SmarterASP.NET).  Idempotent: safe to run more than once.
-- BACK UP THE DATABASE FIRST (mysqldump or the SmarterASP.NET backup tool).
-- Replace the USE line if your schema name differs.
-- ============================================================================
USE db_ad0eb7_libraryspamast;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 0. Helper: add a column / index / FK only when it does not exist yet
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_lmsa_add_column;
DROP PROCEDURE IF EXISTS sp_lmsa_add_index;
DROP PROCEDURE IF EXISTS sp_lmsa_add_fk;
DELIMITER $$
CREATE PROCEDURE sp_lmsa_add_column(IN t VARCHAR(64), IN c VARCHAR(64), IN ddl VARCHAR(255))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = t AND COLUMN_NAME = c) THEN
    SET @s = CONCAT('ALTER TABLE `', t, '` ADD COLUMN `', c, '` ', ddl);
    PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
  END IF;
END$$
CREATE PROCEDURE sp_lmsa_add_index(IN t VARCHAR(64), IN i VARCHAR(64), IN cols VARCHAR(255))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.STATISTICS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = t AND INDEX_NAME = i) THEN
    SET @s = CONCAT('ALTER TABLE `', t, '` ADD INDEX `', i, '` (', cols, ')');
    PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
  END IF;
END$$
CREATE PROCEDURE sp_lmsa_add_fk(IN t VARCHAR(64), IN fk VARCHAR(64), IN def VARCHAR(400))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.TABLE_CONSTRAINTS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = t
                   AND CONSTRAINT_NAME = fk AND CONSTRAINT_TYPE = 'FOREIGN KEY') THEN
    SET @s = CONCAT('ALTER TABLE `', t, '` ADD CONSTRAINT `', fk, '` ', def);
    PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
  END IF;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------------
-- 1. Organization lookup tables (the schema stored these only as free text)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `institutes` (
  `institute_id`   int          NOT NULL AUTO_INCREMENT,
  `institute_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active`      tinyint      NOT NULL DEFAULT 1,
  `created_at`     timestamp    NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     timestamp    NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`institute_id`),
  UNIQUE KEY `uk_institute_name` (`institute_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `programs` (
  `program_id`   int          NOT NULL AUTO_INCREMENT,
  `institute_id` int          NULL,
  `program_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active`    tinyint      NOT NULL DEFAULT 1,
  `created_at`   timestamp    NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   timestamp    NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`program_id`),
  UNIQUE KEY `uk_program_name` (`program_name`),
  KEY `idx_program_institute` (`institute_id`),
  CONSTRAINT `fk_program_institute` FOREIGN KEY (`institute_id`)
      REFERENCES `institutes` (`institute_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `departments` (
  `department_id`   int          NOT NULL AUTO_INCREMENT,
  `department_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active`       tinyint      NOT NULL DEFAULT 1,
  `created_at`      timestamp    NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      timestamp    NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`department_id`),
  UNIQUE KEY `uk_department_name` (`department_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed from existing text values (trimmed, non-empty, de-duplicated)
INSERT IGNORE INTO institutes (institute_name)
SELECT DISTINCT TRIM(institute) FROM students WHERE institute IS NOT NULL AND TRIM(institute) <> '';
INSERT IGNORE INTO institutes (institute_name)
SELECT DISTINCT TRIM(institute) FROM faculty  WHERE institute IS NOT NULL AND TRIM(institute) <> '';

INSERT IGNORE INTO programs (program_name, institute_id)
SELECT TRIM(s.course), MIN(i.institute_id)
FROM students s
LEFT JOIN institutes i ON i.institute_name = TRIM(s.institute)
WHERE s.course IS NOT NULL AND TRIM(s.course) <> ''
GROUP BY TRIM(s.course);

INSERT IGNORE INTO departments (department_name)
SELECT DISTINCT TRIM(office_department) FROM staff
WHERE office_department IS NOT NULL AND TRIM(office_department) <> '';
-- The School Library itself must exist as a department (it owns the "School Library" logo)
INSERT IGNORE INTO departments (department_name) VALUES ('Library');

-- ---------------------------------------------------------------------------
-- 2. ID columns on borrower tables (text columns are KEPT for compatibility)
-- ---------------------------------------------------------------------------
CALL sp_lmsa_add_column('students', 'institute_id',  'int NULL AFTER `institute`');
CALL sp_lmsa_add_column('students', 'program_id',    'int NULL AFTER `course`');
CALL sp_lmsa_add_column('faculty',  'institute_id',  'int NULL AFTER `institute`');
CALL sp_lmsa_add_column('staff',    'department_id', 'int NULL AFTER `office_department`');

CALL sp_lmsa_add_index('students', 'idx_students_institute_id', '`institute_id`');
CALL sp_lmsa_add_index('students', 'idx_students_program_id',   '`program_id`');
CALL sp_lmsa_add_index('faculty',  'idx_faculty_institute_id',   '`institute_id`');
CALL sp_lmsa_add_index('staff',    'idx_staff_department_id',    '`department_id`');

-- Back-fill IDs from the existing text values
UPDATE students s JOIN institutes i ON i.institute_name = TRIM(s.institute)
   SET s.institute_id = i.institute_id WHERE s.institute_id IS NULL;
UPDATE students s JOIN programs p ON p.program_name = TRIM(s.course)
   SET s.program_id = p.program_id WHERE s.program_id IS NULL;
UPDATE faculty f JOIN institutes i ON i.institute_name = TRIM(f.institute)
   SET f.institute_id = i.institute_id WHERE f.institute_id IS NULL;
UPDATE staff st JOIN departments d ON d.department_name = TRIM(st.office_department)
   SET st.department_id = d.department_id WHERE st.department_id IS NULL;

CALL sp_lmsa_add_fk('students', 'fk_students_institute',  'FOREIGN KEY (`institute_id`)  REFERENCES `institutes` (`institute_id`)   ON DELETE SET NULL');
CALL sp_lmsa_add_fk('students', 'fk_students_program',    'FOREIGN KEY (`program_id`)    REFERENCES `programs` (`program_id`)       ON DELETE SET NULL');
CALL sp_lmsa_add_fk('faculty',  'fk_faculty_institute',   'FOREIGN KEY (`institute_id`)  REFERENCES `institutes` (`institute_id`)   ON DELETE SET NULL');
CALL sp_lmsa_add_fk('staff',    'fk_staff_department',    'FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON DELETE SET NULL');

-- ---------------------------------------------------------------------------
-- 3. branding_logos  (replaces organization_logos; the old table is kept)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `branding_logos` (
  `logo_id`       int          NOT NULL AUTO_INCREMENT,
  `logo_category` enum('School','Department','System','Institute','Program') NOT NULL,
  `logo_name`     varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `logo_path`     varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'app-relative, e.g. Assets/Branding/School/x.webp',
  `department_id` int NULL,
  `institute_id`  int NULL,
  `program_id`    int NULL,
  `is_active`     tinyint NOT NULL DEFAULT 1,
  `is_default`    tinyint NOT NULL DEFAULT 0 COMMENT '1 = the primary logo of its category (e.g. the School Library logo)',
  `version`       int NOT NULL DEFAULT 1 COMMENT 'bumped on every replace; used as ?v= cache-buster',
  `created_at`    timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  -- one ACTIVE logo per slot: School, System, each department, each institute, each program
  `slot_key` varchar(24) GENERATED ALWAYS AS (
      IF(`is_active` = 1,
         CASE `logo_category`
           WHEN 'School'     THEN 'SCHOOL'
           WHEN 'System'     THEN 'SYSTEM'
           WHEN 'Department' THEN CONCAT('D', `department_id`)
           WHEN 'Institute'  THEN CONCAT('I', `institute_id`)
           WHEN 'Program'    THEN CONCAT('P', `program_id`)
         END, NULL)) VIRTUAL,
  -- at most one ACTIVE default per category
  `default_key` varchar(12) GENERATED ALWAYS AS (
      IF(`is_active` = 1 AND `is_default` = 1, `logo_category`, NULL)) VIRTUAL,
  PRIMARY KEY (`logo_id`),
  UNIQUE KEY `uk_branding_slot` (`slot_key`),
  UNIQUE KEY `uk_branding_default` (`default_key`),
  KEY `idx_branding_category` (`logo_category`, `is_active`),
  CONSTRAINT `fk_branding_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_branding_institute`  FOREIGN KEY (`institute_id`)  REFERENCES `institutes` (`institute_id`)   ON DELETE CASCADE,
  CONSTRAINT `fk_branding_program`    FOREIGN KEY (`program_id`)    REFERENCES `programs` (`program_id`)       ON DELETE CASCADE,
  CONSTRAINT `chk_branding_entity` CHECK (
       (`logo_category` IN ('School','System') AND `department_id` IS NULL AND `institute_id` IS NULL AND `program_id` IS NULL)
    OR (`logo_category` = 'Department' AND `department_id` IS NOT NULL AND `institute_id` IS NULL AND `program_id` IS NULL)
    OR (`logo_category` = 'Institute'  AND `institute_id`  IS NOT NULL AND `department_id` IS NULL AND `program_id` IS NULL)
    OR (`logo_category` = 'Program'    AND `program_id`    IS NOT NULL AND `department_id` IS NULL AND `institute_id` IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 4. Carry over existing configuration (only when branding_logos is empty)
--    organization_logos rows:  School -> School | Library/'SPAMAST Library' -> Department 'Library'
--                              Library/'LMSA' -> System
-- ---------------------------------------------------------------------------
INSERT INTO branding_logos (logo_category, logo_name, logo_path, is_default)
SELECT 'School', 'SPAMAST', ol.logo_path, 1
FROM organization_logos ol
WHERE ol.entity_type = 'School' AND ol.is_active = 1
  AND NOT EXISTS (SELECT 1 FROM branding_logos WHERE logo_category = 'School')
ORDER BY ol.sort_order, ol.logo_id LIMIT 1;

INSERT INTO branding_logos (logo_category, logo_name, logo_path, department_id, is_default)
SELECT 'Department', 'School Library', ol.logo_path, d.department_id, 1
FROM organization_logos ol JOIN departments d ON d.department_name = 'Library'
WHERE ol.entity_type = 'Library' AND ol.entity_name <> 'LMSA' AND ol.is_active = 1
  AND NOT EXISTS (SELECT 1 FROM branding_logos WHERE logo_category = 'Department')
ORDER BY ol.sort_order, ol.logo_id LIMIT 1;

INSERT INTO branding_logos (logo_category, logo_name, logo_path, is_default)
SELECT 'System', 'LMSA', ol.logo_path, 1
FROM organization_logos ol
WHERE ol.entity_type = 'Library' AND ol.entity_name = 'LMSA' AND ol.is_active = 1
  AND NOT EXISTS (SELECT 1 FROM branding_logos WHERE logo_category = 'System')
ORDER BY ol.sort_order, ol.logo_id LIMIT 1;

-- Guaranteed baseline rows pointing at the bundled files (never overwrites the above)
INSERT INTO branding_logos (logo_category, logo_name, logo_path, is_default)
SELECT 'School', 'SPAMAST', 'Assets/Logo/spamast_logo.png', 1
WHERE NOT EXISTS (SELECT 1 FROM branding_logos WHERE logo_category = 'School');

INSERT INTO branding_logos (logo_category, logo_name, logo_path, department_id, is_default)
SELECT 'Department', 'School Library', 'Assets/Logo/spamast_library_logo.png', d.department_id, 1
FROM departments d WHERE d.department_name = 'Library'
  AND NOT EXISTS (SELECT 1 FROM branding_logos WHERE logo_category = 'Department');

INSERT INTO branding_logos (logo_category, logo_name, logo_path, is_default)
SELECT 'System', 'LMSA', 'Assets/Logo/spamast_lmsa_logo.png', 1
WHERE NOT EXISTS (SELECT 1 FROM branding_logos WHERE logo_category = 'System');

DROP PROCEDURE IF EXISTS sp_lmsa_add_column;
DROP PROCEDURE IF EXISTS sp_lmsa_add_index;
DROP PROCEDURE IF EXISTS sp_lmsa_add_fk;

-- ---------------------------------------------------------------------------
-- ROLLBACK (manual):  DROP TABLE branding_logos;  then drop the four *_id columns
-- and the three lookup tables. organization_logos is untouched by this script.
-- ---------------------------------------------------------------------------
