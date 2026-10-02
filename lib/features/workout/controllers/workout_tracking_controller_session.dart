part of 'workout_tracking_controller.dart';

extension WorkoutTrackingSession on WorkoutTrackingController {
  void startWorkout() {
    if (!_isGpsEnabled || _userId <= 0) {
      return;
    }
    _status = WorkoutState.running;
    _isAutoPaused = false;
    _zeroSpeedSeconds = 0;
    _workoutStartTime = DateTime.now();
    this._safeNotifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_status == WorkoutState.running && !_isAutoPaused) {
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

        this._checkAutoPauseCondition();
      }
    });

    LocationBackgroundService.instance.startTracking();
    this._startLocationUpdates();
  }

  /// คำนวณค่า METs ไดนามิกตามประเภทกิจกรรมและความเร็วปัจจุบัน (กม./ชม.)
  double _calculateCurrentMet() {
    // 1. กิจกรรมไม่อยู่กับที่ (ทำสมาธิ / โยคะ)
    if (_selectedCategory.id == 'meditation') {
      return 1.0;
    }
    if (_selectedCategory.id == 'yoga') {
      return 3.3;
    }

    // 2. กิจกรรมเคลื่อนที่ หากหยุดนิ่งอยู่กับที่ (_zeroSpeedSeconds > 0) คิดเป็น Resting MET = 1.0
    if (_zeroSpeedSeconds > 0) {
      return 1.0;
    }

    // คำนวณความเร็ว (กม./ชม.) จากพิกัดล่าสุด หรือความเร็วเฉลี่ยสะสม
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

  void _checkAutoPauseCondition() {
    // หากความเร็วเข้าใกล้ 0 ต่อเนื่องเกิน 12 วินาที เข้าสู่สถานะ Auto-Pause
    if (_zeroSpeedSeconds >= 12 && !_isAutoPaused) {
      _isAutoPaused = true;
      TtsService.instance.speak('หยุดการบันทึกชั่วคราวอัตโนมัติ');
      this._safeNotifyListeners();
    }
  }

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
