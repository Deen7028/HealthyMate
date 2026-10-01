part of 'dashboard_other_goals_card.dart';

extension _DashboardOtherGoalsCardItem on DashboardOtherGoalsCard {
  Widget _buildRoutineItem(
    BuildContext context,
    int index,
    Map<String, dynamic> routine,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final rId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';
    final targetVal = (routine['targetValue'] as num?)?.toDouble() ?? 1.0;
    final unitText = routine['unit']?.toString() ?? 'ครั้ง';
    final color = DashboardUiHelpers.getRoutineColor(routine, index);
    final icon = DashboardUiHelpers.getRoutineIcon(routine, index);

    final lowerTitle = title.toLowerCase();
    const workoutKeywords = [
      'วิ่ง',
      'เดิน',
      'ปั่นจักรยาน',
      'จักรยาน',
      'ลู่วิ่ง',
      'คาร์ดิโอ',
      'ออกกำลังกาย',
    ];
    final bool isNonWorkout =
        lowerTitle.contains('น้ำ') ||
        lowerTitle.contains('สมาธิ') ||
        lowerTitle.contains('นอน') ||
        lowerTitle.contains('กิน') ||
        lowerTitle.contains('อาหาร') ||
        lowerTitle.contains('ยา') ||
        lowerTitle.contains('อ่าน');

    String matchedType = routine['sLinkedWorkout']?.toString() ?? '';
    if (matchedType.isEmpty && !isNonWorkout) {
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

    final bool isWorkout =
        !isNonWorkout &&
        (matchedType.isNotEmpty ||
            workoutKeywords.any((kw) => lowerTitle.contains(kw)));

    double? workoutVal;
    if (isWorkout &&
        matchedType.isNotEmpty &&
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

    final isDone = todayCompletionMap[rId] ?? false;
    final accumulatedVal =
        todayProgressValues[rId] ?? (isDone ? targetVal : 0.0);
    final currentVal = workoutVal ?? accumulatedVal;
    final isActuallyCompleted = isDone || currentVal >= targetVal;

    return InkWell(
      onTap: onNavigateToPractice,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // 1. ไอคอน
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActuallyCompleted
                    ? Colors.green.withValues(alpha: 0.15)
                    : color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActuallyCompleted ? Icons.check_circle_rounded : icon,
                color: isActuallyCompleted
                    ? (isDark ? const Color(0xFF90DB89) : Colors.green.shade700)
                    : color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // 2. ชื่อกิจวัตรและสถานะแบบตัวหนังสือ (คลีนๆ)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isActuallyCompleted
                          ? (isDark
                                ? const Color(0xFF8C968E)
                                : Colors.grey.shade500)
                          : textPrimary,
                      decoration: isActuallyCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActuallyCompleted
                        ? 'ทำสำเร็จแล้ววันนี้ (${_formatNum(currentVal)} / ${_formatNum(targetVal)} $unitText)'
                        : 'ความคืบหน้า: ${_formatNum(currentVal)} / ${_formatNum(targetVal)} $unitText',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActuallyCompleted
                          ? (isDark
                                ? const Color(0xFF90DB89)
                                : Colors.green.shade600)
                          : textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 3. ป้ายกำกับสถานะ
            if (!isActuallyCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF352B1E)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'รอทำรายการ',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFFFFB74D)
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
