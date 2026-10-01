part of '../app_database.dart';

extension AppDatabaseMutationsDao on AppDatabase {
  Future<int> insertRoutine({
    required int userId,
    required String title,
    String time = '',
    double targetValue = 1.0,
    String unit = 'ครั้ง',
    String linkedWorkout = '',
    int? color,
    int? iconData,
    bool isNotificationActive = true,
  }) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;
    try {
      return await db.insert(AppDatabase.tableRoutines, {
        'nUserId': userId,
        'sTitle': title,
        'sTime': time,
        'targetValue': targetValue,
        'unit': unit,
        'sLinkedWorkout': linkedWorkout,
        'color': color,
        'iconData': iconData,
        'isNotificationActive': isNotificationActive ? 1 : 0,
        'dtCreatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[AppDatabase] insertRoutine error: $e');
      return 0;
    }
  }

  /// แก้ไขกิจวัตร

  Future<void> updateRoutine({
    required int routineId,
    required String title,
    String time = '',
    double? targetValue,
    String? unit,
    String? linkedWorkout,
    int? color,
    int? iconData,
    bool isNotificationActive = true,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      final updateData = <String, dynamic>{
        'sTitle': title,
        'sTime': time,
        'isNotificationActive': isNotificationActive ? 1 : 0,
      };
      if (targetValue != null) updateData['targetValue'] = targetValue;
      if (unit != null) updateData['unit'] = unit;
      if (linkedWorkout != null) updateData['sLinkedWorkout'] = linkedWorkout;
      if (color != null) updateData['color'] = color;
      if (iconData != null) updateData['iconData'] = iconData;

      await db.update(
        AppDatabase.tableRoutines,
        updateData,
        where: 'nRoutineId = ?',
        whereArgs: [routineId],
      );
    } catch (e) {
      debugPrint('[AppDatabase] updateRoutine error: $e');
    }
  }

  /// ลบกิจวัตร (cascade จะลบ RoutineLogs ให้อัตโนมัติ)

  Future<void> deleteRoutine(int routineId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      await db.delete(
        AppDatabase.tableRoutineLogs,
        where: 'nRoutineId = ?',
        whereArgs: [routineId],
      );
      await db.delete(
        AppDatabase.tableRoutines,
        where: 'nRoutineId = ?',
        whereArgs: [routineId],
      );
    } catch (e) {
      debugPrint('[AppDatabase] deleteRoutine error: $e');
    }
  }

  /// ดึง log ของกิจวัตรในวันที่ระบุ
}
