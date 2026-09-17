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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE $tableUsers ADD COLUMN sFirstName TEXT DEFAULT ""',
        );
        await db.execute(
          'ALTER TABLE $tableUsers ADD COLUMN sLastName TEXT DEFAULT ""',
        );
      } catch (e) {
        debugPrint('Migration note: $e');
      }
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
        dtCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSession (
        nSessionId INTEGER PRIMARY KEY DEFAULT 1,
        isLoggedIn INTEGER DEFAULT 0,
        sEmail TEXT,
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

    // สร้าง Table เสร็จเรียบร้อย (ไม่มีการใส่ข้อมูล mock)
  }

  // ==========================================
  // TbUsers CRUD Operations
  // ==========================================

  /// ดึงข้อมูลผู้ใช้จาก `TbUsers` ตาม nUserId
  Future<TbUser?> getUser({int userId = 1}) async {
    if (kIsWeb) {
      final map = _webUsers.cast<Map<String, dynamic>?>().firstWhere(
        (item) => item?['nUserId'] == userId,
        orElse: () => null,
      );
      if (map != null) {
        return TbUser.fromMap(map);
      }
      return null;
    }

    final db = await database;
    if (db == null) return null;

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

  /// ดึงข้อมูลผู้ใช้ตาม Email
  Future<TbUser?> getUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (kIsWeb) {
      final map = _webUsers.cast<Map<String, dynamic>?>().firstWhere(
        (item) => item?['sEmail']?.toString().toLowerCase() == cleanEmail,
        orElse: () => null,
      );
      if (map != null) {
        return TbUser.fromMap(map);
      }
      return null;
    }

    final db = await database;
    if (db == null) return null;

    final maps = await db.query(
      tableUsers,
      where: 'LOWER(sEmail) = ?',
      whereArgs: [cleanEmail],
    );

    if (maps.isNotEmpty) {
      return TbUser.fromMap(maps.first);
    }
    return null;
  }

  /// ดึงอีเมลผู้ใช้ที่ล็อกอินอยู่ใน Session
  Future<String?> getLoggedInUserEmail() async {
    if (kIsWeb) {
      return _webSession?['sEmail']?.toString();
    }
    final db = await database;
    if (db == null) return null;
    final maps = await db.query(tableSession, where: 'nSessionId = 1');
    if (maps.isNotEmpty) {
      return maps.first['sEmail']?.toString();
    }
    return null;
  }

  /// ตรวจสอบว่ามีอีเมลนี้อยู่ใน `TbUsers` แล้วหรือไม่
  Future<bool> isEmailExists(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (kIsWeb) {
      return _webUsers.any(
        (u) => u['sEmail']?.toString().toLowerCase() == cleanEmail,
      );
    }

    final db = await database;
    if (db == null) return false;

    final maps = await db.query(
      tableUsers,
      where: 'LOWER(sEmail) = ?',
      whereArgs: [cleanEmail],
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
    final cleanEmail = email.trim();
    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();

    if (kIsWeb) {
      final id = _webUsers.length + 1;
      final user = TbUser(
        nUserId: id,
        sEmail: cleanEmail,
        sPasswordHash: password,
        sFirstName: cleanFirstName,
        sLastName: cleanLastName,
        nAge: 0,
        nHeight: 0.0,
        nWeight: 0.0,
        sGender: 'male',
        sActivityLevel: 'light',
        isDarkMode: false,
        dtCreatedAt: DateTime.now(),
      );
      _webUsers.add(user.toMap());
      return user;
    }

    final db = await database;
    final userMap = {
      'sEmail': cleanEmail,
      'sPasswordHash': password,
      'sFirstName': cleanFirstName,
      'sLastName': cleanLastName,
      'nAge': 0,
      'nHeight': 0.0,
      'nWeight': 0.0,
      'sGender': 'male',
      'sActivityLevel': 'light',
      'isDarkMode': 0,
      'dtCreatedAt': DateTime.now().toIso8601String(),
    };

    final id = await db!.insert(
      tableUsers,
      userMap,
      conflictAlgorithm: ConflictAlgorithm.fail,
    );

    return TbUser(
      nUserId: id,
      sEmail: cleanEmail,
      sPasswordHash: password,
      sFirstName: cleanFirstName,
      sLastName: cleanLastName,
      nAge: 0,
      nHeight: 0.0,
      nWeight: 0.0,
      sGender: 'male',
      sActivityLevel: 'light',
      isDarkMode: false,
      dtCreatedAt: DateTime.now(),
    );
  }

  /// อัปเดตข้อมูลผู้ใช้ใน `TbUsers`
  Future<void> updateUser(TbUser user) async {
    if (kIsWeb) {
      final index = _webUsers.indexWhere((u) => u['nUserId'] == user.nUserId);
      if (index >= 0) {
        _webUsers[index] = user.toMap();
      } else {
        _webUsers.add(user.toMap());
      }
      return;
    }

    final db = await database;
    if (db == null) return;
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
    if (kIsWeb) {
      return _webHealthRecords
          .map((item) => TbHealthRecord.fromMap(item))
          .where((record) => record.nUserId == userId)
          .toList()
        ..sort((a, b) => b.dtRecordedAt.compareTo(a.dtRecordedAt));
    }

    final db = await database;
    if (db == null) return [];

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
    if (kIsWeb) {
      final newId = DateTime.now().millisecondsSinceEpoch % 1000000;
      final newRecord = TbHealthRecord(
        nRecordId: record.nRecordId == 0 ? newId : record.nRecordId,
        nUserId: record.nUserId,
        nWeight: record.nWeight,
        nHeight: record.nHeight,
        nBmi: record.nBmi,
        nTdee: record.nTdee,
        dtRecordedAt: record.dtRecordedAt,
        computedBmr: record.computedBmr,
        activityLevelTitle: record.activityLevelTitle,
      );
      _webHealthRecords.insert(0, newRecord.toMap());
      return newRecord;
    }

    final db = await database;
    final recordMap = record.toMap();
    if (record.nRecordId == 0) {
      recordMap.remove('nRecordId');
    }

    final id = await db!.insert(
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
    if (kIsWeb) {
      _webHealthRecords.removeWhere((item) => item['nRecordId'] == recordId);
      return;
    }

    final db = await database;
    if (db == null) return;
    await db.delete(
      tableHealthRecords,
      where: 'nRecordId = ?',
      whereArgs: [recordId],
    );
  }

  /// ล้างข้อมูล `TbHealthRecords` ทั้งหมด
  Future<void> clearHealthRecords() async {
    if (kIsWeb) {
      _webHealthRecords.clear();
      return;
    }

    final db = await database;
    if (db == null) return;
    await db.delete(tableHealthRecords);
  }

  /// บันทึกประวัติการออกกำลังกายลงตาราง TbWorkouts
  Future<int> insertWorkout({
    required int userId,
    required String type,
    required double distanceKm,
    required int durationSeconds,
    required double caloriesBurned,
  }) async {
    final nowStr = DateTime.now().toIso8601String();
    if (kIsWeb) {
      return DateTime.now().millisecondsSinceEpoch % 100000;
    }

    final db = await database;
    if (db == null) return 0;

    return await db.insert(tableWorkouts, {
      'nUserId': userId,
      'sType': type,
      'nDistance': distanceKm,
      'nDuration': durationSeconds,
      'nCaloriesBurned': caloriesBurned,
      'dtWorkoutDate': nowStr,
    });
  }

  /// ดึงประวัติการออกกำลังกายทั้งหมดของผู้ใช้ตาม userId
  Future<List<Map<String, dynamic>>> getWorkouts({required int userId}) async {
    if (kIsWeb) return [];

    final db = await database;
    if (db == null) return [];

    return await db.query(
      tableWorkouts,
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'dtWorkoutDate DESC',
    );
  }

  // ==========================================
  // Auth Session Operations
  // ==========================================

  /// ดึงสถานะการล็อกอินปัจจุบัน
  Future<bool> getLoginStatus() async {
    if (kIsWeb) {
      return _webSession?['isLoggedIn'] == true;
    }

    final db = await database;
    if (db == null) return false;
    final maps = await db.query(tableSession, where: 'nSessionId = 1');
    if (maps.isNotEmpty) {
      return (maps.first['isLoggedIn'] as num?)?.toInt() == 1;
    }
    return false;
  }

  /// บันทึกสถานะการล็อกอิน
  Future<void> setLoginStatus(bool isLoggedIn, {String? email}) async {
    if (kIsWeb) {
      _webSession = {
        'nSessionId': 1,
        'isLoggedIn': isLoggedIn,
        'sEmail': email ?? '',
        'dtUpdatedAt': DateTime.now().toIso8601String(),
      };
      return;
    }

    final db = await database;
    if (db == null) return;
    await db.insert(tableSession, {
      'nSessionId': 1,
      'isLoggedIn': isLoggedIn ? 1 : 0,
      'sEmail': email ?? '',
      'dtUpdatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// ตรวจสอบการเข้าสู่ระบบ
  Future<bool> authenticateUser(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (kIsWeb) {
      if (_webUsers.isEmpty) return false;
      final user = _webUsers.firstWhere(
        (u) => u['sEmail']?.toString().toLowerCase() == cleanEmail,
        orElse: () => {},
      );
      if (user.isNotEmpty && user['sPasswordHash'] != null) {
        return user['sPasswordHash'] == password;
      }
      return false;
    }

    final db = await database;
    if (db == null) return false;
    final maps = await db.query(
      tableUsers,
      where: 'LOWER(sEmail) = ?',
      whereArgs: [cleanEmail],
    );

    if (maps.isNotEmpty) {
      final storedHash = maps.first['sPasswordHash']?.toString();
      if (storedHash != null && storedHash.isNotEmpty) {
        return storedHash == password;
      }
    }
    return false;
  }
}
