// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์การวิเคราะห์อาหารจากรูปภาพและข้อมูลโภชนาการ (burn it off advisor card)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';

class BurnItOffAdvisorCard extends StatelessWidget {
  final int totalCalories;
  final double userWeight;
  final Color primaryColor;

  const BurnItOffAdvisorCard({
    super.key,
    required this.totalCalories,
    this.userWeight = 65.0,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCalories <= 0) return const SizedBox.shrink();

    // สูตรคำนวณเวลากิจกรรมจาก METs: Calories / (METs * weight * 0.0175)
    final weight = userWeight > 0 ? userWeight : 65.0;
    final runMinutes = (totalCalories / (8.0 * weight * 0.0175)).round().clamp(1, 999);
    final cycleMinutes = (totalCalories / (6.8 * weight * 0.0175)).round().clamp(1, 999);
    final walkMinutes = (totalCalories / (3.8 * weight * 0.0175)).round().clamp(1, 999);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF8F0),
            const Color(0xFFFFEEDD).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD8B3), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_fire_department_rounded, color: Colors.orange.shade800, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔥 โค้ช AI แนะนำการเผาผลาญ (Burn-It-Off)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    Text(
                      'กิจกรรมที่ต้องทำเพื่อเผาผลาญแคลอรีมื้อนี้',
                      style: TextStyle(fontSize: 11, color: Color(0xFF795548)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalCalories kcal',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFFFE0B2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBurnOption(
                icon: Icons.directions_run_rounded,
                label: 'วิ่ง (Pace 6)',
                minutes: runMinutes,
                color: Colors.orange.shade900,
              ),
              Container(width: 1, height: 36, color: const Color(0xFFFFE0B2)),
              _buildBurnOption(
                icon: Icons.directions_bike_rounded,
                label: 'ปั่นจักรยาน',
                minutes: cycleMinutes,
                color: Colors.deepOrange.shade800,
              ),
              Container(width: 1, height: 36, color: const Color(0xFFFFE0B2)),
              _buildBurnOption(
                icon: Icons.directions_walk_rounded,
                label: 'เดินเร็ว',
                minutes: walkMinutes,
                color: Colors.amber.shade900,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBurnOption({
    required IconData icon,
    required String label,
    required int minutes,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.brown.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$minutes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              TextSpan(
                text: ' นาที',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
