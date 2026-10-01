part of 'routine_step_style.dart';

extension RoutineStepStyleModes on _RoutineStepStyleState {
  Widget _buildNotificationModeSelector(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildModeTab(
              0,
              'เวลาเดียว',
              Icons.access_time_rounded,
              isDark,
              cardBg,
              borderColor,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(width: 6),
            _buildModeTab(
              1,
              'หลายเวลา',
              Icons.more_time_rounded,
              isDark,
              cardBg,
              borderColor,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(width: 6),
            _buildModeTab(
              2,
              'ความถี่',
              Icons.update_rounded,
              isDark,
              cardBg,
              borderColor,
              textPrimary,
              textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedModeIndex == 0)
          _buildSingleTimeMode(isDark, cardBg, borderColor, textPrimary),
        if (_selectedModeIndex == 1)
          _buildMultipleTimesMode(
            isDark,
            cardBg,
            borderColor,
            textPrimary,
            textSecondary,
          ),
        if (_selectedModeIndex == 2)
          _buildIntervalMode(
            isDark,
            cardBg,
            borderColor,
            textPrimary,
            textSecondary,
          ),
      ],
    );
  }

  Widget _buildModeTab(
    int index,
    String label,
    IconData icon,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isSelected = _selectedModeIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedModeIndex = index;
            _updateControllerText();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? widget.btnColor : cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? widget.btnColor : borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
