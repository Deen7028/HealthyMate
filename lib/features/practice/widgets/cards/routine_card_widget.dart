import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
part 'routine_card_progress.dart';
// การ์ดแสดงรายการกิจวัตรแต่ละรายการ
enum RoutineButtonType { workout, stepAdd, timer, singleCheck }
class RoutineCardWidget extends StatelessWidget {
  final Map<String, dynamic> routine;
  final IconData icon;
  final String title;
  final double targetVal;
  final String unitText;
  final double currentVal;
  final bool isWorkoutRoutine;
  final int percent;
  final double progressRatio;
  final Widget actionButton;
  final Widget threeDotsMenu;
  final Color cardColor;
  final VoidCallback? onEdit;
  const RoutineCardWidget({
    super.key,
    required this.routine,
    required this.icon,
    required this.title,
    required this.targetVal,
    required this.unitText,
    required this.currentVal,
    required this.isWorkoutRoutine,
    required this.percent,
    required this.progressRatio,
    required this.actionButton,
    required this.threeDotsMenu,
    this.cardColor = const Color(0xFF2E5327),
    this.onEdit,
  });
  String _formatValue(double val) =>
      val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(2);
  String _formatProgress(double val) =>
      val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(2);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final String sRawTime =
        (routine['sTime'] ?? routine['time'])?.toString() ?? '';
    final String sFormattedTime = _formatNotificationTime(sRawTime);
    final bool isNotificationActive = (routine['isNotificationActive'] == 1 ||
        routine['isNotificationActive'] == true ||
        routine['isNotificationActive'] == null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: cardColor.withValues(alpha: 0.25)),
                ),
                child: Icon(
                  icon,
                  color: isDark ? const Color(0xFF90DB89) : cardColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _buildRoutineMetaWrap(
                      sFormattedTime: sFormattedTime,
                      isNotificationActive: isNotificationActive,
                      isDark: isDark,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(
                        percent >= 100
                            ? 'done_${routine['nRoutineId']}'
                            : 'action_${routine['nRoutineId']}',
                      ),
                      child: actionButton,
                    ),
                  ),
                  threeDotsMenu,
                ],
              ),
            ],
          ),
          _buildProgressSection(isDark, textSecondary),
        ],
      ),
    ),
    ),
    );
  }
}
