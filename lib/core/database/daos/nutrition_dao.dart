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
      HealthApiService.deleteNutritionLogRemote(nutritionId);
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.delete(
      AppDatabase.tableNutritionLogs,
      where: 'nNutritionId = ?',
      whereArgs: [nutritionId],
    );

    // ซิงค์ลบที่ Server
    HealthApiService.deleteNutritionLogRemote(nutritionId);
  }
}
