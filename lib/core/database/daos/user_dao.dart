part of '../app_database.dart';

extension AppDatabaseUserDao on AppDatabase {
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
      AppDatabase.tableUsers,
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
      AppDatabase.tableUsers,
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
    final maps = await db.query(AppDatabase.tableSession, where: 'nSessionId = 1');
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
      AppDatabase.tableUsers,
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
    final hashedPassword = AppDatabase.hashPassword(password, salt: cleanEmail);

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
      AppDatabase.tableUsers,
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
      AppDatabase.tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// บันทึกหรืออัปเดตข้อมูลผู้ใช้ที่ได้จาก Server (User Hydration) ลงใน `TbUsers` ของ SQLite
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
      mapToInsert['isSynced'] = 1;
      await db.insert(
        AppDatabase.tableUsers,
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
      await txn.rawDelete('DELETE FROM ${AppDatabase.tableRoutineLogs} WHERE nRoutineId IN (SELECT nRoutineId FROM ${AppDatabase.tableRoutines} WHERE nUserId = ?)', [userId]);
      await txn.delete(AppDatabase.tableRoutines, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(AppDatabase.tableHealthRecords, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(AppDatabase.tableNutritionLogs, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(AppDatabase.tableWorkouts, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(AppDatabase.tableHealthIntegrations, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(AppDatabase.tableUserBadges, where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete('TbGoals', where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete('TbUserPreferences', where: 'nUserId = ?', whereArgs: [userId]);
      await txn.delete(AppDatabase.tableUsers, where: 'nUserId = ?', whereArgs: [userId]);
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
    final maps = await db.query(AppDatabase.tableSession, where: 'nSessionId = 1');
    if (maps.isNotEmpty) {
      return (maps.first['isLoggedIn'] as num?)?.toInt() == 1;
    }
    return false;
  }

  /// บันทึกสถานะการล็อกอิน
  Future<void> setLoginStatus(bool isLoggedIn, {String? email, String? token}) async {
    if (kIsWeb) {
      _webSession = {
        'nSessionId': 1,
        'isLoggedIn': isLoggedIn,
        'sEmail': email ?? '',
        'sAuthToken': token ?? _webSession?['sAuthToken'] ?? '',
        'dtUpdatedAt': DateTime.now().toIso8601String(),
      };
      return;
    }

    final db = await database;
    if (db == null) return;
    
    final Map<String, dynamic> data = {
      'nSessionId': 1,
      'isLoggedIn': isLoggedIn ? 1 : 0,
      'sEmail': email ?? '',
      'dtUpdatedAt': DateTime.now().toIso8601String(),
    };
    if (token != null) {
      data['sAuthToken'] = token;
    } else {
      final existing = await getAuthToken();
      if (existing != null && existing.isNotEmpty) {
        data['sAuthToken'] = existing;
      }
    }

    await db.insert(AppDatabase.tableSession, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// ดึง Auth Token ล่าสุด
  Future<String?> getAuthToken() async {
    if (kIsWeb) {
      return _webSession?['sAuthToken']?.toString();
    }
    final db = await database;
    if (db == null) return null;
    try {
      final maps = await db.query(AppDatabase.tableSession, where: 'nSessionId = 1');
      if (maps.isNotEmpty) {
        final token = maps.first['sAuthToken']?.toString();
        if (token != null && token.isNotEmpty) return token;
      }
    } catch (_) {}
    return null;
  }

  /// ตรวจสอบการเข้าสู่ระบบ
  Future<bool> authenticateUser(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final saltedHash = AppDatabase.hashPassword(password, salt: cleanEmail);
    final legacyHash = AppDatabase.hashPasswordLegacy(password);

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
      AppDatabase.tableUsers,
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

  Future<void> updateLocalPassword(String email, String newPassword) async {
    final cleanEmail = email.trim().toLowerCase();
    final hashedPassword = AppDatabase.hashPassword(newPassword, salt: cleanEmail);

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
      AppDatabase.tableUsers,
      {'sPasswordHash': hashedPassword, 'isSynced': 1},
      where: 'LOWER(sEmail) = ?',
      whereArgs: [cleanEmail],
    );
  }
}
