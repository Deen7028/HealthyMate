import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/controllers/health_calculator_controller.dart';
import 'bmi_indicator_bar.dart';
import 'calorie_target_card.dart';
import 'result_card.dart';

class HealthCalculatorResultSection extends StatelessWidget {
  final HealthCalculatorController state;

  const HealthCalculatorResultSection({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final bmiCategory = state.bmiCategory;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      size: 20,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ผลลัพธ์การวิเคราะห์',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bmiCategory.badgeText,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 16),

          // BMI Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ดัชนีมวลกาย (BMI)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      text: state.bmi.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -1,
                      ),
                      children: const [
                        TextSpan(
                          text: ' kg/m²',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'เกณฑ์สุขภาพดี',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '18.5 - 22.9',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // BMI Indicator Bar
          BMIIndicatorBar(bmi: state.bmi, category: bmiCategory),

          const SizedBox(height: 20),

          // BMR & TDEE 2 Cards
          Row(
            children: [
              Expanded(
                child: EnergyMetricCard(
                  icon: Icons.hotel_outlined,
                  title: 'BMR (ขณะพัก)',
                  value: state.bmr.toInt().toString(),
                  unit: 'kcal',
                  description: 'พลังงานต่ำสุดที่ร่างกายต้องการ',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EnergyMetricCard(
                  icon: Icons.local_fire_department_outlined,
                  title: 'TDEE (ใช้จริง/วัน)',
                  value: state.tdee.toInt().toString(),
                  unit: 'kcal',
                  description: 'พลังงานรวมที่เผาผลาญต่อวัน',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Calorie Targets Section
          CalorieTargetSection(targets: state.targets),
        ],
      ),
    );
  }
}
