// ส่วนนี้อธิบายบทบาทของไฟล์: ฐานข้อมูลภายในเครื่องและ DAO สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (user dao session)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of '../app_database.dart';

extension AppDatabaseSessionDao on AppDatabase {
  Future<void> deleteUserAccount(int userId) async {
    if (kIsWeb) {
      _webUsers.removeWhere((u) => u['nUserId'] == userId);
      _webHealthRecords.removeWhere((r) => r['nUserId'] == userId);
      return;
    }

    try {
      await AppDatabase._secureStorage.delete(key: 'gemini_api_key_$userId');
      await AppDatabase._secureStorage.delete(key: 'auth_token');
    } catch (_) {}

    final db = await database;
    if (db == null) return;

    await db.transaction((txn) async {
      await txn.rawDelete(
        'DELETE FROM ${AppDatabase.tableRoutineLogs} WHERE nRoutineId IN (SELECT nRoutineId FROM ${AppDatabase.tableRoutines} WHERE nUserId = ?)',
        [userId],
      );
      await txn.delete(
        AppDatabase.tableRoutines,
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        AppDatabase.tableHealthRecords,
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        AppDatabase.tableNutritionLogs,
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        AppDatabase.tableWorkouts,
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        AppDatabase.tableHealthIntegrations,
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        AppDatabase.tablePendingDeletions,
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        AppDatabase.tableUserBadges,
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
      await txn.delete('TbGoals', where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(
        'TbUserPreferences',
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        AppDatabase.tableUsers,
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
      await txn.delete(AppDatabase.tableSession);
    });
  }

  /// ดึงสถานะการล็อกอินปัจจุบัน

  Future<bool> getLoginStatus() async {
    if (kIsWeb) {
      return _webSession?['isLoggedIn'] == true;
    }

    final db = await database;
    if (db == null) return false;
    final maps = await db.query(
      AppDatabase.tableSession,
      where: 'nSessionId = 1',
    );
    if (maps.isNotEmpty) {
      return (maps.first['isLoggedIn'] as num?)?.toInt() == 1;
    }
    return false;
  }

  /// บันทึกสถานะการล็อกอิน

  Future<void> setLoginStatus(
    bool isLoggedIn, {
    String? email,
    String? token,
  }) async {
    if (kIsWeb) {
      _webSession = {
        'nSessionId': 1,
        'isLoggedIn': isLoggedIn,
        'sEmail': email ?? '',
        'sAuthToken': isLoggedIn ? (token ?? '') : '',
        'dtUpdatedAt': DateTime.now().toIso8601String(),
      };
      return;
    }

    final db = await database;
    if (db == null) return;

    try {
      if (isLoggedIn && token != null && token.isNotEmpty) {
        await AppDatabase._secureStorage.write(key: 'auth_token', value: token);
      } else {
        // Never carry a token across local/offline login or logout.
        await AppDatabase._secureStorage.delete(key: 'auth_token');
      }
    } catch (_) {}

    final Map<String, dynamic> data = {
      'nSessionId': 1,
      'isLoggedIn': isLoggedIn ? 1 : 0,
      'sEmail': email ?? '',
      'sAuthToken': '',
      'dtUpdatedAt': DateTime.now().toIso8601String(),
    };

    await db.insert(
      AppDatabase.tableSession,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// ดึง Auth Token ล่าสุด

  Future<String?> getAuthToken() async {
    if (kIsWeb) {
      return _webSession?['sAuthToken']?.toString();
    }
    String? secureToken;
    try {
      secureToken = await AppDatabase._secureStorage.read(key: 'auth_token');
    } catch (_) {
      return null;
    }
    if (secureToken != null && secureToken.isNotEmpty) return secureToken;
    final db = await database;
    if (db == null) return null;
    try {
      final maps = await db.query(
        AppDatabase.tableSession,
        where: 'nSessionId = 1',
      );
      if (maps.isNotEmpty) {
        final token = maps.first['sAuthToken']?.toString();
        if (token != null && token.isNotEmpty) {
          await AppDatabase._secureStorage.write(
            key: 'auth_token',
            value: token,
          );
          await db.update(AppDatabase.tableSession, {
            'sAuthToken': '',
          }, where: 'nSessionId = 1');
          return token;
        }
      }
    } catch (_) {}
    return null;
  }

  /// ตรวจสอบการเข้าสู่ระบบ
}
