part of 'workout_tracking_controller.dart';

// ส่วนจัดการเซสชันการออกกำลังกาย (WorkoutTrackingSession)
// ทำหน้าที่จับเวลา, คำนวณแคลอรีตามสูตร METs, ระบบหยุดอัตโนมัติ (Auto-Pause) และ Checkpoint
extension WorkoutTrackingSession on WorkoutTrackingController {
  // ฟังก์ชัน: เริ่มเซสชันการออกกำลังกาย (Start Workout Session)
  void startWorkout() {
    // 1. ตรวจสอบสถานะ GPS และ ID ของผู้ใช้
    if (!_isGpsEnabled || _userId <= 0) {
      return;
    }

    // 2. ตั้งค่าสถานะเริ่มต้นของเซสชัน
    _status = WorkoutState.running;
    _isAutoPaused = false;
    _zeroSpeedSeconds = 0;
    _workoutStartTime = DateTime.now();
    _kalmanFilter.reset();
    this._safeNotifyListeners();

    // 3. ขอสิทธิ์ยกเว้น Battery Optimization บน Android เพื่อให้ GPS รันต่อเนื่องในเบื้องหลัง
    LocationBackgroundService.instance.requestBatteryOptimizationExemption();

    // 4. เริ่มตัวนับเวลา (Timer Loop ทุก 1 วินาที)
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_status == WorkoutState.running && !_isAutoPaused) {
        // คำนวณเวลาที่ผ่านไป (วินาที)
        if (_workoutStartTime != null) {
          _secondsElapsed =
              _accumulatedSeconds +
              DateTime.now().difference(_workoutStartTime!).inSeconds;
        }
        secondsElapsedNotifier.value = displaySeconds;

        // คำนวณแคลอรีตามสูตรมาตรฐานการกีฬาตามความเร็วไดนามิก (METs * 0.0175 * WeightKg * TimeMinutes)
        final activeMet = this._calculateCurrentMet();
        final caloriesPerSecond = (activeMet * 0.0175 * _userWeightKg) / 60.0;
        _caloriesBurned += caloriesPerSecond;

        // ตรวจสอบเงื่อนไขการหยุดชั่วคราวอัตโนมัติ
        this._checkAutoPauseCondition();

        // บันทึก Checkpoint ทุก 10 วินาที ป้องกันข้อมูลสูญหายกรณีแอปปิดตัวกะทันหัน
        if (_secondsElapsed % 10 == 0 && _userId > 0) {
          WorkoutRecoveryService.instance.saveCheckpoint(
            userId: _userId,
            categoryId: _selectedCategory.id,
            distanceKm: _distanceKm,
            secondsElapsed: _secondsElapsed,
            caloriesBurned: _caloriesBurned,
            routePoints: _routePoints,
          );
        }
      }
    });

    // 5. เปิดระบบติดตามพิกัด GPS เบื้องหลัง
    LocationBackgroundService.instance.startTracking();
    this._startLocationUpdates();
  }

  // ฟังก์ชัน: คำนวณค่า METs ไดนามิกตามประเภทกิจกรรมและความเร็วปัจจุบัน (กม./ชม.)
  double _calculateCurrentMet() {
    // 1. กิจกรรมไม่อยู่กับที่ (ทำสมาธิ / โยคะ)
    if (_selectedCategory.id == 'meditation') {
      return 1.0;
    }
    if (_selectedCategory.id == 'yoga') {
      return 3.3;
    }

    // 2. หากหยุดนิ่งอยู่กับที่ (_zeroSpeedSeconds > 0) คิดเป็น Resting MET = 1.0
    if (_zeroSpeedSeconds > 0) {
      return 1.0;
    }

    // 3. คำนวณความเร็ว (กม./ชม.) จากพิกัดล่าสุด หรือความเร็วเฉลี่ยสะสม
    double speedKmh = 0.0;
    if (_lastPosition != null && _lastPosition!.speed > 0) {
      speedKmh = _lastPosition!.speed * 3.6;
    } else if (_secondsElapsed > 0 && _distanceKm > 0) {
      speedKmh = (_distanceKm / (_secondsElapsed / 3600.0));
    }

    // หากความเร็วเหลือน้อยมาก (< 0.5 กม./ชม.) ถือว่าเป็น Resting MET
    if (speedKmh <= 0.5) {
      return 1.0;
    }

    // 4. คำนวณ METs ตามประเภทการออกกำลังกายและความเร็ว
    switch (_selectedCategory.id) {
      case 'walking':
        // เดิน (Walking)
        if (speedKmh <= 4.0) return 2.5;
        if (speedKmh <= 6.0) return 4.1;
        if (speedKmh <= 7.0) return 6.2;
        return 9.6;

      case 'running':
        // วิ่ง (Running)
        if (speedKmh <= 7.0) return 7.5;
        if (speedKmh <= 10.0) return 9.6;
        if (speedKmh <= 13.0) return 11.5;
        return 14.0;

      case 'cycling':
        // ปั่นจักรยาน (Cycling)
        if (speedKmh < 16.0) return 4.0;
        if (speedKmh <= 19.0) return 6.0;
        if (speedKmh <= 22.0) return 8.0;
        if (speedKmh <= 25.0) return 10.0;
        if (speedKmh <= 30.0) return 12.0;
        return 16.0;

      default:
        return _selectedCategory.metValue;
    }
  }

  // ฟังก์ชัน: ตรวจสอบการหยุดชั่วคราวอัตโนมัติ (Auto-Pause)
  void _checkAutoPauseCondition() {
    // หากความเร็วเข้าใกล้ 0 ต่อเนื่องเกิน 12 วินาที เข้าสู่สถานะ Auto-Pause
    if (_zeroSpeedSeconds >= 12 && !_isAutoPaused) {
      _isAutoPaused = true;
      TtsService.instance.speak('หยุดการบันทึกชั่วคราวอัตโนมัติ');
      this._safeNotifyListeners();
    }
  }

  // ฟังก์ชัน: เริ่มรับพิกัดตำแหน่งเริ่มต้น (Initial Location Updates)
  void _startLocationUpdates() {
    // ดึงพิกัดตั้งต้นเพื่อให้อัปเดต UI ทันที และวาง Marker จุดเริ่มต้น
    Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        )
        .then((pos) {
          if (_lastPosition == null && _status == WorkoutState.running) {
            _lastPosition = pos;
            if (_routePoints.isEmpty) {
              _routePoints.add(LatLng(pos.latitude, pos.longitude));
              this._safeNotifyListeners();
            }
          }
        })
        .catchError((_) {});
  }
}
