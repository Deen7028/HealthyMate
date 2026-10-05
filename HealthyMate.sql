-- PostgreSQL Database Schema (DDL) for HealthyMate

DROP TABLE IF EXISTS "TbWorkoutCategories" CASCADE;
DROP TABLE IF EXISTS "TbWorkouts" CASCADE;
DROP TABLE IF EXISTS "TbUserPreferences" CASCADE;
DROP TABLE IF EXISTS "TbUserBadges" CASCADE;
DROP TABLE IF EXISTS "TbSession" CASCADE;
DROP TABLE IF EXISTS "tbsession" CASCADE;
DROP TABLE IF EXISTS "TbRoutineLogs" CASCADE;
DROP TABLE IF EXISTS "TbNutritionLogs" CASCADE;
DROP TABLE IF EXISTS "TbHealthRecords" CASCADE;
DROP TABLE IF EXISTS "TbHealthIntegrations" CASCADE;
DROP TABLE IF EXISTS "TbGoals" CASCADE;
DROP TABLE IF EXISTS "TbRoutines" CASCADE;
DROP TABLE IF EXISTS "TbEmailOtps" CASCADE;
DROP TABLE IF EXISTS "TbBadges" CASCADE;
DROP TABLE IF EXISTS "TbUsers" CASCADE;

-- 1. Table structure for table "TbUsers"
CREATE TABLE IF NOT EXISTS "TbUsers" (
  "nUserId" SERIAL PRIMARY KEY,
  "sEmail" VARCHAR(255) NOT NULL UNIQUE,
  "sPasswordHash" VARCHAR(255) DEFAULT NULL,
  "sFirstName" VARCHAR(100) NOT NULL,
  "sLastName" VARCHAR(100) NOT NULL,
  "nAge" INT DEFAULT NULL,
  "nHeight" DECIMAL(5,2) DEFAULT NULL,
  "nWeight" DECIMAL(5,2) DEFAULT NULL,
  "sGender" VARCHAR(20) DEFAULT NULL,
  "sActivityLevel" VARCHAR(50) DEFAULT NULL,
  "isDarkMode" BOOLEAN DEFAULT FALSE,
  "sProfileImagePath" TEXT DEFAULT NULL,
  "isSynced" BOOLEAN DEFAULT FALSE,
  "dtUpdatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "dtCreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Table structure for table "TbBadges"
CREATE TABLE IF NOT EXISTS "TbBadges" (
  "nBadgeId" SERIAL PRIMARY KEY,
  "sBadgeName" VARCHAR(100) NOT NULL,
  "sDescription" VARCHAR(255) DEFAULT NULL,
  "sIconUrl" VARCHAR(255) DEFAULT NULL
);

-- 3. Table structure for table "TbEmailOtps"
CREATE TABLE IF NOT EXISTS "TbEmailOtps" (
  "nOtpId" SERIAL PRIMARY KEY,
  "sEmail" VARCHAR(150) NOT NULL,
  "sOtpCode" VARCHAR(6) NOT NULL,
  "nAttempts" INT DEFAULT 0,
  "isUsed" BOOLEAN DEFAULT FALSE,
  "dtExpiresAt" TIMESTAMP NOT NULL,
  "dtCreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "sIpAddress" VARCHAR(45) DEFAULT NULL
);
CREATE INDEX "idx_email_status" ON "TbEmailOtps" ("sEmail", "isUsed", "dtExpiresAt");

-- 4. Table structure for table "TbRoutines"
CREATE TABLE IF NOT EXISTS "TbRoutines" (
  "nRoutineId" SERIAL PRIMARY KEY,
  "nUserId" INT NOT NULL,
  "sTitle" VARCHAR(150) NOT NULL,
  "sTime" VARCHAR(255) DEFAULT NULL,
  "isNotificationActive" BOOLEAN DEFAULT TRUE,
  "dtCreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "nTargetValue" DOUBLE PRECISION DEFAULT 1,
  "sUnit" VARCHAR(50) DEFAULT 'ครั้ง',
  "sLinkedWorkout" VARCHAR(100) DEFAULT '',
  "nColor" BIGINT DEFAULT NULL,
  "nIconData" BIGINT DEFAULT NULL,
  CONSTRAINT "fk_routines_user" FOREIGN KEY ("nUserId") REFERENCES "TbUsers" ("nUserId") ON DELETE CASCADE
);
CREATE INDEX "idx_routines_user" ON "TbRoutines" ("nUserId");

-- 5. Table structure for table "TbGoals"
CREATE TABLE IF NOT EXISTS "TbGoals" (
  "nGoalId" SERIAL PRIMARY KEY,
  "nUserId" INT NOT NULL,
  "sTitle" VARCHAR(255) NOT NULL,
  "nProgress" DECIMAL(5,2) DEFAULT 0.00,
  "sRemainingText" VARCHAR(255) DEFAULT NULL,
  "dtCreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "dtUpdatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "nRoutineId" INT DEFAULT NULL,
  CONSTRAINT "fk_goals_user" FOREIGN KEY ("nUserId") REFERENCES "TbUsers" ("nUserId") ON DELETE CASCADE,
  CONSTRAINT "fk_goals_routine" FOREIGN KEY ("nRoutineId") REFERENCES "TbRoutines" ("nRoutineId") ON DELETE SET NULL
);
CREATE INDEX "idx_goals_user" ON "TbGoals" ("nUserId");
CREATE INDEX "idx_goals_routine" ON "TbGoals" ("nRoutineId");

-- 6. Table structure for table "TbHealthIntegrations"
CREATE TABLE IF NOT EXISTS "TbHealthIntegrations" (
  "nIntegrationId" SERIAL PRIMARY KEY,
  "nUserId" INT NOT NULL,
  "sProviderName" VARCHAR(50) NOT NULL,
  "isSynced" BOOLEAN DEFAULT FALSE,
  "dtLastSyncedAt" TIMESTAMP DEFAULT NULL,
  CONSTRAINT "fk_integrations_user" FOREIGN KEY ("nUserId") REFERENCES "TbUsers" ("nUserId") ON DELETE CASCADE
);
CREATE INDEX "idx_integrations_user" ON "TbHealthIntegrations" ("nUserId");

-- 7. Table structure for table "TbHealthRecords"
CREATE TABLE IF NOT EXISTS "TbHealthRecords" (
  "nRecordId" SERIAL PRIMARY KEY,
  "nUserId" INT NOT NULL,
  "nWeight" DECIMAL(5,2) DEFAULT NULL,
  "nHeight" DECIMAL(5,2) DEFAULT NULL,
  "nBmi" DECIMAL(4,2) DEFAULT NULL,
  "nTdee" DECIMAL(6,2) DEFAULT NULL,
  "computedBmr" DECIMAL(6,2) DEFAULT NULL,
  "activityLevelTitle" VARCHAR(100) DEFAULT NULL,
  "isSynced" BOOLEAN DEFAULT FALSE,
  "dtUpdatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "dtRecordedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "fk_healthrecords_user" FOREIGN KEY ("nUserId") REFERENCES "TbUsers" ("nUserId") ON DELETE CASCADE
);
CREATE INDEX "idx_healthrecords_user" ON "TbHealthRecords" ("nUserId");

-- 8. Table structure for table "TbNutritionLogs"
CREATE TABLE IF NOT EXISTS "TbNutritionLogs" (
  "nNutritionId" SERIAL PRIMARY KEY,
  "nUserId" INT NOT NULL,
  "sMealType" VARCHAR(50) NOT NULL,
  "sFoodName" VARCHAR(150) NOT NULL,
  "nCalories" INT NOT NULL,
  "nProtein" DECIMAL(5,2) DEFAULT 0.00,
  "nCarbs" DECIMAL(5,2) DEFAULT 0.00,
  "nFat" DECIMAL(5,2) DEFAULT 0.00,
  "sServingSize" VARCHAR(100) DEFAULT '',
  "sImagePath" TEXT DEFAULT NULL,
  "isSynced" BOOLEAN DEFAULT FALSE,
  "dtUpdatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "dtLoggedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "fk_nutrition_user" FOREIGN KEY ("nUserId") REFERENCES "TbUsers" ("nUserId") ON DELETE CASCADE
);
CREATE INDEX "idx_nutrition_user" ON "TbNutritionLogs" ("nUserId");

-- 9. Table structure for table "TbRoutineLogs"
CREATE TABLE IF NOT EXISTS "TbRoutineLogs" (
  "nLogId" SERIAL PRIMARY KEY,
  "nRoutineId" INT NOT NULL,
  "isCompleted" BOOLEAN DEFAULT FALSE,
  "dtLogDate" DATE NOT NULL,
  "nProgressValue" DOUBLE PRECISION DEFAULT 0,
  "dtCreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "dtUpdatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "unique_routine_log" UNIQUE ("nRoutineId", "dtLogDate"),
  CONSTRAINT "fk_routinelogs_routine" FOREIGN KEY ("nRoutineId") REFERENCES "TbRoutines" ("nRoutineId") ON DELETE CASCADE
);
CREATE INDEX "idx_routinelogs_routine" ON "TbRoutineLogs" ("nRoutineId");

-- 10. Table structure for table "TbSession"
CREATE TABLE IF NOT EXISTS "TbSession" (
  "nUserId" INT PRIMARY KEY,
  "sToken" TEXT NOT NULL,
  "dtExpiresAt" TIMESTAMP NOT NULL,
  "dtCreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "fk_session_user" FOREIGN KEY ("nUserId") REFERENCES "TbUsers" ("nUserId") ON DELETE CASCADE
);

-- 11. Table structure for table "TbUserBadges"
CREATE TABLE IF NOT EXISTS "TbUserBadges" (
  "nUserBadgeId" SERIAL PRIMARY KEY,
  "nUserId" INT NOT NULL,
  "nBadgeId" INT NOT NULL,
  "dtEarnedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "fk_userbadges_user" FOREIGN KEY ("nUserId") REFERENCES "TbUsers" ("nUserId") ON DELETE CASCADE,
  CONSTRAINT "fk_userbadges_badge" FOREIGN KEY ("nBadgeId") REFERENCES "TbBadges" ("nBadgeId") ON DELETE CASCADE
);
CREATE INDEX "idx_userbadges_user" ON "TbUserBadges" ("nUserId");
CREATE INDEX "idx_userbadges_badge" ON "TbUserBadges" ("nBadgeId");

-- 12. Table structure for table "TbUserPreferences"
CREATE TABLE IF NOT EXISTS "TbUserPreferences" (
  "nUserId" INT PRIMARY KEY,
  "sUnitSystem" VARCHAR(50) DEFAULT 'metric',
  "sUnitLabel" VARCHAR(100) DEFAULT 'Kilometers, Kilograms',
  "sGeminiApiKey" TEXT DEFAULT NULL,
  CONSTRAINT "fk_userpreferences_user" FOREIGN KEY ("nUserId") REFERENCES "TbUsers" ("nUserId") ON DELETE CASCADE
);

-- 13. Table structure for table "TbWorkouts"
CREATE TABLE IF NOT EXISTS "TbWorkouts" (
  "nWorkoutId" SERIAL PRIMARY KEY,
  "nUserId" INT NOT NULL,
  "sType" VARCHAR(50) NOT NULL,
  "nDistance" DECIMAL(6,2) DEFAULT 0.00,
  "nDuration" INT DEFAULT 0,
  "nCaloriesBurned" DECIMAL(6,2) DEFAULT 0.00,
  "sRoutePoints" TEXT DEFAULT NULL,
  "isSynced" BOOLEAN DEFAULT FALSE,
  "dtUpdatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "dtWorkoutDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "fk_workouts_user" FOREIGN KEY ("nUserId") REFERENCES "TbUsers" ("nUserId") ON DELETE CASCADE
);
CREATE INDEX "idx_workouts_user" ON "TbWorkouts" ("nUserId");

-- 14. Table structure for table "TbWorkoutCategories"
CREATE TABLE IF NOT EXISTS "TbWorkoutCategories" (
  "nCategoryId" SERIAL PRIMARY KEY,
  "sCategoryId" VARCHAR(50) NOT NULL UNIQUE,
  "sTitle" VARCHAR(100) NOT NULL,
  "sSubtitle" VARCHAR(255) DEFAULT NULL,
  "sIconName" VARCHAR(50) DEFAULT 'directions_run',
  "nIconCodePoint" INT DEFAULT 57904,
  "nMetValue" DECIMAL(4,2) DEFAULT 1.00,
  "isMoving" BOOLEAN DEFAULT FALSE,
  "dtCreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================================
-- Supabase Storage & Migration Helpers (Run in Supabase SQL Editor)
-- =========================================================================
-- 1. Allow nullable password for OAuth/Google users:
-- ALTER TABLE "TbUsers" ALTER COLUMN "sPasswordHash" DROP NOT NULL;

-- 2. Create Public Storage Bucket for Images (healthymate-uploads):
-- INSERT INTO storage.buckets (id, name, public) 
-- VALUES ('healthymate-uploads', 'healthymate-uploads', true)
-- ON CONFLICT (id) DO UPDATE SET public = true;

-- 3. Storage Policies (Allow Public Read & Authenticated/Anon Upload):
-- CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'healthymate-uploads');
-- CREATE POLICY "Public Insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'healthymate-uploads');
-- CREATE POLICY "Public Update" ON storage.objects FOR UPDATE USING (bucket_id = 'healthymate-uploads');
-- CREATE POLICY "Public Delete" ON storage.objects FOR DELETE USING (bucket_id = 'healthymate-uploads');