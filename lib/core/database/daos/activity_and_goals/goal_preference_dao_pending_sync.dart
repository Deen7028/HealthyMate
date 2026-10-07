part of '../../app_database.dart';

// ส่วนการจัดการรายการที่รอซิงค์ในฐานข้อมูล (AppDatabasePendingSyncDao)
// ทำหน้าที่นับจำนวนข้อมูลที่ยังไม่ได้ซิงค์ (Unsynced Counter) และจัดการคิวลบข้อมูลออฟไลน์ (Pending Deletions)
extension AppDatabasePendingSyncDao on AppDatabase {
  // ฟังก์ชัน: นับจำนวนรายการข้อมูลทั้งหมดที่รอซิงค์ขึ้น Cloud
  Future<int> getPendingSyncCount() async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;

    int total = 0;
    // 1. นับประวัติสุขภาพที่ยังไม่ซิงค์
    try {
      final r1 = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppDatabase.tableHealthRecords} WHERE isSynced = 0',
      );
      total += (r1.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    // 2. นับประวัติการออกกำลังกายที่ยังไม่ซิงค์
    try {
      final r2 = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppDatabase.tableWorkouts} WHERE isSynced = 0',
      );
      total += (r2.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    // 3. นับบันทึกโภชนาการที่ยังไม่ซิงค์
    try {
      final r3 = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppDatabase.tableNutritionLogs} WHERE isSynced = 0',
      );
      total += (r3.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    // 4. นับโปรไฟล์ผู้ใช้ที่ยังไม่ซิงค์
    try {
      final r4 = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppDatabase.tableUsers} WHERE isSynced = 0',
      );
      total += (r4.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    // 5. นับคิวที่รอลบบนเซิร์ฟเวอร์
    try {
      final r5 = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppDatabase.tablePendingDeletions}',
      );
      total += (r5.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    return total;
  }

  // ฟังก์ชัน: เพิ่มรายการลงคิวรอลบบนเซิร์ฟเวอร์ (Queue Pending Deletion)
  Future<void> queuePendingDeletion({
    required int userId,
    required String entity,
    required int remoteId,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.insert(AppDatabase.tablePendingDeletions, {
      'nUserId': userId,
      'sEntity': entity,
      'nRemoteId': remoteId,
      'dtQueuedAt': DateTime.now().toIso8601String(),
    });
  }

  // ฟังก์ชัน: ดึงรายการคิวรอลบของผู้ใช้
  Future<List<Map<String, dynamic>>> getPendingDeletions(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    return db.query(
      AppDatabase.tablePendingDeletions,
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'nDeletionId ASC',
    );
  }

  // ฟังก์ชัน: ลบรายการออกจากคิว Pending Deletions เมื่อลบสำเร็จแล้ว
  Future<void> completePendingDeletion(int deletionId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete(
      AppDatabase.tablePendingDeletions,
      where: 'nDeletionId = ?',
      whereArgs: [deletionId],
    );
  }
}
