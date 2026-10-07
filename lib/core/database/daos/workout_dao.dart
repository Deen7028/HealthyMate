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

  /// ดึงประวัติการออกกำลังกายทั้งหมดของผู้ใช้ตาม userId พร้อมกรองข้อมูลซ้ำซ้อน
  Future<List<Map<String, dynamic>>> getWorkouts({required int userId}) async {
    if (kIsWeb) return [];

    final db = await database;
    if (db == null) return [];

    final rawList = await db.query(
      AppDatabase.tableWorkouts,
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'dtWorkoutDate DESC',
    );

    // ทำ In-Memory Deduplication เพื่อให้แน่ใจว่าประวัติจะไม่แสดงซ้ำกัน
    final seenKeys = <String>{};
    final uniqueList = <Map<String, dynamic>>[];

    for (final item in rawList) {
      final type = item['sType']?.toString() ?? '';
      final duration = (item['nDuration'] as num?)?.toInt() ?? 0;
      final distance = ((item['nDistance'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2);
      final dateStr = item['dtWorkoutDate']?.toString() ?? '';
      final normalizedDate = dateStr.length >= 16 ? dateStr.substring(0, 16) : dateStr;
      
      final uniqueKey = '$type|$duration|$distance|$normalizedDate';
      if (seenKeys.add(uniqueKey)) {
        uniqueList.add(item);
      }
    }

    return uniqueList;
  }

  /// เขียนข้อมูล Workouts จาก Server ลง SQLite ด้วย UPSERT (INSERT OR REPLACE)
  /// พร้อมตรวจสอบข้อมูลซ้ำซ้อนที่มีอยู่ในเครื่องก่อนหน้า
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

        // ตรวจสอบว่าใน SQLite มีรายการนี้อยู่แล้วหรือไม่ (ไม่ว่าจะด้วย nWorkoutId หรือ matching date/type/duration)
        int? existingLocalId;
        if (workoutId != null && workoutId > 0) {
          final byId = await txn.query(
            AppDatabase.tableWorkouts,
            columns: ['nWorkoutId'],
            where: 'nWorkoutId = ?',
            whereArgs: [workoutId],
            limit: 1,
          );
          if (byId.isNotEmpty) {
            existingLocalId = byId.first['nWorkoutId'] as int?;
          }
        }

        if (existingLocalId == null) {
          // ตรวจหา local workout ที่ยัง sync ไม่เสร็จ หรือเพิ่งบันทึกลงเครื่อง
          final datePrefix = workoutDate.length >= 16 ? workoutDate.substring(0, 16) : workoutDate;
          final byProps = await txn.query(
            AppDatabase.tableWorkouts,
            columns: ['nWorkoutId'],
            where: 'nUserId = ? AND sType = ? AND nDuration = ? AND dtWorkoutDate LIKE ?',
            whereArgs: [userId, type, duration, '$datePrefix%'],
            limit: 1,
          );
          if (byProps.isNotEmpty) {
            existingLocalId = byProps.first['nWorkoutId'] as int?;
          }
        }

        final mapToInsert = <String, dynamic>{
          if (existingLocalId != null)
            'nWorkoutId': existingLocalId
          else if (workoutId != null && workoutId > 0)
            'nWorkoutId': workoutId,
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
