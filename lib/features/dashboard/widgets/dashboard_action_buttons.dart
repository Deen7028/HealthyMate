import 'package:flutter/material.dart';

class DashboardActionButtons extends StatelessWidget {
  final Map<String, dynamic>? userGoal;
  final VoidCallback onStartWorkout;
  final VoidCallback? onNavigateToWorkout;
  final Color darkGreen;

  const DashboardActionButtons({
    super.key,
    required this.userGoal,
    required this.onStartWorkout,
    this.onNavigateToWorkout,
    this.darkGreen = const Color(0xFF006432),
  });

  @override
  Widget build(BuildContext context) {
    final pinnedTitle = userGoal?['sTitle']?.toString() ?? '';
    String buttonText = 'เริ่มวิ่งมินิมาราธอน (30 นาที)';
    IconData buttonIcon = Icons.bolt;

    if (pinnedTitle.isNotEmpty) {
      final lower = pinnedTitle.toLowerCase();
      if (lower.contains('จักรยาน') || lower.contains('ปั่น')) {
        buttonText = 'เริ่ม$pinnedTitle';
        buttonIcon = Icons.directions_bike;
      } else if (lower.contains('สมาธิ') || lower.contains('ฝึกสติ')) {
        buttonText = 'จับเวลา$pinnedTitle';
        buttonIcon = Icons.self_improvement;
      } else if (lower.contains('น้ำ') || lower.contains('ดื่ม')) {
        buttonText = 'บันทึก$pinnedTitle';
        buttonIcon = Icons.water_drop;
      } else if (lower.contains('วิ่ง') ||
          lower.contains('เดิน') ||
          lower.contains('ออกกำลัง')) {
        buttonText = 'เริ่ม$pinnedTitle';
        buttonIcon = Icons.directions_run;
      } else {
        buttonText = 'เริ่ม$pinnedTitle';
        buttonIcon = Icons.play_arrow_rounded;
      }
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: onStartWorkout,
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
            onPressed: onNavigateToWorkout ?? () {},
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
