// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (dashboard main goal card presentation)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dashboard_main_goal_stats.dart';
class DashboardMainGoalCardPresentation extends StatelessWidget {
  final bool hasPinnedGoal;
  final Color goalColor;
  final IconData goalIcon;
  final String displayTitle;
  final String displayDetail;
  final bool isCompleted;
  final bool isWorkoutGoal;
  final double progress;
  final String remainingValText;
  final String deadlineSubText;
  final Color primaryGreen;
  final VoidCallback? onNavigateToPractice;
  final Widget Function(String, String, {IconData? icon, String? subValue})
  buildGoalStatItem;
  const DashboardMainGoalCardPresentation({
    super.key,
    required this.hasPinnedGoal,
    required this.goalColor,
    required this.goalIcon,
    required this.displayTitle,
    required this.displayDetail,
    required this.isCompleted,
    required this.isWorkoutGoal,
    required this.progress,
    required this.remainingValText,
    required this.deadlineSubText,
    required this.primaryGreen,
    required this.onNavigateToPractice,
    required this.buildGoalStatItem,
  });

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            displayTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                ],
              ),
              if (!hasPinnedGoal)
                TextButton(
                  onPressed: onNavigateToPractice,
                  child: Text(
                    'ปักหมุด >',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

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

          if (hasPinnedGoal)
            DashboardMainGoalStats(
              isCompleted: isCompleted,
              isWorkoutGoal: isWorkoutGoal,
              remainingValText: remainingValText,
              deadlineSubText: deadlineSubText,
              buildGoalStatItem: buildGoalStatItem,
            ),
        ],
      ),
    );
  }
}
