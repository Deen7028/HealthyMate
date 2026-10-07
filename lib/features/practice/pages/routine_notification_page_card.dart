part of 'routine_notification_page.dart';

extension _RoutineNotificationCard on _MyRoutinesPageState {
  Widget _buildRoutineCardFromDb(Map<String, dynamic> routine, int index) {
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';

    IconData icon = _getRoutineIcon(index);
    if (routine['iconData'] != null) {
      final int codePoint = (routine['iconData'] as num).toInt();
      icon = DashboardUiHelpers.iconFromCodePoint(codePoint, fallback: icon);
    }

    final targetVal =
        (routine['targetValue'] as num?)?.toDouble() ??
        (routine['nTargetValue'] as num?)?.toDouble() ??
        1.0;
    final unitText =
        routine['unit']?.toString() ?? routine['sUnit']?.toString() ?? 'ครั้ง';
    final lowerTitle = title.toLowerCase();

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
      (kw) => lowerTitle.contains(kw),
    );
    final bool isNonWorkout =
        !hasWorkoutKeyword &&
        (lowerTitle.contains('น้ำ') ||
            lowerTitle.contains('นอน') ||
            lowerTitle.contains('กิน') ||
            lowerTitle.contains('อาหาร') ||
            lowerTitle.contains('ยา') ||
            lowerTitle.contains('อ่าน'));

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
      } else if (lowerTitle.contains('สมาธิ')) {
        matchedType = 'ทำสมาธิ';
      } else if (lowerTitle.contains('โยคะ')) {
        matchedType = 'โยคะ';
      }
    }

    final bool isWorkoutRoutine =
        !isNonWorkout &&
        (matchedType.isNotEmpty ||
            workoutKeywords.any((kw) => lowerTitle.contains(kw)));

    double? workoutCurrentVal;
    if (isWorkoutRoutine &&
        matchedType.isNotEmpty &&
        _controller.todayWorkoutStats.containsKey(matchedType)) {
      final stats = _controller.todayWorkoutStats[matchedType]!;
      if (unitText.contains('กม') ||
          unitText.contains('กิโล') ||
          unitText.contains('km')) {
        workoutCurrentVal = stats['distance'];
      } else if (unitText.contains('ชม') ||
          unitText.contains('ชั่วโมง') ||
          unitText.contains('hour') ||
          unitText.contains('hr')) {
        workoutCurrentVal = (stats['duration'] ?? 0.0) / 60.0;
      } else if (unitText.contains('นาที') ||
          unitText.contains('min') ||
          unitText.contains('เวลา')) {
        workoutCurrentVal = stats['duration'];
      } else if (unitText.contains('แคล') || unitText.contains('cal')) {
        workoutCurrentVal = stats['caloriesBurned'];
      }
    }

    final isManuallyCompleted =
        _controller.todayCompletionMap[routineId] ?? false;
    final double accumulatedVal =
        _controller.todayProgressValues[routineId] ??
        (isManuallyCompleted ? targetVal : 0.0);
    final currentVal = workoutCurrentVal ?? accumulatedVal;
    final bool isActuallyCompleted =
        currentVal >= targetVal || isManuallyCompleted;

    final double progressRatio = targetVal > 0
        ? (currentVal / targetVal).clamp(0.0, 1.0)
        : 0.0;
    final int percent = (progressRatio * 100).toInt();

    final buttonType = this._getRoutineButtonType(routine, isWorkoutRoutine);

    Color cardColor = const Color(0xFF2E5327);
    final colorVal =
        (routine['color'] as num?)?.toInt() ??
        (routine['nColor'] as num?)?.toInt();
    if (colorVal != null && colorVal != 0) {
      cardColor = Color(colorVal);
    }

    final actionButton = this._buildRoutineActionButton(
      context: context,
      routine: routine,
      routineId: routineId,
      buttonType: buttonType,
      isActuallyCompleted: isActuallyCompleted,
      cardColor: cardColor,
      unitText: unitText,
      matchedType: matchedType,
      targetVal: targetVal,
      currentVal: currentVal,
    );

    final cardWidget = RoutineCardWidget(
      routine: routine,
      icon: icon,
      title: title,
      targetVal: targetVal,
      unitText: unitText,
      currentVal: currentVal,
      isWorkoutRoutine: isWorkoutRoutine,
      percent: percent,
      progressRatio: progressRatio,
      cardColor: cardColor,
      actionButton: actionButton,
      threeDotsMenu: this._buildThreeDotsMenu(
        onEdit: () => this._editRoutine(routine),
        onDelete: () => this._deleteRoutine(routineId, title),
      ),
    );

    return TweenAnimationBuilder<double>(
      key: ValueKey('routine_anim_$routineId'),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Interval(
        (index * 0.08).clamp(0.0, 0.6),
        1.0,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: cardWidget,
    );
  }
}
