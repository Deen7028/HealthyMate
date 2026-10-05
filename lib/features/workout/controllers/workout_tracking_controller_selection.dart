// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์การติดตามและประวัติการออกกำลังกาย (workout tracking controller selection)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'workout_tracking_controller.dart';

/// ส่วนขยายจัดการการเลือกหมวดหมู่กิจกรรมและตั้งค่าเป้าหมาย (Workout Selection Logic)
extension WorkoutTrackingSelection on WorkoutTrackingController {
  /// เลือกหมวดหมู่กิจกรรมจากข้อความ ID หรือชื่อภาษาไทย
  void selectCategoryByName(String? categoryStr, [int? targetDurationMinutes]) {
    final cat = WorkoutCategory.fromIdOrTitle(categoryStr);
    this.selectCategory(cat, targetDurationMinutes);
  }

  /// เลือกหมวดหมู่กิจกรรมและตั้งค่าเป้าหมายเวลา (ถ้ามี) พร้อมรีเซ็ตตัวแปรสถิติ
  void selectCategory(WorkoutCategory category, [int? targetDurationMinutes]) {
    _selectedCategory = category;
    _status = WorkoutState.initial;
    _secondsElapsed = 0;
    _targetDurationSeconds =
        (targetDurationMinutes != null && targetDurationMinutes > 0)
        ? targetDurationMinutes * 60
        : null;
    secondsElapsedNotifier.value = _targetDurationSeconds ?? 0;
    _accumulatedSeconds = 0;
    _workoutStartTime = null;
    _distanceKm = 0.0;
    _caloriesBurned = 0.0;
    _zeroSpeedSeconds = 0;
    _isAutoPaused = false;
    _lastAnnouncedKm = 0;
    _routePoints.clear();
    _lastPosition = null;
    this._safeNotifyListeners();
  }

  /// กำหนดเป้าหมายเวลาเป็นนาที (นับถอยหลัง)
  void setTargetDurationMinutes(int? targetMinutes) {
    _targetDurationSeconds = (targetMinutes != null && targetMinutes > 0)
        ? targetMinutes * 60
        : null;
    secondsElapsedNotifier.value = isCountdownMode
        ? displaySeconds
        : _secondsElapsed;
    this._safeNotifyListeners();
  }

  /// กลับสู่หน้าจอเลือกหมวดหมู่กิจกรรมและล้างค่าทั้งหมด
  void returnToCategorySelection() {
    _timer?.cancel();
    _workoutStartTime = null;
    LocationBackgroundService.instance.stopTracking();
    _status = WorkoutState.selectingCategory;
    _secondsElapsed = 0;
    _targetDurationSeconds = null;
    secondsElapsedNotifier.value = 0;
    _distanceKm = 0.0;
    _caloriesBurned = 0.0;
    _zeroSpeedSeconds = 0;
    _isAutoPaused = false;
    _lastAnnouncedKm = 0;
    _routePoints.clear();
    _lastPosition = null;
    this._safeNotifyListeners();
  }

  /// เปลี่ยนรูปแบบแผนที่ (Standard / Satellite / Terrain / Hybrid)
  void setMapType(AppMapType type) {
    _currentMapType = type;
    this._safeNotifyListeners();
  }

  void toggleTraffic(bool value) {
    _showTraffic = value;
    this._safeNotifyListeners();
  }

  void enableGps() {
    _isGpsEnabled = true;
    this._safeNotifyListeners();
  }
}
