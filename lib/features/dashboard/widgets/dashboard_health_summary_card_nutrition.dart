// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (dashboard health summary card nutrition)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'dashboard_health_summary_card.dart';

extension _DashboardHealthSummaryCardNutrition on DashboardHealthSummaryCard {
  Widget _buildNutritionCard({
    required bool isDark,
    required Color subtleSurface,
    required Color textPrimary,
    required Color textSecondary,
    required double targetTdee,
    required double remainingEnergyQuota,
    required double netEnergyRatio,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenFoodScanner,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      primaryGreen.withValues(alpha: 0.18),
                      const Color(0xFF352B1E).withValues(alpha: 0.4),
                    ]
                  : [
                      primaryGreen.withValues(alpha: 0.08),
                      Colors.amber.shade50.withValues(alpha: 0.5),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primaryGreen.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNutritionHeader(
                isDark: isDark,
                subtleSurface: subtleSurface,
                textPrimary: textPrimary,
              ),
              _buildNutritionEnergyStats(
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                targetTdee: targetTdee,
                remainingEnergyQuota: remainingEnergyQuota,
                netEnergyRatio: netEnergyRatio,
              ),
              _buildNutritionFoodPreview(
                isDark: isDark,
                subtleSurface: subtleSurface,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
