import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class RoutineMainGoalCard extends StatelessWidget {
  final Map<String, dynamic>? userGoal;
  final int completedCount;
  final int totalRoutinesCount;
  final VoidCallback onUnpin;
  final VoidCallback? onSetMainGoal;
  final Function(String? workoutCategory, [int? targetDurationMinutes])? onNavigateToWorkout;
  final Color cardGreenBg;
  final Color primaryGreen;
  final Color darkGreen;

  const RoutineMainGoalCard({
    super.key,
    required this.userGoal,
    required this.completedCount,
    required this.totalRoutinesCount,
    required this.onUnpin,
    this.onSetMainGoal,
    this.onNavigateToWorkout,
    this.cardGreenBg = const Color(0xFFE8F5E9),
    this.primaryGreen = const Color(0xFF0F9C58),
    this.darkGreen = const Color(0xFF006432),
  });

  @override
  Widget build(BuildContext context) {
    final goalTitle = userGoal?['sTitle']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final innerCardBg = AppTheme.getBackgroundColor(isDark);

    if (goalTitle.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2822) : cardGreenBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryGreen.withValues(alpha: isDark ? 0.4 : 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.flag_rounded, color: isDark ? const Color(0xFF90DB89) : darkGreen, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ยังไม่มีเป้าหมายหลัก',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF90DB89) : darkGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ตั้งเป้าหมายภาพรวม เช่น วิ่งสะสมระยะทาง หรือเผาผลาญแคลอรี',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onSetMainGoal,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  '+ ตั้งเป้าหมายหลัก (Set Main Goal)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final goalProgress = (userGoal?['nProgress'] as num?)?.toDouble() ?? 0.0;
    final goalRemaining = userGoal?['sRemainingText']?.toString() ?? '';
    final String subtitle =
        (goalRemaining.isNotEmpty
                ? goalRemaining
                      .replaceAll(RegExp(r'\s*\(\s*เหลือ[^)]*\)'), '')
                      .trim()
                : 'ทำสำเร็จแล้ว ${(goalProgress * 100).toInt()}%')
            .replaceAll(RegExp(r'\s*\(\s*เหลือ[^)]*\)'), '')
            .trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : cardGreenBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: isDark ? 0.4 : 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: darkGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🚩 กิจวัตรจากเป้าหมายหลัก',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.grey,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'unpin') onUnpin();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'unpin',
                      child: Row(
                        children: [
                          Icon(Icons.close, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Text('ยกเลิกเป้าหมายหลัก'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              if (onNavigateToWorkout != null) {
                final lower = goalTitle.toLowerCase();
                String category = 'selectingCategory';
                if (lower.contains('สมาธิ') || lower.contains('meditation')) {
                  category = 'meditation';
                } else if (lower.contains('โยคะ') || lower.contains('yoga')) {
                  category = 'yoga';
                } else if (lower.contains('วิ่ง') || lower.contains('running')) {
                  category = 'running';
                } else if (lower.contains('เดิน') || lower.contains('walking')) {
                  category = 'walking';
                } else if (lower.contains('ปั่น') || lower.contains('จักรยาน') || lower.contains('cycling')) {
                  category = 'cycling';
                }
                
                int? durationMinutes;
                final targetVal = (userGoal?['targetValue'] as num?)?.toDouble() ??
                    (userGoal?['nTargetValue'] as num?)?.toDouble();
                final currentVal = (userGoal?['currentValue'] as num?)?.toDouble() ??
                    (userGoal?['nCurrentValue'] as num?)?.toDouble() ?? 0.0;
                final unit = (userGoal?['unit'] ?? userGoal?['sUnit'])?.toString().toLowerCase() ?? '';
                if (targetVal != null && (unit.contains('นาที') || unit.contains('min') || category == 'meditation')) {
                  final remaining = (targetVal - currentVal).clamp(0.0, double.infinity);
                  durationMinutes = remaining > 0 ? remaining.ceil() : targetVal.toInt();
                }
                
                onNavigateToWorkout!(category, durationMinutes);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: innerCardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: darkGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.flag, color: isDark ? const Color(0xFF90DB89) : darkGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goalTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onNavigateToWorkout != null)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: darkGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: isDark ? const Color(0xFF90DB89) : darkGreen,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
