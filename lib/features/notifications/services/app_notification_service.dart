import 'package:flutter/foundation.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// บริการกลางสำหรับสร้างการแจ้งเตือนในแอป (In-App Notification Events)
class AppNotificationService {
  static final AppNotificationService instance = AppNotificationService._internal();
  AppNotificationService._internal();

  int _currentUserId = 0;

  void setUserId(int userId) => _currentUserId = userId;
  int get currentUserId => _currentUserId;

  Future<void> onWorkoutSaved({
    required String workoutType,
    required double distanceKm,
    required double caloriesBurned,
    required int durationSeconds,
  }) async {
    if (_currentUserId <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('notif_workout') ?? true;
      if (!isEnabled) return;

      final durationMin = durationSeconds ~/ 60;
      final durationText = durationSeconds >= 3600
          ? '${durationSeconds ~/ 3600} ชม. ${(durationSeconds % 3600) ~/ 60} นาที'
          : '$durationMin นาที';
      final distText = distanceKm > 0
          ? ' ระยะทาง ${distanceKm.toStringAsFixed(2)} กม.'
          : '';
      await AppDatabase.instance.insertNotification(
        userId: _currentUserId,
        type: 'workout',
        title: 'บันทึกกิจกรรมสำเร็จ — $workoutType',
        message: 'ยอดเยี่ยม! ใช้เวลา $durationText$distText เผาผลาญ ${caloriesBurned.toStringAsFixed(0)} kcal',
        actionType: 'navigate_workout',
      );
    } catch (e) {
      debugPrint('[AppNotificationService] onWorkoutSaved error: $e');
    }
  }

  Future<void> onBadgeUnlocked({required String badgeName}) async {
    if (_currentUserId <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('notif_badge') ?? true;
      if (!isEnabled) return;

      await AppDatabase.instance.insertNotification(
        userId: _currentUserId,
        type: 'badge',
        title: 'ปลดล็อกเหรียญรางวัลใหม่!',
        message: 'คุณได้รับเหรียญ "$badgeName" แล้ว แตะเพื่อดูความสำเร็จทั้งหมด',
        actionType: 'navigate_profile',
        actionPayload: badgeName,
      );
    } catch (e) {
      debugPrint('[AppNotificationService] onBadgeUnlocked error: $e');
    }
  }

  Future<void> onFoodLogged({
    required String foodName,
    required int calories,
    required int totalTodayCalories,
  }) async {
    if (_currentUserId <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('notif_meal') ?? true;
      if (!isEnabled) return;

      await AppDatabase.instance.insertNotification(
        userId: _currentUserId,
        type: 'nutrition',
        title: 'บันทึกอาหารสำเร็จ',
        message: '"$foodName" ($calories kcal) · รวมวันนี้ $totalTodayCalories kcal',
        actionType: 'navigate_food_log',
      );
    } catch (e) {
      debugPrint('[AppNotificationService] onFoodLogged error: $e');
    }
  }

  Future<void> onHealthRecordSaved({
    required double weightKg,
    required double bmi,
    required String bmiCategory,
  }) async {
    if (_currentUserId <= 0) return;
    try {
      await AppDatabase.instance.insertNotification(
        userId: _currentUserId,
        type: 'health',
        title: 'บันทึกข้อมูลสุขภาพใหม่',
        message: 'น้ำหนัก ${weightKg.toStringAsFixed(1)} กก. · BMI ${bmi.toStringAsFixed(1)} ($bmiCategory)',
        actionType: 'navigate_calculator',
      );
    } catch (e) {
      debugPrint('[AppNotificationService] onHealthRecordSaved error: $e');
    }
  }

  Future<void> onRoutineCompleted({required String routineName}) async {
    if (_currentUserId <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('notif_routine') ?? true;
      if (!isEnabled) return;

      await AppDatabase.instance.insertNotification(
        userId: _currentUserId,
        type: 'routine',
        title: 'ทำกิจวัตรสำเร็จ!',
        message: '"$routineName" ทำสำเร็จแล้ว เยี่ยมมาก! ทำต่อเนื่องทุกวันเพื่อสร้างนิสัยที่ดี',
        actionType: 'navigate_practice',
      );
    } catch (e) {
      debugPrint('[AppNotificationService] onRoutineCompleted error: $e');
    }
  }

  Future<void> onDailyCalorieGoalReached({required int calories}) async {
    if (_currentUserId <= 0) return;
    try {
      await AppDatabase.instance.insertNotification(
        userId: _currentUserId,
        type: 'workout',
        title: 'เผาผลาญถึงเป้าหมายวันนี้แล้ว!',
        message: 'คุณเผาผลาญไปแล้ว $calories kcal วันนี้ ยอดเยี่ยมมาก! พักผ่อนให้เพียงพอด้วยนะ',
        actionType: 'navigate_workout',
      );
    } catch (e) {
      debugPrint('[AppNotificationService] onDailyCalorieGoalReached error: $e');
    }
  }
}
