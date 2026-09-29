import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
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

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// PBKDF2-HMAC-SHA256 password hash with a random per-password salt.
  static String hashPassword(String password) {
    final actualSalt = base64Url.encode(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    const iterations = 60000;
    final derived = _pbkdf2(password, actualSalt, iterations);
    return 'pbkdf2\$$iterations\$$actualSalt\$${base64Url.encode(derived)}';
  }

  static bool verifyPassword(String password, String encoded) {
    try {
      final parts = encoded.split(r'$');
      if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
      final iterations = int.tryParse(parts[1]);
      if (iterations == null || iterations < 10000 || iterations > 1000000) return false;
      final expected = base64Url.decode(parts[3]);
      final actual = _pbkdf2(password, parts[2], iterations);
      if (actual.length != expected.length) return false;
      var difference = 0;
      for (var i = 0; i < actual.length; i++) {
        difference |= actual[i] ^ expected[i];
      }
      return difference == 0;
    } on FormatException {
      return false;
    }
  }

  static List<int> _pbkdf2(String password, String salt, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final first = hmac.convert([...utf8.encode(salt), 0, 0, 0, 1]).bytes;
    var block = List<int>.from(first);
    final output = List<int>.from(first);
    for (var i = 1; i < iterations; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < output.length; j++) {
        output[j] ^= block[j];
      }
    }
    return output;
  }

  /// Legacy hashes are accepted only for migration during successful login.
  static String hashPasswordLegacy(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String hashPasswordLegacySalted(String password, String email) {
    return sha256.convert(utf8.encode('HM_Salt_${email.trim().toLowerCase()}_$password')).toString();
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
  static const String tablePendingDeletions = 'TbPendingDeletions';

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
      version: 13,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// การอัปเกรดฐานข้อมูลแบบปลอดภัย (Safe Schema Migration)
  /// ตรวจสอบและสร้างตารางหรือคอลัมน์ใหม่ที่อาจตกหล่นจากเวอร์ชันก่อนหน้า
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 1. สร้างตารางทั้งหมดที่อาจยังไม่มี (CREATE TABLE IF NOT EXISTS)
    await _onCreate(db, newVersion);

    // 2. ตรวจสอบและเพิ่มคอลัมน์ใหม่ในแต่ละตารางอย่างปลอดภัย (Safe Add Columns)
    await _safeAddColumn(db, tableUsers, 'isSynced', 'INTEGER DEFAULT 0');
    await _safeAddColumn(db, tableUsers, 'isDarkMode', 'INTEGER DEFAULT 0');
    await _safeAddColumn(db, tableUsers, 'sProfileImagePath', 'TEXT DEFAULT ""');

    await _safeAddColumn(db, tableHealthRecords, 'computedBmr', 'REAL');
    await _safeAddColumn(db, tableHealthRecords, 'activityLevelTitle', 'TEXT');
    await _safeAddColumn(db, tableHealthRecords, 'isSynced', 'INTEGER DEFAULT 0');

    await _safeAddColumn(db, tableNutritionLogs, 'isSynced', 'INTEGER DEFAULT 0');
    await _safeAddColumn(db, tableNutritionLogs, 'nProtein', 'REAL DEFAULT 0.0');
    await _safeAddColumn(db, tableNutritionLogs, 'nCarbs', 'REAL DEFAULT 0.0');
    await _safeAddColumn(db, tableNutritionLogs, 'nFat', 'REAL DEFAULT 0.0');
    await _safeAddColumn(db, tableNutritionLogs, 'sServingSize', 'TEXT DEFAULT ""');
    await _safeAddColumn(db, tableNutritionLogs, 'sImagePath', 'TEXT DEFAULT ""');

    await _safeAddColumn(db, tableRoutines, 'sLinkedWorkout', 'TEXT DEFAULT ""');
    await _safeAddColumn(db, tableRoutines, 'color', 'INTEGER');
    await _safeAddColumn(db, tableRoutines, 'iconData', 'INTEGER');
    await _safeAddColumn(db, tableRoutines, 'targetValue', 'REAL DEFAULT 1.0');
    await _safeAddColumn(db, tableRoutines, 'unit', 'TEXT DEFAULT "ครั้ง"');
    await _safeAddColumn(db, tableRoutines, 'isNotificationActive', 'INTEGER DEFAULT 1');

    await _safeAddColumn(db, tableRoutineLogs, 'nProgressValue', 'REAL DEFAULT 0.0');

    await _safeAddColumn(db, tableWorkouts, 'isSynced', 'INTEGER DEFAULT 0');
    await _safeAddColumn(db, tableWorkouts, 'sRoutePoints', 'TEXT DEFAULT ""');

    await _safeAddColumn(db, 'TbGoals', 'dtCreatedAt', 'TEXT');

    debugPrint('AppDatabase: Schema migrated successfully from v$oldVersion to v$newVersion');
  }

  /// Helper ฟังก์ชันเพื่อเพิ่ม Column ถ้ายังไม่มีในตาราง
  Future<void> _safeAddColumn(Database db, String tableName, String columnName, String columnDef) async {
    try {
      final pragma = await db.rawQuery('PRAGMA table_info($tableName)');
      final columnExists = pragma.any((col) => col['name']?.toString().toLowerCase() == columnName.toLowerCase());
      if (!columnExists) {
        await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnDef');
        debugPrint('AppDatabase Migration: Added column $columnName to $tableName');
      }
    } catch (e) {
      debugPrint('AppDatabase Migration Warning: safeAddColumn $columnName on $tableName failed: $e');
    }
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
      CREATE TABLE IF NOT EXISTS $tableSession (
        nSessionId INTEGER PRIMARY KEY DEFAULT 1,
        isLoggedIn INTEGER DEFAULT 0,
        sEmail TEXT,
        sAuthToken TEXT DEFAULT "",
        dtUpdatedAt TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablePendingDeletions (
        nDeletionId INTEGER PRIMARY KEY AUTOINCREMENT,
        nUserId INTEGER NOT NULL,
        sEntity TEXT NOT NULL,
        nRemoteId INTEGER NOT NULL,
        dtQueuedAt TEXT NOT NULL
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
