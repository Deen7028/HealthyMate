import 'package:flutter/material.dart';

// ส่วนท้ายแสดงสถานะเป้าหมายหลัก (MainGoalCardStatusFooter)
// แสดงแบดจ์เมื่อทำเป้าหมายสำเร็จแล้ว และแสดงสถิติ 'สถานะ' กับ 'เหลือเวลา'
class MainGoalCardStatusFooter extends StatelessWidget {
  /// สถานะทำเป้าหมายสำเร็จแล้วหรือไม่
  final bool isCompleted;
  /// มีเป้าหมายที่ปักหมุดไว้หรือไม่
  final bool hasPinnedGoal;
  /// ข้อความจำนวนวันที่เหลือ (เช่น 'อีก 5 วัน')
  final String remainingValText;
  /// ข้อความวันที่สิ้นสุด (เช่น 'สิ้นสุด 25/10/2569')
  final String deadlineSubText;
  /// สีกรอบเส้นขอบ
  final Color borderColor;
  /// สีข้อความหลัก
  final Color textPrimary;
  /// สีข้อความรอง
  final Color textSecondary;
  /// ฟังก์ชันเรนเดอร์ไอเทมสถิติ
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
      // 1. แบดจ์แสดงความยินดีเมื่อทำเป้าหมายสำเร็จประจำวัน
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

      // 2. แถวสถิติสรุปสถานะและเวลาที่เหลือ (แสดงเฉพาะเมื่อมีเป้าหมายปักหมุด)
      if (hasPinnedGoal) ...[
        const SizedBox(height: 16),
        Divider(height: 1, color: borderColor),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // สถานะ (ทำสำเร็จแล้ว / กำลังดำเนินการ)
            buildGoalStatItem(
              'สถานะ',
              isCompleted ? 'ทำสำเร็จแล้ว' : 'กำลังดำเนินการ',
              textPrimary,
              textSecondary,
              icon: isCompleted ? Icons.check_circle_outline : Icons.timelapse,
            ),
            Container(height: 28, width: 1, color: borderColor),
            // เหลือเวลา (จำนวนวัน และ วันที่สิ้นสุด)
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

