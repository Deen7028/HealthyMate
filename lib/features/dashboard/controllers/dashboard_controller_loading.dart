part of 'dashboard_controller.dart';

/// Extension สำหรับโหลดและประมวลผลข้อมูลในเครื่อง (SQLite DB) สำหรับ Dashboard
extension DashboardControllerLoading on DashboardController {
  /// โหลดข้อมูลสรุปสุขภาพทั้งหมด ทั้งจาก Local DB และ Remote Sync
  Future<void> loadDashboardData({bool silent = false}) async {
    final shouldShowLoading = !silent && user == null;
    if (shouldShowLoading) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final db = AppDatabase.instance;
      user = await db.getCurrentUser();

      if (user == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final userId = user!.nUserId;
      final records = await db.getHealthRecords(userId: userId);
      healthRecords = records;
      latestRecord = records.isNotEmpty ? records.first : null;

      final workouts = await db.getWorkouts(userId: userId);
      this.workouts = workouts;
      workoutCount = workouts.length;
      totalDistanceKm = 0.0;
      totalRunningDistanceKm = 0.0;
      totalCyclingDistanceKm = 0.0;
      totalCaloriesBurned = 0.0;
      totalWorkoutDurationSec = 0;
      for (final w in workouts) {
        final dist = (w['nDistance'] as num?)?.toDouble() ?? 0.0;
        final cals = (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
        final dur = (w['nDuration'] as num?)?.toInt() ?? 0;
        final type = (w['sType']?.toString() ?? '').toLowerCase();

        totalDistanceKm += dist;
        totalCaloriesBurned += cals;
        totalWorkoutDurationSec += dur;

        if (type.contains('วิ่ง') || type.contains('running')) {
          totalRunningDistanceKm += dist;
        } else if (type.contains('ปั่น') ||
            type.contains('จักรยาน') ||
            type.contains('cycling')) {
          totalCyclingDistanceKm += dist;
        }
      }

      // ดึงข้อมูลแคลอรี่จากบันทึกอาหารด้วย AI Food Scanner ในวันนี้ (อิงเวลาปัจจุบันสดใหม่เสมอ)
      final currentNow = DateTime.now();
      final dbInstance = await db.database;
      final todayStr = DateFormat('yyyy-MM-dd').format(currentNow);
      List<Map<String, dynamic>> nutritionToday = [];

      if (dbInstance != null) {
        // Nutrition logs are private to the authenticated user.
        nutritionToday = await dbInstance.query(
          AppDatabase.tableNutritionLogs,
          where: 'nUserId = ? AND dtLoggedAt LIKE ?',
          whereArgs: [userId, '$todayStr%'],
          orderBy: 'nNutritionId DESC',
        );
      } else {
        nutritionToday = await db.getNutritionLogsToday(userId);
      }

      todayNutritionLogs = List<Map<String, dynamic>>.from(nutritionToday);
      todayScannedFoodCount = todayNutritionLogs.length;
      todayNutritionCalories = 0;
      for (final n in todayNutritionLogs) {
        todayNutritionCalories += (n['nCalories'] as num?)?.toInt() ?? 0;
      }

      routines = await db.getRoutines(userId: userId);
      todayCompletionMap.clear();
      todayProgressValues.clear();
      for (final r in routines) {
        final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        final targetVal = (r['targetValue'] as num?)?.toDouble() ?? 1.0;
        final log = await db.getRoutineLogForDate(
          routineId: rId,
          dateStr: todayStr,
        );
        final isDone = (log?['isCompleted'] as num?)?.toInt() == 1;
        final progressVal = (log?['nProgressValue'] as num?)?.toDouble();

        todayCompletionMap[rId] = isDone;
        todayProgressValues[rId] = progressVal ?? (isDone ? targetVal : 0.0);
      }

      todayWorkoutStats.clear();
      for (final w in workouts) {
        final workoutDate = w['dtWorkoutDate']?.toString() ?? '';
        if (workoutDate.startsWith(todayStr)) {
          final type = w['sType']?.toString() ?? 'อื่นๆ';
          final dist = (w['nDistance'] as num?)?.toDouble() ?? 0.0;
          final durationSec = (w['nDuration'] as num?)?.toDouble() ?? 0.0;
          final durationMin = durationSec > 0 ? (durationSec / 60.0) : 0.0;
          final calories = (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;

          final normType = RoutineController.normalizeCategoryType(type);
          final keysToUpdate = {type, normType};

          for (final k in keysToUpdate) {
            todayWorkoutStats.putIfAbsent(
              k,
              () => {'distance': 0.0, 'duration': 0.0, 'caloriesBurned': 0.0},
            );
            todayWorkoutStats[k]!['distance'] =
                (todayWorkoutStats[k]!['distance'] ?? 0) + dist;
            todayWorkoutStats[k]!['duration'] =
                (todayWorkoutStats[k]!['duration'] ?? 0) + durationMin;
            todayWorkoutStats[k]!['caloriesBurned'] =
                (todayWorkoutStats[k]!['caloriesBurned'] ?? 0) + calories;
          }
        }
      }

      userGoal = await db.getUserGoal(userId);
      if (isLoading) {
        isLoading = false;
      }
      notifyListeners();
      _syncFromServer(userId);
    } catch (e) {
      debugPrint('loadDashboardData error: $e');
      if (isLoading) {
        isLoading = false;
      }
      notifyListeners();
    }
  }
}
