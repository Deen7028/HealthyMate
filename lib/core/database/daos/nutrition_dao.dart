part of '../app_database.dart';

extension AppDatabaseNutritionDao on AppDatabase {
  Future<int> insertNutritionLog({
    required int userId,
    required String mealType,
    required String foodName,
    required int calories,
    double protein = 0.0,
    double carbs = 0.0,
    double fat = 0.0,
    String servingSize = '',
    String imagePath = '',
  }) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;

    return await db.insert(AppDatabase.tableNutritionLogs, {
      'nUserId': userId,
      'sMealType': mealType,
      'sFoodName': foodName,
      'nCalories': calories,
      'nProtein': protein,
      'nCarbs': carbs,
      'nFat': fat,
      'sServingSize': servingSize,
      'sImagePath': imagePath,
      'isSynced': 0,
      'dtLoggedAt': DateTime.now().toIso8601String(),
      'dtUpdatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getNutritionLogsToday(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return await db.query(
      AppDatabase.tableNutritionLogs,
      where: 'nUserId = ? AND dtLoggedAt LIKE ?',
      whereArgs: [userId, '$todayStr%'],
      orderBy: 'nNutritionId DESC',
    );
  }

  Future<void> deleteNutritionLog(int nutritionId) async {
    if (kIsWeb) {
      await HealthApiService.deleteNutritionLogRemote(nutritionId);
      return;
    }
    final db = await database;
    if (db == null) return;
    final rows = await db.query(
      AppDatabase.tableNutritionLogs,
      where: 'nNutritionId = ?',
      whereArgs: [nutritionId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final row = rows.first;
    final userId = (row['nUserId'] as num?)?.toInt() ?? 0;
    final wasSynced = (row['isSynced'] as num?)?.toInt() == 1;
    await db.transaction((txn) async {
      if (wasSynced && userId > 0) {
        await txn.insert(AppDatabase.tablePendingDeletions, {
          'nUserId': userId,
          'sEntity': 'nutrition_log',
          'nRemoteId': nutritionId,
          'dtQueuedAt': DateTime.now().toIso8601String(),
        });
      }
      await txn.delete(AppDatabase.tableNutritionLogs, where: 'nNutritionId = ?', whereArgs: [nutritionId]);
    });
    if (wasSynced && userId > 0) {
      if (await HealthApiService.deleteNutritionLogRemote(nutritionId)) {
        final pending = await db.query(
          AppDatabase.tablePendingDeletions,
          where: 'nUserId = ? AND sEntity = ? AND nRemoteId = ?',
          whereArgs: [userId, 'nutrition_log', nutritionId],
          limit: 1,
        );
        if (pending.isNotEmpty) {
          await db.delete(AppDatabase.tablePendingDeletions,
              where: 'nDeletionId = ?', whereArgs: [pending.first['nDeletionId']]);
        }
      } else {
        unawaited(SyncService.instance.updatePendingCount());
        unawaited(SyncService.instance.syncPendingData());
      }
    }
    unawaited(SyncService.instance.updatePendingCount());
  }
}
