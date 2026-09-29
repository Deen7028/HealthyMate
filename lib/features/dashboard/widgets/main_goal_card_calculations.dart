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

      if (lowerTitle.contains('ลดน้ำหนัก') || lowerTitle.contains('น้ำหนัก')) {
        goalColor = const Color(0xFF0F9C58);
        goalIcon = Icons.monitor_weight_outlined;
        unitText = 'กก.';

        // คำนวณน้ำหนักที่ลดได้จากประวัติสุขภาพ TbHealthRecords
        if (controller.healthRecords.length >= 2) {
          final startWeight = controller.healthRecords.last.nWeight;
          final currentWeight = controller.healthRecords.first.nWeight;
          final diff = startWeight - currentWeight;
          currentVal = diff > 0 ? diff : 0.0;
        } else if (controller.healthRecords.isNotEmpty &&
            controller.user != null) {
          final currentWeight = controller.healthRecords.first.nWeight;
          final userWeight = controller.user?.nWeight ?? 0.0;
          final diff = (userWeight > currentWeight && userWeight > 0)
              ? (userWeight - currentWeight)
              : 0.0;
          currentVal = diff;
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
        currentVal = controller.totalCaloriesBurned;
        progress = targetVal > 0
            ? (currentVal / targetVal).clamp(0.0, 1.0)
            : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail =
            'เผาผลาญสะสม: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else if (lowerTitle.contains('ปั่น') ||
          lowerTitle.contains('จักรยาน')) {
        goalColor = const Color(0xFF0288D1);
        goalIcon = Icons.directions_bike;
        unitText = 'กม.';
        currentVal = controller.totalCyclingDistanceKm > 0
            ? controller.totalCyclingDistanceKm
            : controller.totalDistanceKm;
        progress = targetVal > 0
            ? (currentVal / targetVal).clamp(0.0, 1.0)
            : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail =
            'ปั่นสะสม: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else if (lowerTitle.contains('วิ่ง')) {
        goalColor = const Color(0xFF4CAF50);
        goalIcon = Icons.directions_run;
        unitText = 'กม.';
        currentVal = controller.totalRunningDistanceKm > 0
            ? controller.totalRunningDistanceKm
            : controller.totalDistanceKm;
        progress = targetVal > 0
            ? (currentVal / targetVal).clamp(0.0, 1.0)
            : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail =
            'วิ่งสะสม: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
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
