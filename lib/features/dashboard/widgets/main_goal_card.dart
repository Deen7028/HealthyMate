import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/routine_state_notifier.dart';
import 'package:healthymate/features/practice/widgets/add_main_goal_bottom_sheet.dart';
import '../controllers/dashboard_controller.dart';
import '../utils/dashboard_ui_helpers.dart';


class MainGoalCard extends StatelessWidget {
  final DashboardController controller;
  final VoidCallback? onNavigateToPractice;

  const MainGoalCard({
    super.key,
    required this.controller,
    this.onNavigateToPractice,
  });

  @override
  Widget build(BuildContext context) {
    final userGoal = controller.userGoal;
    final routines = controller.routines;
    final todayCompletionMap = controller.todayCompletionMap;
    final todayWorkoutStats = controller.todayWorkoutStats;
    final now = controller.now;

    final hasPinnedGoal = userGoal != null;
    final pinnedRoutineId = (userGoal?['nRoutineId'] as num?)?.toInt() ?? 0;

    Map<String, dynamic>? pinnedRoutine;
    if (hasPinnedGoal) {
      for (final r in routines) {
        final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        if ((pinnedRoutineId > 0 && rId == pinnedRoutineId) ||
            (r['sTitle'] == userGoal['sTitle'])) {
          pinnedRoutine = r;
          break;
        }
      }
    }

    final double progress;
    final String displayTitle;
    final String displayDetail;
    final Color goalColor;
    final IconData goalIcon;
    bool isCompleted = false;
    bool isWorkoutGoal = false;

    if (pinnedRoutine != null) {
      final title = pinnedRoutine['sTitle']?.toString() ?? 'เป้าหมายหลัก';
      final targetVal =
          (pinnedRoutine['targetValue'] as num?)?.toDouble() ?? 1.0;
      final unitText = pinnedRoutine['unit']?.toString() ?? 'ครั้ง';
      goalColor = DashboardUiHelpers.getRoutineColor(pinnedRoutine, 0);
      goalIcon = DashboardUiHelpers.getRoutineIcon(pinnedRoutine, 0);

      final lowerTitle = title.toLowerCase();
      String matchedType = pinnedRoutine['sLinkedWorkout']?.toString() ?? '';
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
      if (matchedType.isNotEmpty) {
        isWorkoutGoal = true;
      }

      if (matchedType.isNotEmpty &&
          todayWorkoutStats.containsKey(matchedType)) {
        final stats = todayWorkoutStats[matchedType]!;
        if (unitText.contains('กม') ||
            unitText.contains('กิโล') ||
            unitText.contains('km')) {
          workoutVal = stats['distance'];
        } else if (unitText.contains('ชม') ||
            unitText.contains('ชั่วโมง') ||
            unitText.contains('hour') ||
            unitText.contains('hr')) {
          workoutVal = (stats['duration'] ?? 0.0) / 60.0;
        } else if (unitText.contains('นาที') ||
            unitText.contains('min') ||
            unitText.contains('เวลา')) {
          workoutVal = stats['duration'];
        } else if (unitText.contains('แคล') || unitText.contains('cal')) {
          workoutVal = stats['caloriesBurned'];
        }
      }

      final routineId = (pinnedRoutine['nRoutineId'] as num?)?.toInt() ?? 0;
      final isDone = todayCompletionMap[routineId] ?? false;
      final currentVal =
          workoutVal ??
          (isDone
              ? targetVal
              : ((pinnedRoutine['currentValue'] as num?)?.toDouble() ?? 0.0));

      progress = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
      final percent = (progress * 100).toInt();
      isCompleted = progress >= 1.0 || isDone;

      displayTitle = title;
      displayDetail =
          'ความคืบหน้าวันนี้: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
    } else if (hasPinnedGoal) {
      progress =
          (userGoal['nProgress'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0;
      goalColor = const Color(0xFF0F9C58);
      goalIcon = Icons.flag_rounded;
      isCompleted = progress >= 1.0;

      displayTitle = userGoal['sTitle']?.toString() ?? 'เป้าหมายหลัก';
      final remaining = userGoal['sRemainingText']?.toString() ?? '';
      displayDetail = remaining.isNotEmpty
          ? remaining
          : 'ทำสำเร็จแล้ว ${(progress * 100).toInt()}%';
    } else {
      progress = 0.0;
      goalColor = const Color(0xFF0F9C58);
      goalIcon = Icons.push_pin_outlined;
      displayTitle = 'ยังไม่ได้ปักหมุดเป้าหมายหลัก';
      displayDetail =
          'เลือกปักหมุดกิจวัตรสำคัญจากหน้ากิจวัตรเพื่อติดตามความคืบหน้า';
    }

    final daysRemaining = DateTime(
      now.year,
      now.month + 1,
      0,
    ).difference(now).inDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasPinnedGoal
              ? goalColor.withValues(alpha: 0.25)
              : Colors.grey.shade200,
          width: hasPinnedGoal ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: goalColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(goalIcon, color: goalColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasPinnedGoal) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.push_pin,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayDetail,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted
                            ? Colors.green.shade700
                            : Colors.grey,
                        fontWeight: isCompleted
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!hasPinnedGoal) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await showModalBottomSheet<Map<String, dynamic>>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    builder: (context) => const AddMainGoalBottomSheet(),
                  );
                  if (result != null && controller.user != null) {
                    final title = result['title']?.toString() ?? '';
                    final icon = result['icon']?.toString() ?? '🚩';
                    final unit = result['unit']?.toString() ?? '';
                    final targetVal = (result['targetValue'] as num?)?.toDouble() ?? 1.0;
                    final deadlineDate = result['deadlineDate'] as DateTime? ?? DateTime.now().add(const Duration(days: 30));
                    final now = DateTime.now();
                    final remainingDays = deadlineDate.difference(now).inDays.clamp(1, 9999);
                    final deadlineStr = '${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year}';
                    final remainingText = 'เป้าหมาย: 0 / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unit (เหลือ $remainingDays วัน • สิ้นสุด $deadlineStr)';

                    await AppDatabase.instance.saveUserGoal(
                      userId: controller.user!.nUserId,
                      nRoutineId: 0,
                      title: '$icon $title',
                      progress: 0.0,
                      remainingText: remainingText,
                    );
                    RoutineStateNotifier.instance.loadData(userId: controller.user!.nUserId);
                  }
                },
                icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.white),
                label: const Text(
                  '+ ตั้งเป้าหมายหลัก (Set Main Goal)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006432),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),

            CircularPercentIndicator(
              radius: 54.0,
              lineWidth: 9.0,
              percent: progress,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: goalColor,
                    ),
                  ),
                  Text(
                    isCompleted ? 'สำเร็จ!' : 'ความคืบหน้า',
                    style: TextStyle(
                      fontSize: 9,
                      color: isCompleted ? Colors.green.shade800 : Colors.grey,
                      fontWeight: isCompleted
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              progressColor: goalColor,
              backgroundColor: goalColor.withValues(alpha: 0.12),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
            ),
          ],


          if (isCompleted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'ทำเป้าหมายสำเร็จแล้ววันนี้! 🎉',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (hasPinnedGoal) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGoalStatItem(
                  'สถานะ',
                  isCompleted ? 'ทำสำเร็จแล้ว' : 'กำลังดำเนินการ',
                  icon: isCompleted
                      ? Icons.check_circle_outline
                      : Icons.timelapse,
                ),
                Container(height: 24, width: 1, color: Colors.grey.shade200),
                _buildGoalStatItem(
                  'ประเภท',
                  isWorkoutGoal ? 'ออกกำลังกาย' : 'กิจวัตร',
                  icon: isWorkoutGoal ? Icons.directions_run : Icons.task_alt,
                ),
                Container(height: 24, width: 1, color: Colors.grey.shade200),
                _buildGoalStatItem(
                  'เหลือเวลา',
                  '$daysRemaining วัน',
                  icon: Icons.calendar_today,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalStatItem(String title, String value, {IconData? icon}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
            ],
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}