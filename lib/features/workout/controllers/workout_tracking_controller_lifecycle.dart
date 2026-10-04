part of 'workout_tracking_controller.dart';

extension WorkoutTrackingLifecycle on WorkoutTrackingController {
  Future<void> _loadUserData() async {
    try {
      final dbCategories = await AppDatabase.instance.getWorkoutCategories();
      if (dbCategories.isNotEmpty) {
        final parsed = dbCategories.map((m) => WorkoutCategory.fromMap(m)).toList();
        WorkoutCategory.updateCategories(parsed);
      }

      final email = AuthService.instance.currentUserEmail;
      final user = email.isNotEmpty
          ? await AppDatabase.instance.getUserByEmail(email)
          : await AppDatabase.instance.getCurrentUser();
      if (user != null) {
        _userId = user.nUserId;
        if (user.nWeight != null && user.nWeight! > 0) {
          _userWeightKg = user.nWeight!;
        }
      }
      this._safeNotifyListeners();
    } catch (_) {
      debugPrint('WorkoutTrackingController: Failed to load signed-in user or categories.');
    }
  }

  void _listenBackgroundLocation() {
    final service = FlutterBackgroundService();
    _bgLocationSub = service.on('updateLocation').listen((event) {
      if (_isDisposed || event == null || _status != WorkoutState.running) {
        return;
      }
      final lat = (event['latitude'] as num?)?.toDouble();
      final lng = (event['longitude'] as num?)?.toDouble();
      final speed = (event['speed'] as num?)?.toDouble() ?? 0.0;
      final accuracy = (event['accuracy'] as num?)?.toDouble() ?? 10.0;

      DateTime? bgTimestamp;
      if (event['timestamp'] != null) {
        bgTimestamp = DateTime.tryParse(event['timestamp'].toString());
      }

      if (lat != null && lng != null) {
        this._handleNewLocation(
          latitude: lat,
          longitude: lng,
          speedMs: speed,
          accuracy: accuracy,
          timestamp: bgTimestamp,
        );
      }
    });
  }

  /// ตรวจสอบว่ามีกิจกรรมที่ค้างอยู่จากการปิดแอปหรือ Crash หรือไม่
  Future<WorkoutCheckpoint?> checkForInterruptedWorkout() async {
    await _userDataLoad;
    if (_userId <= 0) return null;
    return WorkoutRecoveryService.instance.getCheckpoint(_userId);
  }

  /// กู้คืนสถานะกิจกรรมจาก Checkpoint
  void restoreFromCheckpoint(WorkoutCheckpoint checkpoint) {
    // กำหนดหมวดหมู่กิจกรรม
    final matchedCategory = WorkoutCategory.categories.firstWhere(
      (c) => c.id == checkpoint.categoryId,
      orElse: () => WorkoutCategory.categories.first,
    );
    _selectedCategory = matchedCategory;

    _distanceKm = checkpoint.distanceKm;
    _secondsElapsed = checkpoint.secondsElapsed;
    _accumulatedSeconds = checkpoint.secondsElapsed;
    secondsElapsedNotifier.value = checkpoint.secondsElapsed;
    _caloriesBurned = checkpoint.caloriesBurned;

    _routePoints.clear();
    _routePoints.addAll(checkpoint.routePoints);
    if (_routePoints.isNotEmpty) {
      final last = _routePoints.last;
      _lastPosition = Position(
        latitude: last.latitude,
        longitude: last.longitude,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    _status = WorkoutState.paused;
    this._safeNotifyListeners();
    TtsService.instance.speak('กู้คืนกิจกรรมที่ค้างอยู่เรียบร้อยแล้ว');
  }
}
