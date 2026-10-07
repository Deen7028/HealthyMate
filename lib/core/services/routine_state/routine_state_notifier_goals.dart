// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (routine state notifier goals)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_state_notifier.dart';

extension RoutineStateGoals on RoutineStateNotifier {
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
    final deadlineStr =
        '${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year}';
    final remainingText =
        'เป้าหมาย: 0 / ${targetValue == targetValue.toInt() ? targetValue.toInt() : targetValue.toStringAsFixed(1)} $unit (เหลือ $remainingDays วัน • สิ้นสุด $deadlineStr)';

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

    // ซิงค์ Custom Goal ขึ้นเซิร์ฟเวอร์
    try {
      await GoalApiService.saveMainGoalRemote(
        userId: _userId,
        routineId: 0,
        title: '$icon $title',
        progress: 0.0,
        remainingText: remainingText,
      );
    } catch (_) {}

    this._notifyStateListeners();
  }

  /// ยกเลิกปักหมุดเป้าหมายหลัก
  Future<void> unpinMainGoal() async {
    _userGoal = null;
    await AppDatabase.instance.clearUserGoal(_userId);
    try {
      await GoalApiService.clearMainGoalRemote(_userId);
    } catch (_) {}
    this._notifyStateListeners();
  }
}
