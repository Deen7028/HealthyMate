import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

part 'daos/user_dao.dart';
part 'daos/health_record_dao.dart';
part 'daos/workout_dao.dart';
part 'daos/routine_dao.dart';
part 'daos/nutrition_dao.dart';
part 'daos/goal_preference_dao.dart';

/// Database Manager เชื่อมต่อโครงสร้างฐานข้อมูล SQLite ตาม `6620310001_HealthMateDB.sql`
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  /// เข้ารหัสรหัสผ่านด้วย SHA-256 ร่วมกับ Local Salt เพื่อป้องกัน Rainbow Table Attack
  static String hashPassword(String password, {String? salt}) {
    final String combinedKey = (salt != null && salt.isNotEmpty)
        ? 'HM_Salt_${salt.trim().toLowerCase()}_$password'
        : 'HM_Salt_Default_$password';
    final bytes = utf8.encode(combinedKey);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// เข้ารหัสแบบเลกาซี SHA-256 (สำหรับตรวจสอบรหัสผ่านเก่าแบบ Backward Compatible)
  static String hashPasswordLegacy(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static const String _dbName = '6620310001_HealthMateDB.db';

  // Table Names matching 6620310001_HealthMateDB.sql
  static const String tableUsers = 'TbUsers';
  static const String tableHealthRecords = 'TbHealthRecords';
  static const String tableWorkouts = 'TbWorkouts';
  static const String tableNutritionLogs = 'TbNutritionLogs';
  static const String tableRoutines = 'TbRoutines';
  static const String tableRoutineLogs = 'TbRoutineLogs';
  static const String tableBadges = 'TbBadges';
  static const String tableUserBadges = 'TbUserBadges';
  static const String tableHealthIntegrations = 'TbHealthIntegrations';
  static const String tableSession = 'TbSession';

  Database? _db;

  // Web Fallback Storage
  final List<Map<String, dynamic>> _webUsers = [];
  final List<Map<String, dynamic>> _webHealthRecords = [];
  Map<String, dynamic>? _webSession;

  static void ensureInitialized() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database?> _initDatabase() async {
    if (kIsWeb) return null;

    ensureInitialized();

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 11,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // All schema columns are fully consolidated into _onCreate for fresh database installations.
  }

  /// สร้าง Table Schema ทั้งหมดตาม 6620310001_HealthMateDB.sql
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableUsers (
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
      CREATE TABLE IF NOT EXISTS $tableSession (
        nSessionId INTEGER PRIMARY KEY DEFAULT 1,
        isLoggedIn INTEGER DEFAULT 0,
        sEmail TEXT,
        sAuthToken TEXT DEFAULT "",
        dtUpdatedAt TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableBadges (
        nBadgeId INTEGER PRIMARY KEY AUTOINCREMENT,
        sBadgeName TEXT NOT NULL,
        sDescription TEXT,
        sIconUrl TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableHealthIntegrations (
        nIntegrationId INTEGER PRIMARY KEY AUTOINCREMENT,
        nUserId INTEGER NOT NULL,
        sProviderName TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0,
        dtLastSyncedAt TEXT,
        FOREIGN KEY (nUserId) REFERENCES $tableUsers (nUserId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableHealthRecords (
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
        FOREIGN KEY (nUserId) REFERENCES $tableUsers (nUserId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableNutritionLogs (
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
        FOREIGN KEY (nUserId) REFERENCES $tableUsers (nUserId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableRoutines (
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
        FOREIGN KEY (nUserId) REFERENCES $tableUsers (nUserId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableRoutineLogs (
        nLogId INTEGER PRIMARY KEY AUTOINCREMENT,
        nRoutineId INTEGER NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        nProgressValue REAL DEFAULT 0.0,
        dtLogDate TEXT NOT NULL,
        FOREIGN KEY (nRoutineId) REFERENCES $tableRoutines (nRoutineId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableUserBadges (
        nUserBadgeId INTEGER PRIMARY KEY AUTOINCREMENT,
        nUserId INTEGER NOT NULL,
        nBadgeId INTEGER NOT NULL,
        dtEarnedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nUserId) REFERENCES $tableUsers (nUserId) ON DELETE CASCADE,
        FOREIGN KEY (nBadgeId) REFERENCES $tableBadges (nBadgeId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableWorkouts (
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
        FOREIGN KEY (nUserId) REFERENCES $tableUsers (nUserId) ON DELETE CASCADE
      );
    ''');
  }
}
