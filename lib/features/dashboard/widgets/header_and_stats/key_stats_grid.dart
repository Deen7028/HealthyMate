import 'package:flutter/material.dart';
import 'package:healthymate/features/dashboard/models/dashboard_data.dart';

part 'key_stats_grid_cards.dart';

// ==========================================
// กริดการ์ดสถิติสำคัญประจำวัน (KeyStatsGrid)
// จัดวางการ์ดสถิติสำคัญ: ระยะทาง, เวลาการทำกิจกรรม และแคลอรีที่เผาผลาญ
// ==========================================
class KeyStatsGrid extends StatelessWidget {
  /// ข้อมูลสถิติของแดชบอร์ด (ระยะทาง, เวลา, แคลอรี ฯลฯ)
  final DashboardStats stats;

  const KeyStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // ----------------------------------------------------
          // แถวบน: การ์ดระยะทาง (Distance) และ การ์ดเวลา (Active Time) แบบเคียงข้างกัน
          // ----------------------------------------------------
          Row(
            children: [
              // 1. การ์ดระยะทาง (Distance Card - กม.)
              Expanded(
                child: _buildSmallStatCard(
                  icon: Icons.directions_run_rounded,
                  iconColor: const Color(0xFF2E5327),
                  title: 'ระยะทาง',
                  value: stats.distanceKm.toStringAsFixed(1),
                  unit: 'กม.',
                  progressRatio: 0.84, // สัดส่วนความก้าวหน้าเปรียบเทียบกับเป้าหมาย
                  progressColor: const Color(0xFF2E5327),
                ),
              ),
              const SizedBox(width: 12),

              // 2. การ์ดเวลาที่ใช้ (Active Time Card - นาที)
              Expanded(
                child: _buildSmallStatCard(
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFF5A6559),
                  title: 'เวลา',
                  value: '${stats.activeTimeMinutes}',
                  unit: 'นาที',
                  progressRatio: 0.75, // สัดส่วนความก้าวหน้าเปรียบเทียบกับเป้าหมาย
                  progressColor: const Color(0xFFE0E5DF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ----------------------------------------------------
          // แถวล่าง: การ์ดแคลอรีที่เผาผลาญ (Calories Card - kcal) แบบเต็มความกว้าง
          // ----------------------------------------------------
          _buildLargeStatCard(
            icon: Icons.local_fire_department_outlined,
            iconColor: const Color(0xFF5A6559),
            title: 'แคลอรี่',
            value: '${stats.caloriesBurned}',
            unit: 'กิโลแคลอรี่',
            progressRatio: 0.64, // สัดส่วนความก้าวหน้าเปรียบเทียบกับเป้าหมาย
            progressColor: const Color(0xFF2E5327),
          ),
        ],
      ),
    );
  }
}

