part of 'dashboard_health_summary_card.dart';

// ส่วนจัดวางเลย์เอาต์หลัก (_DashboardHealthSummaryCardLayout)
// รวบรวมและจัดลำดับการ์ดสุขภาพส่วนบุคคล, โภชนาการอาหาร และเป้าหมายการเผาผลาญ
extension _DashboardHealthSummaryCardLayout on DashboardHealthSummaryCard {
  /// ฟังก์ชัน: สร้าง UI การ์ดกรอบนอก และจัดวางส่วนประกอบหลักทั้ง 3 ส่วน
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
          // 1. ส่วนข้อมูลสุขภาพส่วนบุคคล (น้ำหนัก, ส่วนสูง, BMI, BMR, TDEE)
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

          // 2. ส่วนสมดุลแคลอรีและ AI Food Scanner
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

          // 3. ส่วนเป้าหมายการเผาผลาญจากการออกกำลังกายประจำวัน
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

