// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์การติดตามและประวัติการออกกำลังกาย (workout history controller)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/features/workout/models/workout_models.dart';

/// Controller สำหรับจัดการ State และ Business Logic ของหน้าประวัติการออกกำลังกาย (WorkoutHistoryPage)
class WorkoutHistoryController extends ChangeNotifier {
  bool isLoading = true;
  bool isPulling = false;
  List<Map<String, dynamic>> workouts = [];
  int _userId = 0;
  bool _isDisposed = false;

  String _selectedCategoryFilter = 'all';
  String _searchQuery = '';

  int get userId => _userId;
  String get selectedCategoryFilter => _selectedCategoryFilter;
  String get searchQuery => _searchQuery;

  void setSelectedCategoryFilter(String categoryId) {
    if (_selectedCategoryFilter != categoryId) {
      _selectedCategoryFilter = categoryId;
      _safeNotifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    _safeNotifyListeners();
  }

  /// รายการออกกำลังกายที่ผ่านการกรองตามหมวดหมู่และการค้นหา
  List<Map<String, dynamic>> get filteredWorkouts {
    return workouts.where((w) {
      final type = w['sType']?.toString() ?? '';
      
      // กรองตามหมวดหมู่
      if (_selectedCategoryFilter != 'all') {
        final category = WorkoutCategory.fromIdOrTitle(type);
        if (category.id != _selectedCategoryFilter) {
          return false;
        }
      }

      // กรองตามคำค้นหา
      if (_searchQuery.isNotEmpty) {
        final lowerType = type.toLowerCase();
        if (!lowerType.contains(_searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// จำนวนรายการออกกำลังกายทั้งหมด (ตามฟิลเตอร์ปัจจุบัน)
  int get totalCount => filteredWorkouts.length;

  /// ระยะทางรวมทั้งหมด (กม.) ตามฟิลเตอร์ปัจจุบัน
  double get totalDistanceKm {
    return filteredWorkouts.fold<double>(
      0.0,
      (sum, item) => sum + ((item['nDistance'] as num?)?.toDouble() ?? 0.0),
    );
  }

  /// แคลอรีที่เผาผลาญรวมทั้งหมด (kcal) ตามฟิลเตอร์ปัจจุบัน
  double get totalCaloriesBurned {
    return filteredWorkouts.fold<double>(
      0.0,
      (sum, item) =>
          sum + ((item['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0),
    );
  }

  /// ระยะเวลารวมทั้งหมด (วินาที) ตามฟิลเตอร์ปัจจุบัน
  int get totalDurationSeconds {
    return filteredWorkouts.fold<int>(
      0,
      (sum, item) => sum + ((item['nDuration'] as num?)?.toInt() ?? 0),
    );
  }

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
