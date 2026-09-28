-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 172.18.111.42:3306
-- Generation Time: Sep 28, 2026 at 11:21 AM
-- Server version: 10.11.14-MariaDB-0ubuntu0.24.04.1
-- PHP Version: 8.3.33

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `HealthyMate`
--

DROP TABLE IF EXISTS `TbWorkouts`;
DROP TABLE IF EXISTS `TbUserPreferences`;
DROP TABLE IF EXISTS `TbUserBadges`;
DROP TABLE IF EXISTS `tbsession`;
DROP TABLE IF EXISTS `TbSession`;
DROP TABLE IF EXISTS `TbRoutineLogs`;
DROP TABLE IF EXISTS `TbNutritionLogs`;
DROP TABLE IF EXISTS `TbHealthRecords`;
DROP TABLE IF EXISTS `TbHealthIntegrations`;
DROP TABLE IF EXISTS `TbGoals`;
DROP TABLE IF EXISTS `TbRoutines`;
DROP TABLE IF EXISTS `TbEmailOtps`;
DROP TABLE IF EXISTS `TbBadges`;
DROP TABLE IF EXISTS `TbUsers`;

-- --------------------------------------------------------

--
-- Table structure for table `TbUsers`
--

CREATE TABLE `TbUsers` (
  `nUserId` int(11) NOT NULL AUTO_INCREMENT,
  `sEmail` varchar(255) NOT NULL,
  `sPasswordHash` varchar(255) NOT NULL,
  `sFirstName` varchar(100) NOT NULL,
  `sLastName` varchar(100) NOT NULL,
  `nAge` int(11) DEFAULT NULL,
  `nHeight` decimal(5,2) DEFAULT NULL,
  `nWeight` decimal(5,2) DEFAULT NULL,
  `sGender` varchar(20) DEFAULT NULL,
  `sActivityLevel` varchar(50) DEFAULT NULL,
  `isDarkMode` tinyint(1) DEFAULT 0,
  `sProfileImagePath` text DEFAULT NULL,
  `isSynced` tinyint(1) DEFAULT 0,
  `dtUpdatedAt` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `dtCreatedAt` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`nUserId`),
  UNIQUE KEY `sEmail` (`sEmail`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `TbUsers`
--

INSERT INTO `TbUsers` (`nUserId`, `sEmail`, `sPasswordHash`, `sFirstName`, `sLastName`, `nAge`, `nHeight`, `nWeight`, `sGender`, `sActivityLevel`, `isDarkMode`, `sProfileImagePath`, `isSynced`, `dtUpdatedAt`, `dtCreatedAt`) VALUES
(14, 'kamaruding7028@gmail.com', 'e735938edc298893d166bcf812686928c716c0cb4a711406ba502426277734db', 'kamaruding', 'ingding', 22, 158.00, 50.00, 'male', 'light', 0, '', 1, '2026-09-28 18:10:06', '2026-09-23 20:00:06'),
(17, 'salwanibaraheng26@gmail.com', '$2y$12$/3ISztxaogAIwDcyAFmUMOlYLX.HMOfwaA/at2UeDeaYnrs4MbYrO', 'sal', 'wanee', 21, 156.00, 47.00, 'female', 'moderate', 0, 'https://lh3.googleusercontent.com/a/ACg8ocJNR7-Ct2tnbR1jk1kiZneZuL_m_qzQsZZNOd5ljWOPsQjWRCs=s96-c', 1, '2026-09-28 18:11:05', '2026-09-23 20:16:26');

-- --------------------------------------------------------

--
-- Table structure for table `TbBadges`
--

CREATE TABLE `TbBadges` (
  `nBadgeId` int(11) NOT NULL AUTO_INCREMENT,
  `sBadgeName` varchar(100) NOT NULL,
  `sDescription` varchar(255) DEFAULT NULL,
  `sIconUrl` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`nBadgeId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `TbBadges`
--

INSERT INTO `TbBadges` (`nBadgeId`, `sBadgeName`, `sDescription`, `sIconUrl`) VALUES
(2, 'ผู้เริ่มต้นก้าวแรก', 'เหรียญรางวัลพิเศษ', 'emoji_events');

-- --------------------------------------------------------

--
-- Table structure for table `TbEmailOtps`
--

CREATE TABLE `TbEmailOtps` (
  `nOtpId` int(11) NOT NULL AUTO_INCREMENT,
  `sEmail` varchar(150) NOT NULL,
  `sOtpCode` varchar(6) NOT NULL,
  `nAttempts` int(11) DEFAULT 0,
  `isUsed` tinyint(1) DEFAULT 0,
  `dtExpiresAt` datetime NOT NULL,
  `dtCreatedAt` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`nOtpId`),
  KEY `idx_email_status` (`sEmail`,`isUsed`,`dtExpiresAt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `TbEmailOtps`
--

INSERT INTO `TbEmailOtps` (`nOtpId`, `sEmail`, `sOtpCode`, `nAttempts`, `isUsed`, `dtExpiresAt`, `dtCreatedAt`) VALUES
(2, 'kamaruding7028@gmail.com', '150830', 0, 1, '2026-09-23 20:04:44', '2026-09-23 19:59:43'),
(5, 'salwanibaraheng26@gmail.com', '613509', 0, 1, '2026-09-23 20:20:59', '2026-09-23 20:15:59'),
(8, 'kamaruding7028@gmail.com', '746448', 0, 1, '2026-09-23 22:53:54', '2026-09-23 22:48:53'),
(10, 'kamaruding7028@gmail.com', '133639', 0, 1, '2026-09-25 22:45:07', '2026-09-25 22:40:06'),
(11, 'kamaruding7028@gmail.com', '993419', 0, 1, '2026-09-25 22:58:05', '2026-09-25 22:53:05'),
(13, 'kamaruding7028@gmail.com', '165973', 0, 1, '2026-09-26 20:11:28', '2026-09-26 20:06:28'),
(15, 'kamaruding7028@gmail.com', '433875', 0, 1, '2026-09-26 23:41:57', '2026-09-26 23:36:58'),
(18, 'kamaruding7028@gmail.com', '165042', 0, 1, '2026-09-27 01:30:39', '2026-09-27 01:25:40'),
(20, 'salwanibaraheng26@gmail.com', '605746', 0, 1, '2026-09-27 12:07:28', '2026-09-27 12:02:28'),
(21, 'salwanibaraheng26@gmail.com', '957660', 0, 1, '2026-09-27 12:09:09', '2026-09-27 12:04:10'),
(23, 'kamaruding7028@gmail.com', '244867', 0, 1, '2026-09-27 17:19:03', '2026-09-27 17:14:02');

-- --------------------------------------------------------

--
-- Table structure for table `TbRoutines`
--

CREATE TABLE `TbRoutines` (
  `nRoutineId` int(11) NOT NULL AUTO_INCREMENT,
  `nUserId` int(11) NOT NULL,
  `sTitle` varchar(150) NOT NULL,
  `sTime` varchar(255) DEFAULT NULL,
  `isNotificationActive` tinyint(1) DEFAULT 1,
  `dtCreatedAt` datetime DEFAULT current_timestamp(),
  `nTargetValue` double DEFAULT 1,
  `sUnit` varchar(50) DEFAULT 'ครั้ง',
  `sLinkedWorkout` varchar(100) DEFAULT '',
  `nColor` bigint(20) DEFAULT NULL,
  `nIconData` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`nRoutineId`),
  KEY `nUserId` (`nUserId`),
  CONSTRAINT `fk_routines_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `TbRoutines`
--

INSERT INTO `TbRoutines` (`nRoutineId`, `nUserId`, `sTitle`, `sTime`, `isNotificationActive`, `dtCreatedAt`, `nTargetValue`, `sUnit`, `sLinkedWorkout`, `nColor`, `nIconData`) VALUES
(25, 14, 'ดื่มน้ำ', 'ทุก 1 ชั่วโมง', 1, '2026-09-27 21:49:11', 2000, 'มล.', '', 4278356177, 63165),
(28, 14, 'เดิน', 'ทุก 1 ชั่วโมง', 1, '2026-09-27 21:49:11', 3, 'กม.', 'เดิน', -11751600, 63165),
(34, 14, 'สมาธิ', '20:18 น.', 1, '2026-09-27 21:49:12', 15, 'นาที', '', 4283215696, 983364),
(46, 14, 'วิ่ง', 'ทุก 2 ชั่วโมง', 1, '2026-09-27 22:05:24', 3, 'กม.', 'วิ่ง', 4286470082, 63165),
(52, 17, 'ดื่มน้ำ', 'ทุก 2 ชั่วโมง', 1, '2026-09-28 00:01:59', 2000, 'มล.', '', -26624, 983988),
(55, 17, 'เดิน', '12:00 & 18:00', 1, '2026-09-28 00:02:51', 10, 'กม.', 'เดิน', -16738680, 63165),
(58, 17, 'ทำสมาธิ', '08:00 น.', 1, '2026-09-28 00:04:22', 15, 'นาที', '', -1499549, 983364);

-- --------------------------------------------------------

--
-- Table structure for table `TbGoals`
--

CREATE TABLE `TbGoals` (
  `nGoalId` int(11) NOT NULL AUTO_INCREMENT,
  `nUserId` int(11) NOT NULL,
  `sTitle` varchar(255) NOT NULL,
  `nProgress` decimal(5,2) DEFAULT 0.00,
  `sRemainingText` varchar(255) DEFAULT NULL,
  `dtUpdatedAt` datetime DEFAULT NULL,
  `nRoutineId` int(11) DEFAULT NULL,
  PRIMARY KEY (`nGoalId`),
  KEY `nUserId` (`nUserId`),
  KEY `fk_goals_routine` (`nRoutineId`),
  CONSTRAINT `fk_goals_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE,
  CONSTRAINT `fk_goals_routine` FOREIGN KEY (`nRoutineId`) REFERENCES `TbRoutines` (`nRoutineId`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbHealthIntegrations`
--

CREATE TABLE `TbHealthIntegrations` (
  `nIntegrationId` int(11) NOT NULL AUTO_INCREMENT,
  `nUserId` int(11) NOT NULL,
  `sProviderName` varchar(50) NOT NULL,
  `isSynced` tinyint(1) DEFAULT 0,
  `dtLastSyncedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`nIntegrationId`),
  KEY `nUserId` (`nUserId`),
  CONSTRAINT `fk_integrations_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbHealthRecords`
--

CREATE TABLE `TbHealthRecords` (
  `nRecordId` int(11) NOT NULL AUTO_INCREMENT,
  `nUserId` int(11) NOT NULL,
  `nWeight` decimal(5,2) DEFAULT NULL,
  `nHeight` decimal(5,2) DEFAULT NULL,
  `nBmi` decimal(4,2) DEFAULT NULL,
  `nTdee` decimal(6,2) DEFAULT NULL,
  `computedBmr` decimal(6,2) DEFAULT NULL,
  `activityLevelTitle` varchar(100) DEFAULT NULL,
  `isSynced` tinyint(1) DEFAULT 0,
  `dtUpdatedAt` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `dtRecordedAt` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`nRecordId`),
  KEY `nUserId` (`nUserId`),
  CONSTRAINT `fk_healthrecords_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `TbHealthRecords`
--

INSERT INTO `TbHealthRecords` (`nRecordId`, `nUserId`, `nWeight`, `nHeight`, `nBmi`, `nTdee`, `computedBmr`, `activityLevelTitle`, `isSynced`, `dtUpdatedAt`, `dtRecordedAt`) VALUES
(51, 14, 55.00, 158.00, 22.00, 1970.00, NULL, NULL, 1, '2026-09-24 00:49:19', '2026-09-24 00:49:17'),
(77, 14, 55.00, 158.00, 22.00, 1970.00, NULL, NULL, 1, '2026-09-24 00:49:33', '2026-09-24 00:49:33'),
(80, 14, 55.00, 158.00, 22.00, 1970.00, NULL, NULL, 1, '2026-09-24 00:49:36', '2026-09-24 00:49:36'),
(81, 14, 55.00, 158.00, 22.00, 1970.00, NULL, NULL, 1, '2026-09-24 00:50:05', '2026-09-24 00:50:04'),
(114, 17, 60.00, 156.00, 24.70, 1764.00, NULL, NULL, 1, '2026-09-24 22:34:52', '2026-09-24 22:34:52'),
(115, 14, 50.00, 158.00, 20.00, 1901.00, NULL, NULL, 1, '2026-09-25 21:24:08', '2026-09-25 21:24:08'),
(118, 14, 53.00, 158.00, 21.20, 1942.00, NULL, NULL, 1, '2026-09-26 20:02:32', '2026-09-26 18:48:05'),
(120, 17, 63.00, 156.00, 25.90, 1607.00, NULL, NULL, 1, '2026-09-27 12:08:15', '2026-09-27 12:08:14'),
(121, 17, 60.00, 156.00, 24.70, 1571.00, NULL, NULL, 1, '2026-09-27 12:13:34', '2026-09-27 12:13:35'),
(124, 14, 53.00, 158.00, 21.20, 1942.00, NULL, NULL, 1, '2026-09-27 23:09:55', '2026-09-27 23:09:54'),
(128, 14, 53.00, 158.00, 21.20, 1942.00, 1413.00, 'ออกกำลังกายเบาๆ', 1, '2026-09-27 23:17:19', '2026-09-27 23:17:18'),
(130, 17, 59.00, 156.00, 24.20, 1559.00, 1299.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:32', '2026-09-27 22:25:43'),
(133, 17, 58.00, 156.00, 23.80, 1547.00, 1289.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:32', '2026-09-27 22:35:46'),
(136, 17, 58.00, 156.00, 23.80, 1547.00, 1289.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:32', '2026-09-27 22:35:51'),
(139, 17, 59.00, 156.00, 24.20, 1559.00, 1299.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:32', '2026-09-27 22:37:59'),
(142, 17, 56.00, 156.00, 23.00, 1523.00, 1269.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:32', '2026-09-27 22:38:20'),
(145, 17, 57.00, 156.00, 23.40, 1535.00, 1279.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:32', '2026-09-27 22:39:10'),
(148, 17, 60.00, 156.00, 24.70, 1571.00, 1309.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:32', '2026-09-27 22:39:28'),
(151, 17, 55.00, 156.00, 22.60, 1511.00, 1259.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:33', '2026-09-27 22:39:50'),
(154, 17, 56.00, 156.00, 23.00, 1523.00, 1269.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:33', '2026-09-27 22:40:30'),
(157, 17, 54.00, 156.00, 22.20, 1499.00, 1249.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:33', '2026-09-27 22:40:58'),
(160, 17, 54.00, 156.00, 22.20, 1499.00, 1249.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:33', '2026-09-27 23:20:12'),
(163, 17, 50.00, 156.00, 20.50, 1451.00, 1209.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:33', '2026-09-27 23:20:35'),
(166, 17, 52.00, 156.00, 21.40, 1475.00, 1229.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-27 23:26:33', '2026-09-27 23:24:05'),
(167, 17, 50.00, 156.00, 20.50, 1451.00, 1209.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-28 17:37:17', '2026-09-28 17:37:18'),
(170, 17, 50.00, 156.00, 20.50, 1451.00, 1209.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-28 17:37:22', '2026-09-28 17:37:22'),
(173, 17, 50.00, 156.00, 20.50, 1451.00, 1209.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-28 17:38:20', '2026-09-28 17:38:20'),
(174, 17, 60.00, 156.00, 24.70, 1571.00, 1309.00, 'ไม่ออกกำลังกายเลย', 1, '2026-09-28 17:38:58', '2026-09-28 17:38:57'),
(176, 17, 60.00, 156.00, 24.70, 2029.00, 1309.00, 'ออกกำลังกายปานกลาง', 1, '2026-09-28 17:40:37', '2026-09-28 17:40:37'),
(177, 17, 50.00, 156.00, 20.50, 1874.00, 1209.00, 'ออกกำลังกายปานกลาง', 1, '2026-09-28 17:41:39', '2026-09-28 17:41:38'),
(179, 17, 55.00, 156.00, 22.60, 1951.00, 1259.00, 'ออกกำลังกายปานกลาง', 1, '2026-09-28 17:42:15', '2026-09-28 17:42:16'),
(180, 17, 47.00, 156.00, 19.30, 1827.00, 1179.00, 'ออกกำลังกายปานกลาง', 1, '2026-09-28 17:42:45', '2026-09-28 17:42:44'),
(183, 14, 53.00, 158.00, 21.20, 1942.00, 1413.00, 'ออกกำลังกายเบาๆ', 1, '2026-09-28 18:03:36', '2026-09-28 18:03:34'),
(185, 14, 53.00, 158.00, 21.20, 1942.00, 1413.00, 'ออกกำลังกายเบาๆ', 1, '2026-09-28 18:05:38', '2026-09-28 18:05:38'),
(188, 14, 50.00, 158.00, 20.00, 1901.00, 1383.00, 'ออกกำลังกายเบาๆ', 1, '2026-09-28 18:05:51', '2026-09-28 18:05:51');

-- --------------------------------------------------------

--
-- Table structure for table `TbNutritionLogs`
--

CREATE TABLE `TbNutritionLogs` (
  `nNutritionId` int(11) NOT NULL AUTO_INCREMENT,
  `nUserId` int(11) NOT NULL,
  `sMealType` varchar(50) NOT NULL,
  `sFoodName` varchar(150) NOT NULL,
  `nCalories` int(11) NOT NULL,
  `nProtein` decimal(5,2) DEFAULT 0.00,
  `nCarbs` decimal(5,2) DEFAULT 0.00,
  `nFat` decimal(5,2) DEFAULT 0.00,
  `sServingSize` varchar(100) DEFAULT '',
  `sImagePath` text DEFAULT NULL,
  `isSynced` tinyint(1) DEFAULT 0,
  `dtUpdatedAt` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `dtLoggedAt` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`nNutritionId`),
  KEY `nUserId` (`nUserId`),
  CONSTRAINT `fk_nutrition_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `TbNutritionLogs`
--

INSERT INTO `TbNutritionLogs` (`nNutritionId`, `nUserId`, `sMealType`, `sFoodName`, `nCalories`, `nProtein`, `nCarbs`, `nFat`, `sServingSize`, `sImagePath`, `isSynced`, `dtUpdatedAt`, `dtLoggedAt`) VALUES
(34, 14, 'dinner', 'ไอศกรีมซอฟต์เสิร์ฟราดช็อกโกแลต', 250, 4.50, 32.00, 11.00, '1 ถ้วย (150g)', '/data/user/0/com.example.healthymate/cache/scaled_c6d55f41-676d-4a47-bcae-2f387edf4ef44468727531037942066.jpg', 1, '2026-09-27 20:14:38', '2026-09-27 17:56:55'),
(37, 14, 'dinner', 'ไอศกรีมซอฟต์เสิร์ฟราดซอสสตรอว์เบอร์รีและคุ้กกี้ชิ้น', 250, 4.50, 35.00, 10.00, '1 ถ้วย (120g)', '/data/user/0/com.example.healthymate/cache/scaled_c2a70f42-cc72-449c-9a4c-7c135b8b00c69077422710683177947.jpg', 1, '2026-09-27 20:14:38', '2026-09-27 17:57:16'),
(40, 14, 'dinner', 'ส้มตำไทย', 120, 4.50, 22.00, 2.00, '1 จาน (150g)', '/data/user/0/com.example.healthymate/cache/scaled_1000008448.jpg', 1, '2026-09-27 20:41:03', '2026-09-27 20:41:02'),
(43, 14, 'dinner', 'กะหล่ำปลีสด (เครื่องเคียง)', 25, 1.30, 5.80, 0.10, '50g', '/data/user/0/com.example.healthymate/cache/scaled_1000008448.jpg', 1, '2026-09-27 20:41:03', '2026-09-27 20:41:02'),
(46, 14, 'dinner', 'ผักบุ้งสด (เครื่องเคียง)', 10, 0.90, 1.80, 0.20, '20g', '/data/user/0/com.example.healthymate/cache/scaled_1000008448.jpg', 1, '2026-09-27 20:41:04', '2026-09-27 20:41:02'),
(49, 14, 'dinner', 'ส้มตำไทย', 120, 3.50, 22.00, 2.50, '1 จาน (150g)', '/data/user/0/com.example.healthymate/cache/scaled_1000008448.jpg', 1, '2026-09-27 20:51:59', '2026-09-27 20:51:58'),
(52, 14, 'dinner', 'กะหล่ำปลีสด', 25, 1.30, 5.80, 0.10, '1 เสิร์ฟ (50g)', '/data/user/0/com.example.healthymate/cache/scaled_1000008448.jpg', 1, '2026-09-27 20:51:59', '2026-09-27 20:51:58'),
(55, 14, 'dinner', 'ผักบุ้งสด', 10, 0.90, 1.90, 0.20, '1 กำ (30g)', '/data/user/0/com.example.healthymate/cache/scaled_1000008448.jpg', 1, '2026-09-27 20:51:59', '2026-09-27 20:51:58'),
(56, 14, 'dinner', 'ส้มตำไทย', 120, 4.50, 20.00, 2.50, '1 จาน (150g)', '/data/user/0/com.example.healthymate/cache/scaled_1000008448.jpg', 1, '2026-09-27 20:58:54', '2026-09-27 20:58:53'),
(59, 14, 'dinner', 'กะหล่ำปลีสด (เครื่องเคียง)', 15, 1.00, 3.50, 0.10, '1 เสิร์ฟ (50g)', '/data/user/0/com.example.healthymate/cache/scaled_1000008448.jpg', 1, '2026-09-27 20:58:55', '2026-09-27 20:58:53'),
(62, 14, 'dinner', 'ผักบุ้งสด (เครื่องเคียง)', 10, 1.00, 2.00, 0.20, '1 กำ (30g)', '/data/user/0/com.example.healthymate/cache/scaled_1000008448.jpg', 1, '2026-09-27 20:58:55', '2026-09-27 20:58:53'),
(64, 17, 'dinner', 'เค้กช็อกโกแลตหนาแน่นแต่งหน้าด้วยเวเฟอร์และคุกกี้', 420, 5.20, 58.00, 19.50, '1 ชิ้น (100g)', '/data/user/0/com.example.healthymate/cache/scaled_e431d1b8-2f7a-4761-b89f-e5ff21b5af428540394867776670936.jpg', 1, '2026-09-27 23:26:33', '2026-09-27 17:52:53'),
(67, 14, 'snack', 'น่องไก่ติดสะโพกย่าง', 350, 32.50, 2.00, 23.00, '1 ชิ้น (200g)', '/data/user/0/com.example.healthymate/cache/scaled_1000008374.jpg', 1, '2026-09-27 23:58:09', '2026-09-27 23:58:07'),
(70, 17, 'dinner', 'ข้าวไข่เจียว', 420, 14.50, 45.00, 20.00, '1 จาน (250g)', '/data/user/0/com.example.healthymate/cache/scaled_1000037321.jpg', 1, '2026-09-28 17:05:50', '2026-09-28 17:05:49'),
(73, 17, 'dinner', 'ซอสพริก', 25, 0.20, 6.00, 0.10, '1 ถ้วยเล็ก (30g)', '/data/user/0/com.example.healthymate/cache/scaled_1000037321.jpg', 1, '2026-09-28 17:05:50', '2026-09-28 17:05:49'),
(74, 17, 'dinner', 'มะเขือเทศหั่นแว่น', 5, 0.20, 1.00, 0.00, '2 ชิ้น (20g)', '/data/user/0/com.example.healthymate/cache/scaled_1000037321.jpg', 1, '2026-09-28 17:05:50', '2026-09-28 17:05:49'),
(76, 17, 'dinner', 'สตรอว์เบอร์รี่สมูทตี้วิปครีม', 350, 4.00, 45.00, 18.00, '1 แก้ว (350ml)', '/data/user/0/com.example.healthymate/cache/scaled_1000037324.jpg', 1, '2026-09-28 17:07:20', '2026-09-28 17:07:20'),
(78, 17, 'dinner', 'ไอศกรีมซอฟต์เสิร์ฟราดซอสช็อกโกแลตและโอรีโอ้บด', 320, 5.00, 48.00, 12.00, '1 ถ้วย (150g)', '/data/user/0/com.example.healthymate/cache/scaled_1000037326.jpg', 1, '2026-09-28 17:08:39', '2026-09-28 17:08:37'),
(81, 17, 'dinner', 'ไอศกรีมซอฟต์เสิร์ฟราดซอสสตรอว์เบอร์รี', 280, 4.50, 45.00, 9.00, '1 ถ้วย (150g)', '/data/user/0/com.example.healthymate/cache/scaled_1000037326.jpg', 1, '2026-09-28 17:08:40', '2026-09-28 17:08:37'),
(83, 17, 'dinner', 'ไอศกรีมซอฟต์เสิร์ฟราดซอสช็อกโกแลตและโอรีโอ้บด', 320, 5.00, 48.00, 12.00, '1 แก้ว (180g)', '/data/user/0/com.example.healthymate/cache/scaled_1000037326.jpg', 1, '2026-09-28 17:12:05', '2026-09-28 17:12:05'),
(84, 17, 'dinner', 'ไอศกรีมซอฟต์เสิร์ฟราดซอสสตรอเบอร์รี่', 280, 4.50, 45.00, 9.00, '1 แก้ว (180g)', '/data/user/0/com.example.healthymate/cache/scaled_1000037326.jpg', 1, '2026-09-28 17:12:07', '2026-09-28 17:12:05'),
(86, 14, 'dinner', 'ส้มตำไทย', 120, 3.50, 22.00, 2.00, '1 จาน (150g)', '/data/user/0/com.example.healthymate/cache/scaled_1000008448.jpg', 1, '2026-09-28 18:11:35', '2026-09-28 18:11:34'),
(87, 14, 'dinner', 'กะหล่ำปลีสด', 25, 1.30, 5.80, 0.10, '1 เสิร์ฟ (50g)', '/data/user/0/com.example.healthymate/cache/scaled_1000008448.jpg', 1, '2026-09-28 18:11:37', '2026-09-28 18:11:34'),
(89, 14, 'dinner', 'ผักบุ้งสด', 10, 0.90, 1.80, 0.20, '2-3 ก้าน (20g)', '/data/user/0/com.example.healthymate/cache/scaled_1000008448.jpg', 1, '2026-09-28 18:11:35', '2026-09-28 18:11:34');

-- --------------------------------------------------------

--
-- Table structure for table `TbRoutineLogs`
--

CREATE TABLE `TbRoutineLogs` (
  `nLogId` int(11) NOT NULL AUTO_INCREMENT,
  `nRoutineId` int(11) NOT NULL,
  `isCompleted` tinyint(1) DEFAULT 0,
  `dtLogDate` date NOT NULL,
  `nProgressValue` double DEFAULT 0,
  `dtCreatedAt` datetime DEFAULT current_timestamp(),
  `dtUpdatedAt` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`nLogId`),
  UNIQUE KEY `unique_routine_log` (`nRoutineId`,`dtLogDate`),
  KEY `nRoutineId` (`nRoutineId`),
  CONSTRAINT `fk_routinelogs_routine` FOREIGN KEY (`nRoutineId`) REFERENCES `TbRoutines` (`nRoutineId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `TbRoutineLogs`
--

INSERT INTO `TbRoutineLogs` (`nLogId`, `nRoutineId`, `isCompleted`, `dtLogDate`, `nProgressValue`, `dtCreatedAt`, `dtUpdatedAt`) VALUES
(284, 28, 0, '2026-09-27', 0.68, '2026-09-27 22:28:15', '2026-09-27 22:28:15'),
(287, 25, 0, '2026-09-27', 1000, '2026-09-27 22:28:16', '2026-09-27 22:37:51'),
(394, 34, 1, '2026-09-27', 0, '2026-09-27 23:19:14', '2026-09-27 23:19:14'),
(410, 52, 1, '2026-09-28', 2000, '2026-09-28 00:02:24', '2026-09-28 17:39:47'),
(523, 34, 0, '2026-09-28', 2, '2026-09-28 00:24:47', '2026-09-28 18:02:34'),
(526, 25, 0, '2026-09-28', 250, '2026-09-28 00:25:09', '2026-09-28 00:25:09'),
(557, 58, 0, '2026-09-28', 1.7, '2026-09-28 17:36:30', '2026-09-28 17:36:30');

-- --------------------------------------------------------

--
-- Table structure for table `tbsession`
--

CREATE TABLE `tbsession` (
  `nUserId` int(11) NOT NULL,
  `sToken` text NOT NULL,
  `dtExpiresAt` datetime NOT NULL,
  `dtCreatedAt` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`nUserId`),
  CONSTRAINT `fk_session_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbsession`
--

INSERT INTO `tbsession` (`nUserId`, `sToken`, `dtExpiresAt`, `dtCreatedAt`) VALUES
(14, 'MTQ6MTc5MDU5MzI3ODo1OTZiODhhYjVhY2NlZTQ0ZjA5ZTZhMjY0YjQyNWRlNzUwZTZkZjVlMGZiMDAyYWI5OWFkNGNhOGY2YWQwZjc5', '2026-10-28 18:01:18', '2026-09-28 18:01:18'),
(17, 'MTc6MTc5MDU5Mzg2Njo0YzYyNjU0ZDExNDg2ZjE2YjFkZTRlNzRmMTJjYjY5NTFhMTdhNzU4NTIxY2M2ZWZjOWE1NWNjOWE4MjFlMjA4', '2026-10-28 18:11:05', '2026-09-28 00:59:55');

-- --------------------------------------------------------

--
-- Table structure for table `TbUserBadges`
--

CREATE TABLE `TbUserBadges` (
  `nUserBadgeId` int(11) NOT NULL AUTO_INCREMENT,
  `nUserId` int(11) NOT NULL,
  `nBadgeId` int(11) NOT NULL,
  `dtEarnedAt` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`nUserBadgeId`),
  KEY `nUserId` (`nUserId`),
  KEY `nBadgeId` (`nBadgeId`),
  CONSTRAINT `fk_userbadges_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE,
  CONSTRAINT `fk_userbadges_badge` FOREIGN KEY (`nBadgeId`) REFERENCES `TbBadges` (`nBadgeId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `TbUserBadges`
--

INSERT INTO `TbUserBadges` (`nUserBadgeId`, `nUserId`, `nBadgeId`, `dtEarnedAt`) VALUES
(2, 17, 2, '2026-09-28 00:05:38'),
(4, 14, 2, '2026-09-28 00:24:46');

-- --------------------------------------------------------

--
-- Table structure for table `TbUserPreferences`
--

CREATE TABLE `TbUserPreferences` (
  `nUserId` int(11) NOT NULL,
  `sUnitSystem` varchar(50) DEFAULT 'metric',
  `sUnitLabel` varchar(100) DEFAULT 'Kilometers, Kilograms',
  `sGeminiApiKey` text DEFAULT NULL,
  PRIMARY KEY (`nUserId`),
  CONSTRAINT `fk_userpreferences_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `TbUserPreferences`
--

INSERT INTO `TbUserPreferences` (`nUserId`, `sUnitSystem`, `sUnitLabel`, `sGeminiApiKey`) VALUES
(14, 'metric', 'Kilometers, Kilograms', ''),
(17, 'metric', 'Kilometers, Kilograms', '');

-- --------------------------------------------------------

--
-- Table structure for table `TbWorkouts`
--

CREATE TABLE `TbWorkouts` (
  `nWorkoutId` int(11) NOT NULL AUTO_INCREMENT,
  `nUserId` int(11) NOT NULL,
  `sType` varchar(50) NOT NULL,
  `nDistance` decimal(6,2) DEFAULT 0.00,
  `nDuration` int(11) DEFAULT 0,
  `nCaloriesBurned` decimal(6,2) DEFAULT 0.00,
  `sRoutePoints` longtext DEFAULT NULL,
  `isSynced` tinyint(1) DEFAULT 0,
  `dtUpdatedAt` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `dtWorkoutDate` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`nWorkoutId`),
  KEY `nUserId` (`nUserId`),
  CONSTRAINT `fk_workouts_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `TbWorkouts`
--

INSERT INTO `TbWorkouts` (`nWorkoutId`, `nUserId`, `sType`, `nDistance`, `nDuration`, `nCaloriesBurned`, `sRoutePoints`, `isSynced`, `dtUpdatedAt`, `dtWorkoutDate`) VALUES
(8, 17, 'เดินเร็ว (Brisk Walk)', 0.06, 161, 2.80, '[{\"lat\":6.8824911,\"lng\":101.2357188},{\"lat\":6.8824996,\"lng\":101.235757},{\"lat\":6.8825133,\"lng\":101.2357815},{\"lat\":6.8824955,\"lng\":101.2358055},{\"lat\":6.8824675,\"lng\":101.2358529},{\"lat\":6.8824348,\"lng\":101.2358678},{\"lat\":6.8824094,\"lng\":101.2358873},{\"lat\":6.8824101,\"lng\":101.2358598},{\"lat\":6.8824415,\"lng\":101.2358577},{\"lat\":6.8824194,\"lng\":101.2358761},{\"lat\":6.8824283,\"lng\":101.2358454},{\"lat\":6.8825092,\"lng\":101.2360124}]', 1, '2026-09-24 02:03:20', '2026-09-24 02:03:21'),
(10, 14, 'เดินเร็ว (Brisk Walk)', 0.05, 167, 2.10, '[{\"lat\":6.8824997,\"lng\":101.2357257},{\"lat\":6.8824999,\"lng\":101.2357533},{\"lat\":6.8824916,\"lng\":101.2357824},{\"lat\":6.882385,\"lng\":101.2358232},{\"lat\":6.8824283,\"lng\":101.2359002},{\"lat\":6.882456,\"lng\":101.2359899},{\"lat\":6.8824078,\"lng\":101.2360745}]', 1, '2026-09-24 02:04:11', '2026-09-24 02:04:11'),
(11, 14, 'วิ่งกลางแจ้ง (Outdoor Run)', 0.10, 114, 5.60, '[{\"lat\":6.882726,\"lng\":101.2377665},{\"lat\":6.8833717,\"lng\":101.2379833},{\"lat\":6.8833383,\"lng\":101.2381933}]', 1, '2026-09-24 13:36:58', '2026-09-24 02:12:46'),
(14, 14, 'เดินเร็ว (Brisk Walk)', 0.23, 616, 9.40, '[{\"lat\":6.8807767,\"lng\":101.2468433},{\"lat\":6.8807657,\"lng\":101.2468702},{\"lat\":6.88076,\"lng\":101.2468373},{\"lat\":6.8806944,\"lng\":101.2468366},{\"lat\":6.8807069,\"lng\":101.2468617},{\"lat\":6.8807707,\"lng\":101.2469251},{\"lat\":6.8807609,\"lng\":101.2468893},{\"lat\":6.880857,\"lng\":101.2468315},{\"lat\":6.8808413,\"lng\":101.2467435},{\"lat\":6.8808195,\"lng\":101.2466943},{\"lat\":6.8808435,\"lng\":101.2466503},{\"lat\":6.8808512,\"lng\":101.2466034},{\"lat\":6.8808397,\"lng\":101.2465459},{\"lat\":6.8808319,\"lng\":101.2464892},{\"lat\":6.8808181,\"lng\":101.2464405},{\"lat\":6.8807784,\"lng\":101.2464098},{\"lat\":6.8807616,\"lng\":101.2464454},{\"lat\":6.8807176,\"lng\":101.2464675},{\"lat\":6.8806905,\"lng\":101.2465004},{\"lat\":6.8806976,\"lng\":101.2465373},{\"lat\":6.8807226,\"lng\":101.246596},{\"lat\":6.8807307,\"lng\":101.2466247},{\"lat\":6.8807206,\"lng\":101.246547},{\"lat\":6.8807107,\"lng\":101.2464917},{\"lat\":6.8806971,\"lng\":101.246455},{\"lat\":6.8807359,\"lng\":101.24642},{\"lat\":6.8808026,\"lng\":101.2463806},{\"lat\":6.8808424,\"lng\":101.2463914},{\"lat\":6.880853,\"lng\":101.2464579},{\"lat\":6.8808613,\"lng\":101.2465245},{\"lat\":6.8808728,\"lng\":101.2465747},{\"lat\":6.8808986,\"lng\":101.2466324},{\"lat\":6.8809057,\"lng\":101.2466904},{\"lat\":6.8809053,\"lng\":101.2467495},{\"lat\":6.8809048,\"lng\":101.2468065},{\"lat\":6.8808994,\"lng\":101.2468596},{\"lat\":6.880859,\"lng\":101.2468608},{\"lat\":6.880785,\"lng\":101.2468443}]', 1, '2026-09-24 13:36:58', '2026-09-24 02:26:11'),
(17, 17, 'เดินเร็ว (Brisk Walk)', 0.03, 95, 1.70, '[{\"lat\":6.8825393,\"lng\":101.2357614},{\"lat\":6.8825512,\"lng\":101.2358046},{\"lat\":6.8825934,\"lng\":101.2358366},{\"lat\":6.8826352,\"lng\":101.2358915},{\"lat\":6.882619,\"lng\":101.235858},{\"lat\":6.8825721,\"lng\":101.2358499},{\"lat\":6.88253,\"lng\":101.235805}]', 1, '2026-09-24 17:43:19', '2026-09-24 17:43:20'),
(20, 17, 'เดินเร็ว (Brisk Walk)', 0.34, 199, 16.40, '[{\"lat\":6.876491,\"lng\":101.2338446},{\"lat\":6.8765276,\"lng\":101.2339501},{\"lat\":6.877269,\"lng\":101.23495},{\"lat\":6.8765839,\"lng\":101.2343935},{\"lat\":6.8764871,\"lng\":101.2343044},{\"lat\":6.8764471,\"lng\":101.2343083},{\"lat\":6.8764738,\"lng\":101.2343209},{\"lat\":6.8764549,\"lng\":101.2343504},{\"lat\":6.8764386,\"lng\":101.2343753},{\"lat\":6.876457,\"lng\":101.2343998},{\"lat\":6.8764756,\"lng\":101.2344217},{\"lat\":6.8764774,\"lng\":101.23445},{\"lat\":6.8764868,\"lng\":101.2344771},{\"lat\":6.876412,\"lng\":101.2340721}]', 1, '2026-09-24 18:31:08', '2026-09-24 18:31:09'),
(22, 14, 'วิ่งกลางแจ้ง (Outdoor Run)', 0.00, 16, 0.00, '[{\"lat\":6.8825102,\"lng\":101.2357306}]', 1, '2026-09-24 21:56:18', '2026-09-24 21:56:18'),
(25, 14, 'เดินเร็ว (Brisk Walk)', 0.07, 101, 2.90, '[{\"lat\":6.8825092,\"lng\":101.2357394},{\"lat\":6.8825085,\"lng\":101.2357677},{\"lat\":6.882473,\"lng\":101.2357899},{\"lat\":6.8825,\"lng\":101.235795},{\"lat\":6.8825369,\"lng\":101.2358218},{\"lat\":6.8825709,\"lng\":101.2358497},{\"lat\":6.882587,\"lng\":101.2358888},{\"lat\":6.8826096,\"lng\":101.23593},{\"lat\":6.8826404,\"lng\":101.2359495},{\"lat\":6.8826358,\"lng\":101.2359781},{\"lat\":6.8825876,\"lng\":101.2359554},{\"lat\":6.8825926,\"lng\":101.2359287},{\"lat\":6.8825417,\"lng\":101.2359197},{\"lat\":6.8824959,\"lng\":101.2358966},{\"lat\":6.8824809,\"lng\":101.2358615},{\"lat\":6.8824678,\"lng\":101.2358336},{\"lat\":6.8824679,\"lng\":101.2358627}]', 1, '2026-09-24 22:01:07', '2026-09-24 22:01:07'),
(26, 14, 'เดินเร็ว (Brisk Walk)', 0.13, 207, 5.40, '[{\"lat\":6.8825753,\"lng\":101.2358504},{\"lat\":6.8826225,\"lng\":101.2358961},{\"lat\":6.8826797,\"lng\":101.2359227},{\"lat\":6.8827291,\"lng\":101.2359285},{\"lat\":6.8827487,\"lng\":101.2359603},{\"lat\":6.8827208,\"lng\":101.235988},{\"lat\":6.8826831,\"lng\":101.2360227},{\"lat\":6.8826665,\"lng\":101.2359659},{\"lat\":6.8826944,\"lng\":101.2359646},{\"lat\":6.8827393,\"lng\":101.2359348},{\"lat\":6.8827176,\"lng\":101.2359133},{\"lat\":6.8826848,\"lng\":101.2359188},{\"lat\":6.8826265,\"lng\":101.2359036},{\"lat\":6.8826131,\"lng\":101.2358703},{\"lat\":6.8825843,\"lng\":101.2358121},{\"lat\":6.8825196,\"lng\":101.2358085},{\"lat\":6.8824956,\"lng\":101.2358469},{\"lat\":6.8824872,\"lng\":101.2358759},{\"lat\":6.8824357,\"lng\":101.2359195},{\"lat\":6.8824349,\"lng\":101.2358901},{\"lat\":6.8824803,\"lng\":101.2358261},{\"lat\":6.8825224,\"lng\":101.2357852},{\"lat\":6.8825474,\"lng\":101.235763},{\"lat\":6.882543,\"lng\":101.2357922},{\"lat\":6.8825081,\"lng\":101.2358226},{\"lat\":6.8824993,\"lng\":101.235854}]', 1, '2026-09-25 01:29:04', '2026-09-25 01:29:04'),
(29, 14, 'เดินเร็ว (Brisk Walk)', 0.19, 231, 7.80, '[{\"lat\":6.8810186,\"lng\":101.2464395},{\"lat\":6.8809406,\"lng\":101.2465631},{\"lat\":6.8808993,\"lng\":101.2465837},{\"lat\":6.8809031,\"lng\":101.246487},{\"lat\":6.8809008,\"lng\":101.2464502},{\"lat\":6.8808752,\"lng\":101.2464278},{\"lat\":6.8808549,\"lng\":101.2464766},{\"lat\":6.880812,\"lng\":101.2464996},{\"lat\":6.8807646,\"lng\":101.2465009},{\"lat\":6.8807167,\"lng\":101.2465016},{\"lat\":6.8807521,\"lng\":101.2465031},{\"lat\":6.8807778,\"lng\":101.2465146},{\"lat\":6.8807717,\"lng\":101.2465556},{\"lat\":6.8807784,\"lng\":101.2465932},{\"lat\":6.8807917,\"lng\":101.2466177},{\"lat\":6.8806547,\"lng\":101.246422},{\"lat\":6.8808467,\"lng\":101.2465383},{\"lat\":6.8810036,\"lng\":101.2465566},{\"lat\":6.8810317,\"lng\":101.2465845},{\"lat\":6.8810041,\"lng\":101.246655},{\"lat\":6.8809128,\"lng\":101.2467381},{\"lat\":6.8809252,\"lng\":101.2467967},{\"lat\":6.8809181,\"lng\":101.2468526}]', 1, '2026-09-25 20:04:07', '2026-09-25 08:48:16'),
(32, 14, 'เดินเร็ว (Brisk Walk)', 0.19, 231, 7.80, '[{\"lat\":6.8810186,\"lng\":101.2464395},{\"lat\":6.8809406,\"lng\":101.2465631},{\"lat\":6.8808993,\"lng\":101.2465837},{\"lat\":6.8809031,\"lng\":101.246487},{\"lat\":6.8809008,\"lng\":101.2464502},{\"lat\":6.8808752,\"lng\":101.2464278},{\"lat\":6.8808549,\"lng\":101.2464766},{\"lat\":6.880812,\"lng\":101.2464996},{\"lat\":6.8807646,\"lng\":101.2465009},{\"lat\":6.8807167,\"lng\":101.2465016},{\"lat\":6.8807521,\"lng\":101.2465031},{\"lat\":6.8807778,\"lng\":101.2465146},{\"lat\":6.8807717,\"lng\":101.2465556},{\"lat\":6.8807784,\"lng\":101.2465932},{\"lat\":6.8807917,\"lng\":101.2466177},{\"lat\":6.8806547,\"lng\":101.246422},{\"lat\":6.8808467,\"lng\":101.2465383},{\"lat\":6.8810036,\"lng\":101.2465566},{\"lat\":6.8810317,\"lng\":101.2465845},{\"lat\":6.8810041,\"lng\":101.246655},{\"lat\":6.8809128,\"lng\":101.2467381},{\"lat\":6.8809252,\"lng\":101.2467967},{\"lat\":6.8809181,\"lng\":101.2468526}]', 1, '2026-09-25 20:04:07', '2026-09-25 08:48:16'),
(33, 14, 'เดินเร็ว (Brisk Walk)', 0.06, 196, 2.20, '[{\"lat\":6.8825139,\"lng\":101.2357979},{\"lat\":6.8824861,\"lng\":101.2357979},{\"lat\":6.8824179,\"lng\":101.2358676},{\"lat\":6.8823907,\"lng\":101.2359016},{\"lat\":6.8823572,\"lng\":101.2358765},{\"lat\":6.882378,\"lng\":101.2358543},{\"lat\":6.8824077,\"lng\":101.2358352},{\"lat\":6.8824755,\"lng\":101.235805},{\"lat\":6.8824385,\"lng\":101.2358293},{\"lat\":6.882397,\"lng\":101.2358406},{\"lat\":6.8824292,\"lng\":101.2358337},{\"lat\":6.8824557,\"lng\":101.2358128},{\"lat\":6.8824393,\"lng\":101.2358346}]', 1, '2026-09-26 00:54:51', '2026-09-26 00:54:50'),
(34, 14, 'ทำสมาธิ (Meditation)', 0.00, 73, 1.10, '[]', 1, '2026-09-26 20:02:32', '2026-09-26 15:20:16'),
(37, 14, 'วิ่ง (Running)', 0.01, 64, 2.90, '[{\"lat\":6.8808141,\"lng\":101.2468722},{\"lat\":6.8807165,\"lng\":101.2468619}]', 1, '2026-09-26 20:02:32', '2026-09-26 19:27:41'),
(40, 14, 'เดิน (Walking)', 0.06, 224, 7.10, '[{\"lat\":6.8825794,\"lng\":101.235825},{\"lat\":6.8826485,\"lng\":101.2359501},{\"lat\":6.882595,\"lng\":101.2358433},{\"lat\":6.882498,\"lng\":101.2358153},{\"lat\":6.8824371,\"lng\":101.235894},{\"lat\":6.8824939,\"lng\":101.2358102}]', 1, '2026-09-27 00:16:50', '2026-09-27 00:16:50'),
(42, 14, 'เดิน (Walking)', 0.08, 128, 6.80, '[{\"lat\":6.8824902,\"lng\":101.2358494},{\"lat\":6.8823747,\"lng\":101.2358844},{\"lat\":6.8824676,\"lng\":101.2358233},{\"lat\":6.8825229,\"lng\":101.2357549},{\"lat\":6.8825154,\"lng\":101.2358397},{\"lat\":6.8825909,\"lng\":101.235896},{\"lat\":6.8826408,\"lng\":101.2359429},{\"lat\":6.8825987,\"lng\":101.2359243},{\"lat\":6.8825249,\"lng\":101.235863}]', 1, '2026-09-27 00:43:09', '2026-09-27 00:43:07'),
(43, 14, 'เดิน (Walking)', 0.05, 71, 2.20, '[{\"lat\":6.8825025,\"lng\":101.2360289},{\"lat\":6.8824319,\"lng\":101.235967},{\"lat\":6.8823783,\"lng\":101.2359053},{\"lat\":6.882424,\"lng\":101.2359118},{\"lat\":6.8824704,\"lng\":101.2359448},{\"lat\":6.8824722,\"lng\":101.2359997},{\"lat\":6.8824239,\"lng\":101.2360349},{\"lat\":6.882378,\"lng\":101.2360431}]', 1, '2026-09-27 01:33:20', '2026-09-27 01:33:20'),
(46, 14, 'เดิน (Walking)', 0.07, 238, 4.30, '[{\"lat\":6.8825922,\"lng\":101.2358332},{\"lat\":6.8826419,\"lng\":101.2359263},{\"lat\":6.8825197,\"lng\":101.2357858},{\"lat\":6.8823417,\"lng\":101.2356783},{\"lat\":6.8825011,\"lng\":101.235724}]', 1, '2026-09-27 15:27:30', '2026-09-27 15:27:30'),
(49, 14, 'เดิน (Walking)', 0.06, 154, 4.10, '[{\"lat\":6.8825047,\"lng\":101.2357419},{\"lat\":6.8823901,\"lng\":101.2358289},{\"lat\":6.8823901,\"lng\":101.2358289},{\"lat\":6.8823398,\"lng\":101.2358821},{\"lat\":6.8823001,\"lng\":101.235966},{\"lat\":6.8822476,\"lng\":101.2359384},{\"lat\":6.8822647,\"lng\":101.2359833},{\"lat\":6.8823053,\"lng\":101.23601},{\"lat\":6.8823578,\"lng\":101.236006}]', 1, '2026-09-27 17:27:00', '2026-09-27 17:27:00'),
(52, 14, 'เดิน (Walking)', 0.36, 2201, 42.60, '[{\"lat\":6.86089,\"lng\":101.2314477},{\"lat\":6.8609783,\"lng\":101.2313183},{\"lat\":6.8610252,\"lng\":101.2313433},{\"lat\":6.8610703,\"lng\":101.2313383},{\"lat\":6.8611175,\"lng\":101.2313416},{\"lat\":6.8611764,\"lng\":101.2313294},{\"lat\":6.8612192,\"lng\":101.231272},{\"lat\":6.8618475,\"lng\":101.2314165},{\"lat\":6.8619363,\"lng\":101.231544},{\"lat\":6.8620515,\"lng\":101.2315379},{\"lat\":6.8619672,\"lng\":101.2316228},{\"lat\":6.8619047,\"lng\":101.2317252},{\"lat\":6.861806,\"lng\":101.2317136},{\"lat\":6.8618783,\"lng\":101.2316518},{\"lat\":6.8615476,\"lng\":101.2314419},{\"lat\":6.8614759,\"lng\":101.2313932},{\"lat\":6.8614994,\"lng\":101.2313003},{\"lat\":6.8616014,\"lng\":101.2312252},{\"lat\":6.8616674,\"lng\":101.2311682},{\"lat\":6.8612361,\"lng\":101.2313644},{\"lat\":6.861177,\"lng\":101.2313263},{\"lat\":6.8611297,\"lng\":101.2313168},{\"lat\":6.8611132,\"lng\":101.2313626},{\"lat\":6.8611532,\"lng\":101.2313879}]', 1, '2026-09-27 20:14:37', '2026-09-27 18:32:46'),
(55, 17, 'เดิน (Walking)', 0.19, 489, 11.80, '[{\"lat\":6.8610147,\"lng\":101.2313071},{\"lat\":6.8609444,\"lng\":101.231393},{\"lat\":6.8615433,\"lng\":101.2314144},{\"lat\":6.8617124,\"lng\":101.2316831},{\"lat\":6.861788,\"lng\":101.2317258},{\"lat\":6.8618854,\"lng\":101.231682},{\"lat\":6.8619863,\"lng\":101.2316651},{\"lat\":6.8620604,\"lng\":101.2316335},{\"lat\":6.8621452,\"lng\":101.2315968},{\"lat\":6.8620201,\"lng\":101.2315734},{\"lat\":6.8620283,\"lng\":101.2316238}]', 1, '2026-09-27 23:26:33', '2026-09-27 17:51:44'),
(58, 17, 'ทำสมาธิ (Meditation)', 0.00, 51, 0.80, '[{\"lat\":6.8825044,\"lng\":101.2357369}]', 1, '2026-09-28 00:05:38', '2026-09-28 00:05:39'),
(61, 17, 'ทำสมาธิ (Meditation)', 0.00, 51, 0.80, '[{\"lat\":6.8825044,\"lng\":101.2357369}]', 1, '2026-09-28 00:05:39', '2026-09-28 00:05:39'),
(64, 14, 'ทำสมาธิ (Meditation)', 0.00, 60, 0.90, '[{\"lat\":6.8825151,\"lng\":101.2357355}]', 1, '2026-09-28 00:24:46', '2026-09-28 00:24:45'),
(67, 14, 'ทำสมาธิ (Meditation)', 0.00, 60, 0.90, '[{\"lat\":6.8825151,\"lng\":101.2357355}]', 1, '2026-09-28 00:24:46', '2026-09-28 00:24:45');

COMMIT;

SET FOREIGN_KEY_CHECKS = 1;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
