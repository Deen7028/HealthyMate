// ส่วนนี้อธิบายบทบาทของไฟล์: ฐานข้อมูลภายในเครื่องและ DAO สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (routine dao history)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of '../app_database.dart';

extension AppDatabaseHistoryDao on AppDatabase {
  Future<int> getRoutineCompletionCount({
    required int userId,
    required String dateStr,
  }) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;
    try {
      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) as cnt
        FROM ${AppDatabase.tableRoutineLogs} rl
        INNER JOIN ${AppDatabase.tableRoutines} r ON rl.nRoutineId = r.nRoutineId
        WHERE r.nUserId = ? AND rl.dtLogDate = ? AND rl.isCompleted = 1
      ''',
        [userId, dateStr],
      );
      if (result.isNotEmpty) {
        return (result.first['cnt'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      debugPrint('[AppDatabase] getRoutineCompletionCount error: $e');
    }
    return 0;
  }

  /// ดึงประวัติกิจวัตรที่ทำสำเร็จย้อนหลัง (ค่าเริ่มต้น: 7 วัน / 1 สัปดาห์ล่าสุด)

  Future<List<Map<String, dynamic>>> getCompletedRoutineLogsHistory({
    required int userId,
    int daysLimit = 7,
  }) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      final startDate = DateTime.now().subtract(Duration(days: daysLimit - 1));
      final startDateStr =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

      return await db.rawQuery(
        '''
        SELECT rl.*, r.sTitle, r.sTime, r.targetValue, r.unit, r.color, r.iconData, r.sLinkedWorkout
        FROM ${AppDatabase.tableRoutineLogs} rl
        INNER JOIN ${AppDatabase.tableRoutines} r ON rl.nRoutineId = r.nRoutineId
        WHERE r.nUserId = ? AND rl.isCompleted = 1 AND rl.dtLogDate >= ?
        ORDER BY rl.dtLogDate DESC, rl.nLogId DESC
      ''',
        [userId, startDateStr],
      );
    } catch (e) {
      debugPrint('[AppDatabase] getCompletedRoutineLogsHistory error: $e');
      return [];
    }
  }
}
