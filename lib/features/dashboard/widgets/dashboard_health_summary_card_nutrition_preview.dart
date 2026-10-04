part of 'dashboard_health_summary_card.dart';

extension _DashboardHealthSummaryCardNutritionPreview
    on DashboardHealthSummaryCard {
  Widget _buildNutritionFoodPreview({
    required bool isDark,
    required Color subtleSurface,
    required Color textPrimary,
    required Color textSecondary,
  }) => Column(
    children: [
      if (todayNutritionLogs.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: todayNutritionLogs.take(3).map((item) {
            final name = item['sFoodName']?.toString() ?? 'อาหาร';
            final cal = (item['nCalories'] as num?)?.toInt() ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? subtleSurface : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍽️ ', style: TextStyle(fontSize: 10)),
                  Text(
                    name.length > 15 ? '${name.substring(0, 14)}...' : name,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '+$cal kcal',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF90DB89) : darkGreen,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ] else ...[
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.touch_app_rounded, size: 12, color: primaryGreen),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'แตะที่นี่เพื่อถ่ายบันทึกอาหารด้วย AI Food Scanner',
                style: TextStyle(
                  fontSize: 10.5,
                  color: textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    ],
  );
}
