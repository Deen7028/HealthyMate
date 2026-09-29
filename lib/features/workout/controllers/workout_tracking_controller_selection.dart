part of 'workout_tracking_controller.dart';

extension WorkoutTrackingSelection on WorkoutTrackingController {
  void selectCategoryByName(String? categoryStr, [int? targetDurationMinutes]) {
    final cat = WorkoutCategory.fromIdOrTitle(categoryStr);
    this.selectCategory(cat, targetDurationMinutes);
  }

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

  void setTargetDurationMinutes(int? targetMinutes) {
    _targetDurationSeconds = (targetMinutes != null && targetMinutes > 0)
        ? targetMinutes * 60
        : null;
    secondsElapsedNotifier.value = isCountdownMode
        ? displaySeconds
        : _secondsElapsed;
    this._safeNotifyListeners();
  }

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
