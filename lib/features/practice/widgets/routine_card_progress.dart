part of 'routine_card_widget.dart';

extension _RoutineCardProgress on RoutineCardWidget {
  Widget _buildPercentBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF90DB89) : cardColor,
        ),
      ),
    );
  }

  Widget _buildProgressSection(bool isDark, Color textSecondary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ความคืบหน้า',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
            Text(
              '${_formatProgress(currentVal)} / ${_formatValue(targetVal)} $unitText',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? const Color(0xFF90DB89) : cardColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progressRatio),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: cardColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(cardColor),
              );
            },
          ),
        ),
      ],
    );
  }
}
