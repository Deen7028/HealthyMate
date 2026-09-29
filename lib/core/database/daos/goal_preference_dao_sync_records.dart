part of '../app_database.dart';

extension AppDatabaseSyncRecordsDao on AppDatabase {
  Future<List<Map<String, dynamic>>> getUnsyncedHealthRecords(
    int userId,
  ) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(
        AppDatabase.tableHealthRecords,
        where: 'isSynced = 0 AND nUserId = ?',
        whereArgs: [userId],
      );
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
      return await db.query(
        AppDatabase.tableWorkouts,
        where: 'isSynced = 0 AND nUserId = ?',
        whereArgs: [userId],
      );
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

  Future<List<Map<String, dynamic>>> getUnsyncedNutritionLogs(
    int userId,
  ) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(
        AppDatabase.tableNutritionLogs,
        where: 'isSynced = 0 AND nUserId = ?',
        whereArgs: [userId],
      );
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
      return await db.query(
        AppDatabase.tableUsers,
        where: 'isSynced = 0 AND nUserId = ?',
        whereArgs: [userId],
      );
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
