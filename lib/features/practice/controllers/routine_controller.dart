import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/device/audio_service.dart';
import 'package:healthymate/core/services/device/notification_service.dart';
import 'package:healthymate/core/services/routine_state/routine_state_notifier.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/practice/models/routine_item.dart';

part 'crud/routine_controller_load.dart';
part 'crud/routine_controller_load_rows.dart';
part 'sync/routine_controller_workout_stats.dart';
part 'sync/routine_controller_workout_sync.dart';
part 'sync/routine_controller_goal_sync.dart';
part 'sync/routine_controller_overall_progress.dart';
part 'sync/routine_controller_sync.dart';
part 'crud/routine_controller_create.dart';
part 'crud/routine_controller_progress.dart';
part 'crud/routine_controller_goals.dart';
part 'crud/routine_controller_mutations.dart';

class RoutineController extends ChangeNotifier {
  bool isLoading = true;
  TbUser? user;
  List<Map<String, dynamic>> routines = [];
  Map<int, bool> todayCompletionMap = {};
  Map<int, double> todayProgressValues = {};
  int completedCount = 0;
  Map<String, dynamic>? userGoal;
  Map<String, Map<String, double>> todayWorkoutStats = {};
  double overallProgressRatio = 0.0;

  void _notifyControllerListeners() => notifyListeners();

  static String normalizeCategoryType(String rawType) {
    if (rawType.isEmpty) return 'อื่นๆ';
    final lower = rawType.toLowerCase();
    if (rawType.contains('วิ่ง') || lower.contains('running')) {
      if (rawType.contains('ลู่วิ่ง') || lower.contains('treadmill')) {
        return 'ลู่วิ่งในร่ม';
      }
      return 'วิ่ง';
    }
    if (rawType.contains('เดิน') || lower.contains('walking')) return 'เดิน';
    if (rawType.contains('จักรยาน') ||
        rawType.contains('ปั่น') ||
        lower.contains('cycling')) {
      return 'ปั่นจักรยาน';
    }
    if (rawType.contains('สมาธิ') || lower.contains('meditation')) {
      return 'ทำสมาธิ';
    }
    if (rawType.contains('โยคะ') || lower.contains('yoga')) return 'โยคะ';
    if (rawType.contains(' (')) {
      return rawType.split(' (').first.trim();
    }
    return rawType.trim();
  }

  String get todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
