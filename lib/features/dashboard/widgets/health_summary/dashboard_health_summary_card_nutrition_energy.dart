part of 'dashboard_health_summary_card.dart';

extension _DashboardHealthSummaryCardNutritionEnergy
    on DashboardHealthSummaryCard {
  /// build widget ส่วนแสดงพลังงานที่กินในวันนี้
  Widget _buildNutritionEnergyStats({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required double targetTdee,
    required double remainingEnergyQuota,
    required double netEnergyRatio,
  }) => Column(
    children: [
      // Row 2: Animated Calorie Stats
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: todayNutritionCalories.toDouble(),
                ),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) => Text(
                  '${val.round()}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: todayNutritionCalories > targetTdee
                        ? Colors.redAccent
                        : (isDark ? const Color(0xFF90DB89) : darkGreen),
                  ),
                ),
              ),
              Text(
                ' / ${targetTdee.round()} kcal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          Text(
            todayScannedFoodCount > 0
                ? 'สแกนแล้ว $todayScannedFoodCount รายการ'
                : 'ยังไม่ได้สแกน',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: todayScannedFoodCount > 0 ? primaryGreen : textSecondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),

      // Progress Bar
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: netEnergyRatio,
          minHeight: 8,
          backgroundColor: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
          valueColor: AlwaysStoppedAnimation<Color>(
            todayNutritionCalories > targetTdee
                ? Colors.redAccent
                : (netEnergyRatio > 0.85 ? Colors.orangeAccent : primaryGreen),
          ),
        ),
      ),
      const SizedBox(height: 8),

      // Row 3: Remaining Quota & Burned
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            remainingEnergyQuota >= 0
                ? 'วันนี้กินได้อีก ${remainingEnergyQuota.round()} kcal'
                : 'เกินโควตาพลังงาน ${(-remainingEnergyQuota).round()} kcal',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: remainingEnergyQuota >= 0 ? textPrimary : Colors.redAccent,
            ),
          ),
        ],
      ),
    ],
  );
}
