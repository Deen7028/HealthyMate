// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์การติดตามและประวัติการออกกำลังกาย (workout tracking controller)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/device/location_background_service.dart';
import 'package:healthymate/core/services/sync/sync_service.dart';
import 'package:healthymate/core/services/device/tts_service.dart';
import 'package:healthymate/core/utils/route_utils.dart';
import '../models/workout_models.dart';
import '../services/kalman_location_filter.dart';
import '../services/map_matching_service.dart';
import '../services/workout_recovery_service.dart';
import 'package:healthymate/features/notifications/services/app_notification_service.dart';

part 'workout_tracking_controller_lifecycle.dart';
part 'workout_tracking_controller_selection.dart';
part 'workout_tracking_controller_session.dart';
part 'workout_tracking_controller_location.dart';
part 'workout_tracking_controller_persistence.dart';

/// คอนโทรลเลอร์หลักจัดการ State สถิติ กิจกรรม และตำแหน่ง GPS การออกกำลังกายทั้งหมด 
class WorkoutTrackingController extends ChangeNotifier {
  /// สถานะปัจจุบันของการออกกำลังกาย (เลือกหมวดหมู่ / กำลังรัน / หยุดชั่วคราว)
  WorkoutState _status = WorkoutState.selectingCategory;

  /// หมวดหมู่กิจกรรมที่เลือก (เช่น วิ่ง, เดิน, ปั่นจักรยาน, โยคะ)
  WorkoutCategory _selectedCategory = WorkoutCategory.categories.first;

  /// รูปแบบโหมดแผนที่ (Standard, Satellite, Terrain, Hybrid)
  AppMapType _currentMapType = AppMapType.standard;

  /// แสดงชั้นข้อมูลการจราจรบนแผนที่หรือไม่
  bool _showTraffic = false;

  /// สถานะความพร้อมใช้งานของสัญญาณ GPS
  bool _isGpsEnabled = false;

  /// ตัวกรองสัญญาณรบกวน Kalman Filter เพื่อลดอาการพิกัดกระโดด (GPS Drift & Jitter)
  final KalmanLocationFilter _kalmanFilter = KalmanLocationFilter();

  /// สถานะกำลังประมวลผลเซฟกิจกรรม (Map Matching & Compression)
  bool _isProcessingSave = false;

  /// นาฬิกานับเวลาแบบ Real-time
  Timer? _timer;

  /// ตัวฟังการอัปเดตพิกัด GPS ขณะเปิดหน้าจอ
  StreamSubscription<Position>? _positionStreamSub;

  /// ตัวฟังการอัปเดตพิกัด GPS จาก Background Service ขณะปิดหน้าจอ
  StreamSubscription<dynamic>? _bgLocationSub;

  /// ตำแหน่งพิกัดล่าสุดที่ผ่านการกรองแล้ว
  Position? _lastPosition;

  /// รายการพิกัดเส้นทางทั้งหมดสำหรับการวาด Polyline บนแผนที่
  final List<LatLng> _routePoints = [];

  /// เวลาที่ใช้ไปทั้งหมด (วินาที)
  int _secondsElapsed = 0;

  /// ตัวแจ้งเตือนวินาทีเพื่อความลื่นไหลของ UI
  final ValueNotifier<int> secondsElapsedNotifier = ValueNotifier<int>(0);

  /// ระยะทางสะสม (กิโลเมตร)
  double _distanceKm = 0.0;

  /// แคลอรีที่เผาผลาญสะสม (kcal)
  double _caloriesBurned = 0.0;

  /// ตัวนับเวลาถอยหลัง (สำหรับกิจกรรมที่กำหนดเป้าหมายเวลา เช่น ทำสมาธิ)
  int? _targetDurationSeconds;

  /// น้ำหนักตัวผู้ใช้ (กิโลกรัม) สำหรับใช้คำนวณแคลอรีตามค่า METs
  double _userWeightKg = 65.0;

  /// รหัสผู้ใช้ที่เข้าสู่ระบบ
  int _userId = 0;

  /// สถานะป้องกันการแจ้งเตือน UI หาก Controller ถูก dispose ไปแล้ว
  bool _isDisposed = false;

  /// Future สำหรับโหลดข้อมูลผู้ใช้และน้ำหนักตัวจากฐานข้อมูล
  late final Future<void> _userDataLoad;

  /// จำนวนวินาทีที่ความเร็วเป็น 0 ต่อเนื่อง (สำหรับ Auto-Pause)
  int _zeroSpeedSeconds = 0;

  /// สถานะหยุดบันทึกชั่วคราวอัตโนมัติ
  bool _isAutoPaused = false;

  /// กิโลเมตรล่าสุดที่มีการขานเสียงผ่าน TTS
  int _lastAnnouncedKm = 0;

  /// เวลาเริ่มต้นกิจกรรม
  DateTime? _workoutStartTime;

  /// เวลาสะสมก่อนหน้าการกด Resume
  int _accumulatedSeconds = 0;

  /// แจ้งเตือนการเปลี่ยนแปลง State ไปยัง UI อย่างปลอดภัย
  void _safeNotifyListeners() {
    if (!_isDisposed && hasListeners) {
      notifyListeners();
    }
  }

  WorkoutTrackingController() {
    _userDataLoad = this._loadUserData();
    this._listenBackgroundLocation();
  }

  // Getters สำหรับ UI และ Widgets ภายนอก
  WorkoutState get status => _status;
  WorkoutCategory get selectedCategory => _selectedCategory;
  AppMapType get currentMapType => _currentMapType;
  bool get showTraffic => _showTraffic;
  bool get isGpsEnabled => _isGpsEnabled;
  int get secondsElapsed => _secondsElapsed;
  int? get targetDurationSeconds => _targetDurationSeconds;
  bool get isCountdownMode =>
      _targetDurationSeconds != null && _targetDurationSeconds! > 0;

  /// คำนวณวินาทีที่แสดงผล (รองรับทั้งโหมดนับขึ้นและนับถอยหลัง)
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
  bool get isProcessingSave => _isProcessingSave;
  KalmanLocationFilter get kalmanFilter => _kalmanFilter;

  /// ยืนยันว่าโหลดข้อมูลผู้ใช้เสร็จสมบูรณ์
  Future<void> ensureUserDataLoaded() => _userDataLoad;

  /// คืนทรัพยากร Timer, Subscriptions และหยุดบริการ Background Service
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
