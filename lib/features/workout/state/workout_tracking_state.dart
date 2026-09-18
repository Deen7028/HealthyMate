import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  StreamSubscription<Position>? _positionStreamSub;
  Position? _lastPosition;
  final List<LatLng> _routePoints = [];
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
  int get userId => _userId;
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);
  bool get isRunning => _status == WorkoutState.running;
  bool get isPaused => _status == WorkoutState.paused;

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _positionStreamSub?.cancel();
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

  void selectCategory(WorkoutCategory category) {
    _selectedCategory = category;
    _status = WorkoutState.initial;
    _secondsElapsed = 0;
    _distanceKm = 0.0;
    _caloriesBurned = 0.0;
    _routePoints.clear();
    _lastPosition = null;
    _safeNotifyListeners();
  }

  void returnToCategorySelection() {
    _timer?.cancel();
    _status = WorkoutState.selectingCategory;
    _secondsElapsed = 0;
    _distanceKm = 0.0;
    _caloriesBurned = 0.0;
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
    _safeNotifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      _safeNotifyListeners();
    });

    // 2. ฟังพิกัด GPS จริง เพื่อคำนวณระยะทางและแคลอรีเฉพาะเมื่อมีการเคลื่อนที่จริงๆ
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _positionStreamSub?.cancel();

    // รับตำแหน่งปัจจุบันเริ่มต้นเป็นจุดอ้างอิง
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
      distanceFilter: 3, // อัปเดตเมื่อขยับเกิน 3 เมตร ป้องกัน GPS drift ตอนยืนนิ่ง
    );

    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (_status != WorkoutState.running) return;

      if (_lastPosition != null) {
        // คำนวณระยะห่างระหว่างพิกัดเดิมกับพิกัดใหม่ (หน่วยเป็นเมตร)
        final distanceInMeters = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // กรองสัญญาณ GPS แกว่ง (GPS Jitter / Noise):
        // ถ้าขยับน้อยกว่า 2.5 เมตร หรือค่าความแม่นยำแย่เกินไป ให้ข้ามไป ไม่นับเป็นระยะทาง
        final accuracy = position.accuracy;
        if (distanceInMeters >= 2.5 && distanceInMeters < 150 && accuracy < 35) {
          final addedKm = distanceInMeters / 1000.0;
          _distanceKm += addedKm;

          // คำนวณแคลอรีจากการเคลื่อนที่จริง:
          // แคลอรีตามระยะทาง: Calorie = ระยะทาง (km) * น้ำหนัก (kg) * ค่าแฟกเตอร์ของแต่ละกิจกรรม
          final calorieFactorPerKm = _selectedCategory.id == 'walking'
              ? 0.75
              : (_selectedCategory.id == 'cycling' ? 0.35 : 1.03); // running
          _caloriesBurned += addedKm * _userWeightKg * calorieFactorPerKm;

          _lastPosition = position;
          _routePoints.add(LatLng(position.latitude, position.longitude));
          _safeNotifyListeners();
        }
      } else {
        _lastPosition = position;
        _routePoints.add(LatLng(position.latitude, position.longitude));
      }
    });
  }

  void pauseWorkout() {
    _timer?.cancel();
    _positionStreamSub?.cancel();
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
    }

    returnToCategorySelection();
    return true;
  }

  /// ละทิ้งกิจกรรม
  void discardWorkout() {
    _timer?.cancel();
    _positionStreamSub?.cancel();
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
