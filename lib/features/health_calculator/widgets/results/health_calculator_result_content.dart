part of 'health_calculator_result_section.dart';
extension _HealthCalculatorResultContent on HealthCalculatorResultSection {
  Widget _buildResults(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final bmiCategory = state.bmiCategory;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                      color: isDark
                          ? const Color(0xFF23352A)
                          : const Color(0xFFE8F3EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 20,
                      color: isDark
                          ? AppTheme.primaryLightGreen
                          : AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ผลลัพธ์การวิเคราะห์',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
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
                  color: isDark
                      ? const Color(0xFF23352A)
                      : const Color(0xFFE8F3EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bmiCategory.badgeText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.primaryLightGreen
                        : AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 16),
          // BMI Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ดัชนีมวลกาย (BMI)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: state.bmi),
                    duration: const Duration(milliseconds: 2500),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) {
                      return RichText(
                        text: TextSpan(
                          text: val.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                            letterSpacing: -1,
                          ),
                          children: [
                            TextSpan(
                              text: ' kg/m²',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'เกณฑ์สุขภาพดี',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.primaryLightGreen
                          : AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '18.5 - 22.9',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
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
                  numericValue: state.bmr,
                  unit: 'kcal',
                  description: 'พลังงานต่ำสุดที่ร่างกายต้องการ',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EnergyMetricCard(
                  icon: Icons.local_fire_department_outlined,
                  title: 'TDEE (ใช้จริง/วัน)',
                  numericValue: state.tdee,
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
