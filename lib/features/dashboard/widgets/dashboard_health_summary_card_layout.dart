part of 'dashboard_health_summary_card.dart';

extension _DashboardHealthSummaryCardLayout on DashboardHealthSummaryCard {
  Widget _buildHealthSummaryLayout({
    required BuildContext context,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color subtleSurface,
    required double weight,
    required double height,
    required double bmi,
    required dynamic bmiCategory,
    required double bmr,
    required double tdee,
    required String lastRecordText,
    required int burnTarget,
    required double targetTdee,
    required double remainingEnergyQuota,
    required double netEnergyRatio,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPersonalHealthSection(
            isDark: isDark,
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
          ),
          _buildNutritionCard(
            isDark: isDark,
            subtleSurface: subtleSurface,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            targetTdee: targetTdee,
            remainingEnergyQuota: remainingEnergyQuota,
            netEnergyRatio: netEnergyRatio,
          ),
          const SizedBox(height: 12),

          _buildBurnTargetCard(
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            burnTarget: burnTarget,
            totalCaloriesBurned: totalCaloriesBurned,
          ),
        ],
      ),
    );
  }
}
