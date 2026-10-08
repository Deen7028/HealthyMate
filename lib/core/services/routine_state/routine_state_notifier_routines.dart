part of 'routine_state_notifier.dart';

// ส่วนขยายสำหรับจัดการการทำกิจวัตร และปักหมุดกิจวัตรเป็นเป้าหมายหลัก (Routine Operations Extension)
extension RoutineStateRoutines on RoutineStateNotifier {
  // สลับสถานะการทำกิจวัตร (สำเร็จ / ยังไม่สำเร็จ) พร้อมบันทึกลง Local DB และซิงค์ขึ้น Server ทันที
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

    // ซิงค์ความคืบหน้าขึ้นเซิร์ฟเวอร์ทันที
    GoalApiService.updateRoutineProgressRemote(
      routineId: routineId,
      date: todayStr,
      progressValue: progressVal,
      isCompleted: newStatus,
    );

    // อัปเดตข้อมูลความคืบหน้าของเป้าหมายหลักแบบ Real-time หากกิจวัตรนี้ถูกปักหมุดไว้
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

    this._notifyStateListeners();
    return newStatus;
  }

  // ปักหมุดกิจวัตรที่มีอยู่ให้กลายเป็นเป้าหมายหลักประจำวัน (Pin Routine as Main Goal)
  Future<void> pinAsMainGoal(Map<String, dynamic> routine) async {
    final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final targetVal =
        (routine['targetValue'] as num?)?.toDouble() ??
        (routine['nTargetValue'] as num?)?.toDouble() ??
        1.0;
    final unitText =
        (routine['unit'] ?? routine['sUnit'])?.toString() ?? 'ครั้ง';

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
      } else if (lowerTitle.contains('สมาธิ')) {
        matchedType = 'ทำสมาธิ';
      } else if (lowerTitle.contains('โยคะ')) {
        matchedType = 'โยคะ';
      }
    }

    double currentVal = 0.0;
    if (matchedType.isNotEmpty && _todayWorkoutStats.containsKey(matchedType)) {
      final stats = _todayWorkoutStats[matchedType]!;
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
      } else if (unitText.contains('แคล') || unitText.contains('cal')) {
        currentVal = stats['caloriesBurned'] ?? 0.0;
      }
    } else {
      final isDone = _todayCompletionMap[routineId] ?? false;
      currentVal = isDone ? targetVal : 0.0;
    }

    final double progress = targetVal > 0
        ? (currentVal / targetVal).clamp(0.0, 1.0)
        : 0.0;
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

    // ซิงค์เป้าหมายหลักขึ้นเซิร์ฟเวอร์
    try {
      await GoalApiService.saveMainGoalRemote(
        userId: _userId,
        routineId: routineId,
        title: title,
        progress: progress,
        remainingText: remainingText,
      );
    } catch (_) {}

    this._notifyStateListeners();
  }
}
