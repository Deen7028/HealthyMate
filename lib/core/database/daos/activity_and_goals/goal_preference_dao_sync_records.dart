part of '../../app_database.dart';

// ส่วนการจัดการข้อมูลและบันทึกสถานะการซิงค์ในฐานข้อมูล (AppDatabaseSyncRecordsDao)
// ทำหน้าที่ดึงรายการที่ยังไม่ได้ซิงค์ (Unsynced Records) และมาร์กสถานะเมื่อซิงค์สำเร็จ (isSynced = 1)
extension AppDatabaseSyncRecordsDao on AppDatabase {
  // ฟังก์ชัน: ดึงประวัติสุขภาพที่ยังไม่ได้ซิงค์ขึ้นเซิร์ฟเวอร์
  Future<List<Map<String, dynamic>>> getUnsyncedHealthRecords(
    int userId,
  ) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(
        AppDatabase.tableHealthRecords,
        where: 'isSynced = 0 AND nUserId = ?',
        whereArgs: [userId],
      );
    } catch (_) {
      return [];
    }
  }

  // ฟังก์ชัน: มาร์กประวัติสุขภาพว่าซิงค์สำเร็จแล้ว
  Future<void> markHealthRecordAsSynced(int recordId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      await db.update(
        AppDatabase.tableHealthRecords,
        {'isSynced': 1, 'dtUpdatedAt': DateTime.now().toIso8601String()},
        where: 'nRecordId = ?',
        whereArgs: [recordId],
      );
    } catch (_) {}
  }

  // ฟังก์ชัน: ดึงกิจกรรมการออกกำลังกายที่ยังไม่ได้ซิงค์
  Future<List<Map<String, dynamic>>> getUnsyncedWorkouts(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(
        AppDatabase.tableWorkouts,
        where: 'isSynced = 0 AND nUserId = ?',
        whereArgs: [userId],
      );
    } catch (_) {
      return [];
    }
  }

  // ฟังก์ชัน: มาร์กกิจกรรมการออกกำลังกายว่าซิงค์สำเร็จแล้ว
  Future<void> markWorkoutAsSynced(int workoutId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      await db.update(
        AppDatabase.tableWorkouts,
        {'isSynced': 1, 'dtUpdatedAt': DateTime.now().toIso8601String()},
        where: 'nWorkoutId = ?',
        whereArgs: [workoutId],
      );
    } catch (_) {}
  }

  // ฟังก์ชัน: ดึงบันทึกโภชนาการที่ยังไม่ได้ซิงค์
  Future<List<Map<String, dynamic>>> getUnsyncedNutritionLogs(
    int userId,
  ) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(
        AppDatabase.tableNutritionLogs,
        where: 'isSynced = 0 AND nUserId = ?',
        whereArgs: [userId],
      );
    } catch (_) {
      return [];
    }
  }

  // ฟังก์ชัน: มาร์กบันทึกโภชนาการว่าซิงค์สำเร็จแล้ว
  Future<void> markNutritionLogAsSynced(int nutritionId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      await db.update(
        AppDatabase.tableNutritionLogs,
        {'isSynced': 1, 'dtUpdatedAt': DateTime.now().toIso8601String()},
        where: 'nNutritionId = ?',
        whereArgs: [nutritionId],
      );
    } catch (_) {}
  }

  // ฟังก์ชัน: ดึงข้อมูลโปรไฟล์ผู้ใช้ที่ยังไม่ได้ซิงค์
  Future<List<Map<String, dynamic>>> getUnsyncedUsers(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(
        AppDatabase.tableUsers,
        where: 'isSynced = 0 AND nUserId = ?',
        whereArgs: [userId],
      );
    } catch (_) {
      return [];
    }
  }

  // ฟังก์ชัน: มาร์กข้อมูลโปรไฟล์ผู้ใช้ว่าซิงค์สำเร็จแล้ว
  Future<void> markUserAsSynced(int userId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      await db.update(
        AppDatabase.tableUsers,
        {'isSynced': 1, 'dtUpdatedAt': DateTime.now().toIso8601String()},
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
    } catch (_) {}
  }
}
