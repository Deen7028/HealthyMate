// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์การติดตามและประวัติการออกกำลังกาย (workout tracking controller persistence)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'workout_tracking_controller.dart';

extension WorkoutTrackingPersistence on WorkoutTrackingController {
  void pauseWorkout() {
    if (_workoutStartTime != null) {
      _accumulatedSeconds += DateTime.now()
          .difference(_workoutStartTime!)
          .inSeconds;
      _workoutStartTime = null;
    }
    _timer?.cancel();
    _positionStreamSub?.cancel();
    LocationBackgroundService.instance.stopTracking();
    _status = WorkoutState.paused;
    this._safeNotifyListeners();
  }

  void resumeWorkout() {
    this.startWorkout();
  }

  /// บันทึกกิจกรรมลงฐานข้อมูลตาราง TbWorkouts (SQLite + Remote Server)
  Future<bool> saveWorkout() async {
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

    // 5. Polyline Encoding & Douglas-Peucker Simplification:
    // บีบอัดพิกัด GPS นับพันจุดให้เหลือเพียง ASCII String สั้นๆ ประหยัดเน็ตและดาต้าเบส 90%+
    final encodedRoute = RouteUtils.toEncodedPolyline(
      processedPoints,
      simplify: true,
      toleranceMeters: 2.0,
    );

    if (savedDuration >= 1 && _userId > 0) {
      // 1. บันทึกลง SQLite (isSynced = 0)
      await AppDatabase.instance.insertWorkout(
        userId: _userId,
        type: _selectedCategory.title,
        distanceKm: savedDistance,
        durationSeconds: savedDuration,
        caloriesBurned: savedCalories,
        routePoints: encodedRoute,
      );

      // 4. ล้าง Checkpoint การกู้คืนเนื่องจากบันทึกกิจกรรมเสร็จสมบูรณ์แล้ว
      await WorkoutRecoveryService.instance.clearCheckpoint();

      // 🏆 อัปเดตและปลดล็อกเหรียญรางวัล (TbBadges & TbUserBadges)
      try {
        final totalWorkouts = await AppDatabase.instance.getWorkoutCount(
          userId: _userId,
        );
        if (totalWorkouts >= 1) {
          await GoalApiService.unlockBadgeRemote(
            userId: _userId,
            badgeName: 'ผู้เริ่มต้นก้าวแรก',
          );
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
        }
        if (cumulativeCalories >= 500.0) {
          await GoalApiService.unlockBadgeRemote(
            userId: _userId,
            badgeName: 'นักเบิร์นไฟแรง',
          );
        }
      } catch (_) {}

      // แจ้งเตือน SyncService ให้เริ่มเช็คและส่งข้อมูลขึ้น Cloud ทันทีถ้ามีเน็ต
      unawaited(SyncService.instance.syncPendingData());
    }

    _isProcessingSave = false;
    this.returnToCategorySelection();
    return true;
  }

  /// ละทิ้งกิจกรรม
  void discardWorkout() {
    _timer?.cancel();
    _positionStreamSub?.cancel();
    LocationBackgroundService.instance.stopTracking();
    unawaited(WorkoutRecoveryService.instance.clearCheckpoint());
    _lastPosition = null;
    _routePoints.clear();
    this.returnToCategorySelection();
  }

  String formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
