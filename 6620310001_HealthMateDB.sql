-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 172.18.111.42:3306
-- Generation Time: Sep 20, 2026 at 03:30 PM
-- Server version: 10.11.14-MariaDB-0ubuntu0.24.04.1
-- PHP Version: 8.3.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `6620310001_HealthMateDB`
--

-- --------------------------------------------------------

--
-- Table structure for table `TbUsers`
--

CREATE TABLE `TbUsers` (
  `nUserId` int(11) NOT NULL,
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
  `sProfileImagePath` text DEFAULT '',
  `isSynced` tinyint(1) DEFAULT 0,
  `dtUpdatedAt` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `dtCreatedAt` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbGoals`
--

CREATE TABLE `TbGoals` (
  `nGoalId` int(11) NOT NULL,
  `nUserId` int(11) NOT NULL,
  `sTitle` varchar(255) NOT NULL,
  `nProgress` decimal(5,2) DEFAULT 0.00,
  `sRemainingText` varchar(255) DEFAULT NULL,
  `dtUpdatedAt` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbUserPreferences`
--

CREATE TABLE `TbUserPreferences` (
  `nUserId` int(11) NOT NULL,
  `sUnitSystem` varchar(50) DEFAULT 'metric',
  `sUnitLabel` varchar(100) DEFAULT 'Kilometers, Kilograms',
  `sGeminiApiKey` text DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbSession`
--

CREATE TABLE `TbSession` (
  `nSessionId` int(11) NOT NULL DEFAULT 1,
  `isLoggedIn` tinyint(1) DEFAULT 0,
  `sEmail` varchar(255) DEFAULT NULL,
  `dtUpdatedAt` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbBadges`
--

CREATE TABLE `TbBadges` (
  `nBadgeId` int(11) NOT NULL,
  `sBadgeName` varchar(100) NOT NULL,
  `sDescription` varchar(255) DEFAULT NULL,
  `sIconUrl` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbHealthIntegrations`
--

CREATE TABLE `TbHealthIntegrations` (
  `nIntegrationId` int(11) NOT NULL,
  `nUserId` int(11) NOT NULL,
  `sProviderName` varchar(50) NOT NULL,
  `isSynced` tinyint(1) DEFAULT 0,
  `dtLastSyncedAt` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbHealthRecords`
--

CREATE TABLE `TbHealthRecords` (
  `nRecordId` int(11) NOT NULL,
  `nUserId` int(11) NOT NULL,
  `nWeight` decimal(5,2) DEFAULT NULL,
  `nHeight` decimal(5,2) DEFAULT NULL,
  `nBmi` decimal(4,2) DEFAULT NULL,
  `nTdee` decimal(6,2) DEFAULT NULL,
  `computedBmr` decimal(6,2) DEFAULT NULL,
  `activityLevelTitle` varchar(100) DEFAULT NULL,
  `isSynced` tinyint(1) DEFAULT 0,
  `dtUpdatedAt` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `dtRecordedAt` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbNutritionLogs`
--

CREATE TABLE `TbNutritionLogs` (
  `nNutritionId` int(11) NOT NULL,
  `nUserId` int(11) NOT NULL,
  `sMealType` varchar(50) NOT NULL,
  `sFoodName` varchar(150) NOT NULL,
  `nCalories` int(11) NOT NULL,
  `nProtein` decimal(5,2) DEFAULT 0.00,
  `nCarbs` decimal(5,2) DEFAULT 0.00,
  `nFat` decimal(5,2) DEFAULT 0.00,
  `sServingSize` varchar(100) DEFAULT '',
  `sImagePath` text DEFAULT '',
  `isSynced` tinyint(1) DEFAULT 0,
  `dtUpdatedAt` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `dtLoggedAt` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbRoutines`
--

CREATE TABLE `TbRoutines` (
  `nRoutineId` int(11) NOT NULL,
  `nUserId` int(11) NOT NULL,
  `sTitle` varchar(150) NOT NULL,
  `sTime` varchar(10) DEFAULT NULL,
  `isNotificationActive` tinyint(1) DEFAULT 1,
  `dtCreatedAt` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbRoutineLogs`
--

CREATE TABLE `TbRoutineLogs` (
  `nLogId` int(11) NOT NULL,
  `nRoutineId` int(11) NOT NULL,
  `isCompleted` tinyint(1) DEFAULT 0,
  `dtLogDate` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbUserBadges`
--

CREATE TABLE `TbUserBadges` (
  `nUserBadgeId` int(11) NOT NULL,
  `nUserId` int(11) NOT NULL,
  `nBadgeId` int(11) NOT NULL,
  `dtEarnedAt` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TbWorkouts`
--

CREATE TABLE `TbWorkouts` (
  `nWorkoutId` int(11) NOT NULL,
  `nUserId` int(11) NOT NULL,
  `sType` varchar(50) NOT NULL,
  `nDistance` decimal(6,2) DEFAULT 0.00,
  `nDuration` int(11) DEFAULT 0,
  `nCaloriesBurned` decimal(6,2) DEFAULT 0.00,
  `sRoutePoints` longtext DEFAULT '',
  `isSynced` tinyint(1) DEFAULT 0,
  `dtUpdatedAt` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `dtWorkoutDate` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `TbUsers`
--
ALTER TABLE `TbUsers`
  ADD PRIMARY KEY (`nUserId`),
  ADD UNIQUE KEY `sEmail` (`sEmail`);

--
-- Indexes for table `TbGoals`
--
ALTER TABLE `TbGoals`
  ADD PRIMARY KEY (`nGoalId`),
  ADD KEY `nUserId` (`nUserId`);

--
-- Indexes for table `TbUserPreferences`
--
ALTER TABLE `TbUserPreferences`
  ADD PRIMARY KEY (`nUserId`);

--
-- Indexes for table `TbSession`
--
ALTER TABLE `TbSession`
  ADD PRIMARY KEY (`nSessionId`);

--
-- Indexes for table `TbBadges`
--
ALTER TABLE `TbBadges`
  ADD PRIMARY KEY (`nBadgeId`);

--
-- Indexes for table `TbHealthIntegrations`
--
ALTER TABLE `TbHealthIntegrations`
  ADD PRIMARY KEY (`nIntegrationId`),
  ADD KEY `nUserId` (`nUserId`);

--
-- Indexes for table `TbHealthRecords`
--
ALTER TABLE `TbHealthRecords`
  ADD PRIMARY KEY (`nRecordId`),
  ADD KEY `nUserId` (`nUserId`);

--
-- Indexes for table `TbNutritionLogs`
--
ALTER TABLE `TbNutritionLogs`
  ADD PRIMARY KEY (`nNutritionId`),
  ADD KEY `nUserId` (`nUserId`);

--
-- Indexes for table `TbRoutines`
--
ALTER TABLE `TbRoutines`
  ADD PRIMARY KEY (`nRoutineId`),
  ADD KEY `nUserId` (`nUserId`);

--
-- Indexes for table `TbRoutineLogs`
--
ALTER TABLE `TbRoutineLogs`
  ADD PRIMARY KEY (`nLogId`),
  ADD KEY `nRoutineId` (`nRoutineId`);

--
-- Indexes for table `TbUserBadges`
--
ALTER TABLE `TbUserBadges`
  ADD PRIMARY KEY (`nUserBadgeId`),
  ADD KEY `nUserId` (`nUserId`),
  ADD KEY `nBadgeId` (`nBadgeId`);

--
-- Indexes for table `TbWorkouts`
--
ALTER TABLE `TbWorkouts`
  ADD PRIMARY KEY (`nWorkoutId`),
  ADD KEY `nUserId` (`nUserId`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `TbUsers`
--
ALTER TABLE `TbUsers`
  MODIFY `nUserId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `TbGoals`
--
ALTER TABLE `TbGoals`
  MODIFY `nGoalId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `TbBadges`
--
ALTER TABLE `TbBadges`
  MODIFY `nBadgeId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `TbHealthIntegrations`
--
ALTER TABLE `TbHealthIntegrations`
  MODIFY `nIntegrationId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `TbHealthRecords`
--
ALTER TABLE `TbHealthRecords`
  MODIFY `nRecordId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `TbNutritionLogs`
--
ALTER TABLE `TbNutritionLogs`
  MODIFY `nNutritionId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `TbRoutines`
--
ALTER TABLE `TbRoutines`
  MODIFY `nRoutineId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `TbRoutineLogs`
--
ALTER TABLE `TbRoutineLogs`
  MODIFY `nLogId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `TbUserBadges`
--
ALTER TABLE `TbUserBadges`
  MODIFY `nUserBadgeId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `TbWorkouts`
--
ALTER TABLE `TbWorkouts`
  MODIFY `nWorkoutId` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `TbGoals`
--
ALTER TABLE `TbGoals`
  ADD CONSTRAINT `TbGoals_ibfk_1` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE;

--
-- Constraints for table `TbUserPreferences`
--
ALTER TABLE `TbUserPreferences`
  ADD CONSTRAINT `TbUserPreferences_ibfk_1` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE;

--
-- Constraints for table `TbHealthIntegrations`
--
ALTER TABLE `TbHealthIntegrations`
  ADD CONSTRAINT `TbHealthIntegrations_ibfk_1` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE;

--
-- Constraints for table `TbHealthRecords`
--
ALTER TABLE `TbHealthRecords`
  ADD CONSTRAINT `TbHealthRecords_ibfk_1` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE;

--
-- Constraints for table `TbNutritionLogs`
--
ALTER TABLE `TbNutritionLogs`
  ADD CONSTRAINT `TbNutritionLogs_ibfk_1` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE;

--
-- Constraints for table `TbRoutines`
--
ALTER TABLE `TbRoutines`
  ADD CONSTRAINT `TbRoutines_ibfk_1` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE;

--
-- Constraints for table `TbRoutineLogs`
--
ALTER TABLE `TbRoutineLogs`
  ADD CONSTRAINT `TbRoutineLogs_ibfk_1` FOREIGN KEY (`nRoutineId`) REFERENCES `TbRoutines` (`nRoutineId`) ON DELETE CASCADE;

--
-- Constraints for table `TbUserBadges`
--
ALTER TABLE `TbUserBadges`
  ADD CONSTRAINT `TbUserBadges_ibfk_1` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE,
  ADD CONSTRAINT `TbUserBadges_ibfk_2` FOREIGN KEY (`nBadgeId`) REFERENCES `TbBadges` (`nBadgeId`) ON DELETE CASCADE;

--
-- Constraints for table `TbWorkouts`
--
ALTER TABLE `TbWorkouts`
  ADD CONSTRAINT `TbWorkouts_ibfk_1` FOREIGN KEY (`nUserId`) REFERENCES `TbUsers` (`nUserId`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
