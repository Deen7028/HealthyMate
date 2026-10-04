// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (routine state notifier)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/foundation.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';

/// RoutineStateNotifier จัดการ State สำหรับ กิจวัตรประจำวัน (Routines) และ เป้าหมายหลัก (Main Goal)
/// ช่วยให้ DashboardPage และ MyRoutinesPage ซิงค์ข้อมูล Real-time ทันทีโดยไม่ต้องรอ re-load หน้าใหม่
part 'routine_state_notifier_loading.dart';
part 'routine_state_notifier_goal_progress.dart';
part 'routine_state_notifier_routines.dart';
part 'routine_state_notifier_goals.dart';

class RoutineStateNotifier extends ChangeNotifier {
  static final RoutineStateNotifier instance = RoutineStateNotifier._internal();
  RoutineStateNotifier._internal();

  void _notifyStateListeners() => notifyListeners();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _routines = [];
  List<Map<String, dynamic>> get routines => _routines;

  Map<int, bool> _todayCompletionMap = {};
  Map<int, bool> get todayCompletionMap => _todayCompletionMap;

  Map<String, dynamic>? _userGoal;
  Map<String, dynamic>? get userGoal => _userGoal;

  Map<String, Map<String, double>> _todayWorkoutStats = {};
  Map<String, Map<String, double>> get todayWorkoutStats => _todayWorkoutStats;

  int _userId = 0;
  int get userId => _userId;

  String get todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// โหลดข้อมูลใหม่ทั้งหมด และแจ้งเตือน UI ที่ฟังอยู่
}
