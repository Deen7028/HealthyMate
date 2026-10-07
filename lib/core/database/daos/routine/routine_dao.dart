part of '../../app_database.dart';

// ส่วนการจัดการกิจวัตรในฐานข้อมูล (AppDatabaseRoutineDao)
// ทำหน้าที่ดึงรายการกิจวัตร, ล้างกิจวัตรซ้ำซ้อน (Deduplicate) และซิงค์กิจวัตรจากเซิร์ฟเวอร์
extension AppDatabaseRoutineDao on AppDatabase {
  // ฟังก์ชัน: ล้างรายการกิจวัตรที่ซ้ำซ้อนในเครื่อง โดยยุบกิจวัตรที่มีชื่อซ้ำกันให้เหลือเพียงรายการเดียว
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
        orderBy: 'nRoutineId DESC',
      );

      final seenTitles = <String, int>{};
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
          await db.rawUpdate(
            '''
            UPDATE OR IGNORE ${AppDatabase.tableRoutineLogs} 
            SET nRoutineId = ? 
            WHERE nRoutineId = ?
          ''',
            [keeperId, rId],
          );
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
        debugPrint(
          '[AppDatabase] 🧹 ลบกิจวัตรที่ซ้ำซ้อนในเครื่องเรียบร้อย: ${duplicateIds.length} รายการ',
        );
      }
    } catch (e) {
      debugPrint('[AppDatabase] deduplicateRoutines error: $e');
    }
  }

  // ฟังก์ชัน: ดึงรายการกิจวัตรทั้งหมดของผู้ใช้จาก SQLite
  Future<List<Map<String, dynamic>>> getRoutines({required int userId}) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      if (userId > 0) {
        final users = await db.query(
          AppDatabase.tableUsers,
          columns: ['nUserId'],
        );
        if (users.length == 1 &&
            (users.first['nUserId'] as num?)?.toInt() == userId) {
          await db.rawUpdate(
            'UPDATE ${AppDatabase.tableRoutines} SET nUserId = ? WHERE nUserId IN (0, 1) AND nUserId != ?',
            [userId, userId],
          );
          await deduplicateRoutines(userId: userId);
        }
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

  // ฟังก์ชัน: เพิ่มและซิงค์กิจวัตรจาก Remote Server ลงฐานข้อมูล SQLite ท้องถิ่น
  Future<void> upsertRoutinesFromServer(
    int userId,
    List<Map<String, dynamic>> serverRoutines,
  ) async {
    if (kIsWeb || serverRoutines.isEmpty) return;
    final db = await database;
    if (db == null) return;
    try {
      final batch = db.batch();
      for (final r in serverRoutines) {
        final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        if (routineId <= 0) continue;
        final title = r['sTitle']?.toString() ?? 'กิจวัตร';

        // ลบแถวเดิมที่ชื่อซ้ำกันแต่คนละ ID ออก
        await db.delete(
          AppDatabase.tableRoutines,
          where:
              'nUserId = ? AND LOWER(TRIM(sTitle)) = LOWER(TRIM(?)) AND nRoutineId != ?',
          whereArgs: [userId, title, routineId],
        );

        batch.insert(AppDatabase.tableRoutines, {
          'nRoutineId': routineId,
          'nUserId': userId,
          'sTitle': title,
          'sTime': r['sTime']?.toString() ?? '',
          'targetValue':
              (r['targetValue'] as num?)?.toDouble() ??
              (r['nTargetValue'] as num?)?.toDouble() ??
              1.0,
          'unit': r['unit']?.toString() ?? (r['sUnit']?.toString() ?? 'ครั้ง'),
          'sLinkedWorkout': r['sLinkedWorkout']?.toString() ?? '',
          'color':
              (r['nColor'] as num?)?.toInt() ?? (r['color'] as num?)?.toInt(),
          'iconData':
              (r['nIconData'] as num?)?.toInt() ??
              (r['iconData'] as num?)?.toInt(),
          'isNotificationActive': (r['isNotificationActive'] is bool
                  ? (r['isNotificationActive'] as bool)
                  : ((r['isNotificationActive'] as num?)?.toInt() ?? 1) == 1)
              ? 1
              : 0,
          'dtCreatedAt':
              r['dtCreatedAt']?.toString() ?? DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      await deduplicateRoutines(userId: userId);
      debugPrint(
        '[AppDatabase] ✅ Sync ${serverRoutines.length} routines from server to local DB.',
      );
    } catch (e) {
      debugPrint('[AppDatabase] upsertRoutinesFromServer error: $e');
    }
  }
}
