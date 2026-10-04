// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (dashboard health summary card)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/core/utils/health_calculator.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/activity_level.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

part 'dashboard_health_summary_card_stat_ui.dart';
part 'dashboard_health_summary_card_layout.dart';
part 'dashboard_health_summary_card_personal.dart';
part 'dashboard_health_summary_card_burn.dart';
part 'dashboard_health_summary_card_nutrition_preview.dart';
part 'dashboard_health_summary_card_nutrition_energy.dart';
part 'dashboard_health_summary_card_nutrition_header.dart';
part 'dashboard_health_summary_card_nutrition.dart';

/// การ์ดสรุปข้อมูลสุขภาพส่วนบุคคล สัดส่วนร่างกาย การเผาผลาญ และแคลอรีโภชนาการประจำวัน
class DashboardHealthSummaryCard extends StatelessWidget {
  final TbUser? user;
  final TbHealthRecord? latestRecord;
  final DateTime now;
  final double totalCaloriesBurned;
  final int todayNutritionCalories;
  final int todayScannedFoodCount;
  final List<Map<String, dynamic>> todayNutritionLogs;
  final VoidCallback? onNavigateToCalculator;
  final VoidCallback? onOpenFoodScanner;
  final Color primaryGreen;
  final Color darkGreen;

  const DashboardHealthSummaryCard({
    super.key,
    required this.user,
    required this.latestRecord,
    required this.now,
    required this.totalCaloriesBurned,
    this.todayNutritionCalories = 0,
    this.todayScannedFoodCount = 0,
    this.todayNutritionLogs = const [],
    this.onNavigateToCalculator,
    this.onOpenFoodScanner,
    this.primaryGreen = const Color(0xFF0F9C58),
    this.darkGreen = const Color(0xFF006432),
  });

  String _formatNumber(double val) => val >= 1000
      ? val.toStringAsFixed(0)
      : val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final subtleSurface = isDark
        ? const Color(0xFF27342C)
        : const Color(0xFFF7F9FB);

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

    // Daily Net Energy Allowance calculation based directly on TDEE
    final double targetTdee = tdee > 0 ? tdee : 2000.0;
    final double remainingEnergyQuota = targetTdee - todayNutritionCalories;
    final double netEnergyRatio = (targetTdee > 0)
        ? (todayNutritionCalories / targetTdee).clamp(0.0, 1.0)
        : 0.0;

    return _buildHealthSummaryLayout(
      context: context,
      isDark: isDark,
      cardBg: cardBg,
      borderColor: borderColor,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      subtleSurface: subtleSurface,
      weight: weight,
      height: height,
      bmi: bmi,
      bmiCategory: bmiCategory,
      bmr: bmr,
      tdee: tdee,
      lastRecordText: lastRecordText,
      burnTarget: burnTarget,
      targetTdee: targetTdee,
      remainingEnergyQuota: remainingEnergyQuota,
      netEnergyRatio: netEnergyRatio,
    );
  }
}
