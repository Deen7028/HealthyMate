SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

DROP TABLE IF EXISTS `TbWorkoutCategories`;
DROP TABLE IF EXISTS `TbWorkouts`;
DROP TABLE IF EXISTS `TbUserPreferences`;
DROP TABLE IF EXISTS `TbUserBadges`;
DROP TABLE IF EXISTS `TbSession`;
DROP TABLE IF EXISTS `tbsession`;
DROP TABLE IF EXISTS `TbRoutineLogs`;
DROP TABLE IF EXISTS `TbNutritionLogs`;
DROP TABLE IF EXISTS `TbHealthRecords`;
DROP TABLE IF EXISTS `TbHealthIntegrations`;
DROP TABLE IF EXISTS `TbGoals`;
DROP TABLE IF EXISTS `TbRoutines`;
DROP TABLE IF EXISTS `TbEmailOtps`;
DROP TABLE IF EXISTS `TbBadges`;
DROP TABLE IF EXISTS `TbUsers`;

CREATE TABLE IF NOT EXISTS `TbUsers` (
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

CREATE TABLE IF NOT EXISTS `TbBadges` (
  `nBadgeId` int(11) NOT NULL AUTO_INCREMENT,
  `sBadgeName` varchar(100) NOT NULL,
  `sDescription` varchar(255) DEFAULT NULL,
  `sIconUrl` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`nBadgeId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `TbEmailOtps` (
  `nOtpId` int(11) NOT NULL AUTO_INCREMENT,
  `sEmail` varchar(150) NOT NULL,
  `sOtpCode` varchar(6) NOT NULL,
  `nAttempts` int(11) DEFAULT 0,
  `isUsed` tinyint(1) DEFAULT 0,
  `dtExpiresAt` datetime NOT NULL,
  `dtCreatedAt` datetime DEFAULT current_timestamp(),
  `sIpAddress` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`nOtpId`),
  KEY `idx_email_status` (`sEmail`,`isUsed`,`dtExpiresAt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `TbRoutines` (
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

CREATE TABLE IF NOT EXISTS `TbGoals` (
  `nGoalId` int(11) NOT NULL AUTO_INCREMENT,
  `nUserId` int(11) NOT NULL,
  `sTitle` varchar(255) NOT NULL,
  `nProgress` decimal(5,2) DEFAULT 0.00,
  `sRemainingText` varchar(255) DEFAULT NULL,
  `dtCreatedAt` datetime DEFAULT current_timestamp(),
  `dtUpdatedAt` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `nRoutineId` int(11) DEFAULT NULL,
  PRIMARY KEY (`nGoalId`),
  KEY `nUserId` (`nUserId`),
  KEY `fk_goals_routine` (`nRoutineId`),
  CONSTRAINT `fk_goals_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE,
  CONSTRAINT `fk_goals_routine` FOREIGN KEY (`nRoutineId`) REFERENCES `TbRoutines` (`nRoutineId`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `TbHealthIntegrations` (
  `nIntegrationId` int(11) NOT NULL AUTO_INCREMENT,
  `nUserId` int(11) NOT NULL,
  `sProviderName` varchar(50) NOT NULL,
  `isSynced` tinyint(1) DEFAULT 0,
  `dtLastSyncedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`nIntegrationId`),
  KEY `nUserId` (`nUserId`),
  CONSTRAINT `fk_integrations_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `TbHealthRecords` (
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

CREATE TABLE IF NOT EXISTS `TbNutritionLogs` (
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

CREATE TABLE IF NOT EXISTS `TbRoutineLogs` (
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

CREATE TABLE IF NOT EXISTS `TbSession` (
  `nUserId` int(11) NOT NULL,
  `sToken` text NOT NULL,
  `dtExpiresAt` datetime NOT NULL,
  `dtCreatedAt` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`nUserId`),
  CONSTRAINT `fk_session_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `TbUserBadges` (
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

CREATE TABLE IF NOT EXISTS `TbUserPreferences` (
  `nUserId` int(11) NOT NULL,
  `sUnitSystem` varchar(50) DEFAULT 'metric',
  `sUnitLabel` varchar(100) DEFAULT 'Kilometers, Kilograms',
  `sGeminiApiKey` text DEFAULT NULL,
  PRIMARY KEY (`nUserId`),
  CONSTRAINT `fk_userpreferences_user` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `TbWorkouts` (
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

CREATE TABLE IF NOT EXISTS `TbWorkoutCategories` (
  `nCategoryId` int(11) NOT NULL AUTO_INCREMENT,
  `sCategoryId` varchar(50) NOT NULL,
  `sTitle` varchar(100) NOT NULL,
  `sSubtitle` varchar(255) DEFAULT NULL,
  `sIconName` varchar(50) DEFAULT 'directions_run',
  `nIconCodePoint` int(11) DEFAULT 57904,
  `nMetValue` decimal(4,2) DEFAULT 1.00,
  `isMoving` tinyint(1) DEFAULT 0,
  `dtCreatedAt` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`nCategoryId`),
  UNIQUE KEY `sCategoryId` (`sCategoryId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

SET FOREIGN_KEY_CHECKS = 1;