part of '../../app_database.dart';

// ส่วนการจัดการการแจ้งเตือนในฐานข้อมูล (AppDatabaseNotificationDao)
// ทำหน้าที่บันทึกการแจ้งเตือน, ดึงรายการแจ้งเตือน, นับจำนวนที่ยังไม่อ่าน และจัดการสถานะอ่านแล้ว
extension AppDatabaseNotificationDao on AppDatabase {
  // ฟังก์ชัน: เพิ่มรายการแจ้งเตือนใหม่ลงในตาราง TbNotifications
  Future<int> insertNotification({
    required int userId,
    required String type,
    required String title,
    required String message,
    String actionType = '',
    String actionPayload = '',
  }) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;

    return await db.insert(AppDatabase.tableNotifications, {
      'nUserId': userId,
      'sType': type,
      'sTitle': title,
      'sMessage': message,
      'sActionType': actionType,
      'sActionPayload': actionPayload,
      'isRead': 0,
      'dtCreatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ฟังก์ชัน: ดึงรายการแจ้งเตือนทั้งหมดของผู้ใช้ เรียงจากล่าสุดไปเก่าสุด
  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];

    return await db.query(
      AppDatabase.tableNotifications,
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'dtCreatedAt DESC',
    );
  }

  // ฟังก์ชัน: ดึงจำนวนการแจ้งเตือนที่ยังไม่ได้อ่านของผู้ใช้ (Unread Count)
  Future<int> getUnreadNotificationCount(int userId) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${AppDatabase.tableNotifications} WHERE nUserId = ? AND isRead = 0',
      [userId],
    );
    if (result.isNotEmpty) {
      return (result.first['cnt'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  // ฟังก์ชัน: มาร์กการแจ้งเตือนรายการหนึ่งว่าอ่านแล้ว (isRead = 1)
  Future<void> markNotificationAsRead(int notificationId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;

    await db.update(
      AppDatabase.tableNotifications,
      {'isRead': 1},
      where: 'nNotificationId = ?',
      whereArgs: [notificationId],
    );
  }

  // ฟังก์ชัน: มาร์กการแจ้งเตือนทั้งหมดของผู้ใช้ว่าอ่านแล้ว
  Future<void> markAllNotificationsAsRead(int userId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;

    await db.update(
      AppDatabase.tableNotifications,
      {'isRead': 1},
      where: 'nUserId = ?',
      whereArgs: [userId],
    );
  }

  // ฟังก์ชัน: ลบการแจ้งเตือนรายการที่ระบุ
  Future<void> deleteNotification(int notificationId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;

    await db.delete(
      AppDatabase.tableNotifications,
      where: 'nNotificationId = ?',
      whereArgs: [notificationId],
    );
  }

  // ฟังก์ชัน: ลบการแจ้งเตือนทั้งหมดของผู้ใช้
  Future<void> clearAllNotifications(int userId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;

    await db.delete(
      AppDatabase.tableNotifications,
      where: 'nUserId = ?',
      whereArgs: [userId],
    );
  }
}
