// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์เครื่องคำนวณสุขภาพและบันทึกค่าสุขภาพ (calorie target card)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/core/utils/health_calculator.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class CalorieTargetSection extends StatelessWidget {
  final CalorieTargets targets;

  const CalorieTargetSection({
    super.key,
    required this.targets,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = AppTheme.getSurfaceColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 18,
                color: isDark ? AppTheme.primaryLightGreen : AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                'เป้าหมายแคลอรีแนะนำ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildGoalCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  title: 'ลดไขมัน',
                  calories: targets.fatLoss.toString(),
                  subtext: '-500 kcal',
                  isHighlighted: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGoalCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  title: 'คงน้ำหนัก',
                  calories: targets.maintain.toString(),
                  subtext: 'พอดีวัน',
                  isHighlighted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGoalCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  title: 'เพิ่มกล้ามเนื้อ',
                  calories: targets.muscleGain.toString(),
                  subtext: '+300 kcal',
                  isHighlighted: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required String title,
    required String calories,
    required String subtext,
    required bool isHighlighted,
  }) {
    final highlightColor = isDark ? AppTheme.primaryLightGreen : AppTheme.primaryGreen;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? highlightColor : borderColor,
          width: isHighlighted ? 1.6 : 1.0,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isHighlighted ? highlightColor : textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            calories,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isHighlighted ? textSecondary : (isDark ? const Color(0xFF6B7E72) : AppTheme.textTertiary),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
