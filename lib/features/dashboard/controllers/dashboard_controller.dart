import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';

class DashboardController extends ChangeNotifier {
  bool isLoading = true;
  TbUser? user;
  TbHealthRecord? latestRecord;
  int workoutCount = 0;
  double totalDistanceKm = 0.0;
  double totalCaloriesBurned = 0.0;
  int totalWorkoutDurationSec = 0;
  int todayNutritionCalories = 0;
  Map<String, dynamic>? userGoal;
  List<Map<String, dynamic>> routines = [];
  Map<int, bool> todayCompletionMap = {};
  Map<String, Map<String, double>> todayWorkoutStats = {};
  final DateTime now = DateTime.now();

  Future<void> loadDashboardData() async {
    isLoading = true;
    notifyListeners();
    try {
      final db = AppDatabase.instance;
      final email = await db.getLoggedInUserEmail();
      if (email != null && email.isNotEmpty) user = await db.getUserByEmail(email);
      user ??= await db.getUser(userId: 1);

      if (user == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final userId = user!.nUserId;
      final records = await db.getHealthRecords(userId: userId);
      latestRecord = records.isNotEmpty ? records.first : null;

      final workouts = await db.getWorkouts(userId: userId);
      workoutCount = workouts.length;
      totalDistanceKm = 0.0;
      totalCaloriesBurned = 0.0;
      totalWorkoutDurationSec = 0;
      for (final w in workouts) {
        totalDistanceKm += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
        totalCaloriesBurned += (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
        totalWorkoutDurationSec += (w['nDuration'] as num?)?.toInt() ?? 0;
      }

      final nutritionToday = await db.getNutritionLogsToday(userId);
      todayNutritionCalories = 0;
      for (final n in nutritionToday) {
        todayNutritionCalories += (n['nCalories'] as num?)?.toInt() ?? 0;
      }

      routines = await db.getRoutines(userId: userId);
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      todayCompletionMap.clear();
      for (final r in routines) {
        final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        final log = await db.getRoutineLogForDate(routineId: rId, dateStr: todayStr);
        todayCompletionMap[rId] = (log?['isCompleted'] as num?)?.toInt() == 1;
      }

      todayWorkoutStats.clear();
      for (final w in workouts) {
        final workoutDate = w['dtWorkoutDate']?.toString() ?? '';
        if (workoutDate.startsWith(todayStr)) {
          final type = w['sType']?.toString() ?? 'อื่นๆ';
          final dist = (w['nDistance'] as num?)?.toDouble() ?? 0.0;
          final duration = (w['nDuration'] as num?)?.toDouble() ?? 0.0;
          todayWorkoutStats.putIfAbsent(type, () => {'distance': 0.0, 'duration': 0.0});
          todayWorkoutStats[type]!['distance'] = (todayWorkoutStats[type]!['distance'] ?? 0) + dist;
          todayWorkoutStats[type]!['duration'] = (todayWorkoutStats[type]!['duration'] ?? 0) + duration;
        }
      }

      userGoal = await db.getUserGoal(userId);
      isLoading = false;
      notifyListeners();
      _syncFromServer(userId);
    } catch (e) {
      debugPrint('loadDashboardData error: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncFromServer(int userId) async {
    try {
      final serverData = await HealthApiService.fetchDashboardData(userId: userId);
      if (serverData != null && serverData['status'] == 'success') {
        final wsMap = serverData['data']['workoutStats'] as Map<String, dynamic>?;
        workoutCount = (wsMap?['totalCount'] as num?)?.toInt() ?? 0;
        totalDistanceKm = (wsMap?['totalDistance'] as num?)?.toDouble() ?? 0.0;
        totalCaloriesBurned = (wsMap?['totalCalories'] as num?)?.toDouble() ?? 0.0;
        totalWorkoutDurationSec = (wsMap?['totalDuration'] as num?)?.toInt() ?? 0;

        final ntMap = serverData['nutritionToday'] as Map<String, dynamic>?;
        todayNutritionCalories = (ntMap?['totalCalories'] as num?)?.toInt() ?? 0;

        userGoal = serverData['data']['goal'] as Map<String, dynamic>?;

        final hrMap = serverData['data']['latestHealthRecord'] as Map<String, dynamic>?;
        if (hrMap != null) latestRecord = TbHealthRecord.fromMap(hrMap);

        final userMap = serverData['data']['user'] as Map<String, dynamic>?;
        if (userMap != null) user = TbUser.fromMap(userMap);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  String formatNumber(double val) => val >= 1000 ? NumberFormat('#,##0', 'th').format(val.round()) : val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1);
  String formatInt(int val) => NumberFormat('#,##0', 'th').format(val);
  String formatNum(double val) => val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(1);
  
  String getGreeting() {
    final hour = now.hour;
    if (hour < 12) return 'อรุณสวัสดิ์';
    if (hour < 17) return 'สวัสดีตอนบ่าย';
    return 'สวัสดีตอนเย็น';
  }

  String getGreetingEmoji() {
    final hour = now.hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  int get weekOfMonth => ((now.day + DateTime(now.year, now.month, 1).weekday - 2) / 7).ceil();
  String get thaiDayName => ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'][now.weekday - 1];
  String get thaiMonthName => ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'][now.month - 1];
}