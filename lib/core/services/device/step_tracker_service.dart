import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/core/services/device/notification_service.dart';
import 'package:healthymate/features/notifications/services/app_notification_service.dart';
import 'package:healthymate/core/services/sync/sync_service.dart';

part 'step_tracker_service_calculation.dart';
part 'step_tracker_service_midnight.dart';
part 'step_tracker_service_sensor.dart';

/// เซอร์วิสหลักจัดการการนับก้าว 24/7 การแจ้งเตือนเกาะติดหน้าจอ และสรุปผลตอนเที่ยงคืน (Step Tracker Service)
class StepTrackerService extends ChangeNotifier {
  static final StepTrackerService instance = StepTrackerService._internal();
  StepTrackerService._internal();

  final Health _health = Health();

  Timer? _timerMidnight;
  Timer? _timerPeriodic;

  int _nTodaySteps = 0;
  double _nTodayDistanceKm = 0.0;
  double _nTodayCalories = 0.0;
  int _nTargetSteps = 8000;
  bool _isTrackingEnabled = true;
  bool _isInitialized = false;

  // ยอดก้าวแยกตามแหล่งข้อมูล (นำค่าที่มากกว่ามาแสดง)
  int _nHealthSteps = 0;
  int _nSensorSteps = 0;
  int _nTick = 0;
  TbUser? _objUserCache;
  StreamSubscription<StepCount>? _subStepCount;
  StreamSubscription<Object?>? _subStepDetect;
  DateTime? _dtLastStepTime;

  int get nTodaySteps => _nTodaySteps;
  double get nTodayDistanceKm => _nTodayDistanceKm;
  double get nTodayCalories => _nTodayCalories;
  int get nTargetSteps => _nTargetSteps;
  bool get isTrackingEnabled => _isTrackingEnabled;
  bool get isInitialized => _isInitialized;

  static const String _kTrackingEnabled = 'notif_step_tracking';
  static const String _kTargetSteps = 'step_target_goal';

  // เริ่มต้นการทำงานของระบบนับก้าว 24/7
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      try {
        await _health.configure();
      } catch (e) {
        debugPrint('Health configure error: $e');
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _isTrackingEnabled = prefs.getBool(_kTrackingEnabled) ?? true;
      _nTargetSteps = prefs.getInt(_kTargetSteps) ?? 8000;

      _isInitialized = true;

      // 1. ตรวจสอบการกู้คืนสรุปผลย้อนหลังตอนเปิดแอป (Lazy Midnight Catch-up)
      unawaited(checkAndProcessMidnightSummary());

      // 2. ตั้งเวลานับถอยหลังสำหรับบันทึกผลเที่ยงคืน
      scheduleMidnightTimer();

      // 3. เริ่มฟังเซ็นเซอร์นับก้าวแบบ Real-time และดึงยอดจาก Health Connect
      if (_isTrackingEnabled) {
        await startSensorStream();
        await refreshTodaySteps();
        _applyStepValues(_nTodaySteps, isForce: true);
      }

      // 4. รีเฟรชหน้าจอ/แจ้งเตือนทุก 5 วินาที (Query Health Connect ทุก 30 วินาทีเพื่อประหยัดแบตเตอรี่)
      _timerPeriodic?.cancel();
      _timerPeriodic = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_isTrackingEnabled) return;
        _nTick++;
        if (_nTick % 6 == 0) {
          refreshTodaySteps();
        } else {
          applyMergedSteps();
        }
      });
    } catch (e) {
      debugPrint('Error initializing StepTrackerService: $e');
    }
  }

  // ปรับสถานะเปิด-ปิด การติดตามก้าวเดิน 24/7
  Future<void> setTrackingEnabled(bool isEnabled) async {
    _isTrackingEnabled = isEnabled;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTrackingEnabled, isEnabled);

    if (isEnabled) {
      final List<HealthDataType> lstTypes = [HealthDataType.STEPS];
      try {
        final bool? hasAuth = await _health.hasPermissions(lstTypes);
        if (hasAuth != true) {
          await _health.requestAuthorization(lstTypes);
        }
      } catch (e) {
        debugPrint('Error requesting health authorization: $e');
      }
      await startSensorStream();
      await refreshTodaySteps();
      _applyStepValues(_nTodaySteps, isForce: true);
    } else {
      await _subStepCount?.cancel();
      _subStepCount = null;
      await _subStepDetect?.cancel();
      _subStepDetect = null;
      await NotificationService.instance.cancelStepTrackerNotification();
    }
    notifyListeners();
  }

  // ปรับเปลี่ยนเป้าหมายก้าวประจำวัน
  Future<void> setTargetSteps(int nTarget) async {
    if (nTarget <= 0) return;
    _nTargetSteps = nTarget;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTargetSteps, nTarget);

    if (_isTrackingEnabled) {
      await NotificationService.instance.updateStepTrackerNotification(
        nSteps: _nTodaySteps,
        nTargetSteps: _nTargetSteps,
        nDistanceKm: _nTodayDistanceKm,
        nCaloriesBurned: _nTodayCalories,
      );
    }
    notifyListeners();
  }

  // ดึงยอดก้าวจาก Health Connect (ไม่เด้งขอสิทธิ์ซ้ำ) แล้วรวมกับยอดจากเซ็นเซอร์
  Future<void> refreshTodaySteps() async {
    try {
      _objUserCache = await AppDatabase.instance.getCurrentUser();
      final DateTime dtNow = DateTime.now();
      final DateTime dtMidnight = DateTime(dtNow.year, dtNow.month, dtNow.day);
      final List<HealthDataType> lstTypes = [HealthDataType.STEPS];

      bool isAuth = false;
      try {
        isAuth = (await _health.hasPermissions(lstTypes)) == true;
      } catch (objErr) {
        debugPrint('Health hasPermissions error: $objErr');
      }

      if (isAuth) {
        int nHealth = 0;
        try {
          final List<HealthDataPoint> lstPoints =
              await _health.getHealthDataFromTypes(
            types: lstTypes,
            startTime: dtMidnight,
            endTime: dtNow,
          );
          if (lstPoints.isNotEmpty) {
            final TbUser? objUser = _objUserCache;
            final List<Map<String, dynamic>> lstTodayWorkouts =
                (objUser != null && objUser.nUserId > 0)
                    ? await AppDatabase.instance.getWorkoutsByDate(
                        userId: objUser.nUserId,
                        date: dtNow,
                      )
                    : [];
            nHealth = filterOverlappingSteps(
              lstPoints: lstPoints,
              lstWorkouts: lstTodayWorkouts,
            );
          }
          if (nHealth <= 0) {
            nHealth = await _health.getTotalStepsInInterval(dtMidnight, dtNow) ?? 0;
          }
        } catch (objErr) {
          debugPrint('Health fetch error: $objErr');
        }
        _nHealthSteps = nHealth;
        if (nHealth > _nTodaySteps) {
          _nSensorSteps = nHealth;
          _applyStepValues(nHealth, isForce: true);
          return;
        }
      }

      await applyMergedSteps(isForce: false);
    } catch (objErr) {
      debugPrint('Error in refreshTodaySteps: $objErr');
    }
  }

  // รวมยอดก้าวและอัปเดต UI/แจ้งเตือนเมื่อค่าเปลี่ยน
  Future<void> applyMergedSteps({bool isForce = false}) async {
    final int nMerged =
        _nHealthSteps > _nSensorSteps ? _nHealthSteps : _nSensorSteps;
    _applyStepValues(nMerged, isForce: isForce);
  }

  // ปรับปรุงค่านับก้าว ระยะทาง แคลอรี และแจ้งเตือนหน้าจอทันที
  void _applyStepValues(int nSteps, {bool isForce = false}) {
    if (!isForce && nSteps == _nTodaySteps && _isInitialized) return;

    _nTodaySteps = nSteps;
    final TbUser? objUser = _objUserCache;
    _nTodayDistanceKm = calculateDistanceKm(
      nSteps,
      objUser?.nHeight ?? 170.0,
      objUser?.sGender ?? 'male',
    );
    _nTodayCalories = calculateCaloriesBurned(nSteps, objUser?.nWeight ?? 65.0);
    notifyListeners();

    if (_isTrackingEnabled) {
      unawaited(NotificationService.instance.updateStepTrackerNotification(
        nSteps: _nTodaySteps,
        nTargetSteps: _nTargetSteps,
        nDistanceKm: _nTodayDistanceKm,
        nCaloriesBurned: _nTodayCalories,
      ));
    }
  }

  // รีเซ็ตค่านับก้าวทั้งหมดเป็น 0 เสมอเมื่อเริ่มวันใหม่
  Future<void> resetForNewDay() async {
    _nHealthSteps = 0;
    _nSensorSteps = 0;
    _applyStepValues(0, isForce: true);

    try {
      final SharedPreferences objPrefs = await SharedPreferences.getInstance();
      final DateTime dtNow = DateTime.now();
      final String sToday =
          '${dtNow.year}-${dtNow.month.toString().padLeft(2, '0')}-${dtNow.day.toString().padLeft(2, '0')}';
      await objPrefs.setString('pedo_base_date', sToday);
      final int? nLastRaw = objPrefs.getInt('pedo_last_raw');
      if (nLastRaw != null) {
        await objPrefs.setInt('pedo_base_count', nLastRaw);
      }
      await objPrefs.setInt('pedo_last_today', 0);
    } catch (objErr) {
      debugPrint('resetForNewDay storage error: $objErr');
    }
  }

  @override
  void dispose() {
    _timerMidnight?.cancel();
    _timerPeriodic?.cancel();
    _subStepCount?.cancel();
    _subStepDetect?.cancel();
    super.dispose();
  }
}
