part of '../app_database.dart';

extension AppDatabaseGoalPreferenceDao on AppDatabase {
  Future<Map<String, dynamic>?> getUserGoal(int userId) async {
    final db = await database;
    if (db == null) return null;
    final maps = await db.query(
      'TbGoals',
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'nGoalId DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  /// ดึงประวัติเป้าหมายหลักทั้งหมดของผู้ใช้ (รวมเป้าหมายที่เคยสำเร็จ)
  Future<List<Map<String, dynamic>>> getAllUserGoalsHistory(int userId) async {
    final db = await database;
    if (db == null) return [];
    return await db.query(
      'TbGoals',
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'dtUpdatedAt DESC, nGoalId DESC',
    );
  }

  Future<void> saveUserGoal({
    required int userId,
    int nRoutineId = 0,
    required String title,
    required double progress,
    required String remainingText,
    String? dtCreatedAt,
  }) async {
    final db = await database;
    if (db == null) return;

    final existing = await getUserGoal(userId);
    final nowStr = DateTime.now().toIso8601String();
    if (existing != null) {
      final existingProgress =
          (existing['nProgress'] as num?)?.toDouble() ?? 0.0;
      final existingRemaining = existing['sRemainingText']?.toString() ?? '';
      final isExistingCompleted =
          existingProgress >= 1.0 || existingRemaining.contains('100%');
      final isSameGoal =
          existing['sTitle'] == title &&
          ((existing['nRoutineId'] as num?)?.toInt() ?? 0) == nRoutineId;

      // หากเป็นเป้าหมายเดิม หรือเป้าหมายเดิมยังไม่สำเร็จ ให้ Update ได้
      if (isSameGoal || !isExistingCompleted) {
        final updateMap = <String, dynamic>{
          'nRoutineId': nRoutineId,
          'sTitle': title,
          'nProgress': progress,
          'sRemainingText': remainingText,
          'dtUpdatedAt': nowStr,
        };
        if (dtCreatedAt != null) {
          updateMap['dtCreatedAt'] = dtCreatedAt;
        }
        await db.update(
          'TbGoals',
          updateMap,
          where: 'nGoalId = ?',
          whereArgs: [existing['nGoalId']],
        );
        return;
      }
    }

    // หากยังไม่มี หรือเป้าหมายเดิมทำสำเร็จ 100% แล้ว ให้ Insert เป็นเป้าหมายใหม่ (ไม่ทับประวัติเดิม)
    await db.insert('TbGoals', {
      'nUserId': userId,
      'nRoutineId': nRoutineId,
      'sTitle': title,
      'nProgress': progress,
      'sRemainingText': remainingText,
      'dtCreatedAt': dtCreatedAt ?? nowStr,
      'dtUpdatedAt': nowStr,
    });
  }

  Future<void> clearUserGoal(int userId) async {
    final db = await database;
    if (db == null) return;
    await db.delete('TbGoals', where: 'nUserId = ?', whereArgs: [userId]);
  }

  Future<String> getUserUnitPreference(int userId) async {
    final db = await database;
    if (db == null) return 'Kilometers, Kilograms';
    final maps = await db.query(
      'TbUserPreferences',
      where: 'nUserId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isNotEmpty && maps.first['sUnitLabel'] != null) {
      return maps.first['sUnitLabel'].toString();
    }
    return 'Kilometers, Kilograms';
  }

  Future<void> saveUserUnitPreference(int userId, String unitLabel) async {
    final db = await database;
    if (db == null) return;
    final existing = await db.query(
      'TbUserPreferences',
      where: 'nUserId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await db.update(
        'TbUserPreferences',
        {
          'sUnitSystem': unitLabel.startsWith('Kilo') ? 'metric' : 'imperial',
          'sUnitLabel': unitLabel,
        },
        where: 'nUserId = ?',
        whereArgs: [userId],
      );
    } else {
      await db.insert('TbUserPreferences', {
        'nUserId': userId,
        'sUnitSystem': unitLabel.startsWith('Kilo') ? 'metric' : 'imperial',
        'sUnitLabel': unitLabel,
        'sGeminiApiKey': '',
      });
    }
  }
}
