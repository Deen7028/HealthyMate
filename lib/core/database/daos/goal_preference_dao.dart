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
  }) async {
    final db = await database;
    if (db == null) return;
    
    final existing = await getUserGoal(userId);
    if (existing != null) {
      final existingProgress = (existing['nProgress'] as num?)?.toDouble() ?? 0.0;
      final existingRemaining = existing['sRemainingText']?.toString() ?? '';
      final isExistingCompleted = existingProgress >= 1.0 || existingRemaining.contains('100%');
      final isSameGoal = existing['sTitle'] == title &&
          ((existing['nRoutineId'] as num?)?.toInt() ?? 0) == nRoutineId;

      // หากเป็นเป้าหมายเดิม หรือเป้าหมายเดิมยังไม่สำเร็จ ให้ Update ได้
      if (isSameGoal || !isExistingCompleted) {
        await db.update(
          'TbGoals',
          {
            'nRoutineId': nRoutineId,
            'sTitle': title,
            'nProgress': progress,
            'sRemainingText': remainingText,
            'dtUpdatedAt': DateTime.now().toIso8601String(),
          },
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
      'dtCreatedAt': DateTime.now().toIso8601String(),
      'dtUpdatedAt': DateTime.now().toIso8601String(),
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
      await db.insert(
        'TbUserPreferences',
        {
          'nUserId': userId,
          'sUnitSystem': unitLabel.startsWith('Kilo') ? 'metric' : 'imperial',
          'sUnitLabel': unitLabel,
          'sGeminiApiKey': '',
        },
      );
    }
  }

  Future<String> getGeminiApiKey(int userId) async {
    if (kIsWeb) return '';
    final storageKey = 'gemini_api_key_$userId';
    String? secureValue;
    try {
      secureValue = await AppDatabase._secureStorage.read(key: storageKey);
    } catch (_) {}
    if (secureValue != null && secureValue.isNotEmpty) return secureValue;
    final db = await database;
    if (db == null) return '';
    try {
      final maps = await db.query(
        'TbUserPreferences',
        where: 'nUserId = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (maps.isNotEmpty && maps.first['sGeminiApiKey'] != null) {
        final legacyValue = maps.first['sGeminiApiKey'].toString();
        if (legacyValue.isNotEmpty) {
          await AppDatabase._secureStorage.write(key: storageKey, value: legacyValue);
          await db.update(
            'TbUserPreferences',
            {'sGeminiApiKey': ''},
            where: 'nUserId = ?',
            whereArgs: [userId],
          );
          return legacyValue;
        }
      }
    } catch (e) {
      debugPrint('getGeminiApiKey error: $e');
    }
    return '';
  }

  Future<void> saveGeminiApiKey(int userId, String apiKey) async {
    if (kIsWeb) return;
    final normalizedKey = apiKey.trim();
    final storageKey = 'gemini_api_key_$userId';
    if (normalizedKey.isEmpty) {
      await AppDatabase._secureStorage.delete(key: storageKey);
    } else {
      await AppDatabase._secureStorage.write(key: storageKey, value: normalizedKey);
    }
    final db = await database;
    if (db == null) return;
    try {
      try {
        await db.execute('ALTER TABLE TbUserPreferences ADD COLUMN sGeminiApiKey TEXT DEFAULT ""');
      } catch (_) {}

      final existing = await db.query(
        'TbUserPreferences',
        where: 'nUserId = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        await db.update(
          'TbUserPreferences',
          {'sGeminiApiKey': ''},
          where: 'nUserId = ?',
          whereArgs: [userId],
        );
      } else {
        await db.insert(
          'TbUserPreferences',
          {
            'nUserId': userId,
            'sUnitSystem': 'metric',
            'sUnitLabel': 'Kilometers, Kilograms',
            'sGeminiApiKey': '',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('saveGeminiApiKey error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getConnectedDevices(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    return await db.query(
      AppDatabase.tableHealthIntegrations,
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'nIntegrationId ASC',
    );
  }

  Future<int> insertConnectedDevice({
    required int userId,
    required String providerName,
    bool isSynced = true,
  }) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;
    return await db.insert(
      AppDatabase.tableHealthIntegrations,
      {
        'nUserId': userId,
        'sProviderName': providerName,
        'isSynced': isSynced ? 1 : 0,
        'dtLastSyncedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> updateConnectedDeviceStatus({
    required int integrationId,
    required bool isSynced,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.update(
      AppDatabase.tableHealthIntegrations,
      {
        'isSynced': isSynced ? 1 : 0,
        'dtLastSyncedAt': DateTime.now().toIso8601String(),
      },
      where: 'nIntegrationId = ?',
      whereArgs: [integrationId],
    );
  }

  Future<void> deleteConnectedDevice(int integrationId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete(
      AppDatabase.tableHealthIntegrations,
      where: 'nIntegrationId = ?',
      whereArgs: [integrationId],
    );
  }

  Future<int> getPendingSyncCount() async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;

    int total = 0;
    try {
      final r1 = await db.rawQuery('SELECT COUNT(*) as cnt FROM ${AppDatabase.tableHealthRecords} WHERE isSynced = 0');
      total += (r1.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    try {
      final r2 = await db.rawQuery('SELECT COUNT(*) as cnt FROM ${AppDatabase.tableWorkouts} WHERE isSynced = 0');
      total += (r2.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    try {
      final r3 = await db.rawQuery('SELECT COUNT(*) as cnt FROM ${AppDatabase.tableNutritionLogs} WHERE isSynced = 0');
      total += (r3.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    try {
      final r4 = await db.rawQuery('SELECT COUNT(*) as cnt FROM ${AppDatabase.tableUsers} WHERE isSynced = 0');
      total += (r4.first['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    try {
      final r5 = await db.rawQuery('SELECT COUNT(*) as cnt FROM ${AppDatabase.tablePendingDeletions}');
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

  Future<List<Map<String, dynamic>>> getUnsyncedHealthRecords(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(AppDatabase.tableHealthRecords, where: 'isSynced = 0 AND nUserId = ?', whereArgs: [userId]);
    } catch (_) {
      return [];
    }
  }

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

  Future<List<Map<String, dynamic>>> getUnsyncedWorkouts(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(AppDatabase.tableWorkouts, where: 'isSynced = 0 AND nUserId = ?', whereArgs: [userId]);
    } catch (_) {
      return [];
    }
  }

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

  Future<List<Map<String, dynamic>>> getUnsyncedNutritionLogs(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(AppDatabase.tableNutritionLogs, where: 'isSynced = 0 AND nUserId = ?', whereArgs: [userId]);
    } catch (_) {
      return [];
    }
  }

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

  Future<List<Map<String, dynamic>>> getUnsyncedUsers(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(AppDatabase.tableUsers, where: 'isSynced = 0 AND nUserId = ?', whereArgs: [userId]);
    } catch (_) {
      return [];
    }
  }

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
