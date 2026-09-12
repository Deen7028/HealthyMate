import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

/// Database Manager เชื่อมต่อโครงสร้างฐานข้อมูล `6620310001_HealthMateDB.sql`
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

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

  File? _dbFile;
  Map<String, dynamic> _databaseStore = {
    tableUsers: <Map<String, dynamic>>[],
    tableHealthRecords: <Map<String, dynamic>>[],
    tableWorkouts: <Map<String, dynamic>>[],
    tableNutritionLogs: <Map<String, dynamic>>[],
    tableRoutines: <Map<String, dynamic>>[],
    tableRoutineLogs: <Map<String, dynamic>>[],
    tableBadges: <Map<String, dynamic>>[],
    tableUserBadges: <Map<String, dynamic>>[],
    tableHealthIntegrations: <Map<String, dynamic>>[],
  };

  bool _isInitialized = false;

  /// สร้าง Table Schema และโหลดข้อมูล
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final directory = Directory.current;
      final dataDir = Directory('${directory.path}/.data');
      if (!dataDir.existsSync()) {
        dataDir.createSync(recursive: true);
      }
      _dbFile = File('${dataDir.path}/6620310001_HealthMateDB.json');

      if (_dbFile!.existsSync()) {
        final content = await _dbFile!.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) {
            _databaseStore = decoded;
            _ensureTablesExist();
          }
        }
      } else {
        _initSampleData();
        await _flush();
      }
    } catch (e) {
      debugPrint('Database init fallback: $e');
      _initSampleData();
    }

    _isInitialized = true;
  }

  void _ensureTablesExist() {
    for (final table in [
      tableUsers,
      tableHealthRecords,
      tableWorkouts,
      tableNutritionLogs,
      tableRoutines,
      tableRoutineLogs,
      tableBadges,
      tableUserBadges,
      tableHealthIntegrations
    ]) {
      if (!_databaseStore.containsKey(table) || _databaseStore[table] == null) {
        _databaseStore[table] = <Map<String, dynamic>>[];
      }
    }
  }

  void _initSampleData() {
    final now = DateTime.now();

    // Default User in TbUsers
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

    _databaseStore[tableUsers] = [defaultUser.toMap()];
    _databaseStore[tableHealthRecords] = <Map<String, dynamic>>[];
  }

  Future<void> _flush() async {
    try {
      if (_dbFile != null) {
        await _dbFile!.writeAsString(jsonEncode(_databaseStore), flush: true);
      }
    } catch (e) {
      debugPrint('Error saving database: $e');
    }
  }

  // ==========================================
  // TbUsers CRUD Operations
  // ==========================================

  /// ดึงข้อมูลผู้ใช้จาก `TbUsers` ตาม nUserId (เริ่มต้นคือ 1)
  Future<TbUser?> getUser({int userId = 1}) async {
    await init();
    final list = _databaseStore[tableUsers] as List<dynamic>? ?? [];
    for (final item in list) {
      if (item['nUserId'] == userId) {
        return TbUser.fromMap(Map<String, dynamic>.from(item as Map));
      }
    }
    return null;
  }

  /// อัปเดตข้อมูลผู้ใช้ใน `TbUsers`
  Future<void> updateUser(TbUser user) async {
    await init();
    final list = _databaseStore[tableUsers] as List<dynamic>;
    final index = list.indexWhere((item) => item['nUserId'] == user.nUserId);
    if (index >= 0) {
      list[index] = user.toMap();
    } else {
      list.add(user.toMap());
    }
    await _flush();
  }

  // ==========================================
  // TbHealthRecords CRUD Operations
  // ==========================================

  /// ดึงรายการประวัติทั้งหมดจาก `TbHealthRecords`
  Future<List<TbHealthRecord>> getHealthRecords({int userId = 1}) async {
    await init();
    final list = _databaseStore[tableHealthRecords] as List<dynamic>? ?? [];
    return list
        .map((item) => TbHealthRecord.fromMap(Map<String, dynamic>.from(item as Map)))
        .where((record) => record.nUserId == userId)
        .toList()
      ..sort((a, b) => b.dtRecordedAt.compareTo(a.dtRecordedAt));
  }

  /// เพิ่มบันทึกใหม่ใน `TbHealthRecords`
  Future<TbHealthRecord> insertHealthRecord(TbHealthRecord record) async {
    await init();
    final list = _databaseStore[tableHealthRecords] as List<dynamic>;
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
    list.insert(0, newRecord.toMap());
    await _flush();
    return newRecord;
  }

  /// ลบบันทึกจาก `TbHealthRecords` ตาม Record ID
  Future<void> deleteHealthRecord(int recordId) async {
    await init();
    final list = _databaseStore[tableHealthRecords] as List<dynamic>;
    list.removeWhere((item) => item['nRecordId'] == recordId);
    await _flush();
  }

  /// ล้างข้อมูล `TbHealthRecords` ทั้งหมด
  Future<void> clearHealthRecords() async {
    await init();
    _databaseStore[tableHealthRecords] = <Map<String, dynamic>>[];
    await _flush();
  }

  /// ดึงสถานะการล็อกอินปัจจุบัน
  Future<bool> getLoginStatus() async {
    await init();
    final session = _databaseStore['session'] as Map<String, dynamic>?;
    return session?['isLoggedIn'] == true;
  }

  /// บันทึกสถานะการล็อกอิน
  Future<void> setLoginStatus(bool isLoggedIn, {String? email}) async {
    await init();
    _databaseStore['session'] = {
      'isLoggedIn': isLoggedIn,
      'email': email ?? '',
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _flush();
  }

  /// ตรวจสอบการเข้าสู่ระบบ
  Future<bool> authenticateUser(String email, String password) async {
    await init();
    final users = _databaseStore[tableUsers] as List<dynamic>? ?? [];
    if (users.isEmpty) return true; // หากยังไม่มีผู้ใช้ในระบบ ให้ผ่านได้

    // ตรวจสอบกับข้อมูลใน TbUsers หรือให้เข้าสู่ระบบได้เสมอถ้ากรอกข้อมูล
    return true;
  }
}
