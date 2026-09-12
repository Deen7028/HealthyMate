import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

/// Database Manager เชื่อมต่อโครงสร้างฐานข้อมูล SQLite ตาม `6620310001_HealthMateDB.sql`
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

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

  Database? _db;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // กำหนด FFI factory เมื่อรันบน Windows, macOS หรือ Linux desktop
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// สร้าง Table Schema ทั้งหมดตาม 6620310001_HealthMateDB.sql
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableUsers (
        nUserId INTEGER PRIMARY KEY AUTOINCREMENT,
        sEmail TEXT NOT NULL UNIQUE,
        sPasswordHash TEXT NOT NULL,
        sFullName TEXT NOT NULL,
        nAge INTEGER,
        nHeight REAL,
        nWeight REAL,
        sGender TEXT,
        sActivityLevel TEXT,
        isDarkMode INTEGER DEFAULT 0,
        dtCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP
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
        dtRecordedAt TEXT DEFAULT CURRENT_TIMESTAMP,
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
        dtLoggedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nUserId) REFERENCES $tableUsers (nUserId) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableRoutines (
        nRoutineId INTEGER PRIMARY KEY AUTOINCREMENT,
        nUserId INTEGER NOT NULL,
        sTitle TEXT NOT NULL,
        sTime TEXT,
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
        dtWorkoutDate TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nUserId) REFERENCES $tableUsers (nUserId) ON DELETE CASCADE
      );
    ''');

    // ใส่ข้อมูลเริ่มต้นสำหรับการทดสอบ
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    final now = DateTime.now();

    final defaultUser = TbUser(
      nUserId: 1,
      sEmail: 'user@healthymate.app',
      sPasswordHash: 'hash_secret',
      sFullName: 'ผู้ใช้งาน',
      nAge: 28,
      nHeight: 175.0,
      nWeight: 70.0,
      sGender: 'male',
      sActivityLevel: 'light',
      isDarkMode: false,
      dtCreatedAt: now.subtract(const Duration(days: 60)),
    );

    await db.insert(
      tableUsers,
      defaultUser.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final sampleRecords = [
      TbHealthRecord(
        nRecordId: 1,
        nUserId: 1,
        nWeight: 73.5,
        nHeight: 175.0,
        nBmi: 24.0,
        nTdee: 2020.0,
        dtRecordedAt: now.subtract(const Duration(days: 30)),
        computedBmr: 1683.0,
        activityLevelTitle: 'ไม่ออกกำลังกายเลย',
      ),
      TbHealthRecord(
        nRecordId: 2,
        nUserId: 1,
        nWeight: 72.0,
        nHeight: 175.0,
        nBmi: 23.5,
        nTdee: 2294.0,
        dtRecordedAt: now.subtract(const Duration(days: 20)),
        computedBmr: 1668.0,
        activityLevelTitle: 'ออกกำลังกายเบาๆ',
      ),
      TbHealthRecord(
        nRecordId: 3,
        nUserId: 1,
        nWeight: 71.0,
        nHeight: 175.0,
        nBmi: 23.2,
        nTdee: 2280.0,
        dtRecordedAt: now.subtract(const Duration(days: 10)),
        computedBmr: 1658.0,
        activityLevelTitle: 'ออกกำลังกายเบาๆ',
      ),
      TbHealthRecord(
        nRecordId: 4,
        nUserId: 1,
        nWeight: 70.0,
        nHeight: 175.0,
        nBmi: 22.9,
        nTdee: 2266.0,
        dtRecordedAt: now.subtract(const Duration(days: 2)),
        computedBmr: 1648.0,
        activityLevelTitle: 'ออกกำลังกายเบาๆ',
      ),
    ];

    for (final record in sampleRecords) {
      await db.insert(
        tableHealthRecords,
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ==========================================
  // TbUsers CRUD Operations
  // ==========================================

  /// ดึงข้อมูลผู้ใช้จาก `TbUsers` ตาม nUserId
  Future<TbUser?> getUser({int userId = 1}) async {
    final db = await database;
    final maps = await db.query(
      tableUsers,
      where: 'nUserId = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return TbUser.fromMap(maps.first);
    }
    return null;
  }

  /// ตรวจสอบว่ามีอีเมลนี้อยู่ใน `TbUsers` แล้วหรือไม่
  Future<bool> isEmailExists(String email) async {
    final db = await database;
    final maps = await db.query(
      tableUsers,
      where: 'LOWER(sEmail) = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    return maps.isNotEmpty;
  }

  /// สมัครสมาชิกบันทึกผู้ใช้ใหม่ลงในตาราง `TbUsers`
  Future<TbUser> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final db = await database;
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();

    final userMap = {
      'sEmail': email.trim(),
      'sPasswordHash': password,
      'sFullName': fullName,
      'nAge': 25,
      'nHeight': 170.0,
      'nWeight': 65.0,
      'sGender': 'male',
      'sActivityLevel': 'light',
      'isDarkMode': 0,
      'dtCreatedAt': DateTime.now().toIso8601String(),
    };

    final id = await db.insert(
      tableUsers,
      userMap,
      conflictAlgorithm: ConflictAlgorithm.fail,
    );

    return TbUser(
      nUserId: id,
      sEmail: email.trim(),
      sPasswordHash: password,
      sFullName: fullName,
      nAge: 25,
      nHeight: 170.0,
      nWeight: 65.0,
      sGender: 'male',
      sActivityLevel: 'light',
      isDarkMode: false,
      dtCreatedAt: DateTime.now(),
    );
  }

  /// อัปเดตข้อมูลผู้ใช้ใน `TbUsers`
  Future<void> updateUser(TbUser user) async {
    final db = await database;
    await db.insert(
      tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================
  // TbHealthRecords CRUD Operations
  // ==========================================

  /// ดึงรายการประวัติทั้งหมดจาก `TbHealthRecords`
  Future<List<TbHealthRecord>> getHealthRecords({int userId = 1}) async {
    final db = await database;
    final maps = await db.query(
      tableHealthRecords,
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'dtRecordedAt DESC',
    );

    return maps.map((map) => TbHealthRecord.fromMap(map)).toList();
  }

  /// เพิ่มบันทึกใหม่ใน `TbHealthRecords`
  Future<TbHealthRecord> insertHealthRecord(TbHealthRecord record) async {
    final db = await database;
    final recordMap = record.toMap();
    if (record.nRecordId == 0) {
      recordMap.remove('nRecordId');
    }

    final id = await db.insert(
      tableHealthRecords,
      recordMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return TbHealthRecord(
      nRecordId: id,
      nUserId: record.nUserId,
      nWeight: record.nWeight,
      nHeight: record.nHeight,
      nBmi: record.nBmi,
      nTdee: record.nTdee,
      dtRecordedAt: record.dtRecordedAt,
      computedBmr: record.computedBmr,
      activityLevelTitle: record.activityLevelTitle,
    );
  }

  /// ลบบันทึกจาก `TbHealthRecords` ตาม Record ID
  Future<void> deleteHealthRecord(int recordId) async {
    final db = await database;
    await db.delete(
      tableHealthRecords,
      where: 'nRecordId = ?',
      whereArgs: [recordId],
    );
  }

  /// ล้างข้อมูล `TbHealthRecords` ทั้งหมด
  Future<void> clearHealthRecords() async {
    final db = await database;
    await db.delete(tableHealthRecords);
  }
}
