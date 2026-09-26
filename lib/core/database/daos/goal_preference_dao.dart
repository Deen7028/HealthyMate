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
    } else {
      await db.insert('TbGoals', {
        'nUserId': userId,
        'nRoutineId': nRoutineId,
        'sTitle': title,
        'nProgress': progress,
        'sRemainingText': remainingText,
        'dtUpdatedAt': DateTime.now().toIso8601String(),
      });
    }
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
        return maps.first['sGeminiApiKey'].toString();
      }
    } catch (e) {
      debugPrint('getGeminiApiKey error: $e');
    }
    return '';
  }

  Future<void> saveGeminiApiKey(int userId, String apiKey) async {
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
          {'sGeminiApiKey': apiKey.trim()},
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
            'sGeminiApiKey': apiKey.trim(),
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

    return total;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedHealthRecords() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(AppDatabase.tableHealthRecords, where: 'isSynced = 0');
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

  Future<List<Map<String, dynamic>>> getUnsyncedWorkouts() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(AppDatabase.tableWorkouts, where: 'isSynced = 0');
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

  Future<List<Map<String, dynamic>>> getUnsyncedNutritionLogs() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(AppDatabase.tableNutritionLogs, where: 'isSynced = 0');
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

  Future<List<Map<String, dynamic>>> getUnsyncedUsers() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(AppDatabase.tableUsers, where: 'isSynced = 0');
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
