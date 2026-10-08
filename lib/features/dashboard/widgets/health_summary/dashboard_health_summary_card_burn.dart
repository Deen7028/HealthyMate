part of 'dashboard_health_summary_card.dart';

// ==========================================
// ส่วนแสดงผลการเผาผลาญจากการออกกำลังกาย (_DashboardHealthSummaryCardBurn)
// แสดงแคลอรีที่เผาผลาญไปแล้วในวันนี้ และเป้าหมายการเผาผลาญประจำวัน (Burn Target kcal)
// ==========================================
extension _DashboardHealthSummaryCardBurn on DashboardHealthSummaryCard {
  /// ฟังก์ชัน: สร้าง UI การ์ดแสดงเป้าหมายการเผาผลาญแคลอรี
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
        // 1. ไอคอนเป้าหมาย
        Icon(Icons.track_changes, color: primaryGreen),
        const SizedBox(width: 12),

        // 2. ข้อความชื่อเป้าหมาย และตัวเลขแคลอรีที่เผาผลาญไปแล้ว
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

        // 3. ค่าเป้าหมายแคลอรีรวมประจำวัน (kcal/วัน)
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

