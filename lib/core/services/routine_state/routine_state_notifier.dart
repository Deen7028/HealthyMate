import 'package:flutter/foundation.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';

// ตัวจัดการ State ส่วนกลางสำหรับกิจวัตรประจำวัน (Routines) และเป้าหมายหลัก (Main Goal)
// ซิงค์ข้อมูล Real-time ข้ามหน้าระหว่าง DashboardPage และ MyRoutinesPage ทันที
part 'routine_state_notifier_loading.dart';
part 'routine_state_notifier_goal_progress.dart';
part 'routine_state_notifier_routines.dart';
part 'routine_state_notifier_goals.dart';

class RoutineStateNotifier extends ChangeNotifier {
  static final RoutineStateNotifier instance = RoutineStateNotifier._internal();
  RoutineStateNotifier._internal();

  void _notifyStateListeners() => notifyListeners();

  // สถานะการโหลดข้อมูล
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // รายการกิจวัตรทั้งหมดของผู้ใช้
  List<Map<String, dynamic>> _routines = [];
  List<Map<String, dynamic>> get routines => _routines;

  // สถานะการทำสำเร็จของแต่ละกิจวัตรในวันนี้ (Map: RoutineId -> isCompleted)
  Map<int, bool> _todayCompletionMap = {};
  Map<int, bool> get todayCompletionMap => _todayCompletionMap;

  // ข้อมูลเป้าหมายหลักของวัน (Main Goal)
  Map<String, dynamic>? _userGoal;
  Map<String, dynamic>? get userGoal => _userGoal;

  // สถิติการออกกำลังกายที่เกิดขึ้นในวันนี้ (ระยะทาง, เวลา, แคลอรี แยกตามประเภท)
  Map<String, Map<String, double>> _todayWorkoutStats = {};
  Map<String, Map<String, double>> get todayWorkoutStats => _todayWorkoutStats;

  // ID ของผู้ใช้ปัจจุบัน
  int _userId = 0;
  int get userId => _userId;

  // วันที่ปัจจุบันในรูปแบบ YYYY-MM-DD
  String get todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
