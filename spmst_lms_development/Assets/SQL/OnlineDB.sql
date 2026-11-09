use db_ad0eb7_libraryspamast;
-- Cleaned for SmarterASP.NET MySQL 8.x restore
-- Tables ordered parent-first, no LOCK TABLES / DISABLE KEYS / DEFINER / USE / CREATE DATABASE

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;

DROP TABLE IF EXISTS `user_submissions`;
DROP TABLE IF EXISTS `students`;
DROP TABLE IF EXISTS `staff`;
DROP TABLE IF EXISTS `renewals`;
DROP TABLE IF EXISTS `penalty_replacements`;
DROP TABLE IF EXISTS `penalty_policy`;
DROP TABLE IF EXISTS `penalty_payments`;
DROP TABLE IF EXISTS `penalty_notification_log`;
DROP TABLE IF EXISTS `penalty_components`;
DROP TABLE IF EXISTS `penalties`;
DROP TABLE IF EXISTS `transactions`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `library_terms`;
DROP TABLE IF EXISTS `library_services`;
DROP TABLE IF EXISTS `library_contact_info`;
DROP TABLE IF EXISTS `library_attendance`;
DROP TABLE IF EXISTS `library_about_us`;
DROP TABLE IF EXISTS `item_copies`;
DROP TABLE IF EXISTS `library_resources`;
DROP TABLE IF EXISTS `faculty`;
DROP TABLE IF EXISTS `campuses`;
DROP TABLE IF EXISTS `audit_logs`;
DROP TABLE IF EXISTS `users`;

-- ----------------------------
-- Table: users
-- ----------------------------
CREATE TABLE `users` (
  `user_id` varchar(20) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) DEFAULT NULL,
  `role` enum('student','faculty','staff','admin') NOT NULL,
  `is_active` tinyint NOT NULL DEFAULT '0' COMMENT '0=pending, 1=active, 2=deactivated, 3=archived',
  `last_login` timestamp NULL DEFAULT NULL,
  `archived_at` timestamp NULL DEFAULT NULL,
  `archived_reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `users` VALUES
('2023-0001','fernandezmaryclaire79@gmail.com','$2a$11$5d.jm9YeFqg9Zz4LIED3WuETkN9k2LDFbnxmx6Iaiq0mEkxmR1Gvy','student',1,'2026-11-04 09:23:10',NULL,NULL,'2026-11-04 06:51:50','2026-11-04 09:23:10'),
('2023-0002','samuel.andrada@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0003','allan.castro@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0004','angelica.soriano@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0005','patrick.tomas@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0006','joanna.dizon@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0007','noel.domingo@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0008','yvonne.natividad@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0009','shaina.tolentino@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0010','marites.ramos@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0011','joanna.castro@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0012','emmanuel.fajardo@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0013','xander.macaraeg@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0014','nicole.domingo@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0015','princess.torres@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0016','patrick.lopez@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0017','mikaela.bautista@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-114000','mc.fernandez@spamast.edu.ph','$2a$11$/wa5181BiaQvFdZPMQfcNegwwipAMxtYt719Vy3TU4AlW3XWKLvuS','admin',1,'2026-11-09 00:49:01',NULL,NULL,'2026-11-04 06:48:25','2026-11-09 00:49:01'),
('2024-0001','tristan.perez@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0002','eric.valdez@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0003','mark.villanueva@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0004','noreen.lim@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0005','vincent.domingo@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0006','tessa.soriano@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0007','nathan.delacruz@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50');
INSERT INTO `users` VALUES
('2024-0008','shaina.lim@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0009','mary.diaz@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0010','daniel.padilla@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0011','mark.garcia@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0012','rowena.castillo@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0013','angelica.salazar@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0014','kenneth.martinez@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0015','joshua.diaz@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0016','irene.mendoza@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0017','kenneth.ulep@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0001','harvey.gonzales@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0002','cedric.aguilar@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0003','bryan.lim@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0004','leo.sison@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0005','pamela.pascual@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0006','hazel.andrada@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0007','faith.delacruz@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0008','rafael.bautista@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0009','tessa.bautista@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0010','katrina.natividad@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0011','eric.tomas@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0012','olivia.perez@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0013','cedric.garcia@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0014','kenneth.reyes@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0015','leo.soriano@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50');
INSERT INTO `users` VALUES
('2025-0016','carlo.garcia@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0017','jericho.macaraeg@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0018','hazel.soriano@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0001','marlon.diaz@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0002','nathan.diaz@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0003','felix.hernandez@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0004','ryan.abella@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0005','erika.banal@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0006','gemma.padilla@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0007','jomar.andrada@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0008','rowena.tolentino@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0009','rafael.salazar@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0010','cherry.velasco@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0011','renato.orteza@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0012','gemma.navarro@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0013','shaina.ramos@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0014','angelica.pascual@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0015','noreen.soriano@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0016','kaye.jimenez@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0017','harvey.padilla@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0018','aileen.orteza@lmsa.edu.ph',NULL,'student',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-001','rizenakishin@gmail.com','$2a$11$aXIKlY0hhTgJK3m3Zmpu5O3NR0MPJlK3VhtClhydtnUtxBFt7/L0i','faculty',1,'2026-11-04 09:24:55',NULL,NULL,'2026-11-04 06:51:50','2026-11-04 09:24:55'),
('FAC-002','jose.cabrera@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-003','kenneth.garcia@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-004','jericho.domingo@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50');
INSERT INTO `users` VALUES
('FAC-005','ian.quiambao@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-006','lyka.lim@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-007','angelica.jimenez@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-008','eric.orteza@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-009','cedric.fajardo@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-010','aileen.cruz@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-011','allan.yap@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-012','bea.diaz@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-013','shaina.abella@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-014','xander.garcia@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-015','trisha.evangelista@lmsa.edu.ph',NULL,'faculty',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-001','darkflamedemoneye@gmail.com',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:52:40'),
('STAFF-002','angelica.fernandez@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-003','bryan.cruz@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-004','kevin.garcia@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-005','jocelyn.garcia@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-006','noreen.padilla@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-007','lovely.fernandez@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-008','eric.fajardo@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-009','eric.hernandez@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-010','wilfredo.velasco@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-011','gemma.castillo@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-012','vanessa.torres@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-013','allan.quiambao@lmsa.edu.ph',NULL,'admin',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-014','princess.villanueva@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50');
INSERT INTO `users` VALUES
('STAFF-015','oscar.dizon@lmsa.edu.ph',NULL,'staff',0,NULL,NULL,NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50');

-- ----------------------------
-- Table: audit_logs
-- ----------------------------
CREATE TABLE `audit_logs` (
  `log_id` int NOT NULL AUTO_INCREMENT,
  `user_id` varchar(20) DEFAULT NULL,
  `action_type` varchar(20) DEFAULT NULL,
  `table_affected` varchar(50) DEFAULT NULL,
  `action_details` text,
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `audit_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `audit_logs` VALUES
(1,'2023-114000','LOGIN','Users','User logged in successfully','::1','2026-11-04 06:49:50'),
(2,'2023-0001','LOGIN','Users','User logged in successfully','::1','2026-11-04 06:54:49'),
(3,'2023-114000','PASSWORD_RESET','Users','Initiated password reset','::1','2026-11-04 07:28:41'),
(4,'2023-114000','LOGIN','Users','User logged in successfully','::1','2026-11-04 07:29:09'),
(5,'2023-0001','LOGIN','Users','User logged in successfully','::1','2026-11-04 07:45:35'),
(6,'2023-0001','PASSWORD_RESET','Users','Initiated password reset','::1','2026-11-04 09:09:20'),
(7,'2023-114000','LOGIN','Users','User logged in successfully','::1','2026-11-04 09:10:20'),
(8,'2023-0001','LOGIN','Users','User logged in successfully','::1','2026-11-04 09:23:10'),
(9,'2023-114000','LOGIN','Users','User logged in successfully','::1','2026-11-04 09:23:36'),
(10,'FAC-001','PASSWORD_CREATE','Users','Initiated initial password creation for account verification','::1','2026-11-04 09:24:40'),
(11,'FAC-001','LOGIN','Users','User logged in successfully','::1','2026-11-04 09:24:55'),
(12,'2023-114000','LOGIN','Users','User logged in successfully','::1','2026-11-04 09:34:44'),
(13,'2023-114000','LOGIN','Users','User logged in successfully','::1','2026-11-08 23:48:19'),
(14,'2023-114000','LOGIN','Users','User logged in successfully','::1','2026-11-09 00:49:01');

-- ----------------------------
-- Table: campuses
-- ----------------------------
CREATE TABLE `campuses` (
  `campus_id` int NOT NULL AUTO_INCREMENT,
  `campus_name` varchar(100) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`campus_id`),
  UNIQUE KEY `uk_campus_name` (`campus_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table: faculty
-- ----------------------------
CREATE TABLE `faculty` (
  `faculty_id` varchar(20) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `middle_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) NOT NULL,
  `extension_name` varchar(10) DEFAULT NULL,
  `gender` enum('Male','Female') DEFAULT NULL,
  `mobile_number` varchar(15) DEFAULT NULL,
  `email` varchar(100) NOT NULL,
  `institute` varchar(50) DEFAULT NULL,
  `address` text,
  `profile_path` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`faculty_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `faculty` VALUES
('FAC-001','Maria','Tolentino','Rivera','','Female','09196347892','rizenakishin@gmail.com','College of Business','Purok 4, Brgy. Pangaleon, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:53:04'),
('FAC-002','Jose','Mendoza','Cabrera',NULL,'Male','09356105914','jose.cabrera@lmsa.edu.ph','College of Agriculture','Purok 9, Brgy. Tubalan, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-003','Kenneth','Soriano','Garcia',NULL,'Male','09661378522','kenneth.garcia@lmsa.edu.ph','College of Agriculture','Purok 3, Brgy. Tubalan, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-004','Jericho','Dela Cruz','Domingo',NULL,'Male','09203257192','jericho.domingo@lmsa.edu.ph','College of Education','Purok 5, Brgy. Poblacion, Santa Maria, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-005','Ian','Morales','Quiambao',NULL,'Male','09272476134','ian.quiambao@lmsa.edu.ph','College of ICT','Purok 2, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-006','Lyka','Rivera','Lim',NULL,'Female','09171461338','lyka.lim@lmsa.edu.ph','College of Business','Purok 1, Brgy. Poblacion, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-007','Angelica','Zamora','Jimenez',NULL,'Female','09277865893','angelica.jimenez@lmsa.edu.ph','College of Fisheries','Purok 1, Brgy. Pangaleon, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-008','Eric','Lopez','Orteza',NULL,'Male','09353848856','eric.orteza@lmsa.edu.ph','College of Education','Purok 9, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-009','Cedric',NULL,'Fajardo','II','Male','09197615141','cedric.fajardo@lmsa.edu.ph','College of ICT','Purok 4, Brgy. Poblacion, Don Marcelino, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-010','Aileen','Robles','Cruz',NULL,'Female','09555262394','aileen.cruz@lmsa.edu.ph','College of Agriculture','Purok 3, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-011','Allan','Lopez','Yap',NULL,'Male','09456539899','allan.yap@lmsa.edu.ph','College of Business','Purok 8, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-012','Bea','Garcia','Diaz',NULL,'Female','09272172334','bea.diaz@lmsa.edu.ph','College of Fisheries','Purok 7, Brgy. Poblacion, Jose Abad Santos, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-013','Shaina','Quiambao','Abella',NULL,'Female','09271047516','shaina.abella@lmsa.edu.ph','College of Business','Purok 9, Brgy. Poblacion, Santa Maria, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-014','Xander','Torres','Garcia',NULL,'Male','09178235953','xander.garcia@lmsa.edu.ph','College of Business','Purok 5, Brgy. Poblacion, Sarangani, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('FAC-015','Trisha','Castillo','Evangelista',NULL,'Female','09277478182','trisha.evangelista@lmsa.edu.ph','College of Fisheries','Purok 5, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50');

-- ----------------------------
-- Table: library_resources
-- ----------------------------
CREATE TABLE `library_resources` (
  `resource_id` int NOT NULL AUTO_INCREMENT,
  `item_type` varchar(100) DEFAULT NULL,
  `isbn` varchar(20) DEFAULT NULL,
  `issn` varchar(20) DEFAULT NULL,
  `call_number` varchar(100) DEFAULT NULL,
  `dewey_decimal` varchar(20) DEFAULT NULL,
  `genre` varchar(20) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `author` text,
  `section` varchar(100) DEFAULT NULL,
  `publisher` varchar(100) DEFAULT NULL,
  `place_of_publication` varchar(100) DEFAULT NULL,
  `series` varchar(100) DEFAULT NULL,
  `edition` varchar(50) DEFAULT NULL,
  `pub_year` int DEFAULT NULL,
  `copyright_year` int DEFAULT NULL,
  `pages_numeric` varchar(320) DEFAULT NULL,
  `height_cm` decimal(5,2) DEFAULT NULL,
  `width_cm` decimal(5,2) DEFAULT NULL,
  `accompanying_material` text,
  `description` text,
  `cover_path` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`resource_id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `library_resources` VALUES
(1,'Book','9.78177E+12',NULL,'005.1 Cor 2022','005.1','Computer Science','Introduction to Algorithms','Thomas H. Cormen; Charles E. Leiserson; Ronald L. Rivest; Clifford Stein','Computer Science','MIT Press','Cambridge, MA',NULL,'4th',2022,2022,'1312',NULL,NULL,NULL,'Comprehensive reference on algorithm design and analysis.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(2,'Book',NULL,NULL,'005.74 Sil 2019','005.74','Computer Science','Database System Concepts','Abraham Silberschatz; Henry F. Korth; S. Sudarshan','Computer Science','McGraw-Hill Education','New York',NULL,'7th',2019,2019,'1376',NULL,NULL,NULL,'Core textbook on database design, query processing and transactions.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(3,'Book',NULL,NULL,'005.43 Sil 2018','005.43','Computer Science','Operating System Concepts','Abraham Silberschatz; Peter B. Galvin; Greg Gagne','Computer Science','Wiley','Hoboken, NJ',NULL,'10th',2018,2018,'1278',NULL,NULL,NULL,'Standard text on operating system principles.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(4,'Book',NULL,NULL,'004.6 Kur 2021','004.6','Computer Science','Computer Networking: A Top-Down Approach','James F. Kurose; Keith W. Ross','Computer Science','Pearson','Hoboken, NJ',NULL,'8th',2021,2021,'800',NULL,NULL,NULL,'Introduction to computer networks organized by protocol layer.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(5,'Book',NULL,NULL,'006.3 Rus 2020','006.3','Computer Science','Artificial Intelligence: A Modern Approach','Stuart Russell; Peter Norvig','Computer Science','Pearson','Hoboken, NJ',NULL,'4th',2020,2020,'1136',NULL,NULL,NULL,'Leading textbook on artificial intelligence.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(6,'Book',NULL,NULL,'005.1 Mar 2008','005.1','Computer Science','Clean Code: A Handbook of Agile Software Craftsmanship','Robert C. Martin','Computer Science','Prentice Hall','Upper Saddle River, NJ',NULL,'1st',2008,2008,'464',NULL,NULL,NULL,'Practices for writing readable and maintainable code.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(7,'Book',NULL,NULL,'005.12 Gam 1994','005.12','Computer Science','Design Patterns: Elements of Reusable Object-Oriented Software','Erich Gamma; Richard Helm; Ralph Johnson; John Vlissides','Computer Science','Addison-Wesley','Reading, MA',NULL,'1st',1994,1994,'395',NULL,NULL,NULL,'Catalog of classic object-oriented design patterns.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(8,'Book',NULL,NULL,'005.1 Mcc 2004','005.1','Computer Science','Code Complete','Steve McConnell','Computer Science','Microsoft Press','Redmond, WA',NULL,'2nd',2004,2004,'960',NULL,NULL,NULL,'Practical handbook of software construction.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(9,'Book',NULL,NULL,'005.1 Tho 2019','005.1','Computer Science','The Pragmatic Programmer','David Thomas; Andrew Hunt','Computer Science','Addison-Wesley','Boston',NULL,'2nd',2019,2019,'352',NULL,NULL,NULL,'Guide to pragmatic software development practice.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(10,'Book',NULL,NULL,'005.1 Som 2016','005.1','Computer Science','Software Engineering','Ian Sommerville','Computer Science','Pearson','Boston',NULL,'10th',2016,2016,'810',NULL,NULL,NULL,'Overview of software engineering processes and methods.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(11,'Book',NULL,NULL,'005.1 Pre 2019','005.1','Computer Science','Software Engineering: A Practitioner\'s Approach','Roger S. Pressman; Bruce R. Maxim','Computer Science','McGraw-Hill Education','New York',NULL,'9th',2019,2019,'704',NULL,NULL,NULL,'Practitioner-oriented text on software engineering.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(12,'Book',NULL,NULL,'003 Ken 2019','003','Information Systems','Systems Analysis and Design','Kenneth E. Kendall; Julie E. Kendall','Computer Science','Pearson','New York',NULL,'10th',2019,2019,NULL,NULL,NULL,NULL,'Textbook on analyzing and designing information systems.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(13,'Book',NULL,NULL,'005.74 Elm 2016','005.74','Computer Science','Fundamentals of Database Systems','Ramez Elmasri; Shamkant B. Navathe','Computer Science','Pearson','Hoboken, NJ',NULL,'7th',2016,2016,'1272',NULL,NULL,NULL,'Textbook on database models, SQL and system implementation.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(14,'Book',NULL,NULL,'006.312 Han 2011','006.312','Data Analytics','Data Mining: Concepts and Techniques','Jiawei Han; Micheline Kamber; Jian Pei','Computer Science','Morgan Kaufmann','Waltham, MA',NULL,'3rd',2011,2011,'703',NULL,NULL,NULL,'Concepts and techniques for data mining and analytics.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(15,'Book',NULL,NULL,'005.133 Mck 2022','005.133','Data Analytics','Python for Data Analysis','Wes McKinney','Computer Science','O\'Reilly Media','Sebastopol, CA',NULL,'3rd',2022,2022,'579',NULL,NULL,NULL,'Data wrangling with pandas, NumPy and Jupyter.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(16,'Book',NULL,NULL,'006.31 Gér 2019','006.31','Data Analytics','Hands-On Machine Learning with Scikit-Learn, Keras, and TensorFlow','Aurélien Géron','Computer Science','O\'Reilly Media','Sebastopol, CA',NULL,'2nd',2019,2019,NULL,NULL,NULL,NULL,'Practical introduction to machine learning and deep learning.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(17,'Book',NULL,NULL,'005.7565 Bea 2020','005.7565','Computer Science','Learning SQL','Alan Beaulieu','Computer Science','O\'Reilly Media','Sebastopol, CA',NULL,'3rd',2020,2020,NULL,NULL,NULL,NULL,'Introduction to SQL for generating, manipulating and retrieving data.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(18,'Book',NULL,NULL,'005.2762 Cro 2008','005.2762','Computer Science','JavaScript: The Good Parts','Douglas Crockford','Computer Science','O\'Reilly Media','Sebastopol, CA',NULL,'1st',2008,2008,'176',NULL,NULL,NULL,'Guide to the reliable core features of JavaScript.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(19,'Book',NULL,NULL,'005.133 Ske 2019','005.133','Computer Science','C# in Depth','Jon Skeet','Computer Science','Manning Publications','Shelter Island, NY',NULL,'4th',2019,2019,NULL,NULL,NULL,NULL,'In-depth treatment of the C# language.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(20,'Book',NULL,NULL,'005.74 Kle 2017','005.74','Computer Science','Designing Data-Intensive Applications','Martin Kleppmann','Computer Science','O\'Reilly Media','Sebastopol, CA',NULL,'1st',2017,2017,'616',NULL,NULL,NULL,'Principles behind reliable, scalable data systems.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(21,'Book',NULL,NULL,'001.4226 Kna 2015','001.4226','Data Analytics','Storytelling with Data','Cole Nussbaumer Knaflic','Computer Science','Wiley','Hoboken, NJ',NULL,'1st',2015,2015,'284',NULL,NULL,NULL,'Data visualization guide for business professionals.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(22,'Book',NULL,NULL,'025.04 Man 2008','025.04','Information Science','Introduction to Information Retrieval','Christopher D. Manning; Prabhakar Raghavan; Hinrich Schütze','Library Science','Cambridge University Press','Cambridge',NULL,'1st',2008,2008,'482',NULL,NULL,NULL,'Textbook on search engines and information retrieval.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(23,'Book',NULL,NULL,'511 Ros 2019','511','Mathematics','Discrete Mathematics and Its Applications','Kenneth H. Rosen','Mathematics','McGraw-Hill Education','New York',NULL,'8th',2019,2019,NULL,NULL,NULL,NULL,'Standard discrete mathematics text for computing students.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(24,'Book',NULL,NULL,'005.1 Jr. 1995','005.1','Computer Science','The Mythical Man-Month','Frederick P. Brooks Jr.','Computer Science','Addison-Wesley','Reading, MA',NULL,'Anniversary',1995,1995,'322',NULL,NULL,NULL,'Essays on software engineering and project management.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(25,'Book',NULL,NULL,'005.1 Fow 2018','005.1','Computer Science','Refactoring: Improving the Design of Existing Code','Martin Fowler','Computer Science','Addison-Wesley','Boston',NULL,'2nd',2018,2018,'448',NULL,NULL,NULL,'Catalog of refactorings for improving existing code.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11');
INSERT INTO `library_resources` VALUES
(26,'Book',NULL,NULL,'025.3 Jou 2015','025.3','Library Science','Introduction to Cataloging and Classification','Daniel N. Joudrey; Arlene G. Taylor; David P. Miller','Library Science','Libraries Unlimited','Santa Barbara, CA',NULL,'11th',2015,2015,NULL,NULL,NULL,NULL,'Standard text on cataloging and classification.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(27,'Book',NULL,NULL,'025.52 Bop 2011','025.52','Library Science','Reference and Information Services: An Introduction','Richard E. Bopp; Linda C. Smith','Library Science','Libraries Unlimited','Santa Barbara, CA',NULL,'4th',2011,2011,NULL,NULL,NULL,NULL,'Introduction to reference work in libraries.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(28,'Book',NULL,NULL,'025.21 Eva 2012','025.21','Library Science','Developing Library and Information Center Collections','G. Edward Evans; Margaret Zarnosky Saponaro','Library Science','Libraries Unlimited','Santa Barbara, CA',NULL,'6th',2012,2012,NULL,NULL,NULL,NULL,'Collection development and management in libraries.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(29,'Book',NULL,NULL,'020 Baw 2012','020','Information Science','Introduction to Information Science','David Bawden; Lyn Robinson','Library Science','Facet Publishing','London',NULL,'1st',2012,2012,NULL,NULL,NULL,NULL,'Foundations of information science.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(30,'Book',NULL,NULL,'300.72 Cre 2018','300.72','Research Methods','Research Design: Qualitative, Quantitative, and Mixed Methods Approaches','John W. Creswell; J. David Creswell','Research','SAGE Publications','Thousand Oaks, CA',NULL,'5th',2018,2018,'304',NULL,NULL,NULL,'Guide to designing research studies.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(31,'Book',NULL,NULL,'370.72 Cre 2012','370.72','Research Methods','Educational Research: Planning, Conducting, and Evaluating Quantitative and Qualitative Research','John W. Creswell','Research','Pearson','Boston',NULL,'4th',2012,2012,NULL,NULL,NULL,NULL,'Research methods text for education.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(32,'Book',NULL,NULL,'001.4 Boo 2016','001.4','Research Methods','The Craft of Research','Wayne C. Booth; Gregory G. Colomb; Joseph M. Williams','Research','University of Chicago Press','Chicago',NULL,'4th',2016,2016,'336',NULL,NULL,NULL,'Guide to planning and writing research.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(33,'Book',NULL,NULL,'519.5 Fie 2018','519.5','Statistics','Discovering Statistics Using IBM SPSS Statistics','Andy Field','Research','SAGE Publications','London',NULL,'5th',2018,2018,NULL,NULL,NULL,NULL,'Statistics text built around SPSS.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(34,'Book',NULL,NULL,'370.72 Fra 2012','370.72','Research Methods','How to Design and Evaluate Research in Education','Jack R. Fraenkel; Norman E. Wallen; Helen H. Hyun','Research','McGraw-Hill Education','New York',NULL,'8th',2012,2012,NULL,NULL,NULL,NULL,'Research design and evaluation for education.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(35,'Book',NULL,NULL,'153.4 Kah 2011','153.4','Psychology','Thinking, Fast and Slow','Daniel Kahneman','Social Sciences','Farrar, Straus and Giroux','New York',NULL,'1st',2011,2011,'499',NULL,NULL,NULL,'Judgment and decision-making by a Nobel laureate.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(36,'Book',NULL,NULL,'658.8 Kot 2021','658.8','Business','Principles of Marketing','Philip Kotler; Gary Armstrong','Business','Pearson','Hoboken, NJ',NULL,'18th',2021,2021,NULL,NULL,NULL,NULL,'Introductory marketing textbook.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(37,'Book',NULL,NULL,'658 Rob 2018','658','Business','Management','Stephen P. Robbins; Mary Coulter','Business','Pearson','Hoboken, NJ',NULL,'14th',2018,2018,NULL,NULL,NULL,NULL,'Introductory management textbook.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(38,'Book',NULL,NULL,'658.15 Bre 2020','658.15','Business','Principles of Corporate Finance','Richard A. Brealey; Stewart C. Myers; Franklin Allen','Business','McGraw-Hill Education','New York',NULL,'13th',2020,2020,NULL,NULL,NULL,NULL,'Corporate finance textbook.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(39,'Book',NULL,NULL,'302.35 Rob 2019','302.35','Business','Organizational Behavior','Stephen P. Robbins; Timothy A. Judge','Business','Pearson','Hoboken, NJ',NULL,'18th',2019,2019,NULL,NULL,NULL,NULL,'Textbook on behavior in organizations.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(40,'Book',NULL,NULL,'658.4 Col 2001','658.4','Business','Good to Great','Jim Collins','Business','HarperBusiness','New York',NULL,'1st',2001,2001,'300',NULL,NULL,NULL,'Study of what makes companies sustain superior results.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(41,'Book',NULL,NULL,'658.11 Rie 2011','658.11','Business','The Lean Startup','Eric Ries','Business','Crown Business','New York',NULL,'1st',2011,2011,NULL,NULL,NULL,NULL,'Methodology for building startups through validated learning.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(42,'Book',NULL,NULL,'330 Man 2021','330','Economics','Principles of Economics','N. Gregory Mankiw','Business','Cengage Learning','Boston',NULL,'9th',2021,2021,NULL,NULL,NULL,NULL,'Introductory economics textbook.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(43,'Book',NULL,NULL,'658.3 Des 2020','658.3','Business','Human Resource Management','Gary Dessler','Business','Pearson','Hoboken, NJ',NULL,'16th',2020,2020,NULL,NULL,NULL,NULL,'Textbook on human resource management.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(44,'Book',NULL,NULL,'620.1 Hib 2016','620.1','Engineering','Engineering Mechanics: Statics','Russell C. Hibbeler','Engineering','Pearson','Hoboken, NJ',NULL,'14th',2016,2016,NULL,NULL,NULL,NULL,'Statics textbook for engineering students.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(45,'Book',NULL,NULL,'530 Hal 2018','530','Physics','Fundamentals of Physics','David Halliday; Robert Resnick; Jearl Walker','Science','Wiley','Hoboken, NJ',NULL,'11th',2018,2018,NULL,NULL,NULL,NULL,'University-level introductory physics.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(46,'Book',NULL,NULL,'540 Bro 2018','540','Chemistry','Chemistry: The Central Science','Theodore L. Brown; H. Eugene LeMay; Bruce E. Bursten; et al.','Science','Pearson','New York',NULL,'14th',2018,2018,NULL,NULL,NULL,NULL,'General chemistry textbook.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(47,'Book',NULL,NULL,'570 Urr 2017','570','Biology','Campbell Biology','Lisa A. Urry; Michael L. Cain; Steven A. Wasserman; et al.','Science','Pearson','New York',NULL,'11th',2017,2017,NULL,NULL,NULL,NULL,'Introductory biology textbook.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(48,'Book',NULL,NULL,'515 Ste 2016','515','Mathematics','Calculus: Early Transcendentals','James Stewart','Mathematics','Cengage Learning','Boston',NULL,'8th',2016,2016,NULL,NULL,NULL,NULL,'Standard calculus textbook.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(49,'Book',NULL,NULL,'621.3815 Ale 2017','621.3815','Engineering','Fundamentals of Electric Circuits','Charles K. Alexander; Matthew N. O. Sadiku','Engineering','McGraw-Hill Education','New York',NULL,'6th',2017,2017,NULL,NULL,NULL,NULL,'Circuit analysis textbook.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
(50,'Book',NULL,NULL,'631.4 Bra 2016','631.4','Agriculture','The Nature and Properties of Soils','Nyle C. Brady; Ray R. Weil','Agriculture','Pearson','Columbus, OH',NULL,'15th',2016,2016,NULL,NULL,NULL,NULL,'Soil science textbook.',NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11');

-- ----------------------------
-- Table: item_copies
-- ----------------------------
CREATE TABLE `item_copies` (
  `accession_number` varchar(50) NOT NULL,
  `resource_id` int DEFAULT NULL,
  `volume_no` varchar(20) DEFAULT NULL,
  `issue_no` varchar(20) DEFAULT NULL,
  `binding_type` varchar(50) DEFAULT NULL,
  `campus` varchar(100) DEFAULT 'Malita Campus',
  `specific_location` varchar(100) DEFAULT 'Circulation Desk',
  `status_condition` enum('Good','Damage','Lost','Combination','Reserved') DEFAULT 'Good',
  `is_available` tinyint NOT NULL DEFAULT '1' COMMENT '0=false, 1=true',
  `remarks` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`accession_number`),
  KEY `idx_resource_id` (`resource_id`),
  CONSTRAINT `item_copies_ibfk_1` FOREIGN KEY (`resource_id`) REFERENCES `library_resources` (`resource_id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `item_copies` VALUES
('000001',1,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000002',2,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000003',3,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000004',4,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000005',5,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',0,NULL,'2026-11-04 06:50:11','2026-11-04 09:26:25'),
('000006',6,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000007',7,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000008',8,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',0,NULL,'2026-11-04 06:50:11','2026-11-08 11:16:01'),
('000009',9,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000010',10,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000011',11,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000012',12,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000013',13,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000014',14,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000015',15,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000016',16,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000017',17,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000018',18,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000019',19,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',0,NULL,'2026-11-04 06:50:11','2026-11-04 06:56:12'),
('000020',20,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000021',21,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000022',22,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000023',23,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000024',24,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000025',25,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11');
INSERT INTO `item_copies` VALUES
('000026',26,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000027',27,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000028',28,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000029',29,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000030',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000031',31,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000032',32,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000033',33,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000034',34,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000035',35,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000036',36,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000037',37,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000038',38,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000039',39,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000040',40,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000041',41,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000042',42,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000043',43,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000044',44,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000045',45,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000046',46,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000047',47,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000048',48,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000049',49,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11'),
('000050',50,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:11','2026-11-04 06:50:11');
INSERT INTO `item_copies` VALUES
('000051',7,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000052',7,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000053',8,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000054',8,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000055',8,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000056',8,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000057',8,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000058',8,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000059',8,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000060',8,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000061',8,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000062',9,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000063',9,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000064',9,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000065',9,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000066',9,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000067',9,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000068',9,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000069',9,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000070',9,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000071',10,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000072',10,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000073',10,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000074',10,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000075',10,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49');
INSERT INTO `item_copies` VALUES
('000076',10,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000077',10,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000078',10,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Reserved',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000079',11,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000080',11,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000081',11,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000082',11,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000083',11,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000084',11,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000085',11,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000086',12,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000087',12,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000088',12,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000089',12,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000090',12,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000091',12,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000092',13,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000093',13,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000094',13,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000095',13,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000096',13,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000097',13,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000098',14,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000099',14,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000100',14,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49');
INSERT INTO `item_copies` VALUES
('000101',14,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Reserved',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000102',14,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000103',14,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000104',14,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000105',14,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000106',14,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000107',15,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000108',15,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000109',15,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000110',15,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000111',15,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000112',15,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000113',15,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:49','2026-11-04 06:50:49'),
('000114',16,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000115',16,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000116',16,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Reserved',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000117',16,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000118',16,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000119',16,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000120',17,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000121',17,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000122',17,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000123',17,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000124',17,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000125',17,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50');
INSERT INTO `item_copies` VALUES
('000126',18,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000127',18,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000128',18,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000129',18,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000130',18,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Reserved',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000131',18,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000132',18,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000133',18,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000134',18,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000135',19,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000136',19,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000137',19,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000138',19,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000139',19,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000140',19,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000141',19,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000142',19,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000143',19,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000144',20,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000145',20,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000146',20,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000147',20,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000148',20,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000149',20,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000150',20,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50');
INSERT INTO `item_copies` VALUES
('000151',21,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000152',21,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000153',21,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000154',21,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000155',21,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000156',21,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000157',21,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000158',21,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000159',21,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000160',21,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000161',21,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000162',21,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000163',21,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000164',21,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000165',21,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000166',22,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000167',22,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000168',22,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000169',22,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000170',22,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000171',22,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000172',23,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000173',23,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000174',23,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000175',23,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50');
INSERT INTO `item_copies` VALUES
('000176',23,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000177',23,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000178',23,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000179',24,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000180',24,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000181',24,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000182',24,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000183',24,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000184',24,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000185',25,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000186',25,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000187',25,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000188',25,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000189',25,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000190',25,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Reserved',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000191',25,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000192',25,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000193',25,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000194',26,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000195',26,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000196',26,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000197',26,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000198',26,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000199',26,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000200',26,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50');
INSERT INTO `item_copies` VALUES
('000201',26,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000202',26,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000203',27,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000204',27,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000205',27,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000206',27,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000207',27,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000208',27,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000209',28,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000210',28,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000211',28,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000212',28,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000213',28,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000214',28,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000215',29,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000216',29,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000217',29,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000218',29,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000219',29,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000220',29,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000221',29,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000222',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000223',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000224',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000225',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50');
INSERT INTO `item_copies` VALUES
('000226',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000227',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000228',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000229',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000230',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000231',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000232',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000233',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000234',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000235',30,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000236',31,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000237',31,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000238',31,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000239',31,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000240',31,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Reserved',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000241',31,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000242',31,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000243',31,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000244',32,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000245',32,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000246',32,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000247',32,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000248',32,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000249',32,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000250',32,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50');
INSERT INTO `item_copies` VALUES
('000251',32,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000252',33,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000253',33,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000254',33,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000255',33,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000256',33,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000257',33,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000258',33,NULL,NULL,'Paperback','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000259',34,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000260',34,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000261',34,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000262',34,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000263',34,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000264',34,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Reserved',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000265',35,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000266',35,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000267',35,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000268',35,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000269',35,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000270',35,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000271',35,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000272',36,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000273',36,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000274',36,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000275',36,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50');
INSERT INTO `item_copies` VALUES
('000276',36,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000277',36,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000278',37,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000279',37,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000280',37,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000281',37,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000282',37,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000283',37,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000284',38,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000285',38,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000286',38,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000287',38,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000288',38,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000289',38,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000290',38,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000291',38,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000292',38,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000293',39,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000294',39,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000295',39,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000296',39,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000297',39,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000298',39,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000299',39,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000300',39,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50');
INSERT INTO `item_copies` VALUES
('000301',40,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000302',40,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000303',40,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000304',40,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000305',40,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000306',40,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000307',41,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000308',41,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000309',41,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000310',41,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000311',41,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000312',41,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000313',41,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000314',42,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000315',42,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000316',42,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000317',42,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000318',42,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000319',42,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000320',42,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000321',42,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Reserved',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000322',42,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000323',43,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000324',43,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000325',43,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50');
INSERT INTO `item_copies` VALUES
('000326',43,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Reserved',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000327',43,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000328',43,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000329',43,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000330',43,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000331',43,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000332',44,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000333',44,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000334',44,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000335',44,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000336',44,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000337',44,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000338',44,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000339',45,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000340',45,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000341',45,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000342',45,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000343',45,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000344',45,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000345',45,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000346',45,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000347',46,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000348',46,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000349',46,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000350',46,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50');
INSERT INTO `item_copies` VALUES
('000351',46,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000352',46,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000353',46,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000354',47,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000355',47,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000356',47,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000357',47,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000358',47,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000359',47,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000360',47,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000361',47,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000362',48,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000363',48,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Damage',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000364',48,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000365',48,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000366',48,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000367',48,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000368',48,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000369',48,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Reserved',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000370',49,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000371',49,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000372',49,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000373',49,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000374',49,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000375',49,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50');
INSERT INTO `item_copies` VALUES
('000376',50,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000377',50,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000378',50,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000379',50,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000380',50,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000381',50,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50'),
('000382',50,NULL,NULL,'Hardcover','Malita Campus','Circulation Desk','Good',1,NULL,'2026-11-04 06:50:50','2026-11-04 06:50:50');

-- ----------------------------
-- Table: library_about_us
-- ----------------------------
CREATE TABLE `library_about_us` (
  `about_id` int NOT NULL AUTO_INCREMENT,
  `heading` varchar(150) DEFAULT NULL,
  `body` text,
  `stat1_label` varchar(60) DEFAULT NULL,
  `stat1_value` varchar(30) DEFAULT NULL,
  `stat2_label` varchar(60) DEFAULT NULL,
  `stat2_value` varchar(30) DEFAULT NULL,
  `stat3_label` varchar(60) DEFAULT NULL,
  `stat3_value` varchar(30) DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`about_id`),
  KEY `fk_about_updated_by` (`updated_by`),
  CONSTRAINT `fk_about_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO library_about_us (heading, body, stat1_label, stat1_value, stat2_label, stat2_value, stat3_label, stat3_value)
SELECT 'Serving the SPAMAST community since day one',
       'The SPAMAST Library is the academic heart of the Southern Philippines Agri-Business and Marine and Aquatic School of Technology, supporting students, faculty, and staff across all institutes with a growing collection of books, journals, and multimedia resources. The Library Management System with Analytics (LMSA) modernizes how the community discovers and borrows materials — from real-time catalog search to transparent, data-driven insight into what the SPAMAST community is reading.',
       'Institutes Served', '7',
       'SPAMAST Founded', '1969',
       'Days a Week Open', '6'
WHERE NOT EXISTS (SELECT 1 FROM library_about_us);

-- ----------------------------
-- Table: library_attendance
-- ----------------------------
CREATE TABLE `library_attendance` (
  `attendance_id` int NOT NULL AUTO_INCREMENT,
  `user_id` varchar(20) DEFAULT NULL,
  `time_in` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `time_out` timestamp NULL DEFAULT NULL,
  `purpose` varchar(100) DEFAULT NULL,
  `entry_method` enum('QR_SCAN','MANUAL_ENTRY') DEFAULT 'QR_SCAN',
  `session_type` enum('STAFF_ASSISTED','KIOSK_SELF_SERVICE') NOT NULL,
  `encoded_by` varchar(20) DEFAULT NULL,
  `attendance_status` enum('Entry','Exited') DEFAULT 'Entry',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`attendance_id`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `library_attendance_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table: library_contact_info
-- ----------------------------
CREATE TABLE `library_contact_info` (
  `contact_id` int NOT NULL AUTO_INCREMENT,
  `address` varchar(255) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `hours_weekdays` varchar(100) DEFAULT NULL,
  `hours_saturday` varchar(100) DEFAULT NULL,
  `hours_sunday` varchar(100) DEFAULT NULL,
  `facebook_url` varchar(255) DEFAULT NULL,
  `map_embed_url` text,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`contact_id`),
  KEY `fk_contact_updated_by` (`updated_by`),
  CONSTRAINT `fk_contact_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO library_contact_info (address, phone, email, hours_weekdays, hours_saturday, hours_sunday, facebook_url, map_embed_url)
SELECT 'Poblacion, Malita, Davao Occidental, Philippines 8012',
       '(082) 272-3725',
       'library@spamast.edu.ph',
       'Mon – Fri: 8:00 AM – 5:00 PM',
       'Saturday: 8:00 AM – 12:00 PM',
       'Sunday & Holidays: Closed',
       '',
       'https://www.google.com/maps/embed?pb=!1m14!1m12!1m3!1d991.2029031222396!2d125.60769499574207!3d6.41824697173699!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!5e0!3m2!1sen!2sph!4v1785921070592!5m2!1sen!2sph'
WHERE NOT EXISTS (SELECT 1 FROM library_contact_info);

-- ----------------------------
-- Table: library_services
-- ----------------------------
CREATE TABLE `library_services` (
  `service_id` int NOT NULL AUTO_INCREMENT,
  `icon_class` varchar(60) NOT NULL DEFAULT 'fa-book',
  `title` varchar(120) NOT NULL,
  `description` text,
  `sort_order` int NOT NULL DEFAULT '0',
  `is_active` tinyint NOT NULL DEFAULT '1' COMMENT '0=false, 1=true',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`service_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO library_services (icon_class, title, description, sort_order, is_active)
SELECT * FROM (SELECT 'fa-book-bookmark' AS icon_class, 'Circulation & Borrowing' AS title, 'Borrow books, journals, and other materials from the general collection with a valid SPAMAST ID. Loan periods and limits follow institute policy.' AS description, 1 AS sort_order, 1 AS is_active
    UNION ALL SELECT 'fa-calendar-check', 'Reservations', 'Reserve high-demand titles online and get notified the moment your copy is ready for pickup at the Circulation Desk.', 2, 1
    UNION ALL SELECT 'fa-magnifying-glass-plus', 'Reference & Research Assistance', 'Get one-on-one help from librarians with literature searches, citation styles, and locating the right sources for your thesis or research paper.', 3, 1
    UNION ALL SELECT 'fa-chalkboard-user', 'Information Literacy Sessions', 'Orientation and workshops on using the catalog, evaluating sources, and avoiding plagiarism — available for classes and student organizations.', 4, 1
    UNION ALL SELECT 'fa-chair', 'Reading & Study Areas', 'Quiet individual study carrels and group discussion tables across the AV Section, Periodicals area, and general reading room.', 5, 1
    UNION ALL SELECT 'fa-print', 'Printing & Photocopying', 'On-site printing and photocopying services for coursework, research output, and official requirements.', 6, 1
    UNION ALL SELECT 'fa-compact-disc', 'AV & Multimedia Access', 'Browse and view DVDs, recorded lectures, and other multimedia resources in the dedicated AV Section.', 7, 1
    UNION ALL SELECT 'fa-newspaper', 'Periodicals & Journals', 'Access current and archived journals, magazines, and newspapers curated for every institute''s field of study.', 8, 1
    UNION ALL SELECT 'fa-chart-line', 'Borrowing Analytics', 'See top borrowers, most requested titles, and institute-wide reading trends right on the library''s home page.', 9, 1
) seed
WHERE NOT EXISTS (SELECT 1 FROM library_services);

-- ----------------------------
-- Table: library_terms
-- ----------------------------
CREATE TABLE `library_terms` (
  `terms_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(150) NOT NULL,
  `version_label` varchar(50) DEFAULT NULL,
  `file_path` varchar(255) NOT NULL,
  `is_active` tinyint NOT NULL DEFAULT '0' COMMENT '0=false, 1=true',
  `uploaded_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `uploaded_by` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`terms_id`),
  KEY `fk_terms_uploaded_by` (`uploaded_by`),
  CONSTRAINT `fk_terms_uploaded_by` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table: notifications
-- ----------------------------
CREATE TABLE `notifications` (
  `notification_id` int NOT NULL AUTO_INCREMENT,
  `user_id` varchar(20) DEFAULT NULL,
  `title` varchar(100) DEFAULT NULL,
  `message` text,
  `is_read` tinyint NOT NULL DEFAULT '0' COMMENT '0=false, 1=true',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`notification_id`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table: transactions
-- ----------------------------
CREATE TABLE `transactions` (
  `transaction_id` int NOT NULL AUTO_INCREMENT,
  `user_id` varchar(20) NOT NULL,
  `accession_number` varchar(50) NOT NULL,
  `borrow_date` date NOT NULL,
  `due_date` date NOT NULL,
  `return_date` date DEFAULT NULL,
  `penalty_id` int DEFAULT NULL,
  `status` enum('Borrowed','Returned','Reserved','Ready','Cancelled','Renewal','Renewed') DEFAULT 'Borrowed',
  `is_damaged` tinyint NOT NULL DEFAULT '0',
  `is_lost` tinyint NOT NULL DEFAULT '0',
  `remarks` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`transaction_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_accession_number` (`accession_number`),
  KEY `idx_status` (`status`),
  KEY `idx_due_date` (`due_date`),
  CONSTRAINT `fk_txn_item` FOREIGN KEY (`accession_number`) REFERENCES `item_copies` (`accession_number`) ON DELETE RESTRICT,
  CONSTRAINT `fk_txn_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT,
  CONSTRAINT `chk_txn_is_damaged` CHECK ((`is_damaged` in (0,1))),
  CONSTRAINT `chk_txn_is_lost` CHECK ((`is_lost` in (0,1)))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `transactions` VALUES
(1,'2023-0001','000019','2026-11-04','2026-11-04',NULL,1,'Borrowed',0,0,NULL,'2026-11-04 06:56:12','2026-11-04 07:56:25'),
(2,'2023-0001','000008','2026-11-04','2026-11-07',NULL,2,'Borrowed',0,0,NULL,'2026-11-04 07:00:16','2026-11-08 11:16:01'),
(3,'FAC-001','000005','2026-11-04','2027-04-03',NULL,NULL,'Borrowed',0,0,NULL,'2026-11-04 09:26:25','2026-11-04 09:27:09');

-- ----------------------------
-- Table: penalties
-- ----------------------------
CREATE TABLE `penalties` (
  `penalty_id` int NOT NULL AUTO_INCREMENT,
  `transaction_id` int NOT NULL,
  `user_id` varchar(20) NOT NULL,
  `accession_number` varchar(50) DEFAULT NULL,
  `penalty_type` enum('Overdue','Damaged','Lost','Overdue_Damaged','Overdue_Lost','Damaged_Lost','Overdue_Damaged_Lost','Other') NOT NULL DEFAULT 'Overdue',
  `reason` varchar(255) NOT NULL,
  `fine_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `amount_paid` decimal(10,2) NOT NULL DEFAULT '0.00',
  `fine_status` enum('Unpaid','Partial','Paid') NOT NULL DEFAULT 'Unpaid',
  `paid_date` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`penalty_id`),
  UNIQUE KEY `uk_penalty_transaction` (`transaction_id`),
  KEY `idx_penalty_user` (`user_id`),
  KEY `idx_penalty_status` (`fine_status`),
  CONSTRAINT `fk_penalty_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`transaction_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_penalty_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `penalties` VALUES
(1,1,'2023-0001','000019','Overdue','Overdue (5 days)',570.00,565.00,'Paid','2026-11-09 08:12:31','2026-11-04 07:56:25','2026-11-09 00:56:25'),
(2,2,'2023-0001','000008','Overdue','Overdue (2 days)',10.00,0.00,'Unpaid',NULL,'2026-11-08 11:16:01','2026-11-09 00:49:25');

-- ----------------------------
-- Table: penalty_components
-- ----------------------------
CREATE TABLE `penalty_components` (
  `component_id` int NOT NULL AUTO_INCREMENT,
  `penalty_id` int NOT NULL,
  `component_type` enum('Overdue','Damaged','Lost') NOT NULL,
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `amount_paid` decimal(10,2) NOT NULL DEFAULT '0.00',
  `settlement_type` enum('Pending','Payment','Replacement') NOT NULL DEFAULT 'Pending',
  `settled_at` datetime DEFAULT NULL,
  `settled_by` varchar(20) DEFAULT NULL,
  `remarks` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`component_id`),
  UNIQUE KEY `uk_comp_penalty_type` (`penalty_id`,`component_type`),
  KEY `idx_comp_penalty` (`penalty_id`),
  KEY `idx_comp_settlement` (`settlement_type`),
  KEY `fk_comp_settledby` (`settled_by`),
  CONSTRAINT `fk_comp_penalty` FOREIGN KEY (`penalty_id`) REFERENCES `penalties` (`penalty_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comp_settledby` FOREIGN KEY (`settled_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `penalty_components` VALUES
(1,1,'Overdue',570.00,565.00,'Payment',NULL,NULL,NULL,'2026-11-09 01:18:51','2026-11-09 01:18:51'),
(2,2,'Overdue',10.00,0.00,'Pending',NULL,NULL,NULL,'2026-11-09 01:18:51','2026-11-09 01:18:51');

-- ----------------------------
-- Table: penalty_notification_log
-- ----------------------------
CREATE TABLE `penalty_notification_log` (
  `notification_log_id` int NOT NULL AUTO_INCREMENT,
  `penalty_id` int NOT NULL,
  `transaction_id` int NOT NULL,
  `channel` enum('SMS','Email','Push') NOT NULL,
  `balance_at_send` decimal(10,2) NOT NULL,
  `status` enum('Sent','Failed') NOT NULL,
  `attempt_count` int NOT NULL DEFAULT '1',
  `recipient_masked` varchar(100) DEFAULT NULL,
  `message_id` varchar(100) DEFAULT NULL,
  `error_details` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`notification_log_id`),
  UNIQUE KEY `uk_pnl_penalty_channel_balance` (`penalty_id`,`channel`,`balance_at_send`),
  KEY `idx_pnl_txn` (`transaction_id`),
  KEY `idx_pnl_status` (`status`),
  CONSTRAINT `fk_pnl_penalty` FOREIGN KEY (`penalty_id`) REFERENCES `penalties` (`penalty_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table: penalty_payments
-- ----------------------------
CREATE TABLE `penalty_payments` (
  `payment_id` int NOT NULL AUTO_INCREMENT,
  `penalty_id` int NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `cash_tendered` decimal(10,2) NOT NULL DEFAULT '0.00',
  `change_given` decimal(10,2) NOT NULL DEFAULT '0.00',
  `payment_method` varchar(50) NOT NULL,
  `payment_reference` varchar(100) DEFAULT NULL,
  `payment_notes` text,
  `received_by` varchar(20) DEFAULT NULL,
  `payment_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`payment_id`),
  KEY `idx_pp_penalty` (`penalty_id`),
  KEY `idx_pp_date` (`payment_date`),
  KEY `fk_pp_staff` (`received_by`),
  CONSTRAINT `fk_pp_penalty` FOREIGN KEY (`penalty_id`) REFERENCES `penalties` (`penalty_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pp_staff` FOREIGN KEY (`received_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `penalty_payments` VALUES
(1,1,565.00,565.00,0.00,'GCash','13123231','','2023-114000','2026-11-09 08:12:31');

-- ----------------------------
-- Table: penalty_policy
-- ----------------------------
CREATE TABLE `penalty_policy` (
  `policy_id` int NOT NULL AUTO_INCREMENT,
  `policy_key` varchar(50) NOT NULL,
  `policy_value` decimal(10,2) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`policy_id`),
  UNIQUE KEY `policy_key` (`policy_key`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `penalty_policy` VALUES
(1,'overdue_hourly_rate',5.00,'Rate per overdue hour (loan-in)','2026-11-09 01:18:50'),
(2,'overdue_daily_rate',5.00,'Rate per overdue day (loan-out)','2026-11-09 01:18:50'),
(3,'damaged_fixed_amount',100.00,'Fixed fine for damaged book','2026-11-09 01:18:50'),
(4,'lost_fixed_amount',200.00,'Fixed fine for lost book','2026-11-09 01:18:50');

-- ----------------------------
-- Table: penalty_replacements
-- ----------------------------
CREATE TABLE `penalty_replacements` (
  `replacement_id` int NOT NULL AUTO_INCREMENT,
  `penalty_id` int NOT NULL,
  `transaction_id` int NOT NULL,
  `component_type` enum('Damaged','Lost') NOT NULL,
  `original_accession_number` varchar(50) NOT NULL,
  `replacement_accession_number` varchar(50) DEFAULT NULL,
  `replacement_status` enum('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  `replacement_book_title` varchar(255) DEFAULT NULL,
  `replacement_book_author` varchar(255) DEFAULT NULL,
  `replacement_book_isbn` varchar(20) DEFAULT NULL,
  `remarks` text,
  `processed_by` varchar(20) DEFAULT NULL,
  `replacement_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`replacement_id`),
  UNIQUE KEY `uk_repl_penalty_component` (`penalty_id`,`component_type`),
  KEY `idx_repl_penalty` (`penalty_id`),
  KEY `idx_repl_txn` (`transaction_id`),
  KEY `fk_repl_staff` (`processed_by`),
  CONSTRAINT `fk_repl_penalty` FOREIGN KEY (`penalty_id`) REFERENCES `penalties` (`penalty_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_repl_staff` FOREIGN KEY (`processed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_repl_txn` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`transaction_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table: renewals
-- ----------------------------
CREATE TABLE `renewals` (
  `renewal_id` int NOT NULL AUTO_INCREMENT,
  `transaction_id` int NOT NULL,
  `old_due_date` date NOT NULL,
  `new_due_date` date NOT NULL,
  `renewed_by` varchar(20) DEFAULT NULL,
  `renewal_type` enum('WalkIn','Online') NOT NULL DEFAULT 'WalkIn',
  `status` enum('Pending','Approved','Denied') NOT NULL DEFAULT 'Approved',
  `remarks` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`renewal_id`),
  KEY `idx_renewal_txn` (`transaction_id`),
  KEY `idx_renewal_status` (`status`),
  KEY `fk_renewal_staff` (`renewed_by`),
  CONSTRAINT `fk_renewal_staff` FOREIGN KEY (`renewed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_renewal_txn` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`transaction_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table: staff
-- ----------------------------
CREATE TABLE `staff` (
  `staff_id` varchar(20) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `middle_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) NOT NULL,
  `extension_name` varchar(10) DEFAULT NULL,
  `gender` enum('Male','Female') DEFAULT NULL,
  `mobile_number` varchar(15) DEFAULT NULL,
  `email` varchar(100) NOT NULL,
  `office_department` varchar(100) DEFAULT 'Circulation Area',
  `is_head_librarian` tinyint NOT NULL DEFAULT '0' COMMENT '0=false, 1=true',
  `address` text,
  `profile_path` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`staff_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `staff` VALUES
('2023-114000','Mary Claire','Lumansoc','Fernandez','','Female','09932960062','mc.fernandez@spamast.edu.ph','Head Office',1,'Poblacion, Malita, Davao Occidental','Assets/Profile/2023-114000_20260923170216256.jpg','2026-11-03 16:00:00','2026-11-03 16:00:00'),
('STAFF-001','Katrina','Garcia','Gonzales','','Female','09458080100','darkflamedemoneye@gmail.com','Serials Section',0,'Purok 1, Brgy. Pangaleon, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:52:40'),
('STAFF-002','Angelica','Bautista','Fernandez',NULL,'Female','09751703927','angelica.fernandez@lmsa.edu.ph','Reference Section',0,'Purok 4, Brgy. Tubalan, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-003','Bryan','Villanueva','Cruz','II','Male','09557816611','bryan.cruz@lmsa.edu.ph','Circulation Area',0,'Purok 5, Brgy. Poblacion, Don Marcelino, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-004','Kevin','Santos','Garcia',NULL,'Male','09200040300','kevin.garcia@lmsa.edu.ph','Reference Section',0,'Purok 5, Brgy. Lais, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-005','Jocelyn','Cabrera','Garcia',NULL,'Female','09185529301','jocelyn.garcia@lmsa.edu.ph','Serials Section',0,'Purok 3, Brgy. Poblacion, Don Marcelino, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-006','Noreen','Garcia','Padilla',NULL,'Female','09757705792','noreen.padilla@lmsa.edu.ph','Serials Section',0,'Purok 3, Brgy. Tubalan, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-007','Lovely','Bautista','Fernandez',NULL,'Female','09551861581','lovely.fernandez@lmsa.edu.ph','Circulation Area',0,'Purok 3, Brgy. Poblacion, Sarangani, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-008','Eric','Reyes','Fajardo',NULL,'Male','09355485066','eric.fajardo@lmsa.edu.ph','Circulation Area',0,'Purok 4, Brgy. Pangaleon, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-009','Eric','Ulep','Hernandez',NULL,'Male','09359734812','eric.hernandez@lmsa.edu.ph','Circulation Area',0,'Purok 5, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-010','Wilfredo','Andrada','Velasco',NULL,'Male','09179208242','wilfredo.velasco@lmsa.edu.ph','Serials Section',0,'Purok 3, Brgy. Poblacion, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-011','Gemma','Alvarez','Castillo',NULL,'Female','09550950601','gemma.castillo@lmsa.edu.ph','Technical Services',0,'Purok 9, Brgy. Poblacion, Santa Maria, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-012','Vanessa','Lim','Torres',NULL,'Female','09660133252','vanessa.torres@lmsa.edu.ph','Serials Section',0,'Purok 7, Brgy. Poblacion, Sarangani, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-013','Allan','Villanueva','Quiambao',NULL,'Male','09197608219','allan.quiambao@lmsa.edu.ph','Head Office',1,'Purok 7, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-014','Princess','Alvarez','Villanueva',NULL,'Female','09450700223','princess.villanueva@lmsa.edu.ph','Head Office',0,'Purok 9, Brgy. Poblacion, Don Marcelino, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('STAFF-015','Oscar','Pascual','Dizon',NULL,'Male','09554655013','oscar.dizon@lmsa.edu.ph','Technical Services',0,'Purok 6, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50');

-- ----------------------------
-- Table: students
-- ----------------------------
CREATE TABLE `students` (
  `student_id` varchar(20) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `middle_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) NOT NULL,
  `extension_name` varchar(10) DEFAULT NULL,
  `gender` enum('Male','Female') DEFAULT NULL,
  `mobile_number` varchar(15) DEFAULT NULL,
  `email` varchar(100) NOT NULL,
  `institute` varchar(50) DEFAULT NULL,
  `course` varchar(50) DEFAULT NULL,
  `section` varchar(10) DEFAULT NULL,
  `year_level` varchar(20) DEFAULT NULL,
  `address` text,
  `profile_path` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`student_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `students` VALUES
('2023-0001','Sheila','Tolentino','Aquino','','Female','09178196727','fernandezmaryclaire79@gmail.com','College of Business','BSHM','C','4th Year','Purok 4, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:52:52'),
('2023-0002','Samuel','Santos','Andrada',NULL,'Male','09552837929','samuel.andrada@lmsa.edu.ph','College of Agriculture','BSA','C','4th Year','Purok 9, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0003','Allan','Hernandez','Castro',NULL,'Male','09195247764','allan.castro@lmsa.edu.ph','College of Agriculture','BSA','B','4th Year','Purok 8, Brgy. Lais, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0004','Angelica','Torres','Soriano',NULL,'Female','09669557990','angelica.soriano@lmsa.edu.ph','College of Business','BSBA','A','4th Year','Purok 7, Brgy. Pangaleon, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0005','Patrick','Jimenez','Tomas',NULL,'Male','09660845850','patrick.tomas@lmsa.edu.ph','College of ICT','BSCS','B','4th Year','Purok 1, Brgy. Tubalan, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0006','Joanna','Rivera','Dizon',NULL,'Female','09275263097','joanna.dizon@lmsa.edu.ph','College of Fisheries','BS Fisheries','A','4th Year','Purok 7, Brgy. Pangaleon, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0007','Noel','Ramos','Domingo',NULL,'Male','09196451547','noel.domingo@lmsa.edu.ph','College of Business','BSHM','B','4th Year','Purok 5, Brgy. Lais, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0008','Yvonne','Castillo','Natividad',NULL,'Female','09189689821','yvonne.natividad@lmsa.edu.ph','College of ICT','BSIT','B','4th Year','Purok 1, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0009','Shaina','Banal','Tolentino',NULL,'Female','09198556898','shaina.tolentino@lmsa.edu.ph','College of Agriculture','BSA','C','4th Year','Purok 4, Brgy. Lais, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0010','Marites','Valdez','Ramos',NULL,'Female','09456753478','marites.ramos@lmsa.edu.ph','College of Business','BSBA','A','4th Year','Purok 8, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0011','Joanna','Banal','Castro',NULL,'Female','09171981524','joanna.castro@lmsa.edu.ph','College of Fisheries','BS Fisheries','B','4th Year','Purok 8, Brgy. Tubalan, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0012','Emmanuel','Evangelista','Fajardo','II','Male','09661780578','emmanuel.fajardo@lmsa.edu.ph','College of Education','BSED','A','4th Year','Purok 1, Brgy. Tubalan, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0013','Xander','Estrada','Macaraeg',NULL,'Male','09189043163','xander.macaraeg@lmsa.edu.ph','College of ICT','BSCS','A','4th Year','Purok 5, Brgy. Poblacion, Sarangani, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0014','Nicole','Tomas','Domingo',NULL,'Female','09666398488','nicole.domingo@lmsa.edu.ph','College of Agriculture','BS Agribusiness','A','4th Year','Purok 7, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0015','Princess','Ramos','Torres',NULL,'Female','09559581635','princess.torres@lmsa.edu.ph','College of Business','BSHM','A','4th Year','Purok 5, Brgy. Poblacion, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0016','Patrick','Abella','Lopez',NULL,'Male','09209828640','patrick.lopez@lmsa.edu.ph','College of ICT','BSIT','C','4th Year','Purok 9, Brgy. Poblacion, Sarangani, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2023-0017','Mikaela','Ocampo','Bautista',NULL,'Female','09175987198','mikaela.bautista@lmsa.edu.ph','College of Business','BSHM','A','4th Year','Purok 9, Brgy. Poblacion, Sarangani, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0001','Tristan','Lopez','Perez',NULL,'Male','09667168976','tristan.perez@lmsa.edu.ph','College of Business','BSHM','A','3rd Year','Purok 9, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0002','Eric','Mendoza','Valdez',NULL,'Male','09197010798','eric.valdez@lmsa.edu.ph','College of Agriculture','BS Agribusiness','A','3rd Year','Purok 2, Brgy. Poblacion, Sarangani, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0003','Mark',NULL,'Villanueva',NULL,'Male','09660737028','mark.villanueva@lmsa.edu.ph','College of Education','BEED','C','3rd Year','Purok 4, Brgy. Poblacion, Santa Maria, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0004','Noreen','Morales','Lim',NULL,'Female','09184524410','noreen.lim@lmsa.edu.ph','College of ICT','BSIT','C','3rd Year','Purok 7, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0005','Vincent','Navarro','Domingo',NULL,'Male','09192808864','vincent.domingo@lmsa.edu.ph','College of Fisheries','BS Fisheries','B','3rd Year','Purok 3, Brgy. Tubalan, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0006','Tessa',NULL,'Soriano',NULL,'Female','09456882811','tessa.soriano@lmsa.edu.ph','College of Agriculture','BSA','A','3rd Year','Purok 3, Brgy. Poblacion, Don Marcelino, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0007','Nathan','Sison','Dela Cruz',NULL,'Male','09458855765','nathan.delacruz@lmsa.edu.ph','College of Education','BEED','A','3rd Year','Purok 3, Brgy. Tubalan, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0008','Shaina','Reyes','Lim',NULL,'Female','09558495183','shaina.lim@lmsa.edu.ph','College of Fisheries','BS Fisheries','C','3rd Year','Purok 9, Brgy. Poblacion, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50');
INSERT INTO `students` VALUES
('2024-0009','Mary Grace','Banal','Diaz',NULL,'Female','09278861930','mary.diaz@lmsa.edu.ph','College of Fisheries','BS Fisheries','B','3rd Year','Purok 8, Brgy. Tubalan, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0010','Daniel','Aguilar','Padilla','Jr.','Male','09359450283','daniel.padilla@lmsa.edu.ph','College of Business','BSHM','A','3rd Year','Purok 2, Brgy. Poblacion, Don Marcelino, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0011','Mark','Francisco','Garcia','II','Male','09751697978','mark.garcia@lmsa.edu.ph','College of Business','BSBA','B','3rd Year','Purok 1, Brgy. Lais, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0012','Rowena','Perez','Castillo',NULL,'Female','09181660330','rowena.castillo@lmsa.edu.ph','College of Education','BSED','A','3rd Year','Purok 5, Brgy. Lais, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0013','Angelica','Ocampo','Salazar',NULL,'Female','09199837252','angelica.salazar@lmsa.edu.ph','College of Fisheries','BS Fisheries','B','3rd Year','Purok 8, Brgy. Poblacion, Santa Maria, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0014','Kenneth','Robles','Martinez',NULL,'Male','09352198033','kenneth.martinez@lmsa.edu.ph','College of Business','BSHM','B','3rd Year','Purok 5, Brgy. Poblacion, Don Marcelino, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0015','Joshua','Francisco','Diaz',NULL,'Male','09171332796','joshua.diaz@lmsa.edu.ph','College of ICT','BSCS','B','3rd Year','Purok 8, Brgy. Lais, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0016','Irene','Salazar','Mendoza',NULL,'Female','09172994461','irene.mendoza@lmsa.edu.ph','College of Agriculture','BSA','B','3rd Year','Purok 4, Brgy. Pangaleon, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2024-0017','Kenneth','Delos Santos','Ulep','III','Male','09750488015','kenneth.ulep@lmsa.edu.ph','College of Business','BSHM','B','3rd Year','Purok 7, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0001','Harvey','Dela Cruz','Gonzales',NULL,'Male','09356815188','harvey.gonzales@lmsa.edu.ph','College of ICT','BSCS','C','2nd Year','Purok 5, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0002','Cedric','Tolentino','Aguilar',NULL,'Male','09660457178','cedric.aguilar@lmsa.edu.ph','College of Business','BSBA','B','2nd Year','Purok 5, Brgy. Poblacion, Jose Abad Santos, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0003','Bryan','Evangelista','Lim',NULL,'Male','09759229836','bryan.lim@lmsa.edu.ph','College of ICT','BSCS','C','2nd Year','Purok 6, Brgy. Poblacion, Jose Abad Santos, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0004','Leo','Estrada','Sison',NULL,'Male','09754821416','leo.sison@lmsa.edu.ph','College of Education','BEED','A','2nd Year','Purok 3, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0005','Pamela','Villanueva','Pascual',NULL,'Female','09182911028','pamela.pascual@lmsa.edu.ph','College of ICT','BSCS','B','2nd Year','Purok 6, Brgy. Poblacion, Sarangani, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0006','Hazel','Fernandez','Andrada',NULL,'Female','09358602145','hazel.andrada@lmsa.edu.ph','College of Business','BSHM','A','2nd Year','Purok 9, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0007','Faith','Ibarra','Dela Cruz',NULL,'Female','09185771883','faith.delacruz@lmsa.edu.ph','College of ICT','BSCS','A','2nd Year','Purok 6, Brgy. Poblacion, Jose Abad Santos, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0008','Rafael','Fajardo','Bautista',NULL,'Male','09278425996','rafael.bautista@lmsa.edu.ph','College of Business','BSBA','B','2nd Year','Purok 8, Brgy. Poblacion, Jose Abad Santos, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0009','Tessa','Yap','Bautista',NULL,'Female','09188847918','tessa.bautista@lmsa.edu.ph','College of Agriculture','BS Agribusiness','B','2nd Year','Purok 9, Brgy. Poblacion, Sarangani, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0010','Katrina','Andrada','Natividad',NULL,'Female','09757804385','katrina.natividad@lmsa.edu.ph','College of Agriculture','BSA','C','2nd Year','Purok 9, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0011','Eric','Mendoza','Tomas',NULL,'Male','09357699085','eric.tomas@lmsa.edu.ph','College of ICT','BSCS','B','2nd Year','Purok 5, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0012','Olivia','Ulep','Perez',NULL,'Female','09208546905','olivia.perez@lmsa.edu.ph','College of Education','BSED','B','2nd Year','Purok 9, Brgy. Lais, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0013','Cedric','Navarro','Garcia','III','Male','09187922328','cedric.garcia@lmsa.edu.ph','College of Business','BSHM','A','2nd Year','Purok 4, Brgy. Poblacion, Santa Maria, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0014','Kenneth','Martinez','Reyes',NULL,'Male','09450791135','kenneth.reyes@lmsa.edu.ph','College of ICT','BSCS','A','2nd Year','Purok 8, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0015','Leo','Zamora','Soriano',NULL,'Male','09668498556','leo.soriano@lmsa.edu.ph','College of Education','BEED','C','2nd Year','Purok 9, Brgy. Tubalan, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0016','Carlo','Reyes','Garcia',NULL,'Male','09187707751','carlo.garcia@lmsa.edu.ph','College of Agriculture','BS Agribusiness','A','2nd Year','Purok 1, Brgy. Poblacion, Don Marcelino, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50');
INSERT INTO `students` VALUES
('2025-0017','Jericho','Pascual','Macaraeg',NULL,'Male','09559615679','jericho.macaraeg@lmsa.edu.ph','College of Agriculture','BS Agribusiness','C','2nd Year','Purok 6, Brgy. Poblacion, Sarangani, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2025-0018','Hazel','Andrada','Soriano',NULL,'Female','09662960179','hazel.soriano@lmsa.edu.ph','College of Fisheries','BS Fisheries','A','2nd Year','Purok 7, Brgy. Poblacion, Jose Abad Santos, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0001','Marlon','Zamora','Diaz',NULL,'Male','09757309114','marlon.diaz@lmsa.edu.ph','College of ICT','BSIT','A','1st Year','Purok 2, Brgy. Poblacion, Jose Abad Santos, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0002','Nathan','Velasco','Diaz',NULL,'Male','09456344002','nathan.diaz@lmsa.edu.ph','College of Business','BSHM','C','1st Year','Purok 8, Brgy. Poblacion, Santa Maria, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0003','Felix','Domingo','Hernandez',NULL,'Male','09206016105','felix.hernandez@lmsa.edu.ph','College of ICT','BSIT','A','1st Year','Purok 6, Brgy. Poblacion, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0004','Ryan','Ramos','Abella',NULL,'Male','09555682052','ryan.abella@lmsa.edu.ph','College of Fisheries','BS Fisheries','A','1st Year','Purok 6, Brgy. Poblacion, Santa Maria, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0005','Erika','Aguilar','Banal',NULL,'Female','09276450604','erika.banal@lmsa.edu.ph','College of Education','BSED','B','1st Year','Purok 6, Brgy. Bito, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0006','Gemma','Valdez','Padilla',NULL,'Female','09208453557','gemma.padilla@lmsa.edu.ph','College of Business','BSBA','C','1st Year','Purok 8, Brgy. Poblacion, Santa Maria, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0007','Jomar','Castillo','Andrada','Jr.','Male','09175154382','jomar.andrada@lmsa.edu.ph','College of Education','BEED','A','1st Year','Purok 4, Brgy. Lais, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0008','Rowena','Torres','Tolentino',NULL,'Female','09757660856','rowena.tolentino@lmsa.edu.ph','College of Education','BEED','B','1st Year','Purok 6, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0009','Rafael','Lim','Salazar',NULL,'Male','09354072075','rafael.salazar@lmsa.edu.ph','College of Business','BSBA','B','1st Year','Purok 5, Brgy. Poblacion, Jose Abad Santos, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0010','Cherry','Yap','Velasco',NULL,'Female','09750044224','cherry.velasco@lmsa.edu.ph','College of Education','BEED','C','1st Year','Purok 9, Brgy. Pangaleon, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0011','Renato','Castillo','Orteza',NULL,'Male','09453608244','renato.orteza@lmsa.edu.ph','College of Agriculture','BSA','A','1st Year','Purok 6, Brgy. Poblacion, Don Marcelino, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0012','Gemma','Aguilar','Navarro',NULL,'Female','09356073927','gemma.navarro@lmsa.edu.ph','College of Fisheries','BS Fisheries','C','1st Year','Purok 4, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0013','Shaina','Santos','Ramos',NULL,'Female','09177418288','shaina.ramos@lmsa.edu.ph','College of Business','BSBA','A','1st Year','Purok 9, Brgy. Tubalan, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0014','Angelica','Evangelista','Pascual',NULL,'Female','09559137298','angelica.pascual@lmsa.edu.ph','College of Education','BEED','B','1st Year','Purok 8, Brgy. Culaman, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0015','Noreen','Cruz','Soriano',NULL,'Female','09204269276','noreen.soriano@lmsa.edu.ph','College of Fisheries','BS Fisheries','A','1st Year','Purok 8, Brgy. Poblacion, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0016','Kaye','Hernandez','Jimenez',NULL,'Female','09183875921','kaye.jimenez@lmsa.edu.ph','College of ICT','BSCS','C','1st Year','Purok 2, Brgy. Pangaleon, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0017','Harvey','Fajardo','Padilla',NULL,'Male','09195844419','harvey.padilla@lmsa.edu.ph','College of Fisheries','BS Fisheries','B','1st Year','Purok 4, Brgy. Poblacion, Malita, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50'),
('2026-0018','Aileen','Ocampo','Orteza',NULL,'Female','09189602780','aileen.orteza@lmsa.edu.ph','College of ICT','BSIT','B','1st Year','Purok 5, Brgy. Poblacion, Don Marcelino, Davao Occidental',NULL,'2026-11-04 06:51:50','2026-11-04 06:51:50');

-- ----------------------------
-- Table: user_submissions
-- ----------------------------
CREATE TABLE `user_submissions` (
  `submission_id` int NOT NULL AUTO_INCREMENT,
  `user_id` varchar(20) DEFAULT NULL,
  `type` enum('Inquiry','Feedback','Request') DEFAULT NULL,
  `message` text,
  `is_restock_suggestion` tinyint NOT NULL DEFAULT '0' COMMENT '0=false, 1=true',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`submission_id`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `user_submissions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET UNIQUE_CHECKS = 1;
SET FOREIGN_KEY_CHECKS = 1;