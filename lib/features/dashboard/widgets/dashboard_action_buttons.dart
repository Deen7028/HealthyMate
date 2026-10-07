// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (dashboard action buttons)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/features/practice/widgets/add_main_goal_bottom_sheet.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/routine_state/routine_state_notifier.dart';

/// ชุดปุ่มลัดสำหรับเริ่มกิจกรรมออกกำลังกาย (วิ่ง เดิน จักรยาน โยคะ สมาธิ) หรือเปิดหน้าต่างตั้งเป้าหมาย
class DashboardActionButtons extends StatelessWidget {
  final Map<String, dynamic>? userGoal;
  final Function(String? category)? onStartWorkout;
  final Function(String? category)? onNavigateToWorkout;
  final VoidCallback? onNavigateToCalculator;
  final VoidCallback? onOpenAddMainGoal;
  final Color darkGreen;

  const DashboardActionButtons({
    super.key,
    required this.userGoal,
    required this.onStartWorkout,
    this.onNavigateToWorkout,
    this.onNavigateToCalculator,
    this.onOpenAddMainGoal,
    this.darkGreen = const Color(0xFF006432),
  });

  @override
  Widget build(BuildContext context) {
    final pinnedTitle = userGoal?['sTitle']?.toString() ?? '';
    String buttonText = 'เริ่มวิ่งมินิมาราธอน (30 นาที)';
    IconData buttonIcon = Icons.bolt;
    bool isWeightGoal = false;
    String? targetWorkoutCategory = 'running';

    if (pinnedTitle.isNotEmpty) {
      final lower = pinnedTitle.toLowerCase();
      if (lower.contains('น้ำหนัก') || lower.contains('ลดน้ำหนัก')) {
        isWeightGoal = true;
        buttonText = lower.contains('บันทึก') ? pinnedTitle : 'บันทึก$pinnedTitle';
        buttonIcon = Icons.monitor_weight_outlined;
        targetWorkoutCategory = null;
      } else if (lower.contains('จักรยาน') || lower.contains('ปั่น')) {
        buttonText = 'เริ่ม$pinnedTitle';
        buttonIcon = Icons.directions_bike;
        targetWorkoutCategory = 'cycling';
      } else if (lower.contains('แคลอรี') || lower.contains('เผาผลาญ')) {
        buttonText = 'เริ่ม$pinnedTitle';
        buttonIcon = Icons.local_fire_department_rounded;
        targetWorkoutCategory = 'selectingCategory';
      } else if (lower.contains('สมาธิ') || lower.contains('ฝึกสติ')) {
        buttonText = 'จับเวลา$pinnedTitle';
        buttonIcon = Icons.self_improvement;
        targetWorkoutCategory = 'meditation';
      } else if (lower.contains('โยคะ')) {
        buttonText = 'เริ่ม$pinnedTitle';
        buttonIcon = Icons.spa_rounded;
        targetWorkoutCategory = 'yoga';
      } else if (lower.contains('น้ำ') || lower.contains('ดื่ม')) {
        buttonText = 'บันทึก$pinnedTitle';
        buttonIcon = Icons.water_drop;
        targetWorkoutCategory = null;
      } else if (lower.contains('เดิน')) {
        buttonText = 'เริ่ม$pinnedTitle';
        buttonIcon = Icons.directions_walk;
        targetWorkoutCategory = 'walking';
      } else if (lower.contains('วิ่ง')) {
        buttonText = 'เริ่ม$pinnedTitle';
        buttonIcon = Icons.directions_run;
        targetWorkoutCategory = 'running';
      } else {
        buttonText = 'เริ่ม$pinnedTitle';
        buttonIcon = Icons.fitness_center;
        targetWorkoutCategory = 'selectingCategory';
      }
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              if (isWeightGoal && onNavigateToCalculator != null) {
                onNavigateToCalculator!();
              } else if (onStartWorkout != null) {
                onStartWorkout!(targetWorkoutCategory);
              } else if (onNavigateToWorkout != null) {
                onNavigateToWorkout!(targetWorkoutCategory);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(buttonIcon, color: Colors.yellow),
                const SizedBox(width: 8),
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () async {
              if (onOpenAddMainGoal != null) {
                onOpenAddMainGoal!();
                return;
              }
              final result = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                builder: (context) => const AddMainGoalBottomSheet(),
              );

              if (result != null) {
                final title = result['title']?.toString() ?? '';
                final icon = result['icon']?.toString() ?? '🚩';
                final unit = result['unit']?.toString() ?? '';
                final targetVal =
                    (result['targetValue'] as num?)?.toDouble() ?? 1.0;
                final deadlineDate =
                    result['deadlineDate'] as DateTime? ??
                    DateTime.now().add(const Duration(days: 30));
                final now = DateTime.now();
                final remainingDays = deadlineDate
                    .difference(now)
                    .inDays
                    .clamp(1, 9999);
                final deadlineStr =
                    '${deadlineDate.day.toString().padLeft(2, '0')}/${deadlineDate.month.toString().padLeft(2, '0')}/${deadlineDate.year + 543}';
                final remainingText =
                    'เป้าหมาย: 0 / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unit (เหลือ $remainingDays วัน • สิ้นสุด $deadlineStr)';

                final user = await AppDatabase.instance.getCurrentUser();
                if (user != null) {
                  await AppDatabase.instance.saveUserGoal(
                    userId: user.nUserId,
                    nRoutineId: 0,
                    title: '$icon $title',
                    progress: 0.0,
                    remainingText: remainingText,
                  );
                  RoutineStateNotifier.instance.loadData(
                    userId: user.nUserId,
                  );
                }

                final isWeightGoal = (result['isWeightGoal'] as bool?) == true ||
                    title.contains('ลดน้ำหนัก') ||
                    (result['linkedWorkout']?.toString() ?? '') == 'น้ำหนัก';

                if (isWeightGoal && onNavigateToCalculator != null) {
                  onNavigateToCalculator!();
                }
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_calls, color: Colors.black54),
                SizedBox(width: 8),
                Text(
                  'เลือกประเภทอื่น',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
