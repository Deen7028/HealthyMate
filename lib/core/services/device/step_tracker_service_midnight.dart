part of 'step_tracker_service.dart';

// ส่วนจัดการบันทึกผลก้าวเดินสะสมตอนเที่ยงคืนและดึงข้อมูลย้อนหลัง (Midnight Auto-Save & Lazy Catch-Up)
extension StepTrackerMidnight on StepTrackerService {
  // ตั้งเวลานับถอยหลังเพื่อบันทึกสรุปผล ณ เวลา 00:00:01 น.
  void scheduleMidnightTimer() {
    _timerMidnight?.cancel();

    final DateTime dtNow = DateTime.now();
    final DateTime dtTomorrow = DateTime(dtNow.year, dtNow.month, dtNow.day + 1, 0, 0, 2);
    final Duration diff = dtTomorrow.difference(dtNow);

    _timerMidnight = Timer(diff, () async {
      debugPrint('🌙 [StepTracker] Midnight reached: Triggering daily step summary...');
      await checkAndProcessMidnightSummary();
      await resetForNewDay();
      // ตั้งเวลาสำหรับเที่ยงคืนวันถัดไป
      scheduleMidnightTimer();
    });
  }

  // ตรวจสอบและประมวลผลการบันทึกข้อมูลก้าวสะสมของเมื่อวาน (รองรับ Lazy Midnight Catch-up หากเครื่องปิดตอนเที่ยงคืน)
  Future<void> checkAndProcessMidnightSummary() async {
    try {
      final TbUser? objUser = await AppDatabase.instance.getCurrentUser();
      if (objUser == null || objUser.nUserId <= 0) return;

      final DateTime dtNow = DateTime.now();
      final DateTime dtYesterday = dtNow.subtract(const Duration(days: 1));

      // ตรวจสอบว่าวันที่เมื่อวานได้บันทึกสรุปผลไปแล้วหรือยัง
      final bool hasSaved = await AppDatabase.instance.hasDailyStepWorkout(
        userId: objUser.nUserId,
        date: dtYesterday,
      );

      if (hasSaved) {
        debugPrint('✅ [StepTracker] Yesterday step summary already recorded.');
        return;
      }

      debugPrint('⏳ [StepTracker] Processing midnight summary for yesterday...');

      // ดึงข้อมูลก้าวสุทธิของเมื่อวาน (ตั้งแต่ 00:00:00 ถึง 23:59:59 ของเมื่อวาน)
      final DateTime dtStart = DateTime(dtYesterday.year, dtYesterday.month, dtYesterday.day, 0, 0, 0);
      final DateTime dtEnd = DateTime(dtYesterday.year, dtYesterday.month, dtYesterday.day, 23, 59, 59);

      final List<HealthDataType> lstTypes = [HealthDataType.STEPS];
      bool isAuth = false;
      try {
        final bool? hasAuth = await _health.hasPermissions(lstTypes);
        isAuth = hasAuth == true;
      } catch (_) {}
      if (!isAuth) return;

      final List<HealthDataPoint> lstPoints = await _health.getHealthDataFromTypes(
        types: lstTypes,
        startTime: dtStart,
        endTime: dtEnd,
      );

      // ดึงกิจกรรมที่จับเวลาเองของเมื่อวานเพื่อทำ Deduplication
      final List<Map<String, dynamic>> lstWorkouts = await AppDatabase.instance.getWorkoutsByDate(
        userId: objUser.nUserId,
        date: dtYesterday,
      );

      final int nNetSteps = filterOverlappingSteps(
        lstPoints: lstPoints,
        lstWorkouts: lstWorkouts,
      );

      // บันทึกเฉพาะเมื่อมีก้าวเดินสะสมเกิน 50 ก้าวขึ้นไป เพื่อป้องกันขยะในฐานข้อมูล
      if (nNetSteps >= 50) {
        final double nDistanceKm = calculateDistanceKm(
          nNetSteps,
          objUser.nHeight ?? 170.0,
          objUser.sGender ?? 'male',
        );
        final double nCalories = calculateCaloriesBurned(
          nNetSteps,
          objUser.nWeight ?? 65.0,
        );

        await _saveDailyStepWorkout(
          nUserId: objUser.nUserId,
          dtTargetDate: dtEnd,
          nSteps: nNetSteps,
          nDistanceKm: nDistanceKm,
          nCalories: nCalories,
        );
      }
    } catch (e) {
      debugPrint('❌ [StepTracker] checkAndProcessMidnightSummary error: $e');
    }
  }

  // บันทึกยอดก้าวสะสมประจำวันลงในตาราง TbWorkouts 1 Record
  Future<void> _saveDailyStepWorkout({
    required int nUserId,
    required DateTime dtTargetDate,
    required int nSteps,
    required double nDistanceKm,
    required double nCalories,
  }) async {
    try {
      // 1. บันทึกลง SQLite โดยกำหนด nDuration = 0
      final int nWorkoutId = await AppDatabase.instance.insertWorkout(
        userId: nUserId,
        type: 'เดินสะสมประจำวัน',
        distanceKm: nDistanceKm,
        durationSeconds: 0,
        caloriesBurned: nCalories,
        steps: nSteps,
        routePoints: '',
        workoutDate: dtTargetDate,
      );

      debugPrint('🎉 [StepTracker] Saved Daily Step Workout ID: $nWorkoutId ($nSteps ก้าว, $nDistanceKm กม., $nCalories kcal)');

      // 2. สร้าง In-App Notification แจ้งเตือนสรุปผลให้ผู้ใช้ทราบ
      unawaited(AppNotificationService.instance.onWorkoutSaved(
        workoutType: 'เดินสะสมประจำวัน',
        distanceKm: nDistanceKm,
        caloriesBurned: nCalories,
        durationSeconds: 0,
      ));

      // 3. ซิงค์ขึ้น Supabase / Server Backend ทันที
      unawaited(SyncService.instance.syncPendingData());
    } catch (e) {
      debugPrint('❌ [StepTracker] _saveDailyStepWorkout error: $e');
    }
  }
}
