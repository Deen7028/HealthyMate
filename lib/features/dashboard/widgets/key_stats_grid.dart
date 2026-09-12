import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';

class KeyStatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const KeyStatsGrid({
    super.key,
    required this.stats,
  });

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

  Widget _buildSmallStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required double progressRatio,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A6559),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C2819),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A6559),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 6,
              backgroundColor: const Color(0xFFF0F4EF),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required double progressRatio,
    required Color progressColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A6559),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C2819),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A6559),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 6,
              backgroundColor: const Color(0xFFF0F4EF),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
