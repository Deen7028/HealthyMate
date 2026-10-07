part of 'workout_tracking_controller.dart';

// ส่วนจัดการการบันทึกและสถานะกิจกรรม (WorkoutTrackingPersistence)
// ทำหน้าที่หยุด/ทำต่อ, บันทึกผลการออกกำลังกาย (SQLite + Remote), ปลดล็อกเหรียญ และจัดการ Checkpoint
extension WorkoutTrackingPersistence on WorkoutTrackingController {
  void pauseWorkout() {
    // 1. สะสมเวลาที่บันทึกไว้ และยกเลิกตัวจับเวลา
    if (_workoutStartTime != null) {
      _accumulatedSeconds += DateTime.now()
          .difference(_workoutStartTime!)
          .inSeconds;
      _workoutStartTime = null;
    }
    _timer?.cancel();
    _positionStreamSub?.cancel();
    LocationBackgroundService.instance.stopTracking();

    // 2. ปรับสถานะเป็น Paused และแจ้งเตือน UI
    _status = WorkoutState.paused;
    this._safeNotifyListeners();
  }

  // ฟังก์ชัน: ทำการออกกำลังกายต่อ (Resume Workout)
  void resumeWorkout() {
    this.startWorkout();
  }
  
  // ฟังก์ชัน: บันทึกกิจกรรมการออกกำลังกาย (Save Workout)
  Future<bool> saveWorkout() async {
    // 1. หยุดตัวจับเวลาและปิดการจับตำแหน่ง GPS
    _timer?.cancel();
    _positionStreamSub?.cancel();
    LocationBackgroundService.instance.stopTracking();

    _isProcessingSave = true;
    this._safeNotifyListeners();

    final savedDuration = _secondsElapsed;
    final savedDistance = double.parse(_distanceKm.toStringAsFixed(2));
    final savedCalories = double.parse(_caloriesBurned.toStringAsFixed(1));

    // 2. Map Matching: ดึงเส้นทางไปเทียบเคียงถนน/ทางวิ่งจริง (Post-workout Processing)
    List<LatLng> processedPoints = _routePoints;
    if (_selectedCategory.isMoving && _routePoints.length >= 3) {
      final mode = _selectedCategory.id == 'cycling' ? 'cycling' : 'walking';
      processedPoints = await MapMatchingService.instance.matchRoute(
        _routePoints,
        mode: mode,
      );
    }

    // 3. Polyline Encoding: บีบอัดพิกัด GPS นับพันจุดให้เหลือเพียง String สั้นๆ
    final encodedRoute = RouteUtils.toEncodedPolyline(
      processedPoints,
      simplify: true,
      toleranceMeters: 2.0,
    );

    if (savedDuration >= 1 && _userId > 0) {
      // 4. บันทึกลงฐานข้อมูล SQLite ประจำเครื่อง
      await AppDatabase.instance.insertWorkout(
        userId: _userId,
        type: _selectedCategory.title,
        distanceKm: savedDistance,
        durationSeconds: savedDuration,
        caloriesBurned: savedCalories,
        routePoints: encodedRoute,
      );

      // 5. ล้าง Checkpoint การกู้คืนเนื่องจากบันทึกกิจกรรมเสร็จสมบูรณ์แล้ว
      await WorkoutRecoveryService.instance.clearCheckpoint();

      // 6. สร้างการแจ้งเตือนสรุปผลในแอป
      unawaited(AppNotificationService.instance.onWorkoutSaved(
        workoutType: _selectedCategory.title,
        distanceKm: savedDistance,
        caloriesBurned: savedCalories,
        durationSeconds: savedDuration,
      ));

      // 7. ตรวจสอบและปลดล็อกเหรียญรางวัลความสำเร็จ (Badges Gamification)
      try {
        final totalWorkouts = await AppDatabase.instance.getWorkoutCount(
          userId: _userId,
        );
        if (totalWorkouts >= 1) {
          await GoalApiService.unlockBadgeRemote(
            userId: _userId,
            badgeName: 'ผู้เริ่มต้นก้าวแรก',
          );
          unawaited(AppNotificationService.instance.onBadgeUnlocked(
            badgeName: 'ผู้เริ่มต้นก้าวแรก',
          ));
        }
        final workouts = await AppDatabase.instance.getWorkouts(
          userId: _userId,
        );
        final cumulativeRunningDistance = workouts.fold<double>(0.0, (
          total,
          workout,
        ) {
          final type = workout['sType']?.toString().toLowerCase() ?? '';
          if (!type.contains('วิ่ง') && !type.contains('running')) return total;
          return total + ((workout['nDistance'] as num?)?.toDouble() ?? 0.0);
        });
        final cumulativeCalories = workouts.fold<double>(
          0.0,
          (total, workout) =>
              total + ((workout['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0),
        );
        if (cumulativeRunningDistance >= 5.0) {
          await GoalApiService.unlockBadgeRemote(
            userId: _userId,
            badgeName: 'วิ่งสะสม 5 กิโลเมตร',
          );
          unawaited(AppNotificationService.instance.onBadgeUnlocked(
            badgeName: 'วิ่งสะสม 5 กิโลเมตร',
          ));
        }
        if (cumulativeCalories >= 500.0) {
          await GoalApiService.unlockBadgeRemote(
            userId: _userId,
            badgeName: 'นักเบิร์นไฟแรง',
          );
          unawaited(AppNotificationService.instance.onBadgeUnlocked(
            badgeName: 'นักเบิร์นไฟแรง',
          ));
        }
      } catch (_) {}

      // 8. สั่ง SyncService ให้อัปโหลดข้อมูลที่ค้างอยู่ขึ้น Cloud ทันที
      unawaited(SyncService.instance.syncPendingData());
    }

    _isProcessingSave = false;
    this.returnToCategorySelection();
    return true;
  }

  // ฟังก์ชัน: ละทิ้งกิจกรรมการออกกำลังกาย (Discard Workout)
  void discardWorkout() {
    _timer?.cancel();
    _positionStreamSub?.cancel();
    LocationBackgroundService.instance.stopTracking();
    unawaited(WorkoutRecoveryService.instance.clearCheckpoint());
    _lastPosition = null;
    _routePoints.clear();
    this.returnToCategorySelection();
  }

  // ฟังก์ชัน: จัดรูปแบบเวลาเป็น HH:mm:ss
  String formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
