import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import '../utils/dashboard_ui_helpers.dart';

part 'dashboard_other_goals_card_item.dart';

/// การ์ดแสดงรายการเป้าหมายย่อยและกิจวัตรประจำวันอื่นๆ (Routines & Goals)
class DashboardOtherGoalsCard extends StatelessWidget {
  final Map<String, dynamic>? userGoal;
  final List<Map<String, dynamic>> routines;
  final Map<int, bool> todayCompletionMap;
  final Map<int, double> todayProgressValues;
  final Map<String, Map<String, double>> todayWorkoutStats;
  final DateTime now;
  final Color darkGreen;
  final Color lightBg;
  final VoidCallback? onNavigateToPractice;

  const DashboardOtherGoalsCard({
    super.key,
    this.userGoal,
    required this.routines,
    required this.todayCompletionMap,
    this.todayProgressValues = const {},
    required this.todayWorkoutStats,
    required this.now,
    required this.darkGreen,
    required this.lightBg,
    this.onNavigateToPractice,
  });

  String _formatNum(double val) =>
      val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    final pinnedRoutineId = (userGoal?['nRoutineId'] as num?)?.toInt() ?? 0;
    final pinnedTitle = userGoal?['sTitle']?.toString() ?? '';

    // กรองเอากิจวัตรอื่นๆ ที่ไม่ได้ปักหมุด
    final otherRoutines = routines.where((r) {
      final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
      final rTitle = r['sTitle']?.toString() ?? '';
      if (pinnedRoutineId > 0 && rId == pinnedRoutineId) return false;
      if (pinnedRoutineId == 0 &&
          pinnedTitle.isNotEmpty &&
          rTitle == pinnedTitle) {
        return false;
      }
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onNavigateToPractice,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.format_list_bulleted_rounded,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      otherRoutines.isNotEmpty
                          ? 'เป้าหมายอื่นๆ (${otherRoutines.length})'
                          : 'เป้าหมายอื่นๆ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onNavigateToPractice,
                  child: const Text(
                    'ดูทั้งหมด >',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (otherRoutines.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: otherRoutines.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 12, thickness: 0.5, color: borderColor),
              itemBuilder: (context, index) {
                return _buildRoutineItem(
                  context,
                  index,
                  otherRoutines[index],
                  isDark,
                  textPrimary,
                  textSecondary,
                );
              },
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'ยังไม่ได้เพิ่มเป้าหมายอื่นๆ',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
