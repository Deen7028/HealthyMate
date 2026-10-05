// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine notification page card actions)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_notification_page.dart';

extension _RoutineNotificationCardActions on _MyRoutinesPageState {
  Widget _buildRoutineActionButton({
    required BuildContext context,
    required Map<String, dynamic> routine,
    required int routineId,
    required RoutineButtonType buttonType,
    required bool isActuallyCompleted,
    required Color cardColor,
    required String unitText,
    required String matchedType,
    required double targetVal,
    required double currentVal,
  }) {
    String formatValue(double val) =>
        val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(2);

    Widget actionButton;
    if (isActuallyCompleted) {
      actionButton = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              buttonType == RoutineButtonType.stepAdd
                  ? ' ครบแล้ว'
                  : ' เสร็จแล้ว',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else if (buttonType == RoutineButtonType.workout) {
      actionButton = ElevatedButton.icon(
        onPressed: () {
          if (widget.onNavigateToWorkout != null) {
            int? durationMin;
            if (unitText.contains('นาที') ||
                unitText.contains('min') ||
                matchedType.contains('สมาธิ') ||
                matchedType.contains('โยคะ')) {
              final double remainingVal = (targetVal - currentVal).clamp(
                0.0,
                double.infinity,
              );
              durationMin = remainingVal > 0
                  ? remainingVal.ceil()
                  : (targetVal > 0 ? targetVal.toInt() : 15);
            }
            widget.onNavigateToWorkout!(matchedType, durationMin);
          }
        },
        icon: const Icon(
          Icons.play_arrow_rounded,
          size: 16,
          color: Colors.white,
        ),
        label: const Text(
          'เริ่มเลย',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: cardColor,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (buttonType == RoutineButtonType.stepAdd) {
      final stepAmount = this._calculateStepAmount(targetVal, unitText);
      final stepStr = formatValue(stepAmount);
      actionButton = InkWell(
        onTap: () => _controller.incrementRoutineValue(routineId, stepAmount),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cardColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: cardColor),
              const SizedBox(width: 3),
              Text(
                '+$stepStr $unitText',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (buttonType == RoutineButtonType.timer) {
      final durationMin = targetVal > 0 ? targetVal.toInt() : 15;
      actionButton = InkWell(
        onTap: () =>
            this._showCountdownTimerDialog(context, routine, durationMin),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cardColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 14, color: cardColor),
              const SizedBox(width: 4),
              Text(
                '⏱️ $durationMin นาที',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      actionButton = InkWell(
        onTap: () => _controller.toggleRoutineCompletion(routineId),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_task_rounded, size: 14, color: cardColor),
              const SizedBox(width: 4),
              Text(
                'บันทึก',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return actionButton;
  }
}
