part of '../../app_database.dart';

// ส่วนการลงทะเบียนและอัปเดตข้อมูลผู้ใช้ (AppDatabaseRegistrationDao)
// ทำหน้าที่สร้างบัญชีใหม่, อัปเดตข้อมูลผู้ใช้ และเชื่อมโยงข้อมูลจากเซิร์ฟเวอร์ (User Hydration)
extension AppDatabaseRegistrationDao on AppDatabase {
  // ฟังก์ชัน: บันทึกข้อมูลการสมัครสมาชิกใหม่ลงในตาราง TbUsers
  Future<TbUser> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();
    final hashedPassword = AppDatabase.hashPassword(password);

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

  // ฟังก์ชัน: อัปเดตข้อมูลผู้ใช้ในตาราง TbUsers
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

  // ฟังก์ชัน: บันทึกหรืออัปเดตข้อมูลผู้ใช้ที่ได้รับจากเซิร์ฟเวอร์ (User Hydration) ลงใน SQLite
  Future<TbUser> upsertUserFromServer(
    Map<String, dynamic> userMap, {
    String? authenticatedPassword,
  }) async {
    final parsed = TbUser.fromMap(userMap);
    if (parsed.nUserId <= 0 || parsed.sEmail.trim().isEmpty) {
      throw const FormatException('Server returned an invalid user record');
    }
    final user = authenticatedPassword == null
        ? parsed
        : parsed.copyWith(
            sPasswordHash: AppDatabase.hashPassword(authenticatedPassword),
          );
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

      // ป้องกัน Password Hash เสียหาย: หากมี Hash ใน SQLite อยู่แล้ว ให้เก็บของเดิมไว้
      final existing = await db.query(
        AppDatabase.tableUsers,
        where: 'nUserId = ? OR LOWER(sEmail) = ?',
        whereArgs: [user.nUserId, user.sEmail.toLowerCase()],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final existingLocalHash = existing.first['sPasswordHash']?.toString();
        if (existingLocalHash != null && existingLocalHash.isNotEmpty) {
          mapToInsert['sPasswordHash'] = existingLocalHash;
        }
      }

      await db.insert(
        AppDatabase.tableUsers,
        mapToInsert,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return user;
  }
}
