import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

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
  });

  String _formatValue(double val) =>
      val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(2);

  String _formatProgress(double val) => val.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    final percentBadge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF90DB89) : cardColor,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
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
                child: Icon(icon, color: isDark ? const Color(0xFF90DB89) : cardColor, size: 22),
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
                    const SizedBox(height: 4),

                    if (isWorkoutRoutine) ...[
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF352B1E) : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isDark ? const Color(0xFF5C4018) : Colors.orange.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 12,
                                  color: isDark ? const Color(0xFFFFB74D) : Colors.orange.shade800,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Auto-GPS Sync',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFFFB74D) : Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'เป้าหมาย: ${_formatValue(targetVal)} $unitText',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          percentBadge,
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'เป้าหมายประจำวัน: ${_formatValue(targetVal)} $unitText',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          percentBadge,
                        ],
                      ),
                    ],
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
                      key: ValueKey(percent >= 100 ? 'done_${routine['nRoutineId']}' : 'action_${routine['nRoutineId']}'),
                      child: actionButton,
                    ),
                  ),
                  threeDotsMenu,
                ],
              ),
            ],
          ),


          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ความคืบหน้า',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
              Text(
                '${_formatProgress(currentVal)} / ${_formatValue(targetVal)} $unitText',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF90DB89) : cardColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progressRatio),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: cardColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    cardColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
