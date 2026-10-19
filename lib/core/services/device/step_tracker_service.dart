import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/core/services/device/notification_service.dart';
import 'package:healthymate/features/notifications/services/app_notification_service.dart';
import 'package:healthymate/core/services/sync/sync_service.dart';

part 'step_tracker_service_calculation.dart';
part 'step_tracker_service_midnight.dart';

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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _isTrackingEnabled = prefs.getBool(_kTrackingEnabled) ?? false;
      _nTargetSteps = prefs.getInt(_kTargetSteps) ?? 8000;

      _isInitialized = true;

      // 1. ตรวจสอบการกู้คืนสรุปผลย้อนหลังตอนเปิดแอป (Lazy Midnight Catch-up)
      unawaited(checkAndProcessMidnightSummary());

      // 2. ตั้งเวลานับถอยหลังสำหรับบันทึกผลเที่ยงคืน
      scheduleMidnightTimer();

      // 3. ดึงยอดก้าวสดๆ วันนี้ (เฉพาะกรณีที่เปิดใช้งานและได้รับสิทธิ์แล้ว ไม่เด้ง Dialog บล็อกหน้าจอ)
      if (_isTrackingEnabled) {
        await refreshTodaySteps();
      }

      // 4. ตั้งเวลารีเฟรชอัตโนมัติทุก 15 นาที
      _timerPeriodic?.cancel();
      _timerPeriodic = Timer.periodic(const Duration(minutes: 15), (_) {
        refreshTodaySteps();
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
      await refreshTodaySteps();
    } else {
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

  // ดึงข้อมูลจำนวนก้าวของวันนี้ พร้อมหักลบกิจกรรมทับซ้อนและอัปเดต Notification
  Future<void> refreshTodaySteps() async {
    try {
      final TbUser? objUser = await AppDatabase.instance.getCurrentUser();
      final DateTime dtNow = DateTime.now();
      final DateTime dtMidnight = DateTime(dtNow.year, dtNow.month, dtNow.day, 0, 0, 0);

      final List<HealthDataType> lstTypes = [HealthDataType.STEPS];
      
      bool isAuth = false;
      try {
        final bool? hasAuth = await _health.hasPermissions(lstTypes);
        isAuth = hasAuth == true;
      } catch (e) {
        debugPrint('Health hasPermissions check error: $e');
      }

      int nCalculatedSteps = 0;

      if (isAuth) {
        try {
          final List<HealthDataPoint> lstPoints = await _health.getHealthDataFromTypes(
            types: lstTypes,
            startTime: dtMidnight,
            endTime: dtNow,
          );

          List<Map<String, dynamic>> lstTodayWorkouts = [];
          if (objUser != null && objUser.nUserId > 0) {
            lstTodayWorkouts = await AppDatabase.instance.getWorkoutsByDate(
              userId: objUser.nUserId,
              date: dtNow,
            );
          }

          nCalculatedSteps = filterOverlappingSteps(
            lstPoints: lstPoints,
            lstWorkouts: lstTodayWorkouts,
          );
        } catch (e) {
          debugPrint('Health fetch error: $e');
        }
      }

      _nTodaySteps = nCalculatedSteps;
      final double nUserHeight = objUser?.nHeight ?? 170.0;
      final String sUserGender = objUser?.sGender ?? 'male';
      final double nUserWeight = objUser?.nWeight ?? 65.0;

      _nTodayDistanceKm = calculateDistanceKm(_nTodaySteps, nUserHeight, sUserGender);
      _nTodayCalories = calculateCaloriesBurned(_nTodaySteps, nUserWeight);

      notifyListeners();

      // อัปเดตแถบแจ้งเตือน Ongoing Foreground Notification หากเปิดใช้งาน
      if (_isTrackingEnabled) {
        await NotificationService.instance.updateStepTrackerNotification(
          nSteps: _nTodaySteps,
          nTargetSteps: _nTargetSteps,
          nDistanceKm: _nTodayDistanceKm,
          nCaloriesBurned: _nTodayCalories,
        );
      }
    } catch (e) {
      debugPrint('Error in refreshTodaySteps: $e');
    }
  }

  @override
  void dispose() {
    _timerMidnight?.cancel();
    _timerPeriodic?.cancel();
    super.dispose();
  }
}
