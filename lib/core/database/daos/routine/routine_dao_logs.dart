part of '../../app_database.dart';

// ส่วนการจัดการประวัติการทำกิจวัตรในฐานข้อมูล (AppDatabaseLogsDao)
// ทำหน้าที่ดึงบันทึกกิจวัตรประจำวัน, สลับสถานะทำสำเร็จ (Toggle) และอัปเดตค่าความคืบหน้า
extension AppDatabaseLogsDao on AppDatabase {
  // ฟังก์ชัน: ดึงข้อมูลบันทึกของกิจวัตรในวันที่ระบุ
  Future<Map<String, dynamic>?> getRoutineLogForDate({
    required int routineId,
    required String dateStr,
  }) async {
    if (kIsWeb) return null;
    final db = await database;
    if (db == null) return null;
    try {
      final result = await db.query(
        AppDatabase.tableRoutineLogs,
        where: 'nRoutineId = ? AND dtLogDate = ?',
        whereArgs: [routineId, dateStr],
        limit: 1,
      );
      if (result.isNotEmpty) return result.first;
    } catch (e) {
      debugPrint('[AppDatabase] getRoutineLogForDate error: $e');
    }
    return null;
  }

  // ฟังก์ชัน: ดึงบันทึกกิจวัตรทั้งหมดของผู้ใช้ในวันที่ระบุ (พร้อมข้อมูลชื่อและเวลา)
  Future<List<Map<String, dynamic>>> getRoutineLogsForDate({
    required int userId,
    required String dateStr,
  }) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.rawQuery(
        '''
        SELECT rl.*, r.sTitle, r.sTime, r.isNotificationActive
        FROM ${AppDatabase.tableRoutineLogs} rl
        INNER JOIN ${AppDatabase.tableRoutines} r ON rl.nRoutineId = r.nRoutineId
        WHERE r.nUserId = ? AND rl.dtLogDate = ?
      ''',
        [userId, dateStr],
      );
    } catch (e) {
      debugPrint('[AppDatabase] getRoutineLogsForDate error: $e');
      return [];
    }
  }

  // ฟังก์ชัน: สลับสถานะสำเร็จ/ยังไม่สำเร็จของกิจวัตรในวันนั้น (Toggle Completion)
  Future<bool> toggleRoutineLog({
    required int routineId,
    required String dateStr,
  }) async {
    if (kIsWeb) return false;
    final db = await database;
    if (db == null) return false;
    try {
      final existing = await getRoutineLogForDate(
        routineId: routineId,
        dateStr: dateStr,
      );

      if (existing == null) {
        await db.insert(AppDatabase.tableRoutineLogs, {
          'nRoutineId': routineId,
          'isCompleted': 1,
          'dtLogDate': dateStr,
        });
        debugPrint(
          '[AppDatabase] ✅ toggleRoutineLog: routineId=$routineId → checked',
        );
        return true;
      } else {
        final wasCompleted = (existing['isCompleted'] as num?)?.toInt() == 1;
        final newVal = wasCompleted ? 0 : 1;
        await db.update(
          AppDatabase.tableRoutineLogs,
          {'isCompleted': newVal},
          where: 'nLogId = ?',
          whereArgs: [existing['nLogId']],
        );
        debugPrint(
          '[AppDatabase] 🔄 toggleRoutineLog: routineId=$routineId → ${newVal == 1 ? "checked" : "unchecked"}',
        );
        return newVal == 1;
      }
    } catch (e) {
      debugPrint('[AppDatabase] toggleRoutineLog error: $e');
      return false;
    }
  }

  // ฟังก์ชัน: บันทึกหรืออัปเดตประวัติกิจวัตร (พร้อมระบุค่าความคืบหน้า Progress Value)
  Future<void> insertOrUpdateRoutineLog({
    required int routineId,
    required String dateStr,
    required bool isCompleted,
    num? progressValue,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      final existing = await getRoutineLogForDate(
        routineId: routineId,
        dateStr: dateStr,
      );

      if (existing == null) {
        final Map<String, dynamic> insertData = {
          'nRoutineId': routineId,
          'isCompleted': isCompleted ? 1 : 0,
          'dtLogDate': dateStr,
        };
        if (progressValue != null) {
          insertData['nProgressValue'] = progressValue;
        }
        await db.insert(AppDatabase.tableRoutineLogs, insertData);
      } else {
        final Map<String, dynamic> updateData = {
          'isCompleted': isCompleted ? 1 : 0,
        };
        if (progressValue != null) {
          updateData['nProgressValue'] = progressValue;
        }
        await db.update(
          AppDatabase.tableRoutineLogs,
          updateData,
          where: 'nLogId = ?',
          whereArgs: [existing['nLogId']],
        );
      }
    } catch (e) {
      debugPrint('[AppDatabase] insertOrUpdateRoutineLog error: $e');
    }
  }
}
