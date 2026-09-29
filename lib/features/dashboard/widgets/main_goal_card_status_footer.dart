import 'package:flutter/material.dart';

class MainGoalCardStatusFooter extends StatelessWidget {
  final bool isCompleted;
  final bool hasPinnedGoal;
  final String remainingValText;
  final String deadlineSubText;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Widget Function(
    String,
    String,
    Color,
    Color, {
    IconData? icon,
    String? subValue,
  })
  buildGoalStatItem;

  const MainGoalCardStatusFooter({
    super.key,
    required this.isCompleted,
    required this.hasPinnedGoal,
    required this.remainingValText,
    required this.deadlineSubText,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.buildGoalStatItem,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
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
        Divider(height: 1, color: borderColor),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildGoalStatItem(
              'สถานะ',
              isCompleted ? 'ทำสำเร็จแล้ว' : 'กำลังดำเนินการ',
              textPrimary,
              textSecondary,
              icon: isCompleted ? Icons.check_circle_outline : Icons.timelapse,
            ),
            Container(height: 28, width: 1, color: borderColor),
            buildGoalStatItem(
              'เหลือเวลา',
              remainingValText,
              textPrimary,
              textSecondary,
              subValue: deadlineSubText,
              icon: Icons.calendar_today,
            ),
          ],
        ),
      ],
    ],
  );
}
