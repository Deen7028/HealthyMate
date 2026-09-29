part of 'routine_controller.dart';

extension RoutineControllerGoalSync on RoutineController {
  Future<void> _syncGoalProgress(
    AppDatabase db,
    int userId,
    List<Map<String, dynamic>> workouts,
  ) async {
    // Real-time Goal Sync: อัปเดตความคืบหน้าของเป้าหมายหลักให้ตรงกับ Routine หรือ Workout ล่าสุด
    if (userGoal != null) {
      final pinnedRoutineId = (userGoal!['nRoutineId'] as num?)?.toInt() ?? 0;
      if (pinnedRoutineId > 0) {
        final matchedRoutine = routines.firstWhere(
          (item) =>
              ((item['nRoutineId'] as num?)?.toInt() ?? 0) == pinnedRoutineId,
          orElse: () => {},
        );
        if (matchedRoutine.isNotEmpty) {
          final targetVal =
              (matchedRoutine['targetValue'] as num?)?.toDouble() ??
              (matchedRoutine['nTargetValue'] as num?)?.toDouble() ??
              1.0;
          final currentVal = todayProgressValues[pinnedRoutineId] ?? 0.0;
          final isDone = todayCompletionMap[pinnedRoutineId] ?? false;
          final effectiveVal = isDone ? targetVal : currentVal;
          final progress = targetVal > 0
              ? (effectiveVal / targetVal).clamp(0.0, 1.0)
              : 0.0;
          final percent = (progress * 100).toInt();
          final unitText =
              (matchedRoutine['unit'] ?? matchedRoutine['sUnit'])?.toString() ??
              'ครั้ง';
          final remainingText =
              'ความคืบหน้า: ${effectiveVal == effectiveVal.toInt() ? effectiveVal.toInt() : effectiveVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unitText ($percent%)';

          userGoal = {
            ...userGoal!,
            'nProgress': progress,
            'sRemainingText': remainingText,
          };

          await db.saveUserGoal(
            userId: userId,
            nRoutineId: pinnedRoutineId,
            title: matchedRoutine['sTitle']?.toString() ?? userGoal!['sTitle'],
            progress: progress,
            remainingText: remainingText,
          );
        }
      } else {
        // เป้าหมายแบบกำหนดเอง (Custom Goal เช่น ลดน้ำหนัก, วิ่งสะสม, ปั่นสะสม, เผาผลาญ)
        final title = userGoal!['sTitle']?.toString() ?? '';
        final lowerTitle = title.toLowerCase();
        final remaining = userGoal!['sRemainingText']?.toString() ?? '';
        double targetVal = 0.0;
        final targetMatch = RegExp(
          r'/\s*([\d.]+)\s*(\S+)?',
        ).firstMatch(remaining);
        if (targetMatch != null) {
          targetVal = double.tryParse(targetMatch.group(1) ?? '') ?? 0.0;
        }
        if (targetVal <= 0) {
          targetVal = (userGoal!['targetValue'] as num?)?.toDouble() ?? 1.0;
        }

        // กรองกิจกรรมไม่ให้นับข้อมูลที่เกิดขึ้นก่อนเวลาที่สร้างเป้าหมาย (Goal Creation Time Condition)
        DateTime? goalCreatedAt;
        final rawCreatedAt = userGoal!['dtCreatedAt']?.toString();
        if (rawCreatedAt != null && rawCreatedAt.isNotEmpty) {
          goalCreatedAt = DateTime.tryParse(rawCreatedAt);
        }

        final validWorkouts = workouts.where((w) {
          if (goalCreatedAt == null) return true;
          final wDateStr = w['dtWorkoutDate']?.toString() ?? '';
          final wDate = DateTime.tryParse(wDateStr);
          if (wDate == null) return true;
          return wDate.isAfter(goalCreatedAt) ||
              wDate.isAtSameMomentAs(goalCreatedAt);
        }).toList();

        double currentVal = 0.0;
        String unitText = '';

        if (lowerTitle.contains('ลดน้ำหนัก') ||
            lowerTitle.contains('น้ำหนัก')) {
          unitText = 'กก.';
          final records = await db.getHealthRecords(userId: userId);
          final userObj = await db.getCurrentUser();
          final validRecords = records.where((r) {
            if (goalCreatedAt == null) return true;
            return r.dtRecordedAt.isAfter(goalCreatedAt) ||
                r.dtRecordedAt.isAtSameMomentAs(goalCreatedAt);
          }).toList();

          if (validRecords.length >= 2) {
            final startWeight = validRecords.last.nWeight;
            final curWeight = validRecords.first.nWeight;
            final diff = startWeight - curWeight;
            currentVal = diff > 0 ? diff : 0.0;
          } else if (validRecords.isNotEmpty && userObj != null) {
            final curWeight = validRecords.first.nWeight;
            final userWeight = userObj.nWeight ?? 0.0;
            final diff = (userWeight > curWeight && userWeight > 0)
                ? (userWeight - curWeight)
                : 0.0;
            currentVal = diff;
          }
        } else if (lowerTitle.contains('แคลอรี') ||
            lowerTitle.contains('เผาผลาญ')) {
          unitText = 'แคล';
          double totalBurned = 0.0;
          for (final w in validWorkouts) {
            totalBurned += (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
          }
          currentVal = totalBurned;
        } else if (lowerTitle.contains('ปั่น') ||
            lowerTitle.contains('จักรยาน')) {
          unitText = 'กม.';
          double totalCycling = 0.0;
          for (final w in validWorkouts) {
            final type = (w['sType']?.toString() ?? '').toLowerCase();
            if (type.contains('ปั่น') ||
                type.contains('จักรยาน') ||
                type.contains('cycling')) {
              totalCycling += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
            }
          }
          currentVal = totalCycling;
        } else if (lowerTitle.contains('วิ่ง')) {
          unitText = 'กม.';
          double totalRunning = 0.0;
          for (final w in validWorkouts) {
            final type = (w['sType']?.toString() ?? '').toLowerCase();
            if (type.contains('วิ่ง') || type.contains('running')) {
              totalRunning += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
            }
          }
          currentVal = totalRunning;
        }

        if (unitText.isNotEmpty && targetVal > 0) {
          final progress = (currentVal / targetVal).clamp(0.0, 1.0);
          final percent = (progress * 100).toInt();
          final detailText =
              'ความคืบหน้า: ${currentVal == currentVal.toInt() ? currentVal.toInt() : currentVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unitText ($percent%)';

          userGoal = {
            ...userGoal!,
            'nProgress': progress,
            'sRemainingText': detailText,
          };

          await db.saveUserGoal(
            userId: userId,
            nRoutineId: 0,
            title: title,
            progress: progress,
            remainingText: detailText,
          );
        }
      }
    }
  }
}
