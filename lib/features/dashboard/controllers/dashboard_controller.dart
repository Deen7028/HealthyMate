import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/practice/controllers/routine_controller.dart';

part 'dashboard_controller_sync.dart';
part 'dashboard_controller_loading.dart';

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

  String formatNumber(double val) => val >= 1000
      ? NumberFormat('#,##0', 'th').format(val.round())
      : val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1);
  String formatInt(int val) => NumberFormat('#,##0', 'th').format(val);
  String formatNum(double val) =>
      val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(2);

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

  int get weekOfMonth =>
      ((now.day + DateTime(now.year, now.month, 1).weekday - 2) / 7).ceil();
  String get thaiDayName => [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ][now.weekday - 1];
  String get thaiMonthName => [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ][now.month - 1];
}
