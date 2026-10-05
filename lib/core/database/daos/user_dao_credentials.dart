// ส่วนนี้อธิบายบทบาทของไฟล์: ฐานข้อมูลภายในเครื่องและ DAO สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (user dao credentials)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of '../app_database.dart';

extension AppDatabaseCredentialsDao on AppDatabase {
  Future<bool> authenticateUser(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final legacyHash = AppDatabase.hashPasswordLegacy(password);

    if (kIsWeb) {
      if (_webUsers.isEmpty) return false;
      final user = _webUsers.firstWhere(
        (u) => u['sEmail']?.toString().toLowerCase() == cleanEmail,
        orElse: () => {},
      );
      if (user.isNotEmpty && user['sPasswordHash'] != null) {
        final stored = user['sPasswordHash'].toString();
        if (AppDatabase.verifyPassword(password, stored)) return true;
        final legacyMatched =
            stored ==
                AppDatabase.hashPasswordLegacySalted(password, cleanEmail) ||
            stored == legacyHash ||
            stored == password;
        if (legacyMatched) {
          user['sPasswordHash'] = AppDatabase.hashPassword(password);
        }
        return legacyMatched;
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
        if (AppDatabase.verifyPassword(password, storedHash)) return true;
        final legacyMatched =
            storedHash ==
                AppDatabase.hashPasswordLegacySalted(password, cleanEmail) ||
            storedHash == legacyHash ||
            storedHash == password;
        if (legacyMatched) {
          await db.update(
            AppDatabase.tableUsers,
            {'sPasswordHash': AppDatabase.hashPassword(password)},
            where: 'LOWER(sEmail) = ?',
            whereArgs: [cleanEmail],
          );
        }
        return legacyMatched;
      }
    }
    return false;
  }

  Future<void> updateLocalPassword(String email, String newPassword) async {
    final cleanEmail = email.trim().toLowerCase();
    final hashedPassword = AppDatabase.hashPassword(newPassword);

    if (kIsWeb) {
      final idx = _webUsers.indexWhere(
        (u) => u['sEmail']?.toString().toLowerCase() == cleanEmail,
      );
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
