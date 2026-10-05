// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine controller workout sync)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_controller.dart';

extension RoutineControllerWorkoutSync on RoutineController {
  Future<void> _syncWorkoutRoutineProgress(AppDatabase db) async {
    // Auto-GPS Sync: ประเมินความสำเร็จของกิจวัตรประเภทการออกกำลังกายจากสถิติ GPS วันนี้
    for (final r in routines) {
      final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
      final targetVal =
          (r['targetValue'] as num?)?.toDouble() ??
          (r['nTargetValue'] as num?)?.toDouble() ??
          1.0;
      final title = (r['sTitle'] as String? ?? '').toLowerCase();
      final unit = (r['unit'] as String? ?? (r['sUnit'] as String? ?? ''))
          .toLowerCase();

      const workoutKeywords = [
        'วิ่ง',
        'เดิน',
        'ปั่นจักรยาน',
        'จักรยาน',
        'ลู่วิ่ง',
        'คาร์ดิโอ',
        'ออกกำลังกาย',
        'สมาธิ',
        'ทำสมาธิ',
        'โยคะ',
      ];
      final bool hasWorkoutKeyword = workoutKeywords.any(
        (kw) => title.contains(kw),
      );
      final bool isNonWorkout =
          !hasWorkoutKeyword &&
          (title.contains('น้ำ') ||
              title.contains('นอน') ||
              title.contains('กิน') ||
              title.contains('อาหาร') ||
              title.contains('ยา') ||
              title.contains('อ่าน'));

      String matchedType = r['sLinkedWorkout']?.toString() ?? '';
      if (matchedType.isEmpty && !isNonWorkout) {
        if (title.contains('วิ่ง')) {
          matchedType = 'วิ่ง';
        } else if (title.contains('เดิน')) {
          matchedType = 'เดิน';
        } else if (title.contains('จักรยาน') || title.contains('ปั่น')) {
          matchedType = 'ปั่นจักรยาน';
        } else if (title.contains('ลู่วิ่ง')) {
          matchedType = 'ลู่วิ่งในร่ม';
        } else if (title.contains('สมาธิ')) {
          matchedType = 'ทำสมาธิ';
        } else if (title.contains('โยคะ')) {
          matchedType = 'โยคะ';
        }
      }

      final bool isWorkout =
          !isNonWorkout &&
          (matchedType.isNotEmpty ||
              workoutKeywords.any((kw) => title.contains(kw)));

      if (isWorkout &&
          matchedType.isNotEmpty &&
          todayWorkoutStats.containsKey(matchedType)) {
        final stats = todayWorkoutStats[matchedType]!;
        double workoutVal = 0.0;
        if (unit.contains('กม') ||
            unit.contains('กิโล') ||
            unit.contains('km')) {
          workoutVal = stats['distance'] ?? 0.0;
        } else if (unit.contains('ชม') ||
            unit.contains('ชั่วโมง') ||
            unit.contains('hour') ||
            unit.contains('hr')) {
          workoutVal = (stats['duration'] ?? 0.0) / 60.0;
        } else if (unit.contains('นาที') ||
            unit.contains('min') ||
            unit.contains('เวลา')) {
          workoutVal = stats['duration'] ?? 0.0;
        } else if (unit.contains('แคล') || unit.contains('cal')) {
          workoutVal = stats['caloriesBurned'] ?? 0.0;
        }
        if (workoutVal > 0) {
          todayProgressValues[routineId] = workoutVal;
          final isDone = workoutVal >= targetVal;
          if (isDone) {
            todayCompletionMap[routineId] = true;
          }

          // บันทึกลง SQLite และซิงค์ขึ้น Server ตาราง TbRoutineLogs
          await db.insertOrUpdateRoutineLog(
            routineId: routineId,
            dateStr: todayStr,
            progressValue: workoutVal,
            isCompleted: isDone,
          );
          GoalApiService.updateRoutineProgressRemote(
            routineId: routineId,
            date: todayStr,
            progressValue: workoutVal,
            isCompleted: isDone,
          );
        }
      }
    }
  }
}
