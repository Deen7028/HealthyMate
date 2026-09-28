import 'package:flutter/foundation.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';

/// RoutineStateNotifier จัดการ State สำหรับ กิจวัตรประจำวัน (Routines) และ เป้าหมายหลัก (Main Goal)
/// ช่วยให้ DashboardPage และ MyRoutinesPage ซิงค์ข้อมูล Real-time ทันทีโดยไม่ต้องรอ re-load หน้าใหม่
class RoutineStateNotifier extends ChangeNotifier {
  static final RoutineStateNotifier instance = RoutineStateNotifier._internal();
  RoutineStateNotifier._internal();

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

  int _userId = 1;
  int get userId => _userId;

  String get todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// โหลดข้อมูลใหม่ทั้งหมด และแจ้งเตือน UI ที่ฟังอยู่
  Future<void> loadData({int? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = AppDatabase.instance;

      if (userId != null) {
        _userId = userId;
      } else {
        final email = await db.getLoggedInUserEmail();
        if (email != null && email.isNotEmpty) {
          final u = await db.getUserByEmail(email);
          if (u != null) _userId = u.nUserId;
        }
      }

      // 1. ดึง Routines
      _routines = await db.getRoutines(userId: _userId);

      // 2. ดึง Completion วันนี้
      final Map<int, bool> completionMap = {};
      for (final r in _routines) {
        final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        final log = await db.getRoutineLogForDate(
          routineId: rId,
          dateStr: todayStr,
        );
        completionMap[rId] = (log?['isCompleted'] as num?)?.toInt() == 1;
      }
      _todayCompletionMap = completionMap;

      // 3. ดึง Goal
      _userGoal = await db.getUserGoal(_userId);

      // 4. ดึง Workouts วันนี้
      final workouts = await db.getWorkouts(userId: _userId);
      final Map<String, Map<String, double>> todayStats = {};
      for (final w in workouts) {
        final workoutDate = w['dtWorkoutDate']?.toString() ?? '';
        if (workoutDate.startsWith(todayStr)) {
          final type = w['sType']?.toString() ?? 'อื่นๆ';
          final dist = (w['nDistance'] as num?)?.toDouble() ?? 0.0;
          final duration = (w['nDuration'] as num?)?.toDouble() ?? 0.0;
          if (!todayStats.containsKey(type)) {
            todayStats[type] = {'distance': 0.0, 'duration': 0.0};
          }
          todayStats[type]!['distance'] = (todayStats[type]!['distance'] ?? 0) + dist;
          todayStats[type]!['duration'] = (todayStats[type]!['duration'] ?? 0) + duration;
        }
      }
      _todayWorkoutStats = todayStats;
    } catch (e) {
      debugPrint('[RoutineStateNotifier] ❌ Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ติ๊กทำรายการ / ยกเลิกทำรายการ
  Future<bool> toggleRoutineCompletion(int routineId) async {
    final newStatus = await AppDatabase.instance.toggleRoutineLog(
      routineId: routineId,
      dateStr: todayStr,
    );
    _todayCompletionMap[routineId] = newStatus;

    final r = _routines.firstWhere(
      (item) => ((item['nRoutineId'] as num?)?.toInt() ?? 0) == routineId,
      orElse: () => {},
    );
    final targetVal = (r['targetValue'] as num?)?.toDouble() ?? 1.0;
    final progressVal = newStatus ? targetVal : 0.0;

    // ซิงค์ขึ้นเซิร์ฟเวอร์ทันที
    HealthApiService.updateRoutineProgressRemote(
      routineId: routineId,
      date: todayStr,
      progressValue: progressVal,
      isCompleted: newStatus,
    );

    // อัปเดต Goal Real-time ถ้าตัวนี้เป็น Goal หลัก
    if (_userGoal != null) {
      final pinnedId = (_userGoal!['nRoutineId'] as num?)?.toInt() ?? 0;
      if (pinnedId == routineId) {
        if (r.isNotEmpty) {
          final unitText = r['unit']?.toString() ?? 'ครั้ง';
          final currentVal = newStatus ? targetVal : 0.0;
          final progress = newStatus ? 1.0 : 0.0;
          final percent = (progress * 100).toInt();
          final remainingText =
              'ความคืบหน้า: ${currentVal == currentVal.toInt() ? currentVal.toInt() : currentVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unitText ($percent%)';

          _userGoal = {
            'nRoutineId': routineId,
            'sTitle': r['sTitle']?.toString() ?? _userGoal!['sTitle'],
            'nProgress': progress,
            'sRemainingText': remainingText,
          };

          AppDatabase.instance.saveUserGoal(
            userId: _userId,
            nRoutineId: routineId,
            title: r['sTitle']?.toString() ?? _userGoal!['sTitle'],
            progress: progress,
            remainingText: remainingText,
          );
        }
      }
    }

    notifyListeners();
    return newStatus;
  }

  /// ปักหมุดเป้าหมายหลักจาก Routine
  Future<void> pinAsMainGoal(Map<String, dynamic> routine) async {
    final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final targetVal = (routine['targetValue'] as num?)?.toDouble() ??
        (routine['nTargetValue'] as num?)?.toDouble() ?? 1.0;
    final unitText = (routine['unit'] ?? routine['sUnit'])?.toString() ?? 'ครั้ง';

    final lowerTitle = title.toLowerCase();
    String matchedType = routine['sLinkedWorkout']?.toString() ?? '';
    if (matchedType.isEmpty) {
      if (lowerTitle.contains('วิ่ง')) {
        matchedType = 'วิ่ง';
      } else if (lowerTitle.contains('เดิน')) {
        matchedType = 'เดิน';
      } else if (lowerTitle.contains('จักรยาน') || lowerTitle.contains('ปั่น')) {
        matchedType = 'ปั่นจักรยาน';
      } else if (lowerTitle.contains('ลู่วิ่ง')) {
        matchedType = 'ลู่วิ่งในร่ม';
      } else if (lowerTitle.contains('สมาธิ')) {
        matchedType = 'ทำสมาธิ';
      } else if (lowerTitle.contains('โยคะ')) {
        matchedType = 'โยคะ';
      }
    }

    double currentVal = 0.0;
    if (matchedType.isNotEmpty && _todayWorkoutStats.containsKey(matchedType)) {
      final stats = _todayWorkoutStats[matchedType]!;
      if (unitText.contains('กม') || unitText.contains('กิโล') || unitText.contains('km')) {
        currentVal = stats['distance'] ?? 0.0;
      } else if (unitText.contains('ชม') || unitText.contains('ชั่วโมง') || unitText.contains('hour') || unitText.contains('hr')) {
        currentVal = (stats['duration'] ?? 0.0) / 60.0;
      } else if (unitText.contains('นาที') || unitText.contains('min') || unitText.contains('เวลา')) {
        currentVal = stats['duration'] ?? 0.0;
      } else if (unitText.contains('แคล') || unitText.contains('cal')) {
        currentVal = stats['caloriesBurned'] ?? 0.0;
      }
    } else {
      final isDone = _todayCompletionMap[routineId] ?? false;
      currentVal = isDone ? targetVal : 0.0;
    }

    final double progress = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
    final int percent = (progress * 100).toInt();
    final String remainingText =
        'ความคืบหน้า: ${currentVal == currentVal.toInt() ? currentVal.toInt() : currentVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unitText ($percent%)';

    _userGoal = {
      'nRoutineId': routineId,
      'sTitle': title,
      'nProgress': progress,
      'sRemainingText': remainingText,
      'targetValue': targetVal,
      'unit': unitText,
      'linkedWorkout': matchedType,
    };

    await AppDatabase.instance.saveUserGoal(
      userId: _userId,
      nRoutineId: routineId,
      title: title,
      progress: progress,
      remainingText: remainingText,
    );

    notifyListeners();
  }

  /// ตั้งเป้าหมายหลักแบบกำหนดเอง (Custom Main Goal)
  Future<void> setCustomMainGoal({
    required String title,
    required String icon,
    required String unit,
    required double targetValue,
    required String linkedWorkout,
    required DateTime deadlineDate,
  }) async {
    final now = DateTime.now();
    final remainingDays = deadlineDate.difference(now).inDays.clamp(1, 9999);
    final deadlineStr = '${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year}';
    final remainingText = 'เป้าหมาย: 0 / ${targetValue == targetValue.toInt() ? targetValue.toInt() : targetValue.toStringAsFixed(1)} $unit (เหลือ $remainingDays วัน • สิ้นสุด $deadlineStr)';

    _userGoal = {
      'nRoutineId': 0,
      'sTitle': '$icon $title',
      'nProgress': 0.0,
      'sRemainingText': remainingText,
      'targetValue': targetValue,
      'unit': unit,
      'linkedWorkout': linkedWorkout,
      'dtDeadline': deadlineDate.toIso8601String(),
    };

    await AppDatabase.instance.saveUserGoal(
      userId: _userId,
      nRoutineId: 0,
      title: '$icon $title',
      progress: 0.0,
      remainingText: remainingText,
    );

    notifyListeners();
  }

  /// ยกเลิกปักหมุดเป้าหมายหลัก
  Future<void> unpinMainGoal() async {
    _userGoal = null;
    await AppDatabase.instance.clearUserGoal(_userId);
    notifyListeners();
  }
}
