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

  double _userWeightKg = 65.0;
  int _userId = 1;
  bool _isDisposed = false;

  // Auto-pause & TTS variables
  int _zeroSpeedSeconds = 0;
  bool _isAutoPaused = false;
  int _lastAnnouncedKm = 0;

  WorkoutTrackingController() {
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
  LatLng? get currentLatLng =>
      _lastPosition != null ? LatLng(_lastPosition!.latitude, _lastPosition!.longitude) : null;
  bool get isRunning => _status == WorkoutState.running;
  bool get isPaused => _status == WorkoutState.paused;
  bool get isAutoPaused => _isAutoPaused;

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

      DateTime? bgTimestamp;
      if (event['timestamp'] != null) {
        bgTimestamp = DateTime.tryParse(event['timestamp'].toString());
      }

      if (lat != null && lng != null) {
        _handleNewLocation(
          latitude: lat,
          longitude: lng,
          speedMs: speed,
          accuracy: accuracy,
          timestamp: bgTimestamp,
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
    secondsElapsedNotifier.value = 0;
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
    secondsElapsedNotifier.value = 0;
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
        secondsElapsedNotifier.value = _secondsElapsed;

        // คำนวณแคลอรีตามสูตรมาตรฐานการกีฬาตามความเร็วไดนามิก (METs * 0.0175 * WeightKg * TimeMinutes)
        final activeMet = _calculateCurrentMet();
        final caloriesPerSecond = (activeMet * 0.0175 * _userWeightKg) / 60.0;
        _caloriesBurned += caloriesPerSecond;

        _checkAutoPauseCondition();
      }
    });

    LocationBackgroundService.instance.startTracking();
    _startLocationUpdates();
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
      _safeNotifyListeners();
    }
  }

  void _startLocationUpdates() {
    _positionStreamSub?.cancel();

    // ดึงพิกัดตั้งต้นเฉพาะเมื่อยังไม่มี _lastPosition เพื่อป้องกัน Race Condition จาก async callback ย้อนหลัง
    Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).then((pos) {
      if (_lastPosition == null && _status == WorkoutState.running) {
        _lastPosition = pos;
        if (_routePoints.isEmpty) {
          _routePoints.add(LatLng(pos.latitude, pos.longitude));
          _safeNotifyListeners();
        }
      }
    }).catchError((_) {});

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
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
        timestamp: position.timestamp,
      );
    });
  }

  void _handleNewLocation({
    required double latitude,
    required double longitude,
    required double speedMs,
    required double accuracy,
    DateTime? timestamp,
  }) {
    // 0. หากเป็นกิจกรรมที่ไม่เกี่ยวกับการเคลื่อนที่ (ทำสมาธิ/โยคะ) ไม่ต้องบันทึกระยะทางและเส้นทาง GPS
    if (!_selectedCategory.isMoving) {
      return;
    }

    final newTime = timestamp ?? DateTime.now();

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
      // ป้องกันพิกัดที่ย้อนหลังหรือมาสลับลำดับเวลา (Chronological Check)
      final timeDifferenceSec = newTime.difference(_lastPosition!.timestamp).inMilliseconds / 1000.0;
      if (timeDifferenceSec <= 0.3) {
        return;
      }

      final distanceInMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        latitude,
        longitude,
      );

      // คำนวณความเร็วเฉลี่ยระหว่างจุดจริง (Calculated Speed = distance / time)
      final calculatedSpeedMs = timeDifferenceSec > 0 ? (distanceInMeters / timeDifferenceSec) : 0.0;

      // กรอง GPS Drift เข้มงวดระดับแอปออกกำลังกายมาตรฐาน:
      // 1. ความแม่นยำสัญญาณ GPS (accuracy) ต้องดีกว่า 15 เมตร
      // 2. ระยะทางขยับขั้นต่ำต้อง >= 5.0 เมตร (สอดคล้องกับ distanceFilter)
      // 3. ความเร็วที่คำนวณได้จริงต้องไม่เกิน 15.0 m/s (~54 km/h) สำหรับกีฬาเดิน/วิ่ง/จักรยาน
      // 4. หากมีค่า speed จากฮาร์ดแวร์ ต้องสอดคล้อง ไม่ก้าวกระโดดผิดธรรมชาติ
      final bool isAccuracyValid = accuracy <= 15.0;
      final bool isDistanceValid = distanceInMeters >= 5.0 && distanceInMeters < 120.0;
      final bool isSpeedValid = calculatedSpeedMs < 15.0 && speedMs < 20.0;
      
      // ตรวจสอบว่าพิกัดขยับพ้นจากวงรัศมีคลาดเคลื่อน GPS (Displacement Threshold)
      final bool isClearDisplacement = distanceInMeters >= (accuracy * 0.8);

      final bool isRealMovement = isAccuracyValid &&
          isDistanceValid &&
          isSpeedValid &&
          isClearDisplacement;

      if (isRealMovement) {
        final addedKm = distanceInMeters / 1000.0;
        _distanceKm += addedKm;

        // หากยังไม่มีจุดในเส้นทาง ให้เพิ่มจุดเริ่มต้นก่อน
        if (_routePoints.isEmpty) {
          _routePoints.add(LatLng(_lastPosition!.latitude, _lastPosition!.longitude));
        }

        _lastPosition = Position(
          longitude: longitude,
          latitude: latitude,
          timestamp: newTime,
          accuracy: accuracy,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: speedMs,
          speedAccuracy: 0.0,
        );

        _routePoints.add(LatLng(latitude, longitude));
        _safeNotifyListeners();

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
      }
    } else {
      _lastPosition = Position(
        longitude: longitude,
        latitude: latitude,
        timestamp: newTime,
        accuracy: accuracy,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: speedMs,
        speedAccuracy: 0.0,
      );
      _routePoints.add(LatLng(latitude, longitude));
      _safeNotifyListeners();
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

