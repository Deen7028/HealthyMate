import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/sync_service.dart';

/// Controller สำหรับจัดการ State และ Business Logic ของหน้าประวัติการออกกำลังกาย (WorkoutHistoryPage)
class WorkoutHistoryController extends ChangeNotifier {
  bool isLoading = true;
  bool isPulling = false;
  List<Map<String, dynamic>> workouts = [];
  int _userId = 1;
  bool _isDisposed = false;

  int get userId => _userId;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed && hasListeners) {
      notifyListeners();
    }
  }

  /// เริ่มต้นโหลดข้อมูลสำหรับ userId ที่ระบุ
  Future<void> init(int userId) async {
    _userId = userId;
    await loadWorkoutHistory();

    // ตรวจสอบว่า Local DB ว่างเปล่าหรือไม่ หากว่างให้สั่งดึงจากเซิร์ฟเวอร์แบบ Initial Pull Sync
    try {
      final count = await AppDatabase.instance.getWorkoutCount(userId: _userId);
      if (count == 0) {
        debugPrint('WorkoutHistoryController: Local DB is empty (COUNT == 0). Triggering Initial Pull Sync...');
        await pullDownstreamData(isInitial: true);
      }
    } catch (e) {
      debugPrint('WorkoutHistoryController: Error checking workout count: $e');
    }
  }

  /// โหลดประวัติการออกกำลังกายจาก Local SQLite Database
  Future<void> loadWorkoutHistory() async {
    isLoading = true;
    _safeNotifyListeners();

    try {
      workouts = await AppDatabase.instance.getWorkouts(userId: _userId);
    } catch (e) {
      debugPrint('WorkoutHistoryController: Error loading workouts: $e');
    } finally {
      isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// ดึงข้อมูลประวัติจาก Remote PHP Server ลงมายังเครื่อง (Pull Downstream Sync)
  /// คืนค่าจำนวนรายการที่ดึงลงมาเพิ่มได้
  Future<int> pullDownstreamData({bool isInitial = false}) async {
    isPulling = true;
    _safeNotifyListeners();

    try {
      final pulledCount = await SyncService.instance.pullDownstreamWorkouts(
        _userId,
        forceInitial: isInitial,
      );

      // โหลดข้อมูลล่าสุดจาก SQLite หลังอัปเดตลงเครื่อง
      workouts = await AppDatabase.instance.getWorkouts(userId: _userId);
      return pulledCount;
    } catch (e) {
      debugPrint('WorkoutHistoryController: Error pulling downstream workouts: $e');
      return 0;
    } finally {
      isLoading = false;
      isPulling = false;
      _safeNotifyListeners();
    }
  }
}
