import 'package:flutter/material.dart';
import 'package:healthymate/core/utils/health_calculator.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/activity_level.dart';

class DashboardHealthSummaryCard extends StatelessWidget {
  final TbUser? user;
  final TbHealthRecord? latestRecord;
  final DateTime now;
  final double totalCaloriesBurned;
  final VoidCallback? onNavigateToCalculator;
  final Color primaryGreen;
  final Color darkGreen;

  const DashboardHealthSummaryCard({
    super.key,
    required this.user,
    required this.latestRecord,
    required this.now,
    required this.totalCaloriesBurned,
    this.onNavigateToCalculator,
    this.primaryGreen = const Color(0xFF0F9C58),
    this.darkGreen = const Color(0xFF006432),
  });

  String _formatNumber(double val) =>
      val >= 1000 ? val.toStringAsFixed(0) : val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1);
  String _formatInt(int val) => val.toString();

  @override
  Widget build(BuildContext context) {
    final weight = latestRecord?.nWeight ?? user?.nWeight ?? 0.0;
    final height = latestRecord?.nHeight ?? user?.nHeight ?? 0.0;
    final bmi =
        latestRecord?.nBmi ??
        (weight > 0 && height > 0
            ? HealthCalculator.calculateBMI(weightKg: weight, heightCm: height)
            : 0.0);
    final bmiCategory = HealthCalculator.getBMICategory(bmi);

    final age = user?.nAge ?? 0;
    final gender = user?.genderEnum ?? Gender.male;
    final activityLevel = user?.activityLevelObj ?? ActivityLevel.options[1];

    double bmr = latestRecord?.computedBmr ?? 0.0;
    double tdee = latestRecord?.nTdee ?? 0.0;

    if (bmr <= 0 && weight > 0 && height > 0 && age > 0) {
      bmr = HealthCalculator.calculateBMR(
        gender: gender,
        weightKg: weight,
        heightCm: height,
        age: age,
      );
    }
    if (tdee <= 0 && bmr > 0) {
      tdee = HealthCalculator.calculateTDEE(
        bmr: bmr,
        activityMultiplier: activityLevel.multiplier,
      );
    }

    String lastRecordText = 'ยังไม่มีข้อมูล';
    if (latestRecord != null) {
      final diff = now.difference(latestRecord!.dtRecordedAt);
      if (diff.inMinutes < 60) {
        lastRecordText = 'คำนวณล่าสุดเมื่อ ${diff.inMinutes} นาทีที่แล้ว';
      } else if (diff.inHours < 24) {
        lastRecordText = 'คำนวณล่าสุดเมื่อ ${diff.inHours} ชม. ที่แล้ว';
      } else {
        lastRecordText = 'คำนวณล่าสุดเมื่อ ${diff.inDays} วันที่แล้ว';
      }
    }

    final burnTarget = tdee > 0 ? (tdee * 0.2).round() : 400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
                  Icon(Icons.health_and_safety, color: darkGreen),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ข้อมูลสุขภาพส่วนบุคคล',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        lastRecordText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onNavigateToCalculator,
                icon: const Icon(Icons.sync, size: 16, color: Colors.blue),
                label: const Text(
                  'อัปเดตข้อมูล',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatItem(
                  'น้ำหนัก / ส่วนสูง',
                  weight > 0
                      ? '${_formatNumber(weight)} กก. | ${_formatNumber(height)} ซม.'
                      : 'ยังไม่ระบุ',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItemWithBadge(
                  'ดัชนีมวลกาย',
                  bmi > 0 ? bmi.toStringAsFixed(1) : '-',
                  bmi > 0 ? bmiCategory.badgeText : 'ยังไม่ระบุ',
                  bmi > 0 ? bmiCategory.color : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatItem(
                  'BMR พลังงานพื้นฐาน',
                  bmr > 0 ? '${_formatInt(bmr.round())} kcal' : '- kcal',
                  icon: Icons.bolt,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  'TDEE ต้องการต่อวัน',
                  tdee > 0 ? '${_formatInt(tdee.round())} kcal' : '- kcal',
                  icon: Icons.local_fire_department,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.track_changes, color: primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เป้าหมายเผาผลาญจากการออกกำลังกาย',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'เผาผลาญแล้ววันนี้ ${totalCaloriesBurned.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$burnTarget\nkcal/วัน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemWithBadge(
    String title,
    String value,
    String badgeText,
    Color badgeColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
