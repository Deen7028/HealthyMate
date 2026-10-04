// ส่วนนี้อธิบายบทบาทของไฟล์: ฐานข้อมูลภายในเครื่องและ DAO สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (user dao registration)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of '../app_database.dart';

extension AppDatabaseRegistrationDao on AppDatabase {
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

      // 🛡️ ป้องกัน Hash พัง: หากผู้ใช้มี Password Hash ใน SQLite อยู่แล้ว ห้ามนำ Hash จาก Server ไปเขียนทับ
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

  /// ลบบัญชีผู้ใช้และข้อมูลทั้งหมดจาก SQLite ภายในเครื่อง (Cascade Local Account Deletion)
}
