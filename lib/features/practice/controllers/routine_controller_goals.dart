// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine controller goals)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_controller.dart';

extension RoutineControllerGoals on RoutineController {
  Future<void> pinAsMainGoal(Map<String, dynamic> routine) async {
    final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final targetVal = (routine['targetValue'] as num?)?.toDouble() ?? 1.0;
    final unitText = routine['unit']?.toString() ?? 'ครั้ง';

    final lowerTitle = title.toLowerCase();
    String matchedType = routine['sLinkedWorkout']?.toString() ?? '';
    if (matchedType.isEmpty) {
      if (lowerTitle.contains('วิ่ง')) {
        matchedType = 'วิ่ง';
      } else if (lowerTitle.contains('เดิน')) {
        matchedType = 'เดิน';
      } else if (lowerTitle.contains('จักรยาน') ||
          lowerTitle.contains('ปั่น')) {
        matchedType = 'ปั่นจักรยาน';
      } else if (lowerTitle.contains('ลู่วิ่ง')) {
        matchedType = 'ลู่วิ่งในร่ม';
      }
    }

    double currentVal = 0.0;
    if (matchedType.isNotEmpty && todayWorkoutStats.containsKey(matchedType)) {
      final stats = todayWorkoutStats[matchedType]!;
      if (unitText.contains('กม') ||
          unitText.contains('กิโล') ||
          unitText.contains('km')) {
        currentVal = stats['distance'] ?? 0.0;
      } else if (unitText.contains('ชม') ||
          unitText.contains('ชั่วโมง') ||
          unitText.contains('hour') ||
          unitText.contains('hr')) {
        currentVal = (stats['duration'] ?? 0.0) / 60.0;
      } else if (unitText.contains('นาที') ||
          unitText.contains('min') ||
          unitText.contains('เวลา')) {
        currentVal = stats['duration'] ?? 0.0;
      }
    } else {
      final isDone = todayCompletionMap[routineId] ?? false;
      currentVal = isDone ? targetVal : 0.0;
    }

    final double progress = targetVal > 0
        ? (currentVal / targetVal).clamp(0.0, 1.0)
        : 0.0;
    final int percent = (progress * 100).toInt();
    final String remainingText =
        'ความคืบหน้า: ${currentVal == currentVal.toInt() ? currentVal.toInt() : currentVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unitText ($percent%)';

    userGoal = {
      'nRoutineId': routineId,
      'sTitle': title,
      'nProgress': progress,
      'sRemainingText': remainingText,
    };
    this._notifyControllerListeners();

    if (user != null) {
      try {
        await AppDatabase.instance.saveUserGoal(
          userId: user!.nUserId,
          nRoutineId: routineId,
          title: title,
          progress: progress,
          remainingText: remainingText,
        );
        await GoalApiService.saveMainGoalRemote(
          userId: user!.nUserId,
          routineId: routineId,
          title: title,
          progress: progress,
          remainingText: remainingText,
        );
        RoutineStateNotifier.instance.loadData(userId: user!.nUserId);
      } catch (_) {}
    }
  }

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

    final createdAtStr = now.toIso8601String();
    userGoal = {
      'nRoutineId': 0,
      'sTitle': '$icon $title',
      'nProgress': 0.0,
      'sRemainingText': remainingText,
      'targetValue': targetValue,
      'unit': unit,
      'linkedWorkout': linkedWorkout,
      'dtDeadline': deadlineDate.toIso8601String(),
      'dtCreatedAt': createdAtStr,
    };
    this._notifyControllerListeners();

    if (user != null) {
      try {
        await AppDatabase.instance.saveUserGoal(
          userId: user!.nUserId,
          nRoutineId: 0,
          title: '$icon $title',
          progress: 0.0,
          remainingText: remainingText,
          dtCreatedAt: createdAtStr,
        );
        await GoalApiService.saveMainGoalRemote(
          userId: user!.nUserId,
          routineId: 0,
          title: '$icon $title',
          progress: 0.0,
          remainingText: remainingText,
        );
        RoutineStateNotifier.instance.loadData(userId: user!.nUserId);
      } catch (_) {}
    }
  }

  Future<void> unpinMainGoal() async {
    userGoal = null;
    this._notifyControllerListeners();

    if (user != null) {
      try {
        await AppDatabase.instance.clearUserGoal(user!.nUserId);
        await GoalApiService.clearMainGoalRemote(user!.nUserId);
        RoutineStateNotifier.instance.loadData(userId: user!.nUserId);
      } catch (_) {}
    }
  }
}
