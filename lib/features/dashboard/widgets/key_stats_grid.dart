// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (key stats grid)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';

part 'key_stats_grid_cards.dart';

/// Grid แสดงการ์ดสถิติสำคัญประจำวัน (ระยะทาง เวลาออกกำลังกาย แคลอรี และก้าวเดิน)
class KeyStatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const KeyStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // Top Row: Distance & Active Time cards side by side
          Row(
            children: [
              // 1. Distance Card (ระยะทาง)
              Expanded(
                child: _buildSmallStatCard(
                  icon: Icons.directions_run_rounded,
                  iconColor: const Color(0xFF2E5327),
                  title: 'ระยะทาง',
                  value: stats.distanceKm.toStringAsFixed(1),
                  unit: 'กม.',
                  progressRatio: 0.84, // 4.2 / 5.0
                  progressColor: const Color(0xFF2E5327),
                ),
              ),
              const SizedBox(width: 12),
              // 2. Active Time Card (เวลา)
              Expanded(
                child: _buildSmallStatCard(
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFF5A6559),
                  title: 'เวลา',
                  value: '${stats.activeTimeMinutes}',
                  unit: 'นาที',
                  progressRatio: 0.75, // 45 / 60
                  progressColor: const Color(0xFFE0E5DF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom Row: Calories Card (แคลอรี่) - Full Width
          _buildLargeStatCard(
            icon: Icons.local_fire_department_outlined,
            iconColor: const Color(0xFF5A6559),
            title: 'แคลอรี่',
            value: '${stats.caloriesBurned}',
            unit: 'กิโลแคลอรี่',
            progressRatio: 0.64, // 320 / 500
            progressColor: const Color(0xFF2E5327),
          ),
        ],
      ),
    );
  }
}
