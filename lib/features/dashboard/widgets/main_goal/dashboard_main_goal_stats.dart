import 'package:flutter/material.dart';

// คอมโพเนนต์แสดงสถิติสถานะเป้าหมายหลัก (DashboardMainGoalStats)
// จัดวางสถิติ 3 คอลัมน์: สถานะ, ประเภทเป้าหมาย และเหลือเวลา
class DashboardMainGoalStats extends StatelessWidget {
  /// สถานะทำเป้าหมายสำเร็จแล้วหรือไม่
  final bool isCompleted;
  /// เป็นเป้าหมายประเภทออกกำลังกายหรือไม่
  final bool isWorkoutGoal;
  /// ข้อความจำนวนวันที่เหลือ
  final String remainingValText;
  /// ข้อความวันที่สิ้นสุด
  final String deadlineSubText;
  /// ฟังก์ชันสร้าง Widget สถิติย่อย
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
          // 1. สถานะเป้าหมาย (ทำสำเร็จแล้ว / กำลังดำเนินการ)
          buildGoalStatItem(
            'สถานะ',
            isCompleted ? 'ทำสำเร็จแล้ว' : 'กำลังดำเนินการ',
            icon: isCompleted ? Icons.check_circle_outline : Icons.timelapse,
          ),
          Container(height: 24, width: 1, color: Colors.grey.shade200),

          // 2. ประเภทเป้าหมาย (ออกกำลังกาย / กิจวัตร)
          buildGoalStatItem(
            'ประเภท',
            isWorkoutGoal ? 'ออกกำลังกาย' : 'กิจวัตร',
            icon: isWorkoutGoal ? Icons.directions_run : Icons.task_alt,
          ),
          Container(height: 24, width: 1, color: Colors.grey.shade200),

          // 3. เหลือเวลา (จำนวนวัน และวันที่สิ้นสุด)
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

