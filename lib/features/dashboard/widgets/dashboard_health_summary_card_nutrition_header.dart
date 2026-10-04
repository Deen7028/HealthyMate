part of 'dashboard_health_summary_card.dart';

extension _DashboardHealthSummaryCardNutritionHeader
    on DashboardHealthSummaryCard {
  /// build widget ส่วนหัวของแคลอรี่
  Widget _buildNutritionHeader({
    required bool isDark,
    required Color subtleSurface,
    required Color textPrimary,
  }) => Column(
    children: [
      // Row 1: Header + Scanner Badge + Scan Button
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant_rounded,
                      size: 16,
                      color: primaryGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'สมดุลแคลอรี่ประจำวัน',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_rounded,
                        size: 10,
                        color: isDark ? const Color(0xFF90DB89) : darkGreen,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'AI Food Scanner',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF90DB89) : darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onOpenFoodScanner != null)
            Material(
              color: isDark ? subtleSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 0.5,
              child: InkWell(
                onTap: onOpenFoodScanner,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        size: 12,
                        color: isDark ? const Color(0xFF90DB89) : darkGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ถ่ายบันทึก',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF90DB89) : darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
    ],
  );
}
