part of 'app_database.dart';

extension AppDatabaseSchema on AppDatabase {
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppDatabase.tableUsers} (
        nUserId INTEGER PRIMARY KEY AUTOINCREMENT,
        sEmail TEXT NOT NULL UNIQUE,
        sPasswordHash TEXT NOT NULL,
        sFirstName TEXT NOT NULL,
        sLastName TEXT NOT NULL,
        nAge INTEGER,
        nHeight REAL,
        nWeight REAL,
        sGender TEXT,
        sActivityLevel TEXT,
        isDarkMode INTEGER DEFAULT 0,
        sProfileImagePath TEXT DEFAULT "",
        isSynced INTEGER DEFAULT 0,
        dtCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        dtUpdatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS TbGoals (
        nGoalId INTEGER PRIMARY KEY AUTOINCREMENT,
        nUserId INTEGER NOT NULL,
        nRoutineId INTEGER DEFAULT 0,
        sTitle TEXT NOT NULL,
        nProgress REAL DEFAULT 0.0,
        sRemainingText TEXT,
        dtCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        dtUpdatedAt TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS TbUserPreferences (
        nUserId INTEGER PRIMARY KEY,
        sUnitSystem TEXT DEFAULT "metric",
        sUnitLabel TEXT DEFAULT "Kilometers, Kilograms",
        sGeminiApiKey TEXT DEFAULT ""
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppDatabase.tableSession} (
        nSessionId INTEGER PRIMARY KEY DEFAULT 1,
        isLoggedIn INTEGER DEFAULT 0,
        sEmail TEXT,
        sAuthToken TEXT DEFAULT "",
        dtUpdatedAt TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppDatabase.tablePendingDeletions} (
        nDeletionId INTEGER PRIMARY KEY AUTOINCREMENT,
        nUserId INTEGER NOT NULL,
        sEntity TEXT NOT NULL,
        nRemoteId INTEGER NOT NULL,
        dtQueuedAt TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppDatabase.tableBadges} (
        nBadgeId INTEGER PRIMARY KEY AUTOINCREMENT,
        sBadgeName TEXT NOT NULL,
        sDescription TEXT,
        sIconUrl TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppDatabase.tableHealthIntegrations} (
        nIntegrationId INTEGER PRIMARY KEY AUTOINCREMENT,
        nUserId INTEGER NOT NULL,
        sProviderName TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0,
        dtLastSyncedAt TEXT,
        FOREIGN KEY (nUserId) REFERENCES ${AppDatabase.tableUsers} (nUserId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppDatabase.tableHealthRecords} (
        nRecordId INTEGER PRIMARY KEY AUTOINCREMENT,
        nUserId INTEGER NOT NULL,
        nWeight REAL,
        nHeight REAL,
        nBmi REAL,
        nTdee REAL,
        computedBmr REAL,
        activityLevelTitle TEXT,
        isSynced INTEGER DEFAULT 0,
        dtRecordedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        dtUpdatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nUserId) REFERENCES ${AppDatabase.tableUsers} (nUserId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppDatabase.tableNutritionLogs} (
        nNutritionId INTEGER PRIMARY KEY AUTOINCREMENT,
        nUserId INTEGER NOT NULL,
        sMealType TEXT NOT NULL,
        sFoodName TEXT NOT NULL,
        nCalories INTEGER NOT NULL,
        nProtein REAL DEFAULT 0.0,
        nCarbs REAL DEFAULT 0.0,
        nFat REAL DEFAULT 0.0,
        sServingSize TEXT DEFAULT "",
        sImagePath TEXT DEFAULT "",
        isSynced INTEGER DEFAULT 0,
        dtLoggedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        dtUpdatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nUserId) REFERENCES ${AppDatabase.tableUsers} (nUserId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppDatabase.tableRoutines} (
        nRoutineId INTEGER PRIMARY KEY AUTOINCREMENT,
        nUserId INTEGER NOT NULL,
        sTitle TEXT NOT NULL,
        sTime TEXT,
        targetValue REAL DEFAULT 1.0,
        unit TEXT DEFAULT "ครั้ง",
        sLinkedWorkout TEXT DEFAULT "",
        color INTEGER,
        iconData INTEGER,
        isNotificationActive INTEGER DEFAULT 1,
        dtCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nUserId) REFERENCES ${AppDatabase.tableUsers} (nUserId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppDatabase.tableRoutineLogs} (
        nLogId INTEGER PRIMARY KEY AUTOINCREMENT,
        nRoutineId INTEGER NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        nProgressValue REAL DEFAULT 0.0,
        dtLogDate TEXT NOT NULL,
        FOREIGN KEY (nRoutineId) REFERENCES ${AppDatabase.tableRoutines} (nRoutineId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppDatabase.tableUserBadges} (
        nUserBadgeId INTEGER PRIMARY KEY AUTOINCREMENT,
        nUserId INTEGER NOT NULL,
        nBadgeId INTEGER NOT NULL,
        dtEarnedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nUserId) REFERENCES ${AppDatabase.tableUsers} (nUserId) ON DELETE CASCADE,
        FOREIGN KEY (nBadgeId) REFERENCES ${AppDatabase.tableBadges} (nBadgeId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppDatabase.tableWorkouts} (
        nWorkoutId INTEGER PRIMARY KEY AUTOINCREMENT,
        nUserId INTEGER NOT NULL,
        sType TEXT NOT NULL,
        nDistance REAL DEFAULT 0.00,
        nDuration INTEGER DEFAULT 0,
        nCaloriesBurned REAL DEFAULT 0.00,
        sRoutePoints TEXT DEFAULT "",
        isSynced INTEGER DEFAULT 0,
        dtWorkoutDate TEXT DEFAULT CURRENT_TIMESTAMP,
        dtUpdatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nUserId) REFERENCES ${AppDatabase.tableUsers} (nUserId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppDatabase.tableWorkoutCategories} (
        nCategoryId INTEGER PRIMARY KEY AUTOINCREMENT,
        sCategoryId TEXT NOT NULL UNIQUE,
        sTitle TEXT NOT NULL,
        sSubtitle TEXT,
        sIconName TEXT,
        nIconCodePoint INTEGER,
        nMetValue REAL DEFAULT 1.00,
        isMoving INTEGER DEFAULT 0,
        dtCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // Default seed categories
    await db.execute('''
      INSERT OR IGNORE INTO ${AppDatabase.tableWorkoutCategories} 
        (nCategoryId, sCategoryId, sTitle, sSubtitle, sIconName, nIconCodePoint, nMetValue, isMoving) 
      VALUES
        (1, 'running', 'วิ่ง (Running)', 'ติดตามเส้นทาง GPS และความเร็ว', 'directions_run', 57904, 8.50, 1),
        (2, 'walking', 'เดิน (Walking)', 'ออกกำลังกายเบาๆ เผาผลาญไขมัน', 'directions_walk', 57906, 3.80, 1),
        (3, 'cycling', 'ปั่นจักรยาน (Cycling)', 'บันทึกระยะทางและความเร็วรอบขา', 'directions_bike', 57903, 7.50, 1),
        (4, 'meditation', 'ทำสมาธิ (Meditation)', 'ฝึกสติ ผ่อนคลายความเครียด และฟื้นฟูจิตใจ', 'self_improvement', 58718, 1.50, 0),
        (5, 'yoga', 'โยคะ (Yoga)', 'ยืดเหยียดกล้ามเนื้อ เสริมความยืดหยุ่นและสมดุล', 'spa', 58732, 3.00, 0);
    ''');
  }
}
