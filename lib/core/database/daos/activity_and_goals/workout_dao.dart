part of '../../app_database.dart';

// ส่วนการจัดการข้อมูลการออกกำลังกายในฐานข้อมูล (AppDatabaseWorkoutDao)
// ทำหน้าที่บันทึกประวัติการออกกำลังกาย, ดึงประวัติพร้อมกรองข้อมูลซ้ำ, Upsert จากเซิร์ฟเวอร์ และจัดการ Timestamp
extension AppDatabaseWorkoutDao on AppDatabase {
  // ฟังก์ชัน: บันทึกประวัติการออกกำลังกายลงตาราง TbWorkouts
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

  // ฟังก์ชัน: ดึงประวัติการออกกำลังกายทั้งหมดของผู้ใช้ พร้อมกรองข้อมูลซ้ำซ้อน (Deduplication)
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

    // กรองข้อมูลซ้ำซ้อนในหน่วยความจำโดยใช้ประเภท, ระยะเวลา, ระยะทาง และนาทีที่บันทึก
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

  // ฟังก์ชัน: บันทึกหรืออัปเดตข้อมูลกิจกรรมจากเซิร์ฟเวอร์ลง SQLite (Upsert Workouts)
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

        // 1. ตรวจสอบว่าใน SQLite มีรายการนี้อยู่แล้วหรือไม่
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

        // 2. ประกอบข้อมูลและบันทึกลงตาราง
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

  // ฟังก์ชัน: ดึงเวลาการซิงค์ข้อมูลกิจกรรมล่าสุด (Last Workout Sync Timestamp)
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

  // ฟังก์ชัน: บันทึกเวลาซิงค์กิจกรรมล่าสุด
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

  // ฟังก์ชัน: นับจำนวนกิจกรรมการออกกำลังกายทั้งหมดของผู้ใช้
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

  // ฟังก์ชัน: ดึงหมวดหมู่ประเภทการออกกำลังกายทั้งหมดจากตาราง TbWorkoutCategories
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
