import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

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
      version: 9,
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
        debugPrint('Migration note v2: $e');
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE $tableWorkouts ADD COLUMN sRoutePoints TEXT DEFAULT ""',
        );
      } catch (e) {
        debugPrint('Migration note v3: $e');
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE $tableUsers ADD COLUMN sProfileImagePath TEXT DEFAULT ""',
        );
      } catch (e) {
        debugPrint('Migration note v4: $e');
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS TbGoals (
            nGoalId INTEGER PRIMARY KEY AUTOINCREMENT,
            nUserId INTEGER NOT NULL,
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
            sUnitLabel TEXT DEFAULT "Kilometers, Kilograms"
          );
        ''');
      } catch (e) {
        debugPrint('Migration note v5: $e');
      }
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE $tableNutritionLogs ADD COLUMN nProtein REAL DEFAULT 0.0');
        await db.execute('ALTER TABLE $tableNutritionLogs ADD COLUMN nCarbs REAL DEFAULT 0.0');
        await db.execute('ALTER TABLE $tableNutritionLogs ADD COLUMN nFat REAL DEFAULT 0.0');
        await db.execute('ALTER TABLE $tableNutritionLogs ADD COLUMN sServingSize TEXT DEFAULT ""');
        await db.execute('ALTER TABLE $tableNutritionLogs ADD COLUMN sImagePath TEXT DEFAULT ""');
      } catch (e) {
        debugPrint('Migration note v6: $e');
      }
    }
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE TbUserPreferences ADD COLUMN sGeminiApiKey TEXT DEFAULT ""');
      } catch (e) {
        debugPrint('Migration note v7: $e');
      }
    }
    if (oldVersion < 8) {
      try {
        // เพิ่มคอลัมน์ isSynced และ dtUpdatedAt สำหรับ Offline-First Architecture
        await db.execute('ALTER TABLE $tableHealthRecords ADD COLUMN isSynced INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE $tableHealthRecords ADD COLUMN dtUpdatedAt TEXT DEFAULT ""');

        await db.execute('ALTER TABLE $tableWorkouts ADD COLUMN isSynced INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE $tableWorkouts ADD COLUMN dtUpdatedAt TEXT DEFAULT ""');

        await db.execute('ALTER TABLE $tableNutritionLogs ADD COLUMN isSynced INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE $tableNutritionLogs ADD COLUMN dtUpdatedAt TEXT DEFAULT ""');

        await db.execute('ALTER TABLE $tableUsers ADD COLUMN isSynced INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE $tableUsers ADD COLUMN dtUpdatedAt TEXT DEFAULT ""');
      } catch (e) {
        debugPrint('Migration note v8 (Offline-first sync flags): $e');
      }
    }
    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE $tableRoutines ADD COLUMN targetValue REAL DEFAULT 1.0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableRoutines ADD COLUMN unit TEXT DEFAULT "ครั้ง"');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableRoutines ADD COLUMN sLinkedWorkout TEXT DEFAULT ""');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableRoutines ADD COLUMN color INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableRoutines ADD COLUMN iconData INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE TbGoals ADD COLUMN nRoutineId INTEGER DEFAULT 0');
      } catch (_) {}
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

  /// ดึงข้อมูลผู้ใช้จาก `TbUsers` ตามอีเมล
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
    final hashedPassword = hashPassword(password, salt: cleanEmail);

    if (kIsWeb) {
      final id = _webUsers.length + 1;
      final user = TbUser(
        nUserId: id,
        sEmail: cleanEmail,
        sPasswordHash: hashedPassword,
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
      'sPasswordHash': hashedPassword,
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
      sPasswordHash: hashedPassword,
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

  /// บันทึกหรืออัปเดตข้อมูลผู้ใช้ที่ได้จาก Server (User Hydration) ลงใน `TbUsers` ของ SQLite
  /// รองรับทั้งการติดตั้งใหม่และย้ายเครื่อง โดยเก็บ nUserId เดิมจาก MySQL เสมอ
  Future<TbUser> upsertUserFromServer(Map<String, dynamic> userMap) async {
    final user = TbUser.fromMap(userMap);
    if (kIsWeb) {
      final index = _webUsers.indexWhere((u) => u['nUserId'] == user.nUserId);
      if (index >= 0) {
        _webUsers[index] = user.toMap();
      } else {
        _webUsers.add(user.toMap());
      }
      return user;
    }

    final db = await database;
    if (db != null) {
      final mapToInsert = Map<String, dynamic>.from(user.toMap());
      mapToInsert['isSynced'] = 1; // บัญชีมาจาก Server ถือว่าซิงค์เรียบร้อยแล้ว
      await db.insert(
        tableUsers,
        mapToInsert,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return user;
  }

  /// ลบบัญชีผู้ใช้และข้อมูลทั้งหมดจาก SQLite ภายในเครื่อง (Cascade Local Account Deletion)
  Future<void> deleteUserAccount(int userId) async {
    if (kIsWeb) {
      _webUsers.removeWhere((u) => u['nUserId'] == userId);
      _webHealthRecords.removeWhere((r) => r['nUserId'] == userId);
      return;
    }

    final db = await database;
    if (db == null) return;

    await db.transaction((txn) async {
      await txn.rawDelete('DELETE FROM $tableRoutineLogs WHERE nRoutineId IN (SELECT nRoutineId FROM $tableRoutines WHERE nUserId = ?)', [userId]);
      await txn.delete(tableRoutines, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(tableHealthRecords, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(tableNutritionLogs, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(tableWorkouts, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(tableHealthIntegrations, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(tableUserBadges, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete('TbGoals', where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete('TbUserPreferences', where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(tableUsers, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(tableSession);
    });
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
    String routePoints = '',
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
      'sRoutePoints': routePoints,
      'isSynced': 0,
      'dtWorkoutDate': nowStr,
      'dtUpdatedAt': nowStr,
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

  /// เขียนข้อมูล Workouts จาก Server ลง SQLite ด้วย UPSERT (INSERT OR REPLACE)
  /// - กำหนด `isSynced = 1` ทันที
  /// - ใช้ ID ที่ได้รับจาก Server (`nWorkoutId`) เพื่อป้องกัน Primary Key ชนกัน
  Future<int> upsertWorkoutsFromServer(List<Map<String, dynamic>> workouts) async {
    if (kIsWeb || workouts.isEmpty) return 0;
    final db = await database;
    if (db == null) return 0;

    int affectedCount = 0;
    await db.transaction((txn) async {
      for (final item in workouts) {
        final rawId = item['nWorkoutId'];
        final workoutId = rawId != null ? int.tryParse(rawId.toString()) : null;
        final rawUserId = item['nUserId'];
        final userId = rawUserId != null ? int.tryParse(rawUserId.toString()) ?? 1 : 1;

        final rawDuration = item['nDuration'];
        final duration = rawDuration != null ? int.tryParse(rawDuration.toString()) ?? 0 : 0;

        final rawDistance = item['nDistance'];
        final distance = rawDistance != null ? double.tryParse(rawDistance.toString()) ?? 0.0 : 0.0;

        final rawCalories = item['nCaloriesBurned'];
        final calories = rawCalories != null ? double.tryParse(rawCalories.toString()) ?? 0.0 : 0.0;

        final type = item['sType']?.toString() ?? 'วิ่ง';
        final routePoints = item['sRoutePoints']?.toString() ?? '';
        final workoutDate = item['dtWorkoutDate']?.toString() ?? DateTime.now().toIso8601String();
        final updatedAt = item['dtUpdatedAt']?.toString() ?? DateTime.now().toIso8601String();

        final mapToInsert = <String, dynamic>{
          if (workoutId != null && workoutId > 0) 'nWorkoutId': workoutId,
          'nUserId': userId,
          'sType': type,
          'nDistance': distance,
          'nDuration': duration,
          'nCaloriesBurned': calories,
          'sRoutePoints': routePoints,
          'isSynced': 1, // ข้อมูลมาจาก Server ให้ระบุว่าซิงค์สมบูรณ์แล้วทันที
          'dtWorkoutDate': workoutDate,
          'dtUpdatedAt': updatedAt,
        };

        await txn.insert(
          tableWorkouts,
          mapToInsert,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        affectedCount++;
      }
    });

    return affectedCount;
  }

  /// อ่านเวลาการดึงข้อมูลล่าสุด (dtLastWorkoutSync) จาก TbHealthIntegrations หรือ Session
  Future<String?> getLastWorkoutSyncTimestamp(int userId) async {
    if (kIsWeb) return null;
    final db = await database;
    if (db == null) return null;
    try {
      final res = await db.query(
        tableHealthIntegrations,
        where: 'nUserId = ? AND sProviderName = ?',
        whereArgs: [userId, 'workout_sync_timestamp'],
        limit: 1,
      );
      if (res.isNotEmpty) {
        return res.first['dtLastSyncedAt']?.toString();
      }
    } catch (_) {}
    return null;
  }

  /// บันทึกเวลาซิงค์ล่าสุด (Save Last Sync Timestamp)
  Future<void> setLastWorkoutSyncTimestamp(int userId, String timestamp) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      await db.insert(
        tableHealthIntegrations,
        {
          'nUserId': userId,
          'sProviderName': 'workout_sync_timestamp',
          'isSynced': 1,
          'dtLastSyncedAt': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('AppDatabase: Error saving workout sync timestamp: $e');
    }
  }

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

  /// ตรวจสอบการเข้าสู่ระบบ (รองรับทั้ง Salted Hash ใหม่ และ Legacy SHA-256 เดิม)
  Future<bool> authenticateUser(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final saltedHash = hashPassword(password, salt: cleanEmail);
    final legacyHash = hashPasswordLegacy(password);

    if (kIsWeb) {
      if (_webUsers.isEmpty) return false;
      final user = _webUsers.firstWhere(
        (u) => u['sEmail']?.toString().toLowerCase() == cleanEmail,
        orElse: () => {},
      );
      if (user.isNotEmpty && user['sPasswordHash'] != null) {
        final stored = user['sPasswordHash'].toString();
        return stored == saltedHash || stored == legacyHash || stored == password;
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
        return storedHash == saltedHash || storedHash == legacyHash || storedHash == password;
      }
    }
    return false;
  }

  // ==========================================
  // Goal Operations (TbGoals)
  // ==========================================

  Future<Map<String, dynamic>?> getUserGoal(int userId) async {
    final db = await database;
    if (db == null) return null;
    final maps = await db.query(
      'TbGoals',
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'nGoalId DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<void> saveUserGoal({
    required int userId,
    int nRoutineId = 0,
    required String title,
    required double progress,
    required String remainingText,
  }) async {
    final db = await database;
    if (db == null) return;
    final existing = await getUserGoal(userId);
    if (existing != null) {
      await db.update(
        'TbGoals',
        {
          'nRoutineId': nRoutineId,
          'sTitle': title,
          'nProgress': progress,
          'sRemainingText': remainingText,
          'dtUpdatedAt': DateTime.now().toIso8601String(),
        },
        where: 'nGoalId = ?',
        whereArgs: [existing['nGoalId']],
      );
    } else {
      await db.insert('TbGoals', {
        'nUserId': userId,
        'nRoutineId': nRoutineId,
        'sTitle': title,
        'nProgress': progress,
        'sRemainingText': remainingText,
        'dtUpdatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> clearUserGoal(int userId) async {
    final db = await database;
    if (db == null) return;
    await db.delete('TbGoals', where: 'nUserId = ?', whereArgs: [userId]);
  }

  // ==========================================
  // Preferences Operations (TbUserPreferences)
  // ==========================================

  Future<String> getUserUnitPreference(int userId) async {
    final db = await database;
    if (db == null) return 'Kilometers, Kilograms';
    final maps = await db.query(
      'TbUserPreferences',
      where: 'nUserId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isNotEmpty && maps.first['sUnitLabel'] != null) {
      return maps.first['sUnitLabel'].toString();
    }
    return 'Kilometers, Kilograms';
  }

  Future<void> saveUserUnitPreference(int userId, String unitLabel) async {
    final db = await database;
    if (db == null) return;
    final existing = await db.query(
      'TbUserPreferences',
      where: 'nUserId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await db.update(
        'TbUserPreferences',
        {
          'sUnitSystem': unitLabel.startsWith('Kilo') ? 'metric' : 'imperial',
          'sUnitLabel': unitLabel,
        },
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
    } else {
      await db.insert(
        'TbUserPreferences',
        {
          'nUserId': userId,
          'sUnitSystem': unitLabel.startsWith('Kilo') ? 'metric' : 'imperial',
          'sUnitLabel': unitLabel,
          'sGeminiApiKey': '',
        },
      );
    }
  }

  Future<String> getGeminiApiKey(int userId) async {
    final db = await database;
    if (db == null) return '';
    try {
      final maps = await db.query(
        'TbUserPreferences',
        where: 'nUserId = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (maps.isNotEmpty && maps.first['sGeminiApiKey'] != null) {
        return maps.first['sGeminiApiKey'].toString();
      }
    } catch (e) {
      debugPrint('getGeminiApiKey error: $e');
    }
    return '';
  }

  Future<void> saveGeminiApiKey(int userId, String apiKey) async {
    final db = await database;
    if (db == null) return;
    try {
      // ตรวจสอบและสร้างคอลัมน์ sGeminiApiKey หากยังไม่มี (กรณี database เก่าค้าง)
      try {
        await db.execute('ALTER TABLE TbUserPreferences ADD COLUMN sGeminiApiKey TEXT DEFAULT ""');
      } catch (_) {
        // มี column อยู่แล้ว ข้ามได้
      }

      final existing = await db.query(
        'TbUserPreferences',
        where: 'nUserId = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        await db.update(
          'TbUserPreferences',
          {'sGeminiApiKey': apiKey.trim()},
          where: 'nUserId = ?',
          whereArgs: [userId],
        );
      } else {
        await db.insert(
          'TbUserPreferences',
          {
            'nUserId': userId,
            'sUnitSystem': 'metric',
            'sUnitLabel': 'Kilometers, Kilograms',
            'sGeminiApiKey': apiKey.trim(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('saveGeminiApiKey error: $e');
      rethrow;
    }
  }

  Future<int> getWorkoutCount({required int userId}) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $tableWorkouts WHERE nUserId = ?',
      [userId],
    );
    if (result.isNotEmpty) {
      return (result.first['cnt'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  // ==========================================
  // Connected Devices (TbHealthIntegrations)
  // ==========================================

  Future<List<Map<String, dynamic>>> getConnectedDevices(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    return await db.query(
      tableHealthIntegrations,
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'nIntegrationId ASC',
    );
  }

  Future<int> insertConnectedDevice({
    required int userId,
    required String providerName,
    bool isSynced = true,
  }) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;
    return await db.insert(
      tableHealthIntegrations,
      {
        'nUserId': userId,
        'sProviderName': providerName,
        'isSynced': isSynced ? 1 : 0,
        'dtLastSyncedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> updateConnectedDeviceStatus({
    required int integrationId,
    required bool isSynced,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.update(
      tableHealthIntegrations,
      {
        'isSynced': isSynced ? 1 : 0,
        'dtLastSyncedAt': DateTime.now().toIso8601String(),
      },
      where: 'nIntegrationId = ?',
      whereArgs: [integrationId],
    );
  }

  Future<void> deleteConnectedDevice(int integrationId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete(
      tableHealthIntegrations,
      where: 'nIntegrationId = ?',
      whereArgs: [integrationId],
    );
  }

  // ==========================================
  // Nutrition Logs Operations (TbNutritionLogs)
  // ==========================================

  Future<int> insertNutritionLog({
    required int userId,
    required String mealType,
    required String foodName,
    required int calories,
    double protein = 0.0,
    double carbs = 0.0,
    double fat = 0.0,
    String servingSize = '',
    String imagePath = '',
  }) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;

    return await db.insert(tableNutritionLogs, {
      'nUserId': userId,
      'sMealType': mealType,
      'sFoodName': foodName,
      'nCalories': calories,
      'nProtein': protein,
      'nCarbs': carbs,
      'nFat': fat,
      'sServingSize': servingSize,
      'sImagePath': imagePath,
      'isSynced': 0,
      'dtLoggedAt': DateTime.now().toIso8601String(),
      'dtUpdatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getNutritionLogsToday(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return await db.query(
      tableNutritionLogs,
      where: 'nUserId = ? AND dtLoggedAt LIKE ?',
      whereArgs: [userId, '$todayStr%'],
      orderBy: 'nNutritionId DESC',
    );
  }

  Future<void> deleteNutritionLog(int nutritionId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete(
      tableNutritionLogs,
      where: 'nNutritionId = ?',
      whereArgs: [nutritionId],
    );
  }

  // ==========================================
  // Offline-First Sync Flags & Operations
  // ==========================================

  /// คำนวณจำนวนแถวข้อมูลที่ยังไม่ได้ซิงค์ทั้งหมด (isSynced = 0)
  Future<int> getPendingSyncCount() async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;

    int total = 0;
    try {
      final r1 = await db.rawQuery('SELECT COUNT(*) as cnt FROM $tableHealthRecords WHERE isSynced = 0');
      total += (r1.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    try {
      final r2 = await db.rawQuery('SELECT COUNT(*) as cnt FROM $tableWorkouts WHERE isSynced = 0');
      total += (r2.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    try {
      final r3 = await db.rawQuery('SELECT COUNT(*) as cnt FROM $tableNutritionLogs WHERE isSynced = 0');
      total += (r3.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    try {
      final r4 = await db.rawQuery('SELECT COUNT(*) as cnt FROM $tableUsers WHERE isSynced = 0');
      total += (r4.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    return total;
  }

  /// ดึงข้อมูล HealthRecords ที่ยังไม่ซิงค์
  Future<List<Map<String, dynamic>>> getUnsyncedHealthRecords() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(tableHealthRecords, where: 'isSynced = 0');
    } catch (_) {
      return [];
    }
  }

  /// มาร์กว่า HealthRecord ซิงค์สำเร็จแล้ว
  Future<void> markHealthRecordAsSynced(int recordId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      await db.update(
        tableHealthRecords,
        {'isSynced': 1, 'dtUpdatedAt': DateTime.now().toIso8601String()},
        where: 'nRecordId = ?',
        whereArgs: [recordId],
      );
    } catch (_) {}
  }

  /// ดึงข้อมูล Workouts ที่ยังไม่ซิงค์
  Future<List<Map<String, dynamic>>> getUnsyncedWorkouts() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(tableWorkouts, where: 'isSynced = 0');
    } catch (_) {
      return [];
    }
  }

  /// มาร์กว่า Workout ซิงค์สำเร็จแล้ว
  Future<void> markWorkoutAsSynced(int workoutId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      await db.update(
        tableWorkouts,
        {'isSynced': 1, 'dtUpdatedAt': DateTime.now().toIso8601String()},
        where: 'nWorkoutId = ?',
        whereArgs: [workoutId],
      );
    } catch (_) {}
  }

  /// ดึงข้อมูล NutritionLogs ที่ยังไม่ซิงค์
  Future<List<Map<String, dynamic>>> getUnsyncedNutritionLogs() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(tableNutritionLogs, where: 'isSynced = 0');
    } catch (_) {
      return [];
    }
  }

  /// มาร์กว่า NutritionLog ซิงค์สำเร็จแล้ว
  Future<void> markNutritionLogAsSynced(int nutritionId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      await db.update(
        tableNutritionLogs,
        {'isSynced': 1, 'dtUpdatedAt': DateTime.now().toIso8601String()},
        where: 'nNutritionId = ?',
        whereArgs: [nutritionId],
      );
    } catch (_) {}
  }

  /// ดึงข้อมูล Users ที่ยังไม่ซิงค์
  Future<List<Map<String, dynamic>>> getUnsyncedUsers() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(tableUsers, where: 'isSynced = 0');
    } catch (_) {
      return [];
    }
  }

  /// มาร์กว่า User ซิงค์สำเร็จแล้ว
  Future<void> markUserAsSynced(int userId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      await db.update(
        tableUsers,
        {'isSynced': 1, 'dtUpdatedAt': DateTime.now().toIso8601String()},
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
    } catch (_) {}
  }

  // ==========================================
  // TbRoutines CRUD Operations
  // ==========================================

  /// ดึงกิจวัตรทั้งหมดของผู้ใช้
  Future<List<Map<String, dynamic>>> getRoutines({required int userId}) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(
        tableRoutines,
        where: 'nUserId = ?',
        whereArgs: [userId],
        orderBy: 'nRoutineId ASC',
      );
    } catch (e) {
      debugPrint('[AppDatabase] getRoutines error: $e');
      return [];
    }
  }

  /// เพิ่มกิจวัตรใหม่
  Future<int> insertRoutine({
    required int userId,
    required String title,
    String time = '',
    double targetValue = 1.0,
    String unit = 'ครั้ง',
    String linkedWorkout = '',
    int? color,
    int? iconData,
    bool isNotificationActive = true,
  }) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;
    try {
      return await db.insert(tableRoutines, {
        'nUserId': userId,
        'sTitle': title,
        'sTime': time,
        'targetValue': targetValue,
        'unit': unit,
        'sLinkedWorkout': linkedWorkout,
        'color': ?color,
        'iconData': ?iconData,
        'isNotificationActive': isNotificationActive ? 1 : 0,
        'dtCreatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[AppDatabase] insertRoutine error: $e');
      return 0;
    }
  }

  /// แก้ไขกิจวัตร
  Future<void> updateRoutine({
    required int routineId,
    required String title,
    String time = '',
    double? targetValue,
    String? unit,
    String? linkedWorkout,
    int? color,
    int? iconData,
    bool isNotificationActive = true,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      final updateData = <String, dynamic>{
        'sTitle': title,
        'sTime': time,
        'isNotificationActive': isNotificationActive ? 1 : 0,
      };
      if (targetValue != null) updateData['targetValue'] = targetValue;
      if (unit != null) updateData['unit'] = unit;
      if (linkedWorkout != null) updateData['sLinkedWorkout'] = linkedWorkout;
      if (color != null) updateData['color'] = color;
      if (iconData != null) updateData['iconData'] = iconData;

      await db.update(
        tableRoutines,
        updateData,
        where: 'nRoutineId = ?',
        whereArgs: [routineId],
      );
    } catch (e) {
      debugPrint('[AppDatabase] updateRoutine error: $e');
    }
  }

  /// ลบกิจวัตร (cascade จะลบ RoutineLogs ให้อัตโนมัติ)
  Future<void> deleteRoutine(int routineId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      // ลบ logs ก่อน (กรณี PRAGMA foreign_keys ไม่ได้เปิด)
      await db.delete(
        tableRoutineLogs,
        where: 'nRoutineId = ?',
        whereArgs: [routineId],
      );
      await db.delete(
        tableRoutines,
        where: 'nRoutineId = ?',
        whereArgs: [routineId],
      );
    } catch (e) {
      debugPrint('[AppDatabase] deleteRoutine error: $e');
    }
  }

  // ==========================================
  // TbRoutineLogs CRUD Operations
  // ==========================================

  /// ดึง log ของกิจวัตรในวันที่ระบุ
  Future<Map<String, dynamic>?> getRoutineLogForDate({
    required int routineId,
    required String dateStr, // 'yyyy-MM-dd'
  }) async {
    if (kIsWeb) return null;
    final db = await database;
    if (db == null) return null;
    try {
      final result = await db.query(
        tableRoutineLogs,
        where: 'nRoutineId = ? AND dtLogDate = ?',
        whereArgs: [routineId, dateStr],
        limit: 1,
      );
      if (result.isNotEmpty) return result.first;
    } catch (e) {
      debugPrint('[AppDatabase] getRoutineLogForDate error: $e');
    }
    return null;
  }

  /// ดึง logs ของกิจวัตรทั้งหมดของ user ในวันที่ระบุ
  Future<List<Map<String, dynamic>>> getRoutineLogsForDate({
    required int userId,
    required String dateStr, // 'yyyy-MM-dd'
  }) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.rawQuery('''
        SELECT rl.*, r.sTitle, r.sTime, r.isNotificationActive
        FROM $tableRoutineLogs rl
        INNER JOIN $tableRoutines r ON rl.nRoutineId = r.nRoutineId
        WHERE r.nUserId = ? AND rl.dtLogDate = ?
      ''', [userId, dateStr]);
    } catch (e) {
      debugPrint('[AppDatabase] getRoutineLogsForDate error: $e');
      return [];
    }
  }

  /// สลับสถานะ เช็ค / ยกเลิกเช็ค กิจวัตรของวันนั้น
  /// คืนค่า true = เช็คแล้ว, false = ยกเลิกเช็ค
  Future<bool> toggleRoutineLog({
    required int routineId,
    required String dateStr, // 'yyyy-MM-dd'
  }) async {
    if (kIsWeb) return false;
    final db = await database;
    if (db == null) return false;
    try {
      final existing = await getRoutineLogForDate(
        routineId: routineId,
        dateStr: dateStr,
      );

      if (existing == null) {
        // ยังไม่มี → สร้างใหม่เป็น completed
        await db.insert(tableRoutineLogs, {
          'nRoutineId': routineId,
          'isCompleted': 1,
          'dtLogDate': dateStr,
        });
        debugPrint('[AppDatabase] ✅ toggleRoutineLog: routineId=$routineId → checked');
        return true;
      } else {
        // มีอยู่แล้ว → toggle
        final wasCompleted = (existing['isCompleted'] as num?)?.toInt() == 1;
        final newVal = wasCompleted ? 0 : 1;
        await db.update(
          tableRoutineLogs,
          {'isCompleted': newVal},
          where: 'nLogId = ?',
          whereArgs: [existing['nLogId']],
        );
        debugPrint('[AppDatabase] 🔄 toggleRoutineLog: routineId=$routineId → ${newVal == 1 ? "checked" : "unchecked"}');
        return newVal == 1;
      }
    } catch (e) {
      debugPrint('[AppDatabase] toggleRoutineLog error: $e');
      return false;
    }
  }

  /// นับจำนวนกิจวัตรที่เสร็จแล้วในวันนั้น
  Future<int> getRoutineCompletionCount({
    required int userId,
    required String dateStr,
  }) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;
    try {
      final result = await db.rawQuery('''
        SELECT COUNT(*) as cnt
        FROM $tableRoutineLogs rl
        INNER JOIN $tableRoutines r ON rl.nRoutineId = r.nRoutineId
        WHERE r.nUserId = ? AND rl.dtLogDate = ? AND rl.isCompleted = 1
      ''', [userId, dateStr]);
      if (result.isNotEmpty) {
        return (result.first['cnt'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      debugPrint('[AppDatabase] getRoutineCompletionCount error: $e');
    }
    return 0;
  }

  Future<void> updateLocalPassword(String email, String newPassword) async {
    final cleanEmail = email.trim().toLowerCase();
    final hashedPassword = hashPassword(newPassword, salt: cleanEmail);

    if (kIsWeb) {
      final idx = _webUsers.indexWhere((u) => u['sEmail']?.toString().toLowerCase() == cleanEmail);
      if (idx != -1) {
        _webUsers[idx]['sPasswordHash'] = hashedPassword;
      }
      return;
    }

    final db = await database;
    if (db == null) return;
    await db.update(
      tableUsers,
      {'sPasswordHash': hashedPassword, 'isSynced': 1},
      where: 'LOWER(sEmail) = ?',
      whereArgs: [cleanEmail],
    );
  }
}
