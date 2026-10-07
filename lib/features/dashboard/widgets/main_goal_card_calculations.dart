part of 'main_goal_card.dart';

extension _MainGoalCardCalculations on MainGoalCard {
  ({
    double progress,
    String displayTitle,
    String displayDetail,
    Color goalColor,
    IconData goalIcon,
    bool isCompleted,
  })
  _calculateGoalState({
    required Map<String, dynamic>? userGoal,
    required Map<String, dynamic>? pinnedRoutine,
    required bool hasPinnedGoal,
    required Map<int, bool> todayCompletionMap,
    required Map<String, Map<String, double>> todayWorkoutStats,
  }) {
    final double progress;
    final String displayTitle;
    String displayDetail;
    final Color goalColor;
    final IconData goalIcon;
    bool isCompleted = false;
    if (pinnedRoutine != null) {
      final title = pinnedRoutine['sTitle']?.toString() ?? 'เป้าหมายหลัก';
      final targetVal =
          (pinnedRoutine['targetValue'] as num?)?.toDouble() ?? 1.0;
      final unitText = pinnedRoutine['unit']?.toString() ?? 'ครั้ง';
      goalColor = DashboardUiHelpers.getRoutineColor(pinnedRoutine, 0);
      goalIcon = DashboardUiHelpers.getRoutineIcon(pinnedRoutine, 0);
      final lowerTitle = title.toLowerCase();
      String matchedType = pinnedRoutine['sLinkedWorkout']?.toString() ?? '';
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
      double? workoutVal;
      if (matchedType.isNotEmpty &&
          todayWorkoutStats.containsKey(matchedType)) {
        final stats = todayWorkoutStats[matchedType]!;
        if (unitText.contains('กม') ||
            unitText.contains('กิโล') ||
            unitText.contains('km')) {
          workoutVal = stats['distance'];
        } else if (unitText.contains('ชม') ||
            unitText.contains('ชั่วโมง') ||
            unitText.contains('hour') ||
            unitText.contains('hr')) {
          workoutVal = (stats['duration'] ?? 0.0) / 60.0;
        } else if (unitText.contains('นาที') ||
            unitText.contains('min') ||
            unitText.contains('เวลา')) {
          workoutVal = stats['duration'];
        } else if (unitText.contains('แคล') || unitText.contains('cal')) {
          workoutVal = stats['caloriesBurned'];
        }
      }
      final routineId = (pinnedRoutine['nRoutineId'] as num?)?.toInt() ?? 0;
      final isDone = todayCompletionMap[routineId] ?? false;
      final currentVal =
          workoutVal ??
          (isDone
              ? targetVal
              : ((pinnedRoutine['currentValue'] as num?)?.toDouble() ?? 0.0));
      progress = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
      final percent = (progress * 100).toInt();
      isCompleted = progress >= 1.0 || isDone;

      displayTitle = title;
      displayDetail =
          'ความคืบหน้าวันนี้: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
    } else if (userGoal != null) {
      displayTitle = userGoal['sTitle']?.toString() ?? 'เป้าหมายหลัก';
      final remaining = userGoal['sRemainingText']?.toString() ?? '';
      final lowerTitle = displayTitle.toLowerCase();

      // ดึง targetVal จาก remainingText (เช่น 'เป้าหมาย: 0 / 3.0 กก.')
      double targetVal = 0.0;
      final targetMatch = RegExp(
        r'/\s*([\d.]+)\s*(\S+)?',
      ).firstMatch(remaining);
      if (targetMatch != null) {
        targetVal = double.tryParse(targetMatch.group(1) ?? '') ?? 0.0;
      }
      if (targetVal <= 0) {
        targetVal = (userGoal['targetValue'] as num?)?.toDouble() ?? 1.0;
      }

      double currentVal = 0.0;
      String unitText = '';

      // กรองกิจกรรมไม่ให้นับข้อมูลที่เกิดขึ้นก่อนเวลาที่สร้างเป้าหมาย (Goal Creation Time Condition)
      DateTime? goalCreatedAt;
      final rawCreatedAt = userGoal['dtCreatedAt']?.toString();
      if (rawCreatedAt != null && rawCreatedAt.isNotEmpty) {
        goalCreatedAt = DateTime.tryParse(rawCreatedAt);
      }

      final validWorkouts = controller.workouts.where((w) {
        if (goalCreatedAt == null) return true;
        final wDateStr = w['dtWorkoutDate']?.toString() ?? '';
        final wDate = DateTime.tryParse(wDateStr);
        if (wDate == null) return false;
        return wDate.isAfter(goalCreatedAt) ||
            wDate.isAtSameMomentAs(goalCreatedAt);
      }).toList();

      if (lowerTitle.contains('ลดน้ำหนัก') || lowerTitle.contains('น้ำหนัก')) {
        goalColor = const Color(0xFF0F9C58);
        goalIcon = Icons.monitor_weight_outlined;
        unitText = 'กก.';

        final records = controller.healthRecords;
        final validRecords = records.where((r) {
          if (goalCreatedAt == null) return true;
          return r.dtRecordedAt.isAfter(goalCreatedAt) ||
              r.dtRecordedAt.isAtSameMomentAs(goalCreatedAt);
        }).toList();

        double startWeight = 0.0;
        final recordsBeforeOrAt = records.where((r) {
          if (goalCreatedAt == null) return true;
          return r.dtRecordedAt.isBefore(goalCreatedAt) ||
              r.dtRecordedAt.isAtSameMomentAs(goalCreatedAt);
        }).toList();

        if (recordsBeforeOrAt.isNotEmpty) {
          startWeight = recordsBeforeOrAt.first.nWeight;
        } else if (records.isNotEmpty) {
          startWeight = records.last.nWeight;
        } else if (controller.user != null) {
          startWeight = controller.user?.nWeight ?? 0.0;
        }

        if (validRecords.isNotEmpty && startWeight > 0) {
          final curWeight = validRecords.first.nWeight;
          final diff = startWeight - curWeight;
          currentVal = diff > 0 ? diff : 0.0;
        } else {
          currentVal = 0.0;
        }

        progress = targetVal > 0
            ? (currentVal / targetVal).clamp(0.0, 1.0)
            : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail =
            'ลดน้ำหนักได้: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else if (lowerTitle.contains('แคลอรี') ||
          lowerTitle.contains('เผาผลาญ')) {
        goalColor = const Color(0xFFFF9800);
        goalIcon = Icons.local_fire_department_rounded;
        unitText = 'แคล';
        double totalBurned = 0.0;
        for (final w in validWorkouts) {
          totalBurned += (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
        }
        currentVal = totalBurned;
        progress = targetVal > 0
            ? (currentVal / targetVal).clamp(0.0, 1.0)
            : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail =
            'เผาผลาญสะสม: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else if (lowerTitle.contains('ปั่น') ||
          lowerTitle.contains('จักรยาน') ||
          lowerTitle.contains('cycling')) {
        goalColor = const Color(0xFF0288D1);
        goalIcon = Icons.directions_bike;
        unitText = (userGoal['unit'] ?? 'กม.').toString();
        double totalCycling = 0.0;
        for (final w in validWorkouts) {
          final type = (w['sType']?.toString() ?? '').toLowerCase();
          if (type.contains('ปั่น') ||
              type.contains('จักรยาน') ||
              type.contains('cycling')) {
            if (unitText.contains('นาที') || unitText.contains('min')) {
              totalCycling +=
                  ((w['nDuration'] as num?)?.toDouble() ?? 0.0) / 60.0;
            } else {
              totalCycling += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
            }
          }
        }
        currentVal = totalCycling;
        progress = targetVal > 0
            ? (currentVal / targetVal).clamp(0.0, 1.0)
            : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail =
            'ปั่นสะสม: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else if (lowerTitle.contains('วิ่ง') ||
          lowerTitle.contains('running')) {
        goalColor = const Color(0xFF4CAF50);
        goalIcon = Icons.directions_run;
        unitText = (userGoal['unit'] ?? 'กม.').toString();
        double totalRunning = 0.0;
        for (final w in validWorkouts) {
          final type = (w['sType']?.toString() ?? '').toLowerCase();
          if (type.contains('วิ่ง') || type.contains('running')) {
            if (unitText.contains('นาที') || unitText.contains('min')) {
              totalRunning +=
                  ((w['nDuration'] as num?)?.toDouble() ?? 0.0) / 60.0;
            } else {
              totalRunning += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
            }
          }
        }
        currentVal = totalRunning;
        progress = targetVal > 0
            ? (currentVal / targetVal).clamp(0.0, 1.0)
            : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail =
            'วิ่งสะสม: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else if (lowerTitle.contains('เดิน') ||
          lowerTitle.contains('walking')) {
        goalColor = const Color(0xFF26A69A);
        goalIcon = Icons.directions_walk;
        unitText = (userGoal['unit'] ?? 'กม.').toString();
        double totalWalking = 0.0;
        for (final w in validWorkouts) {
          final type = (w['sType']?.toString() ?? '').toLowerCase();
          if (type.contains('เดิน') || type.contains('walking')) {
            if (unitText.contains('นาที') || unitText.contains('min')) {
              totalWalking +=
                  ((w['nDuration'] as num?)?.toDouble() ?? 0.0) / 60.0;
            } else {
              totalWalking += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
            }
          }
        }
        currentVal = totalWalking;
        progress = targetVal > 0
            ? (currentVal / targetVal).clamp(0.0, 1.0)
            : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail =
            'เดินสะสม: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else if (lowerTitle.contains('สมาธิ') ||
          lowerTitle.contains('meditation')) {
        goalColor = const Color(0xFF8E24AA);
        goalIcon = Icons.self_improvement_rounded;
        unitText = (userGoal['unit'] ?? 'นาที').toString();
        double totalMeditation = 0.0;
        for (final w in validWorkouts) {
          final type = (w['sType']?.toString() ?? '').toLowerCase();
          if (type.contains('สมาธิ') || type.contains('meditation')) {
            totalMeditation +=
                ((w['nDuration'] as num?)?.toDouble() ?? 0.0) / 60.0;
          }
        }
        currentVal = totalMeditation;
        progress = targetVal > 0
            ? (currentVal / targetVal).clamp(0.0, 1.0)
            : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail =
            'สมาธิสะสม: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else if (lowerTitle.contains('โยคะ') ||
          lowerTitle.contains('yoga')) {
        goalColor = const Color(0xFFE91E63);
        goalIcon = Icons.spa_rounded;
        unitText = (userGoal['unit'] ?? 'นาที').toString();
        double totalYoga = 0.0;
        for (final w in validWorkouts) {
          final type = (w['sType']?.toString() ?? '').toLowerCase();
          if (type.contains('โยคะ') || type.contains('yoga')) {
            totalYoga +=
                ((w['nDuration'] as num?)?.toDouble() ?? 0.0) / 60.0;
          }
        }
        currentVal = totalYoga;
        progress = targetVal > 0
            ? (currentVal / targetVal).clamp(0.0, 1.0)
            : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail =
            'โยคะสะสม: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else {
        progress =
            (userGoal['nProgress'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0;
        goalColor = const Color(0xFF0F9C58);
        goalIcon = Icons.flag_rounded;
        isCompleted = progress >= 1.0;
        displayDetail = remaining.isNotEmpty
            ? remaining.replaceAll(RegExp(r'\s*\(\s*เหลือ[^)]*\)'), '').trim()
            : 'ทำสำเร็จแล้ว ${(progress * 100).toInt()}%';
      }
    } else {
      progress = 0.0;
      goalColor = const Color(0xFF0F9C58);
      goalIcon = Icons.push_pin_outlined;
      displayTitle = 'ยังไม่ได้ปักหมุดเป้าหมายหลัก';
      displayDetail =
          'เลือกปักหมุดกิจวัตรสำคัญจากหน้ากิจวัตรเพื่อติดตามความคืบหน้า';
    }

    return (
      progress: progress,
      displayTitle: displayTitle,
      displayDetail: displayDetail,
      goalColor: goalColor,
      goalIcon: goalIcon,
      isCompleted: isCompleted,
    );
  }
}
