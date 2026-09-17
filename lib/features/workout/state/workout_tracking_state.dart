import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/auth_service.dart';
import '../models/workout_models.dart';


class WorkoutTrackingState extends ChangeNotifier {
  WorkoutState _status = WorkoutState.selectingCategory;
  WorkoutCategory _selectedCategory = WorkoutCategory.categories.first;
  AppMapType _currentMapType = AppMapType.standard;
  bool _showTraffic = false;
  bool _isGpsEnabled = false;

  Timer? _timer;
  int _secondsElapsed = 0;
  double _distanceKm = 0.0;
  double _caloriesBurned = 0.0;

  double _userWeightKg = 65.0;
  int _userId = 1;
  bool _isDisposed = false;

  WorkoutTrackingState() {
    _loadUserData();
  }

  // Getters
  WorkoutState get status => _status;
  WorkoutCategory get selectedCategory => _selectedCategory;
  AppMapType get currentMapType => _currentMapType;
  bool get showTraffic => _showTraffic;
  bool get isGpsEnabled => _isGpsEnabled;
  int get secondsElapsed => _secondsElapsed;
  double get distanceKm => _distanceKm;
  double get caloriesBurned => _caloriesBurned;
  bool get isRunning => _status == WorkoutState.running;
  bool get isPaused => _status == WorkoutState.paused;

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed && hasListeners) {
      notifyListeners();
    }
  }

  Future<void> _loadUserData() async {
    final email = AuthService.instance.currentUserEmail;
    if (email.isNotEmpty) {
      final user = await AppDatabase.instance.getUserByEmail(email);
      if (user != null) {
        _userId = user.nUserId;
        if (user.nWeight > 0) {
          _userWeightKg = user.nWeight;
        }
        _safeNotifyListeners();
      }
    }
  }

  void selectCategory(WorkoutCategory category) {
    _selectedCategory = category;
    _status = WorkoutState.initial;
    _secondsElapsed = 0;
    _distanceKm = 0.0;
    _caloriesBurned = 0.0;
    _safeNotifyListeners();
  }

  void returnToCategorySelection() {
    _timer?.cancel();
    _status = WorkoutState.selectingCategory;
    _secondsElapsed = 0;
    _distanceKm = 0.0;
    _caloriesBurned = 0.0;
    _safeNotifyListeners();
  }

  void setMapType(AppMapType type) {
    _currentMapType = type;
    _safeNotifyListeners();
  }

  void toggleTraffic(bool value) {
    _showTraffic = value;
    _safeNotifyListeners();
  }

  void enableGps() {
    _isGpsEnabled = true;
    _safeNotifyListeners();
  }

  void startWorkout() {
    _status = WorkoutState.running;
    _safeNotifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      final speedMultiplier = _selectedCategory.id == 'walking'
          ? 0.0014
          : (_selectedCategory.id == 'cycling' ? 0.0055 : 0.0024);
      _distanceKm += speedMultiplier;

      final calPerSecond =
          (_selectedCategory.metValue * 3.5 * _userWeightKg / 200.0) / 60.0;
      _caloriesBurned += calPerSecond;

      _safeNotifyListeners();
    });
  }

  void pauseWorkout() {
    _timer?.cancel();
    _status = WorkoutState.paused;
    _safeNotifyListeners();
  }

  void resumeWorkout() {
    startWorkout();
  }

  /// บันทึกกิจกรรมลงฐานข้อมูลตาราง TbWorkouts
  Future<bool> saveWorkout() async {
    _timer?.cancel();

    final savedDuration = _secondsElapsed;
    final savedDistance = double.parse(_distanceKm.toStringAsFixed(2));
    final savedCalories = double.parse(_caloriesBurned.toStringAsFixed(1));

    if (savedDuration >= 1) {
      await AppDatabase.instance.insertWorkout(
        userId: _userId,
        type: _selectedCategory.title,
        distanceKm: savedDistance,
        durationSeconds: savedDuration,
        caloriesBurned: savedCalories,
      );
    }

    returnToCategorySelection();
    return true;
  }

  /// ละทิ้งกิจกรรม
  void discardWorkout() {
    _timer?.cancel();
    returnToCategorySelection();
  }

  String formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
