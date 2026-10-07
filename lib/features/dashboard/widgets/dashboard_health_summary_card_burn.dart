part of 'dashboard_health_summary_card.dart';

extension _DashboardHealthSummaryCardBurn on DashboardHealthSummaryCard {
  /// build widget ส่วนแสดงเป้าหมายการเผาผลาญ
  Widget _buildBurnTargetCard({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required int burnTarget,
    required double totalCaloriesBurned,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: primaryGreen.withValues(alpha: isDark ? 0.18 : 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.track_changes, color: primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'เป้าหมายเผาผลาญจากการออกกำลังกาย',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: totalCaloriesBurned),
                duration: const Duration(milliseconds: 2500),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) => Text(
                  'เผาผลาญแล้ววันนี้ ${val.toStringAsFixed(0)} kcal',
                  style: TextStyle(fontSize: 10, color: textSecondary),
                ),
              ),
            ],
          ),
        ),
        Text(
          '$burnTarget\nkcal/วัน',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryGreen,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}
