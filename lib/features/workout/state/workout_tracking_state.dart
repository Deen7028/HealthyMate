import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/location_background_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/core/services/tts_service.dart';
import '../models/workout_models.dart';

class WorkoutTrackingState extends ChangeNotifier {
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
  double _distanceKm = 0.0;
  double _caloriesBurned = 0.0;

  double _userWeightKg = 65.0;
  int _userId = 1;
  bool _isDisposed = false;

  // Auto-pause & TTS variables
  int _zeroSpeedSeconds = 0;
  bool _isAutoPaused = false;
  int _lastAnnouncedKm = 0;

  WorkoutTrackingState() {
    _loadUserData();
    _listenBackgroundLocation();
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
  int get userId => _userId;
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);
  bool get isRunning => _status == WorkoutState.running;
  bool get isPaused => _status == WorkoutState.paused;
  bool get isAutoPaused => _isAutoPaused;

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _positionStreamSub?.cancel();
    _bgLocationSub?.cancel();
    LocationBackgroundService.instance.stopTracking();
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
        if (user.nWeight != null && user.nWeight! > 0) {
          _userWeightKg = user.nWeight!;
        }
        _safeNotifyListeners();
      }
    }
  }

  void _listenBackgroundLocation() {
    final service = FlutterBackgroundService();
    _bgLocationSub = service.on('updateLocation').listen((event) {
      if (_isDisposed || event == null || _status != WorkoutState.running) return;
      final lat = (event['latitude'] as num?)?.toDouble();
      final lng = (event['longitude'] as num?)?.toDouble();
      final speed = (event['speed'] as num?)?.toDouble() ?? 0.0;
      final accuracy = (event['accuracy'] as num?)?.toDouble() ?? 10.0;

      if (lat != null && lng != null) {
        _handleNewLocation(
          latitude: lat,
          longitude: lng,
          speedMs: speed,
          accuracy: accuracy,
        );
      }
    });
  }

  DateTime? _workoutStartTime;
  int _accumulatedSeconds = 0;

  void selectCategoryByName(String? categoryStr) {
    final cat = WorkoutCategory.fromIdOrTitle(categoryStr);
    selectCategory(cat);
  }

  void selectCategory(WorkoutCategory category) {
    _selectedCategory = category;
    _status = WorkoutState.initial;
    _secondsElapsed = 0;
    _accumulatedSeconds = 0;
    _workoutStartTime = null;
    _distanceKm = 0.0;
    _caloriesBurned = 0.0;
    _zeroSpeedSeconds = 0;
    _isAutoPaused = false;
    _lastAnnouncedKm = 0;
    _routePoints.clear();
    _lastPosition = null;
    _safeNotifyListeners();
  }

  void returnToCategorySelection() {
    _timer?.cancel();
    _workoutStartTime = null;
    LocationBackgroundService.instance.stopTracking();
    _status = WorkoutState.selectingCategory;
    _secondsElapsed = 0;
    _distanceKm = 0.0;
    _caloriesBurned = 0.0;
    _zeroSpeedSeconds = 0;
    _isAutoPaused = false;
    _lastAnnouncedKm = 0;
    _routePoints.clear();
    _lastPosition = null;
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
    if (!_isGpsEnabled) {
      return;
    }
    _status = WorkoutState.running;
    _isAutoPaused = false;
    _zeroSpeedSeconds = 0;
    _workoutStartTime = DateTime.now();
    _safeNotifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_status == WorkoutState.running && !_isAutoPaused) {
        if (_workoutStartTime != null) {
          _secondsElapsed = _accumulatedSeconds + DateTime.now().difference(_workoutStartTime!).inSeconds;
        }
        _checkAutoPauseCondition();
        _safeNotifyListeners();
      }
    });

    LocationBackgroundService.instance.startTracking();
    _startLocationUpdates();
  }

  void _checkAutoPauseCondition() {
    // หากความเร็วเข้าใกล้ 0 ต่อเนื่องเกิน 12 วินาที เข้าสู่สถานะ Auto-Pause
    if (_zeroSpeedSeconds >= 12 && !_isAutoPaused) {
      _isAutoPaused = true;
      TtsService.instance.speak('หยุดการบันทึกชั่วคราวอัตโนมัติ');
      _safeNotifyListeners();
    }
  }

  void _startLocationUpdates() {
    _positionStreamSub?.cancel();

    Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).then((pos) {
      _lastPosition = pos;
      if (_routePoints.isEmpty) {
        _routePoints.add(LatLng(pos.latitude, pos.longitude));
        _safeNotifyListeners();
      }
    }).catchError((_) {});

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (_status != WorkoutState.running) return;
      _handleNewLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        speedMs: position.speed,
        accuracy: position.accuracy,
      );
    });
  }

  void _handleNewLocation({
    required double latitude,
    required double longitude,
    required double speedMs,
    required double accuracy,
  }) {
    // 1. ตรวจสอบความเร็วสำหรับ Auto-Pause (ความเร็วน้อยกว่า 0.3 m/s หรือ 1 km/h ถือว่าหยุดนิ่ง)
    if (speedMs < 0.3) {
      _zeroSpeedSeconds++;
    } else {
      _zeroSpeedSeconds = 0;
      if (_isAutoPaused) {
        _isAutoPaused = false;
        TtsService.instance.speak('เริ่มบันทึกกิจกรรมต่ออัตโนมัติ');
      }
    }

    if (_isAutoPaused) return;

    if (_lastPosition != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        latitude,
        longitude,
      );

      if (distanceInMeters >= 2.5 && distanceInMeters < 150 && accuracy < 35 && speedMs < 25.0) {
        final addedKm = distanceInMeters / 1000.0;
        _distanceKm += addedKm;

        final calorieFactorPerKm = _selectedCategory.id == 'walking'
            ? 0.75
            : (_selectedCategory.id == 'cycling' ? 0.35 : 1.03);
        _caloriesBurned += addedKm * _userWeightKg * calorieFactorPerKm;

        _lastPosition = Position(
          longitude: longitude,
          latitude: latitude,
          timestamp: DateTime.now(),
          accuracy: accuracy,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: speedMs,
          speedAccuracy: 0.0,
        );

        _routePoints.add(LatLng(latitude, longitude));

        // 2. Voice Feedback: ทุกๆ 1 กิโลเมตร ให้ ขานบอกระยะทาง เวลา และ Pace
        final currentKmFloor = _distanceKm.floor();
        if (currentKmFloor > _lastAnnouncedKm && currentKmFloor >= 1) {
          _lastAnnouncedKm = currentKmFloor;
          final double validDistance = _distanceKm >= 0.05 ? _distanceKm : 0.0;
          final double paceMinutesPerKm = validDistance > 0 ? ((_secondsElapsed / 60.0) / validDistance).clamp(0.0, 99.0) : 0.0;
          final int paceMin = paceMinutesPerKm.floor();
          final int paceSec = ((paceMinutesPerKm - paceMin) * 60).round();
          final paceStr = '$paceMin นาที ${paceSec.toString().padLeft(2, '0')} วินาที ต่อกิโลเมตร';
          TtsService.instance.announceWorkoutProgress(
            distanceKm: _distanceKm,
            secondsElapsed: _secondsElapsed,
            paceText: paceStr,
          );
        }

        _safeNotifyListeners();
      }
    } else {
      _lastPosition = Position(
        longitude: longitude,
        latitude: latitude,
        timestamp: DateTime.now(),
        accuracy: accuracy,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: speedMs,
        speedAccuracy: 0.0,
      );
      _routePoints.add(LatLng(latitude, longitude));
    }
  }

  void pauseWorkout() {
    if (_workoutStartTime != null) {
      _accumulatedSeconds += DateTime.now().difference(_workoutStartTime!).inSeconds;
      _workoutStartTime = null;
    }
    _timer?.cancel();
    _positionStreamSub?.cancel();
    LocationBackgroundService.instance.stopTracking();
    _status = WorkoutState.paused;
    _safeNotifyListeners();
  }

  void resumeWorkout() {
    startWorkout();
  }

  /// บันทึกกิจกรรมลงฐานข้อมูลตาราง TbWorkouts
  Future<bool> saveWorkout() async {
    _timer?.cancel();
    _positionStreamSub?.cancel();
    LocationBackgroundService.instance.stopTracking();

    final savedDuration = _secondsElapsed;
    final savedDistance = double.parse(_distanceKm.toStringAsFixed(2));
    final savedCalories = double.parse(_caloriesBurned.toStringAsFixed(1));

    // แปลงพิกัด GPS เส้นทางทั้งหมดเป็น JSON String
    final routePointsJson = jsonEncode(
      _routePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    );

    if (savedDuration >= 1) {
      await AppDatabase.instance.insertWorkout(
        userId: _userId,
        type: _selectedCategory.title,
        distanceKm: savedDistance,
        durationSeconds: savedDuration,
        caloriesBurned: savedCalories,
        routePoints: routePointsJson,
      );
      // แจ้งเตือน SyncService ให้เริ่มเช็คและส่งข้อมูลขึ้น Cloud ทันทีถ้ามีเน็ต
      unawaited(SyncService.instance.syncPendingData());
    }

    returnToCategorySelection();
    return true;
  }

  /// ละทิ้งกิจกรรม
  void discardWorkout() {
    _timer?.cancel();
    _positionStreamSub?.cancel();
    LocationBackgroundService.instance.stopTracking();
    _lastPosition = null;
    _routePoints.clear();
    returnToCategorySelection();
  }

  String formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

