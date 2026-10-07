import 'package:flutter/material.dart';

class DashboardMainGoalStats extends StatelessWidget {
  final bool isCompleted;
  final bool isWorkoutGoal;
  final String remainingValText;
  final String deadlineSubText;
  final Widget Function(String, String, {IconData? icon, String? subValue})
  buildGoalStatItem;

  const DashboardMainGoalStats({
    super.key,
    required this.isCompleted,
    required this.isWorkoutGoal,
    required this.remainingValText,
    required this.deadlineSubText,
    required this.buildGoalStatItem,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 16),
      const Divider(height: 1),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildGoalStatItem(
            'สถานะ',
            isCompleted ? 'ทำสำเร็จแล้ว' : 'กำลังดำเนินการ',
            icon: isCompleted ? Icons.check_circle_outline : Icons.timelapse,
          ),
          Container(height: 24, width: 1, color: Colors.grey.shade200),
          buildGoalStatItem(
            'ประเภท',
            isWorkoutGoal ? 'ออกกำลังกาย' : 'กิจวัตร',
            icon: isWorkoutGoal ? Icons.directions_run : Icons.task_alt,
          ),
          Container(height: 24, width: 1, color: Colors.grey.shade200),
          buildGoalStatItem(
            'เหลือเวลา',
            remainingValText,
            subValue: deadlineSubText,
            icon: Icons.calendar_today,
          ),
        ],
      ),
    ],
  );
}
