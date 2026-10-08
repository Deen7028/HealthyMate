part of 'workout_top_stats_card.dart';
// เมธอดสร้างส่วนหัวสำหรับแสดงสถานะ (isRunning) และประเภทกิจกรรม
extension _WorkoutTopStatsCardHeader on WorkoutTopStatsCard {
  Widget _buildStatusAndCategoryHeader(bool isDarkModeMap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: onChangeCategoryTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkModeMap
                  ? const Color(0xFF74B46E).withValues(alpha: 0.25)
                  : const Color(0xFF2E5327).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.icon,
                  size: 16,
                  color: isDarkModeMap
                      ? const Color(0xFF90DB89)
                      : const Color(0xFF2E5327),
                ),
                const SizedBox(width: 4),
                Text(
                  category.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDarkModeMap
                        ? const Color(0xFF90DB89)
                        : const Color(0xFF2E5327),
                  ),
                ),
                if (onChangeCategoryTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: isDarkModeMap
                        ? const Color(0xFF90DB89)
                        : const Color(0xFF2E5327),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isRunning)
          FadeTransition(
            opacity: pulseAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  CircleAvatar(radius: 4, backgroundColor: Colors.redAccent),
                  SizedBox(width: 6),
                  Text(
                    'กำลังบันทึก',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
