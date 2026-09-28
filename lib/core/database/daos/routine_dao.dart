part of '../app_database.dart';

extension AppDatabaseRoutineDao on AppDatabase {
  /// ล้างรายการกิจวัตรที่ซ้ำซ้อนในเครื่อง โดยยุบกิจวัตรที่มีชื่อซ้ำกันให้เหลือเพียงรายการเดียว
  Future<void> deduplicateRoutines({required int userId}) async {
    if (kIsWeb || userId <= 0) return;
    final db = await database;
    if (db == null) return;
    try {
      // 1. ค้นหากิจวัตรทั้งหมดของ user
      final all = await db.query(
        AppDatabase.tableRoutines,
        where: 'nUserId = ?',
        whereArgs: [userId],
        orderBy: 'nRoutineId DESC', // ให้ ID ล่าสุดมาก่อน (หรือ ID ที่ตรงกับ server)
      );

      final seenTitles = <String, int>{}; // title -> keeperRoutineId
      final duplicateIds = <int>[];

      for (final row in all) {
        final rId = (row['nRoutineId'] as num?)?.toInt() ?? 0;
        final title = (row['sTitle']?.toString() ?? '').trim().toLowerCase();
        if (title.isEmpty) continue;

        if (seenTitles.containsKey(title)) {
          // ซ้ำกับรายการที่มีอยู่แล้ว
          final keeperId = seenTitles[title]!;
          duplicateIds.add(rId);

          // โอนย้าย logs จากรายการที่ซ้ำมาหารายการหลัก
          await db.rawUpdate('''
            UPDATE OR IGNORE ${AppDatabase.tableRoutineLogs} 
            SET nRoutineId = ? 
            WHERE nRoutineId = ?
          ''', [keeperId, rId]);
        } else {
          seenTitles[title] = rId;
        }
      }

      if (duplicateIds.isNotEmpty) {
        for (final dupId in duplicateIds) {
          await db.delete(
            AppDatabase.tableRoutineLogs,
            where: 'nRoutineId = ?',
            whereArgs: [dupId],
          );
          await db.delete(
            AppDatabase.tableRoutines,
            where: 'nRoutineId = ?',
            whereArgs: [dupId],
          );
        }
        debugPrint('[AppDatabase] 🧹 ลบกิจวัตรที่ซ้ำซ้อนในเครื่องเรียบร้อย: ${duplicateIds.length} รายการ');
      }
    } catch (e) {
      debugPrint('[AppDatabase] deduplicateRoutines error: $e');
    }
  }

  /// ดึงกิจวัตรทั้งหมดของผู้ใช้
  Future<List<Map<String, dynamic>>> getRoutines({required int userId}) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      // 🛡️ ซ่อมแซม nUserId ของกิจวัตรในเครื่องหากพบว่าผูกกับ ID เก่า (เช่น 1 หรือ 0)
      if (userId > 0) {
        await db.rawUpdate(
          'UPDATE ${AppDatabase.tableRoutines} SET nUserId = ? WHERE nUserId != ? AND (nUserId = 1 OR nUserId = 0)',
          [userId, userId],
        );
        // กวาดล้างรายการที่ชื่อซ้ำกันออกไป
        await deduplicateRoutines(userId: userId);
      }

      return await db.query(
        AppDatabase.tableRoutines,
        where: 'nUserId = ?',
        whereArgs: [userId],
        orderBy: 'nRoutineId ASC',
      );
    } catch (e) {
      debugPrint('[AppDatabase] getRoutines error: $e');
      return [];
    }
  }

  /// เพิ่ม/ซิงค์กิจวัตรจาก Server ลง SQLite ท้องถิ่น
  Future<void> upsertRoutinesFromServer(
      int userId, List<Map<String, dynamic>> serverRoutines) async {
    if (kIsWeb || serverRoutines.isEmpty) return;
    final db = await database;
    if (db == null) return;
    try {
      final batch = db.batch();
      for (final r in serverRoutines) {
        final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        if (routineId <= 0) continue;
        final title = r['sTitle']?.toString() ?? 'กิจวัตร';

        // ลบแถวเดิมใน SQLite ที่ชื่อเดียวกันแต่คนละ ID ออกไป เพื่อไม่ให้แสดงซ้ำ
        await db.delete(
          AppDatabase.tableRoutines,
          where: 'nUserId = ? AND LOWER(TRIM(sTitle)) = LOWER(TRIM(?)) AND nRoutineId != ?',
          whereArgs: [userId, title, routineId],
        );

        batch.insert(
          AppDatabase.tableRoutines,
          {
            'nRoutineId': routineId,
            'nUserId': userId,
            'sTitle': title,
            'sTime': r['sTime']?.toString() ?? '',
            'targetValue': (r['targetValue'] as num?)?.toDouble() ??
                (r['nTargetValue'] as num?)?.toDouble() ??
                1.0,
            'unit': r['unit']?.toString() ?? (r['sUnit']?.toString() ?? 'ครั้ง'),
            'sLinkedWorkout': r['sLinkedWorkout']?.toString() ?? '',
            'color': (r['nColor'] as num?)?.toInt() ?? (r['color'] as num?)?.toInt(),
            'iconData': (r['nIconData'] as num?)?.toInt() ?? (r['iconData'] as num?)?.toInt(),
            'isNotificationActive':
                ((r['isNotificationActive'] as num?)?.toInt() ?? 1) == 1
                    ? 1
                    : 0,
            'dtCreatedAt': r['dtCreatedAt']?.toString() ??
                DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      await deduplicateRoutines(userId: userId);
      debugPrint(
          '[AppDatabase] ✅ Sync ${serverRoutines.length} routines from server to local DB.');
    } catch (e) {
      debugPrint('[AppDatabase] upsertRoutinesFromServer error: $e');
    }
  }

  /// เพิ่มกิจวัตรใหม่
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

  /// ดึง logs ของกิจวัตรทั้งหมดของ user ในวันที่ระบุ
  Future<List<Map<String, dynamic>>> getRoutineLogsForDate({
    required int userId,
    required String dateStr,
  }) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.rawQuery('''
        SELECT rl.*, r.sTitle, r.sTime, r.isNotificationActive
        FROM ${AppDatabase.tableRoutineLogs} rl
        INNER JOIN ${AppDatabase.tableRoutines} r ON rl.nRoutineId = r.nRoutineId
        WHERE r.nUserId = ? AND rl.dtLogDate = ?
      ''', [userId, dateStr]);
    } catch (e) {
      debugPrint('[AppDatabase] getRoutineLogsForDate error: $e');
      return [];
    }
  }

  /// สลับสถานะ เช็ค / ยกเลิกเช็ค กิจวัตรของวันนั้น
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
        debugPrint('[AppDatabase] ✅ toggleRoutineLog: routineId=$routineId → checked');
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
        debugPrint('[AppDatabase] 🔄 toggleRoutineLog: routineId=$routineId → ${newVal == 1 ? "checked" : "unchecked"}');
        return newVal == 1;
      }
    } catch (e) {
      debugPrint('[AppDatabase] toggleRoutineLog error: $e');
      return false;
    }
  }

  /// บันทึกหรืออัปเดต Routine Log (รวมทั้งค่าความคืบหน้า progressValue)
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

  /// นับจำนวนกิจวัตรที่เสร็จแล้วในวันนั้น
  Future<int> getRoutineCompletionCount({
    required int userId,
    required String dateStr,
  }) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;
    try {
      final result = await db.rawQuery('''
        SELECT COUNT(*) as cnt
        FROM ${AppDatabase.tableRoutineLogs} rl
        INNER JOIN ${AppDatabase.tableRoutines} r ON rl.nRoutineId = r.nRoutineId
        WHERE r.nUserId = ? AND rl.dtLogDate = ? AND rl.isCompleted = 1
      ''', [userId, dateStr]);
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

      return await db.rawQuery('''
        SELECT rl.*, r.sTitle, r.sTime, r.targetValue, r.unit, r.color, r.iconData, r.sLinkedWorkout
        FROM ${AppDatabase.tableRoutineLogs} rl
        INNER JOIN ${AppDatabase.tableRoutines} r ON rl.nRoutineId = r.nRoutineId
        WHERE r.nUserId = ? AND rl.isCompleted = 1 AND rl.dtLogDate >= ?
        ORDER BY rl.dtLogDate DESC, rl.nLogId DESC
      ''', [userId, startDateStr]);
    } catch (e) {
      debugPrint('[AppDatabase] getCompletedRoutineLogsHistory error: $e');
      return [];
    }
  }
}
