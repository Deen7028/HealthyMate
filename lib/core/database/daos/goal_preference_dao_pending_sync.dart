// ส่วนนี้อธิบายบทบาทของไฟล์: ฐานข้อมูลภายในเครื่องและ DAO สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (goal preference dao pending sync)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of '../app_database.dart';

extension AppDatabasePendingSyncDao on AppDatabase {
  Future<int> getPendingSyncCount() async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;

    int total = 0;
    try {
      final r1 = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppDatabase.tableHealthRecords} WHERE isSynced = 0',
      );
      total += (r1.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    try {
      final r2 = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppDatabase.tableWorkouts} WHERE isSynced = 0',
      );
      total += (r2.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    try {
      final r3 = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppDatabase.tableNutritionLogs} WHERE isSynced = 0',
      );
      total += (r3.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    try {
      final r4 = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppDatabase.tableUsers} WHERE isSynced = 0',
      );
      total += (r4.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    try {
      final r5 = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppDatabase.tablePendingDeletions}',
      );
      total += (r5.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    return total;
  }

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
