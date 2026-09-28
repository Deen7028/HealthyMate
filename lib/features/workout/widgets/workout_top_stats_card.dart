import 'package:flutter/material.dart';
import 'package:healthymate/features/workout/models/workout_models.dart';

class WorkoutTopStatsCard extends StatelessWidget {
  final WorkoutCategory category;
  final bool isRunning;
  final AppMapType mapType;
  final String formattedTime;
  final double distanceKm;
  final double caloriesBurned;
  final Animation<double> pulseAnimation;
  final VoidCallback? onChangeCategoryTap;
  final bool isCountdownMode;

  const WorkoutTopStatsCard({
    super.key,
    required this.category,
    required this.isRunning,
    required this.mapType,
    required this.formattedTime,
    required this.distanceKm,
    required this.caloriesBurned,
    required this.pulseAnimation,
    this.onChangeCategoryTap,
    this.isCountdownMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkModeMap =
        mapType == AppMapType.hybrid || mapType == AppMapType.satellite;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkModeMap
            ? const Color(0xFF1E281F).withValues(alpha: 0.95)
            : const Color(0xFFF7FAF7).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDarkModeMap ? Colors.white24 : Colors.white,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onChangeCategoryTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkModeMap
                        ? const Color(0xFF74B46E).withValues(alpha: 0.25)
                        : const Color(0xFF2E5327).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.icon,
                        size: 16,
                        color: isDarkModeMap
                            ? const Color(0xFF90DB89)
                            : const Color(0xFF2E5327),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDarkModeMap
                              ? const Color(0xFF90DB89)
                              : const Color(0xFF2E5327),
                        ),
                      ),
                      if (onChangeCategoryTap != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: isDarkModeMap
                              ? const Color(0xFF90DB89)
                              : const Color(0xFF2E5327),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isRunning)
                FadeTransition(
                  opacity: pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        CircleAvatar(radius: 4, backgroundColor: Colors.redAccent),
                        SizedBox(width: 6),
                        Text(
                          'กำลังบันทึก',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            isCountdownMode ? 'เวลานับถอยหลัง' : 'เวลา',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkModeMap ? const Color(0xFFA0ACA0) : const Color(0xFF5A665A),
              letterSpacing: 0.2,
            ),
          ),

          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: isDarkModeMap ? Colors.white : const Color(0xFF1E281F),
              letterSpacing: -1,
            ),
          ),

          Divider(
            height: 1,
            color: isDarkModeMap ? Colors.white12 : const Color(0xFFE4ECE2),
          ),

          Row(
            children: [
              if (category.isMoving) ...[
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'ระยะทาง',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkModeMap ? const Color(0xFFA0ACA0) : const Color(0xFF677366),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: distanceKm),
                        duration: const Duration(milliseconds: 2500),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, _) {
                          return RichText(
                            text: TextSpan(
                              text: val.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: isDarkModeMap ? const Color(0xFF90DB89) : const Color(0xFF2E5327),
                                letterSpacing: -0.5,
                              ),
                              children: [
                                TextSpan(
                                  text: ' km',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkModeMap ? const Color(0xFFA0ACA0) : const Color(0xFF5A665A),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 36,
                  width: 1,
                  color: isDarkModeMap ? Colors.white12 : const Color(0xFFE4ECE2),
                ),
              ],

              Expanded(
                child: Column(
                  children: [
                    Text(
                      'แคลอรี',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDarkModeMap ? const Color(0xFFA0ACA0) : const Color(0xFF677366),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: caloriesBurned),
                      duration: const Duration(milliseconds: 2500),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return RichText(
                          text: TextSpan(
                            text: val.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: isDarkModeMap ? Colors.white : const Color(0xFF1E281F),
                              letterSpacing: -0.5,
                            ),
                            children: [
                              TextSpan(
                                text: ' kcal',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkModeMap ? const Color(0xFFA0ACA0) : const Color(0xFF5A665A),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
