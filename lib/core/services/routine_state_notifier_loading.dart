// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (routine state notifier loading)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_state_notifier.dart';

extension RoutineStateLoading on RoutineStateNotifier {
  Future<void> loadData({int? userId}) async {
    _isLoading = true;
    this._notifyStateListeners();

    try {
      final db = AppDatabase.instance;

      if (userId != null) {
        _userId = userId;
      } else {
        final user = await db.getCurrentUser();
        _userId = user?.nUserId ?? 0;
      }

      if (_userId <= 0) {
        _routines = [];
        _todayCompletionMap = {};
        _userGoal = null;
        _todayWorkoutStats = {};
        return;
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
          todayStats[type]!['distance'] =
              (todayStats[type]!['distance'] ?? 0) + dist;
          todayStats[type]!['duration'] =
              (todayStats[type]!['duration'] ?? 0) + duration;
        }
      }
      _todayWorkoutStats = todayStats;

      await _refreshCurrentGoal(db, workouts);
    } catch (e) {
      debugPrint('[RoutineStateNotifier] ❌ Error: $e');
    } finally {
      _isLoading = false;
      this._notifyStateListeners();
    }
  }

  /// ติ๊กทำรายการ / ยกเลิกทำรายการ
}
