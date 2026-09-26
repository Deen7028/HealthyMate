import 'package:flutter/material.dart';
import '../utils/dashboard_ui_helpers.dart';

class DashboardOtherGoalsCard extends StatelessWidget {
  final Map<String, dynamic>? userGoal;
  final List<Map<String, dynamic>> routines;
  final Map<int, bool> todayCompletionMap;
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
    required this.todayWorkoutStats,
    required this.now,
    required this.darkGreen,
    required this.lightBg,
    this.onNavigateToPractice,
  });

  String _formatNum(double val) =>
      val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
              separatorBuilder: (context, index) => const Divider(height: 12, thickness: 0.5),
              itemBuilder: (context, index) {
                final routine = otherRoutines[index];
                final rId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
                final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';
                final targetVal =
                    (routine['targetValue'] as num?)?.toDouble() ?? 1.0;
                final unitText = routine['unit']?.toString() ?? 'ครั้ง';
                final color = DashboardUiHelpers.getRoutineColor(routine, index);
                final icon = DashboardUiHelpers.getRoutineIcon(routine, index);

                final lowerTitle = title.toLowerCase();
                String matchedType =
                    routine['sLinkedWorkout']?.toString() ?? '';
                if (matchedType.isEmpty) {
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

                double? workoutVal;
                if (matchedType.isNotEmpty &&
                    todayWorkoutStats.containsKey(matchedType)) {
                  final stats = todayWorkoutStats[matchedType]!;
                  if (unitText.contains('กม') ||
                      unitText.contains('กิโล') ||
                      unitText.contains('km')) {
                    workoutVal = stats['distance'];
                  } else if (unitText.contains('นาที') ||
                      unitText.contains('min') ||
                      unitText.contains('เวลา') ||
                      unitText.contains('ชม')) {
                    workoutVal = stats['duration'];
                  }
                }

                final isDone = todayCompletionMap[rId] ?? false;
                final currentVal = workoutVal ??
                    (isDone
                        ? targetVal
                        : ((routine['currentValue'] as num?)?.toDouble() ??
                            0.0));

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
                            color: isDone
                                ? Colors.green.withValues(alpha: 0.15)
                                : color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDone ? Icons.check_circle_rounded : icon,
                            color: isDone ? Colors.green.shade700 : color,
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
                                  color: isDone ? Colors.grey.shade500 : const Color(0xFF1E293B),
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isDone
                                    ? 'ทำสำเร็จแล้ววันนี้'
                                    : 'ความคืบหน้า: ${_formatNum(currentVal)} / ${_formatNum(targetVal)} $unitText',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDone ? Colors.green.shade600 : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 3. ป้ายกำกับสถานะ (Badge เล็กๆ แทนหลอด Progress ใหญ่ๆ)
                        if (!isDone)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'รอทำรายการ',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'ยังไม่ได้เพิ่มเป้าหมายอื่นๆ',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
