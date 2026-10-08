part of 'profile_header_card.dart';
//การ์ดสำหรับแสดงเป้าหมายหลัก
extension _ProfileHeaderCardGoal on ProfileHeaderCard {
  Widget _buildGoalCard(bool isDark, Color primaryColor, bool hasGoal) {
    return InkWell(
      onTap: onGoalTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF27342C) : const Color(0xFFF7F8F4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF3B4D41) : const Color(0xFFE2E7DF),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.25 : 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.radar_rounded,
                        size: 18,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'เป้าหมายหลัก',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFB0BEB3)
                            : const Color(0xFF5A6559),
                      ),
                    ),
                  ],
                ),
                if (onGoalTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isDark
                        ? Colors.grey.shade400
                        : const Color(0xFF6F7A72),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasGoal ? goalTitle : 'ยังไม่ได้กำหนดเป้าหมาย',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: hasGoal
                    ? (isDark ? Colors.white : const Color(0xFF1E2822))
                    : (isDark ? Colors.grey.shade400 : const Color(0xFF8C968E)),
              ),
            ),
            if (hasGoal) ...[
              const SizedBox(height: 10),
              // Progress Bar & Percentage
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.0,
                  end: goalProgress.clamp(0.0, 1.0),
                ),
                duration: const Duration(milliseconds: 2500),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: animValue,
                            minHeight: 7,
                            backgroundColor: isDark
                                ? Colors.black26
                                : const Color(0xFFE2E7DF),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(animValue * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFB0BEB3)
                              : const Color(0xFF5A6559),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (goalRemainingText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  goalRemainingText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C968E),
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 6),
              Text(
                'แตะที่นี่เพื่อตั้งเป้าหมายสุขภาพหรือการออกกำลังกายของคุณ',
                style: TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
