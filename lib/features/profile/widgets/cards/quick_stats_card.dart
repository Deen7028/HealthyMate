import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/index.dart';
// การ์ดสำหรับแสดงสถิติย่อ
class QuickStatsCard extends StatelessWidget {
  final int workoutCount;
  final int activeDays;

  const QuickStatsCard({
    super.key,
    required this.workoutCount,
    required this.activeDays,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สถิติย่อ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextSecondaryColor(isDark),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ครั้ง',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: workoutCount),
                      duration: const Duration(milliseconds: 2500),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return Text(
                          '$val',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.getTextPrimaryColor(isDark),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.getBorderColor(isDark),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'วัน',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: activeDays),
                        duration: const Duration(milliseconds: 2500),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, _) {
                          return Text(
                            '$val',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.getTextPrimaryColor(isDark),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
