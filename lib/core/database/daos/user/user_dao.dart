part of '../../app_database.dart';

// ส่วนการดึงข้อมูลผู้ใช้จากฐานข้อมูล (AppDatabaseUserDao)
// ทำหน้าที่ค้นหาข้อมูลผู้ใช้ปัจจุบัน, ค้นหาตาม ID, ค้นหาตามอีเมล และตรวจสอบความซ้ำซ้อน
extension AppDatabaseUserDao on AppDatabase {
  // ฟังก์ชัน: ดึงข้อมูลโปรไฟล์ของผู้ใช้ที่ล็อกอินอยู่ในปัจจุบัน
  Future<TbUser?> getCurrentUser() async {
    final email = await getLoggedInUserEmail();
    if (email == null || email.trim().isEmpty) return null;
    return getUserByEmail(email);
  }

  // ฟังก์ชัน: ดึงข้อมูลผู้ใช้จากตาราง TbUsers ตาม nUserId
  Future<TbUser?> getUser({required int userId}) async {
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

  // ฟังก์ชัน: ดึงข้อมูลผู้ใช้จากตาราง TbUsers ตามอีเมล (Case-insensitive)
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

  // ฟังก์ชัน: ดึงอีเมลของผู้ใช้ที่บันทึกอยู่ใน Session ปัจจุบัน
  Future<String?> getLoggedInUserEmail() async {
    if (kIsWeb) {
      return _webSession?['sEmail']?.toString();
    }
    final db = await database;
    if (db == null) return null;
    final maps = await db.query(
      AppDatabase.tableSession,
      where: 'nSessionId = 1',
    );
    if (maps.isNotEmpty) {
      return maps.first['sEmail']?.toString();
    }
    return null;
  }

  // ฟังก์ชัน: ตรวจสอบว่ามีอีเมลนี้อยู่ในระบบแล้วหรือไม่
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
}
