part of 'routine_card_widget.dart';
// ส่วนขยายแสดงหลอดความคืบหน้าของการ์ดกิจวัตร
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

  Widget _buildRoutineMetaWrap({
    required String sFormattedTime,
    required bool isNotificationActive,
    required bool isDark,
    required Color textSecondary,
  }) {
    if (isWorkoutRoutine) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          if (sFormattedTime.isNotEmpty)
            _buildNotificationTimeBadge(
              sFormattedTime: sFormattedTime,
              isNotificationActive: isNotificationActive,
              isDark: isDark,
              textSecondary: textSecondary,
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF352B1E) : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? const Color(0xFF5C4018) : Colors.orange.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 12,
                  color: isDark
                      ? const Color(0xFFFFB74D)
                      : Colors.orange.shade800,
                ),
                const SizedBox(width: 2),
                Text(
                  'Auto-GPS Sync',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFFB74D)
                        : Colors.orange.shade900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'เป้าหมาย: ${_formatValue(targetVal)} $unitText',
            style: TextStyle(fontSize: 11, color: textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
          _buildPercentBadge(isDark),
        ],
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        if (sFormattedTime.isNotEmpty)
          _buildNotificationTimeBadge(
            sFormattedTime: sFormattedTime,
            isNotificationActive: isNotificationActive,
            isDark: isDark,
            textSecondary: textSecondary,
          ),
        Text(
          'เป้าหมายประจำวัน: ${_formatValue(targetVal)} $unitText',
          style: TextStyle(fontSize: 11.5, color: textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
        _buildPercentBadge(isDark),
      ],
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

  String _formatNotificationTime(String? sRawTime) {
    if (sRawTime == null || sRawTime.trim().isEmpty) return '';
    final sClean = sRawTime.trim();
    final match = RegExp(r'(\d{1,2})[:\.](\d{2})').firstMatch(sClean);
    if (match != null) {
      final sH = match.group(1)!.padLeft(2, '0');
      final sM = match.group(2)!;
      return '$sH:$sM น.';
    }
    return sClean.endsWith('น.') ? sClean : '$sClean น.';
  }

  Widget _buildNotificationTimeBadge({
    required String sFormattedTime,
    required bool isNotificationActive,
    required bool isDark,
    required Color textSecondary,
  }) {
    final Color badgeBg = isNotificationActive
        ? (isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9))
        : (isDark ? const Color(0xFF2D3748) : const Color(0xFFEDF2F7));
    final Color badgeBorder = isNotificationActive
        ? (isDark ? const Color(0xFF2E5327) : const Color(0xFFA5D6A7))
        : (isDark ? const Color(0xFF4A5568) : const Color(0xFFCBD5E0));
    final Color badgeContentColor = isNotificationActive
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNotificationActive
                ? Icons.alarm_rounded
                : Icons.alarm_off_rounded,
            size: 11.5,
            color: badgeContentColor,
          ),
          const SizedBox(width: 3.5),
          Text(
            isNotificationActive ? sFormattedTime : '$sFormattedTime (ปิดเตือน)',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: badgeContentColor,
            ),
          ),
        ],
      ),
    );
  }
}
