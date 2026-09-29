import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/location_background_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/core/services/tts_service.dart';
import '../models/workout_models.dart';

part 'workout_tracking_controller_lifecycle.dart';
part 'workout_tracking_controller_selection.dart';
part 'workout_tracking_controller_session.dart';
part 'workout_tracking_controller_location.dart';
part 'workout_tracking_controller_persistence.dart';

class WorkoutTrackingController extends ChangeNotifier {
  WorkoutState _status = WorkoutState.selectingCategory;
  WorkoutCategory _selectedCategory = WorkoutCategory.categories.first;
  AppMapType _currentMapType = AppMapType.standard;
  bool _showTraffic = false;
  bool _isGpsEnabled = false;

  Timer? _timer;
  StreamSubscription<Position>? _positionStreamSub;
  StreamSubscription<dynamic>? _bgLocationSub;
  Position? _lastPosition;
  final List<LatLng> _routePoints = [];
  int _secondsElapsed = 0;
  final ValueNotifier<int> secondsElapsedNotifier = ValueNotifier<int>(0);
  double _distanceKm = 0.0;
  double _caloriesBurned = 0.0;

  // Countdown timer support (e.g. meditation with target minutes)
  int? _targetDurationSeconds;

  double _userWeightKg = 65.0;
  int _userId = 0;
  bool _isDisposed = false;
  late final Future<void> _userDataLoad;

  // Auto-pause & TTS variables
  int _zeroSpeedSeconds = 0;
  bool _isAutoPaused = false;
  int _lastAnnouncedKm = 0;
  DateTime? _workoutStartTime;
  int _accumulatedSeconds = 0;

  void _safeNotifyListeners() {
    if (!_isDisposed && hasListeners) {
      notifyListeners();
    }
  }

  WorkoutTrackingController() {
    _userDataLoad = this._loadUserData();
    this._listenBackgroundLocation();
  }

  // Getters
  WorkoutState get status => _status;
  WorkoutCategory get selectedCategory => _selectedCategory;
  AppMapType get currentMapType => _currentMapType;
  bool get showTraffic => _showTraffic;
  bool get isGpsEnabled => _isGpsEnabled;
  int get secondsElapsed => _secondsElapsed;
  int? get targetDurationSeconds => _targetDurationSeconds;
  bool get isCountdownMode =>
      _targetDurationSeconds != null && _targetDurationSeconds! > 0;
  int get displaySeconds {
    if (isCountdownMode) {
      final remaining = _targetDurationSeconds! - _secondsElapsed;
      return remaining > 0 ? remaining : 0;
    }
    return _secondsElapsed;
  }

  double get distanceKm => _distanceKm;
  double get caloriesBurned => _caloriesBurned;
  int get userId => _userId;
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);
  LatLng? get currentLatLng => _lastPosition != null
      ? LatLng(_lastPosition!.latitude, _lastPosition!.longitude)
      : null;
  bool get isRunning => _status == WorkoutState.running;
  bool get isPaused => _status == WorkoutState.paused;
  bool get isAutoPaused => _isAutoPaused;
  bool get hasAuthenticatedUser => _userId > 0;

  Future<void> ensureUserDataLoaded() => _userDataLoad;

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _positionStreamSub?.cancel();
    _bgLocationSub?.cancel();
    secondsElapsedNotifier.dispose();
    LocationBackgroundService.instance.stopTracking();
    super.dispose();
  }
}
