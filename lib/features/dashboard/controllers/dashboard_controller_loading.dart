part of 'dashboard_controller.dart';

/// Extension สำหรับโหลดและประมวลผลข้อมูลในเครื่อง (SQLite DB) สำหรับหน้า Dashboard
extension DashboardControllerLoading on DashboardController {
  /// โหลดข้อมูลสรุปสุขภาพทั้งหมด ทั้งจาก Local DB และสั่ง Background Sync
  Future<void> loadDashboardData({bool silent = false}) async {
    // 1. ตรวจสอบว่าจะแสดง Loading Spinner หรือไม่
    final shouldShowLoading = !silent && user == null;
    if (shouldShowLoading) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final db = AppDatabase.instance;
      // 2. ดึงข้อมูล User ปัจจุบันจาก SQLite
      user = await db.getCurrentUser();

      // ถ้าไม่พบผู้ใช้ในเครื่อง ให้สิ้นสุดการโหลด
      if (user == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final userId = user!.nUserId;
      // 3. ตั้งค่า userId ให้ระบบแจ้งเตือน AppNotificationService
      AppNotificationService.instance.setUserId(userId);

      // 4. อ่านจำนวนการแจ้งเตือนที่ยังไม่ได้อ่าน
      unreadNotificationCount = await db.getUnreadNotificationCount(userId);

      // 5. ดึงประวัติสุขภาพ (Health Records) และเก็บบันทึกล่าสุด
      final records = await db.getHealthRecords(userId: userId);
      healthRecords = records;
      latestRecord = records.isNotEmpty ? records.first : null;

      // 6. ดึงประวัติการออกกำลังกายและคำนวณสถิติรวม (ระยะทาง, แคลอรี่, เวลา)
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

      // 7. ดึงข้อมูลแคลอรี่จากบันทึกอาหาร AI Food Scanner ประจำวันนี้
      try {
        final rawNutrition = await db.getNutritionLogsToday(userId);
        todayNutritionLogs = rawNutrition;
        todayScannedFoodCount = rawNutrition.length;
        todayNutritionCalories = rawNutrition.fold<int>(
          0,
          (sum, item) => sum + ((item['nCalories'] as num?)?.toInt() ?? 0),
        );
      } catch (e) {
        debugPrint('DashboardController: Failed to load local nutrition logs: $e');
      }

      // 8. ดึงข้อมูลเป้าหมายหลักของผู้ใช้ (Main Goal)
      userGoal = await db.getUserGoal(userId);

      // 9. ดึงข้อมูลกิจวัตรประจำวัน (Routines) และสถานะของวันนี้
      routines = await db.getRoutines(userId: userId);
      final currentNow = DateTime.now();
      final todayStr =
          "${currentNow.year}-${currentNow.month.toString().padLeft(2, '0')}-${currentNow.day.toString().padLeft(2, '0')}";
      final allLogsToday = await db.getRoutineLogsForDate(
        userId: userId,
        dateStr: todayStr,
      );

      final Map<int, Map<String, dynamic>> logsMap = {};
      for (final log in allLogsToday) {
        final rId = (log['nRoutineId'] as num?)?.toInt() ?? 0;
        logsMap[rId] = log;
      }

      todayCompletionMap.clear();
      todayProgressValues.clear();
      for (final r in routines) {
        final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        final targetVal = (r['targetValue'] as num?)?.toDouble() ??
            (r['nTargetValue'] as num?)?.toDouble() ??
            1.0;
        final log = logsMap[routineId];
        final isDone = (log?['isCompleted'] as num?)?.toInt() == 1;
        final logProgress = (log?['nProgressValue'] as num?)?.toDouble() ??
            (log?['progressValue'] as num?)?.toDouble();

        todayCompletionMap[routineId] = isDone;
        todayProgressValues[routineId] =
            logProgress ?? (isDone ? targetVal : 0.0);
      }

      // 10. คำนวณสถิติออกกำลังกายของวันนี้แยกตามประเภทกิจกรรม
      todayWorkoutStats.clear();
      for (final w in workouts) {
        final workoutDate = w['dtWorkoutDate']?.toString() ?? '';
        if (workoutDate.startsWith(todayStr)) {
          final type = w['sType']?.toString() ?? 'อื่นๆ';
          final dist = (w['nDistance'] as num?)?.toDouble() ?? 0.0;
          final durationSec = (w['nDuration'] as num?)?.toDouble() ?? 0.0;
          final durationMin = durationSec > 0 ? (durationSec / 60.0) : 0.0;
          final calories = (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;

          todayWorkoutStats.putIfAbsent(
            type,
            () => {'distance': 0.0, 'duration': 0.0, 'caloriesBurned': 0.0},
          );
          todayWorkoutStats[type]!['distance'] =
              (todayWorkoutStats[type]!['distance'] ?? 0) + dist;
          todayWorkoutStats[type]!['duration'] =
              (todayWorkoutStats[type]!['duration'] ?? 0) + durationMin;
          todayWorkoutStats[type]!['caloriesBurned'] =
              (todayWorkoutStats[type]!['caloriesBurned'] ?? 0) + calories;
        }
      }

      // โหลดข้อมูลในเครื่องเสร็จสิ้น -> สั่งอัปเดตหน้าจอทันที
      isLoading = false;
      notifyListeners();

      // 11. ซิงค์ข้อมูลล่าสุดกับ Server ในเบื้องหลัง (ถ้าต่ออินเทอร์เน็ต)
      _syncFromServer(userId);
    } catch (e) {
      debugPrint('DashboardController Error: $e');
      isLoading = false;
      notifyListeners();
    }
  }
}
