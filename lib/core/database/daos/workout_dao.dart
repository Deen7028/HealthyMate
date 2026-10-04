// ส่วนนี้อธิบายบทบาทของไฟล์: ฐานข้อมูลภายในเครื่องและ DAO สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (workout dao)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of '../app_database.dart';

extension AppDatabaseWorkoutDao on AppDatabase {
  /// บันทึกประวัติการออกกำลังกายลงตาราง TbWorkouts
  Future<int> insertWorkout({
    required int userId,
    required String type,
    required double distanceKm,
    required int durationSeconds,
    required double caloriesBurned,
    String routePoints = '',
  }) async {
    final nowStr = DateTime.now().toIso8601String();
    if (kIsWeb) {
      return DateTime.now().millisecondsSinceEpoch % 100000;
    }

    final db = await database;
    if (db == null) return 0;

    return await db.insert(AppDatabase.tableWorkouts, {
      'nUserId': userId,
      'sType': type,
      'nDistance': distanceKm,
      'nDuration': durationSeconds,
      'nCaloriesBurned': caloriesBurned,
      'sRoutePoints': routePoints,
      'isSynced': 0,
      'dtWorkoutDate': nowStr,
      'dtUpdatedAt': nowStr,
    });
  }

  /// ดึงประวัติการออกกำลังกายทั้งหมดของผู้ใช้ตาม userId
  Future<List<Map<String, dynamic>>> getWorkouts({required int userId}) async {
    if (kIsWeb) return [];

    final db = await database;
    if (db == null) return [];

    return await db.query(
      AppDatabase.tableWorkouts,
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'dtWorkoutDate DESC',
    );
  }

  /// เขียนข้อมูล Workouts จาก Server ลง SQLite ด้วย UPSERT (INSERT OR REPLACE)
  Future<int> upsertWorkoutsFromServer(
    int userId,
    List<Map<String, dynamic>> workouts,
  ) async {
    if (kIsWeb || workouts.isEmpty) return 0;
    final db = await database;
    if (db == null) return 0;

    int affectedCount = 0;
    await db.transaction((txn) async {
      for (final item in workouts) {
        final rawId = item['nWorkoutId'];
        final workoutId = rawId != null ? int.tryParse(rawId.toString()) : null;
        final rawUserId = item['nUserId'];
        final responseUserId = rawUserId != null
            ? int.tryParse(rawUserId.toString())
            : null;
        if (responseUserId != null && responseUserId != userId) continue;

        final rawDuration = item['nDuration'];
        final duration = rawDuration != null
            ? int.tryParse(rawDuration.toString()) ?? 0
            : 0;

        final rawDistance = item['nDistance'];
        final distance = rawDistance != null
            ? double.tryParse(rawDistance.toString()) ?? 0.0
            : 0.0;

        final rawCalories = item['nCaloriesBurned'];
        final calories = rawCalories != null
            ? double.tryParse(rawCalories.toString()) ?? 0.0
            : 0.0;

        final type = item['sType']?.toString() ?? 'วิ่ง';
        final routePoints = item['sRoutePoints']?.toString() ?? '';
        final workoutDate =
            item['dtWorkoutDate']?.toString() ??
            DateTime.now().toIso8601String();
        final updatedAt =
            item['dtUpdatedAt']?.toString() ?? DateTime.now().toIso8601String();

        final mapToInsert = <String, dynamic>{
          if (workoutId != null && workoutId > 0) 'nWorkoutId': workoutId,
          'nUserId': userId,
          'sType': type,
          'nDistance': distance,
          'nDuration': duration,
          'nCaloriesBurned': calories,
          'sRoutePoints': routePoints,
          'isSynced': 1,
          'dtWorkoutDate': workoutDate,
          'dtUpdatedAt': updatedAt,
        };

        await txn.insert(
          AppDatabase.tableWorkouts,
          mapToInsert,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        affectedCount++;
      }
    });

    return affectedCount;
  }

  /// อ่านเวลาการดึงข้อมูลล่าสุด (dtLastWorkoutSync) จาก TbHealthIntegrations หรือ Session
  Future<String?> getLastWorkoutSyncTimestamp(int userId) async {
    if (kIsWeb) return null;
    final db = await database;
    if (db == null) return null;
    try {
      final res = await db.query(
        AppDatabase.tableHealthIntegrations,
        where: 'nUserId = ? AND sProviderName = ?',
        whereArgs: [userId, 'workout_sync_timestamp'],
        limit: 1,
      );
      if (res.isNotEmpty) {
        return res.first['dtLastSyncedAt']?.toString();
      }
    } catch (_) {}
    return null;
  }

  /// บันทึกเวลาซิงค์ล่าสุด (Save Last Sync Timestamp)
  Future<void> setLastWorkoutSyncTimestamp(int userId, String timestamp) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    try {
      await db.insert(
        AppDatabase.tableHealthIntegrations,
        {
          'nUserId': userId,
          'sProviderName': 'workout_sync_timestamp',
          'isSynced': 1,
          'dtLastSyncedAt': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('AppDatabase: Error saving workout sync timestamp: $e');
    }
  }

  Future<int> getWorkoutCount({required int userId}) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${AppDatabase.tableWorkouts} WHERE nUserId = ?',
      [userId],
    );
    if (result.isNotEmpty) {
      return (result.first['cnt'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  /// ดึงหมวดหมู่การออกกำลังกายทั้งหมดจากตาราง TbWorkoutCategories
  Future<List<Map<String, dynamic>>> getWorkoutCategories() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(
        AppDatabase.tableWorkoutCategories,
        orderBy: 'nCategoryId ASC',
      );
    } catch (_) {
      return [];
    }
  }
}
