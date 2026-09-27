import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class CalendarStripWidget extends StatelessWidget {
  final DateTime now;
  final String thaiMonthName;
  final int workoutCount;
  final double totalDistanceKm;
  final double totalCaloriesBurned;
  final Color darkGreen;

  const CalendarStripWidget({
    super.key,
    required this.now,
    required this.thaiMonthName,
    required this.workoutCount,
    required this.totalDistanceKm,
    required this.totalCaloriesBurned,
    this.darkGreen = const Color(0xFF006432),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);

    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    const dayLabels = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'สัปดาห์นี้ • $thaiMonthName ${now.year + 543}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      '🏃 ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade400,
                      ),
                    ),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: workoutCount),
                      duration: const Duration(milliseconds: 2500),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return Text(
                          '$val ครั้งออกกำลังกาย',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Days Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isToday =
                  days[i].day == now.day &&
                  days[i].month == now.month &&
                  days[i].year == now.year;
              final isPast = days[i].isBefore(
                DateTime(now.year, now.month, now.day),
              );
              return _buildDayItem(
                dayLabels[i],
                '${days[i].day}',
                isToday,
                isPast,
                isDark,
              );
            }),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 14,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: totalDistanceKm),
                    duration: const Duration(milliseconds: 2500),
                    curve: Curves.easeOutCubic,
                    builder: (context, distVal, _) {
                      return TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: workoutCount),
                        duration: const Duration(milliseconds: 2500),
                        curve: Curves.easeOutCubic,
                        builder: (context, countVal, _) {
                          return Text(
                            'ออกกำลังกายแล้ว $countVal ครั้ง | ${distVal.toStringAsFixed(1)} กม.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: totalCaloriesBurned),
                duration: const Duration(milliseconds: 2500),
                curve: Curves.easeOutCubic,
                builder: (context, calVal, _) {
                  return Text(
                    '${calVal.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(String day, String date, bool isSelected, bool isPast, bool isDark) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? darkGreen : (isDark ? const Color(0xFFA0ACA0) : Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? darkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.greenAccent
                : (isPast ? darkGreen : (isDark ? const Color(0xFF3B4D41) : Colors.grey.shade300)),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
