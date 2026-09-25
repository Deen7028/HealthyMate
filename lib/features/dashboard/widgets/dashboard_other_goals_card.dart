// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
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
  final Function(int routineId, bool isDone)? onRoutineToggled;

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
    this.onRoutineToggled,
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
          Row(
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
          const SizedBox(height: 8),

          if (otherRoutines.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: otherRoutines.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                final progress = targetVal > 0
                    ? (currentVal / targetVal).clamp(0.0, 1.0)
                    : 0.0;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.shade50.withValues(alpha: 0.5)
                        : lightBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDone
                          ? Colors.green.shade200
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDone ? Icons.check_circle : icon,
                              color: isDone ? Colors.green.shade700 : color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDone
                                        ? Colors.grey.shade600
                                        : const Color(0xFF1E293B),
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatNum(currentVal)} / ${_formatNum(targetVal)} $unitText',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final updatedState = await AppDatabase.instance
                                  .toggleRoutineLog(
                                routineId: rId,
                                dateStr:
                                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                              );
                              if (onRoutineToggled != null) {
                                onRoutineToggled!(rId, updatedState);
                              }
                              messenger.hideCurrentSnackBar();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        updatedState
                                            ? Icons.check_circle
                                            : Icons.refresh,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          updatedState
                                              ? 'เช็คทำรายการ "$title" เรียบร้อยแล้ว! 🎉'
                                              : 'ยกเลิกการเช็ค "$title" แล้ว',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: updatedState
                                      ? darkGreen
                                      : Colors.grey.shade800,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? Colors.green.shade100
                                    : color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDone
                                      ? Colors.green.shade300
                                      : color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isDone
                                        ? Icons.check_circle_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 14,
                                    color: isDone
                                        ? Colors.green.shade800
                                        : color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isDone ? 'สำเร็จแล้ว' : 'ทำรายการ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDone
                                          ? Colors.green.shade800
                                          : color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDone ? Colors.green : color,
                          ),
                        ),
                      ),
                    ],
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
