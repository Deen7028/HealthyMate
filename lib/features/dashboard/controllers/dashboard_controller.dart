import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/practice/controllers/routine_controller.dart';

class DashboardController extends ChangeNotifier {
  bool isLoading = true;
  TbUser? user;
  TbHealthRecord? latestRecord;
  List<TbHealthRecord> healthRecords = [];
  int workoutCount = 0;
  double totalDistanceKm = 0.0;
  double totalRunningDistanceKm = 0.0;
  double totalCyclingDistanceKm = 0.0;
  double totalCaloriesBurned = 0.0;
  int totalWorkoutDurationSec = 0;
  int todayNutritionCalories = 0;
  int todayScannedFoodCount = 0;
  List<Map<String, dynamic>> todayNutritionLogs = [];
  Map<String, dynamic>? userGoal;
  List<Map<String, dynamic>> routines = [];
  Map<int, bool> todayCompletionMap = {};
  Map<int, double> todayProgressValues = {};
  Map<String, Map<String, double>> todayWorkoutStats = {};

  final DateTime now = DateTime.now();

  Future<void> loadDashboardData({bool silent = false}) async {
    final shouldShowLoading = !silent && user == null;
    if (shouldShowLoading) {
      isLoading = true;
      notifyListeners();
    }
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
      healthRecords = records;
      latestRecord = records.isNotEmpty ? records.first : null;

      final workouts = await db.getWorkouts(userId: userId);
      workoutCount = workouts.length;
      totalDistanceKm = 0.0;
      totalRunningDistanceKm = 0.0;
      totalCyclingDistanceKm = 0.0;
      totalCaloriesBurned = 0.0;
      totalWorkoutDurationSec = 0;
      for (final w in workouts) {
        final dist = (w['nDistance'] as num?)?.toDouble() ?? 0.0;
        final cals = (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
        final dur = (w['nDuration'] as num?)?.toInt() ?? 0;
        final type = (w['sType']?.toString() ?? '').toLowerCase();

        totalDistanceKm += dist;
        totalCaloriesBurned += cals;
        totalWorkoutDurationSec += dur;

        if (type.contains('วิ่ง') || type.contains('running')) {
          totalRunningDistanceKm += dist;
        } else if (type.contains('ปั่น') || type.contains('จักรยาน') || type.contains('cycling')) {
          totalCyclingDistanceKm += dist;
        }
      }

      // ดึงข้อมูลแคลอรี่จากบันทึกอาหารด้วย AI Food Scanner ในวันนี้ (อิงเวลาปัจจุบันสดใหม่เสมอ)
      final currentNow = DateTime.now();
      final dbInstance = await db.database;
      final todayStr = DateFormat('yyyy-MM-dd').format(currentNow);
      List<Map<String, dynamic>> nutritionToday = [];

      if (dbInstance != null) {
        // ค้นหาจาก TbNutritionLogs ที่บันทึกผ่าน AI Food Scanner
        // ตรวจสอบทั้ง userId ปัจจุบัน และ default userId (1) เพื่อป้องกันกรณี user ID ไม่ตรงกัน
        nutritionToday = await dbInstance.query(
          AppDatabase.tableNutritionLogs,
          where: '(nUserId = ? OR nUserId = 1) AND dtLoggedAt LIKE ?',
          whereArgs: [userId, '$todayStr%'],
          orderBy: 'nNutritionId DESC',
        );

        // หากยังไม่พบ ให้ดึงจากบันทึกอาหารทั้งหมดในวันนี้บนอุปกรณ์
        if (nutritionToday.isEmpty) {
          nutritionToday = await dbInstance.query(
            AppDatabase.tableNutritionLogs,
            where: 'dtLoggedAt LIKE ?',
            whereArgs: ['$todayStr%'],
            orderBy: 'nNutritionId DESC',
          );
        }
      } else {
        nutritionToday = await db.getNutritionLogsToday(userId);
      }

      todayNutritionLogs = List<Map<String, dynamic>>.from(nutritionToday);
      todayScannedFoodCount = todayNutritionLogs.length;
      todayNutritionCalories = 0;
      for (final n in todayNutritionLogs) {
        todayNutritionCalories += (n['nCalories'] as num?)?.toInt() ?? 0;
      }

      routines = await db.getRoutines(userId: userId);
      todayCompletionMap.clear();
      todayProgressValues.clear();
      for (final r in routines) {
        final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        final targetVal = (r['targetValue'] as num?)?.toDouble() ?? 1.0;
        final log = await db.getRoutineLogForDate(routineId: rId, dateStr: todayStr);
        final isDone = (log?['isCompleted'] as num?)?.toInt() == 1;
        final progressVal = (log?['nProgressValue'] as num?)?.toDouble();
        
        todayCompletionMap[rId] = isDone;
        todayProgressValues[rId] = progressVal ?? (isDone ? targetVal : 0.0);
      }


      todayWorkoutStats.clear();
      for (final w in workouts) {
        final workoutDate = w['dtWorkoutDate']?.toString() ?? '';
        if (workoutDate.startsWith(todayStr)) {
          final type = w['sType']?.toString() ?? 'อื่นๆ';
          final dist = (w['nDistance'] as num?)?.toDouble() ?? 0.0;
          final durationSec = (w['nDuration'] as num?)?.toDouble() ?? 0.0;
          final durationMin = durationSec > 0 ? (durationSec / 60.0) : 0.0;
          final calories = (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;

          final normType = RoutineController.normalizeCategoryType(type);
          final keysToUpdate = {type, normType};

          for (final k in keysToUpdate) {
            todayWorkoutStats.putIfAbsent(
                k, () => {'distance': 0.0, 'duration': 0.0, 'caloriesBurned': 0.0});
            todayWorkoutStats[k]!['distance'] =
                (todayWorkoutStats[k]!['distance'] ?? 0) + dist;
            todayWorkoutStats[k]!['duration'] =
                (todayWorkoutStats[k]!['duration'] ?? 0) + durationMin;
            todayWorkoutStats[k]!['caloriesBurned'] =
                (todayWorkoutStats[k]!['caloriesBurned'] ?? 0) + calories;
          }
        }
      }

      userGoal = await db.getUserGoal(userId);
      if (isLoading) {
        isLoading = false;
      }
      notifyListeners();
      _syncFromServer(userId);
    } catch (e) {
      debugPrint('loadDashboardData error: $e');
      if (isLoading) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> _syncFromServer(int userId) async {
    try {
      final serverData = await HealthApiService.fetchDashboardData(userId: userId);
      if (serverData != null) {
        final dataMap = serverData['data'] is Map<String, dynamic>
            ? serverData['data'] as Map<String, dynamic>
            : serverData;

        final wsMap = dataMap['workoutStats'] as Map<String, dynamic>?;
        if (wsMap != null) {
          workoutCount = (wsMap['totalCount'] as num?)?.toInt() ?? workoutCount;
          totalDistanceKm = (wsMap['totalDistance'] as num?)?.toDouble() ?? totalDistanceKm;
          totalCaloriesBurned = (wsMap['totalCalories'] as num?)?.toDouble() ?? totalCaloriesBurned;
          totalWorkoutDurationSec = (wsMap['totalDuration'] as num?)?.toInt() ?? totalWorkoutDurationSec;
        }

        final ntMap = dataMap['nutritionToday'] as Map<String, dynamic>?;
        final serverCalories = (ntMap?['totalCalories'] as num?)?.toInt() ?? 0;
        // อัปเดตแคลอรี่จาก server เฉพาะเมื่อ server มีค่ามากกว่า (ป้องกันการเขียนทับข้อมูลจาก AI Food Scanner ในเครื่อง)
        if (serverCalories > todayNutritionCalories) {
          todayNutritionCalories = serverCalories;
        }

        final goalMap = dataMap['goal'] as Map<String, dynamic>?;
        if (goalMap != null) userGoal = goalMap;

        final hrMap = dataMap['latestHealthRecord'] as Map<String, dynamic>?;
        if (hrMap != null) latestRecord = TbHealthRecord.fromMap(hrMap);

        final userMap = dataMap['user'] as Map<String, dynamic>?;
        if (userMap != null) user = TbUser.fromMap(userMap);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  String formatNumber(double val) => val >= 1000 ? NumberFormat('#,##0', 'th').format(val.round()) : val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1);
  String formatInt(int val) => NumberFormat('#,##0', 'th').format(val);
  String formatNum(double val) => val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(2);
  
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