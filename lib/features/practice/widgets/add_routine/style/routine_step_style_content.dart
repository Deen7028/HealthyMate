part of 'routine_step_style.dart';
// Step 3: ตั้งค่าการแจ้งเตือนและธีม 🎨
extension RoutineStepStyleContent on _RoutineStepStyleState {
  Widget _buildStepStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final surfaceBg = AppTheme.getSurfaceColor(isDark);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: การแจ้งเตือนและธีมกิจวัตร 🔔🎨',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.isNotificationEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          color: widget.isNotificationEnabled
                              ? (isDark
                                    ? Colors.amberAccent
                                    : Colors.amber.shade800)
                              : textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'การแจ้งเตือนประจำวัน',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: widget.isNotificationEnabled,
                      onChanged: widget.onToggleNotification,
                      activeThumbColor: widget.btnColor,
                    ),
                  ],
                ),
                if (widget.isNotificationEnabled) ...[
                  const SizedBox(height: 12),
                  Text(
                    'รูปแบบการแจ้งเตือน',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildNotificationModeSelector(
                    isDark,
                    cardBg,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildIconSelector(
            isDark,
            surfaceBg,
            borderColor,
            textPrimary,
            textSecondary,
          ),
          const SizedBox(height: 10),
          _buildColorSelector(
            isDark,
            cardBg,
            borderColor,
            textPrimary,
            textSecondary,
          ),
        ],
      ),
    );
  }
}
