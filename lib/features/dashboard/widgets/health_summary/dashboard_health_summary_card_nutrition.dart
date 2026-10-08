part of 'dashboard_health_summary_card.dart';

// ส่วนประกอบการ์ดสมดุลแคลอรีประจำวัน (_DashboardHealthSummaryCardNutrition)
// รวม Header, กราฟสถิติแคลอรีที่บริโภค และส่วนพรีวิวรายการอาหาร
extension _DashboardHealthSummaryCardNutrition on DashboardHealthSummaryCard {
  /// ฟังก์ชัน: สร้าง UI การ์ดสมดุลแคลอรีประจำวัน (แตะเพื่อเปิด AI Food Scanner)
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
              // 1. ส่วนหัวการ์ด: ชื่อสมดุลแคลอรี่ + แบดจ์ AI Scanner + ปุ่มถ่ายบันทึก
              _buildNutritionHeader(
                isDark: isDark,
                subtleSurface: subtleSurface,
                textPrimary: textPrimary,
              ),

              // 2. ส่วนสถิติแคลอรี: ตัวเลขกินไปแล้ว/TDEE + หลอด Progress Bar + โควตาที่เหลือ
              _buildNutritionEnergyStats(
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                targetTdee: targetTdee,
                remainingEnergyQuota: remainingEnergyQuota,
                netEnergyRatio: netEnergyRatio,
              ),

              // 3. ส่วนพรีวิวอาหารที่สแกนล่าสุด (Food Chips Preview)
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

