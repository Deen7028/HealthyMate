part of '../routine_controller.dart';

// ส่วนจัดการเป้าหมายหลัก (RoutineControllerGoals)
// ทำหน้าที่ปักหมุดกิจวัตรเป็นเป้าหมายหลัก, ตั้งเป้าหมายแบบกำหนดเอง และยกเลิกการปักหมุด

extension RoutineControllerGoals on RoutineController {
  // ฟังก์ชัน: ปักหมุดกิจวัตรที่มีอยู่ให้เป็นเป้าหมายหลัก (Pin Routine as Main Goal)
  Future<void> pinAsMainGoal(Map<String, dynamic> routine) async {
    // 1. ดึงและจัดรูปแบบข้อมูลของกิจวัตร
    final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final targetVal = (routine['targetValue'] as num?)?.toDouble() ?? 1.0;
    final unitText = routine['unit']?.toString() ?? 'ครั้ง';

    // 2. ตรวจสอบการเชื่อมโยงกับประเภทการออกกำลังกาย (Linked Workout)
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

    // 3. คำนวณค่าความคืบหน้าปัจจุบันตามสถิติการออกกำลังกายหรือสถานะความสำเร็จ
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

    // 4. อัปเดตข้อมูลเป้าหมายใน State และแจ้งเตือนหน้า UI
    userGoal = {
      'nRoutineId': routineId,
      'sTitle': title,
      'nProgress': progress,
      'sRemainingText': remainingText,
    };
    this._notifyControllerListeners();

    // 5. บันทึกลง SQLite และซิงค์ขึ้นเซิร์ฟเวอร์
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

  // ฟังก์ชัน: กำหนดเป้าหมายหลักแบบกำหนดเอง (Set Custom Main Goal)
  Future<void> setCustomMainGoal({
    required String title,
    required String icon,
    required String unit,
    required double targetValue,
    required String linkedWorkout,
    required DateTime deadlineDate,
  }) async {
    // 1. คำนวณจำนวนวันที่เหลือและข้อความแสดงผล
    final now = DateTime.now();
    final remainingDays = deadlineDate.difference(now).inDays.clamp(1, 9999);
    final deadlineStr =
        '${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year}';
    final remainingText =
        'เป้าหมาย: 0 / ${targetValue == targetValue.toInt() ? targetValue.toInt() : targetValue.toStringAsFixed(1)} $unit (เหลือ $remainingDays วัน • สิ้นสุด $deadlineStr)';

    // 2. อัปเดตข้อมูลเป้าหมายใน State ท้องถิ่น
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

    // 3. บันทึกลง SQLite และซิงค์เป้าหมายขึ้นเซิร์ฟเวอร์
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

  // ฟังก์ชัน: ยกเลิกการปักหมุดเป้าหมายหลัก (Unpin Main Goal)
  Future<void> unpinMainGoal() async {
    // 1. ล้างเป้าหมายในหน่วยความจำและแจ้ง UI
    userGoal = null;
    this._notifyControllerListeners();

    // 2. ลบออกจาก Local DB และ Server
    if (user != null) {
      try {
        await AppDatabase.instance.clearUserGoal(user!.nUserId);
        await GoalApiService.clearMainGoalRemote(user!.nUserId);
        RoutineStateNotifier.instance.loadData(userId: user!.nUserId);
      } catch (_) {}
    }
  }
}
