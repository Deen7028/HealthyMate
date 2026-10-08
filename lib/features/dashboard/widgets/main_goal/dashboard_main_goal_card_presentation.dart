import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dashboard_main_goal_stats.dart';

// ส่วนแสดงผล UI ของการ์ดเป้าหมายหลักในแดชบอร์ด (DashboardMainGoalCardPresentation)
// แสดงข้อมูลไอคอน, รายละเอียดเป้าหมาย, วงแหวนเปอร์เซ็นต์ความคืบหน้า และปุ่มปักหมุด
class DashboardMainGoalCardPresentation extends StatelessWidget {
  /// มีเป้าหมายที่ปักหมุดไว้หรือไม่
  final bool hasPinnedGoal;
  /// สีประจำเป้าหมาย
  final Color goalColor;
  /// ไอคอนประจำเป้าหมาย
  final IconData goalIcon;
  /// ชื่อเป้าหมาย
  final String displayTitle;
  /// รายละเอียดเป้าหมาย
  final String displayDetail;
  /// สถานะทำสำเร็จแล้วหรือไม่
  final bool isCompleted;
  /// เป็นเป้าหมายออกกำลังกายหรือไม่
  final bool isWorkoutGoal;
  /// อัตราส่วนความคืบหน้า (0.0 - 1.0)
  final double progress;
  /// ข้อความจำนวนวันที่เหลือ
  final String remainingValText;
  /// ข้อความวันที่สิ้นสุด
  final String deadlineSubText;
  /// สีเขียวหลัก
  final Color primaryGreen;
  /// Callback เมื่อกดปุ่มไปหน้าฝึกฝน/กิจวัตร
  final VoidCallback? onNavigateToPractice;
  /// ฟังก์ชันสร้าง Widget สถิติย่อย
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
