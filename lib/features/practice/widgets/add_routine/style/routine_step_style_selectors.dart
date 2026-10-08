part of 'routine_step_style.dart';
//  Step 3: ตั้งค่าการแจ้งเตือน  ไอคอน สี
extension RoutineStepStyleSelectors on _RoutineStepStyleState {
  Widget _buildIconSelector(
    bool isDark,
    Color surfaceBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      children: [
        Text(
          'ไอคอน:',
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.availableIcons.length + 1,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = widget.selectedIcon == null;
                  return InkWell(
                    onTap: () => widget.onSelectIcon(null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? const Color(0xFF354E3C)
                                  : Colors.grey.shade300)
                            : (isDark ? surfaceBg : Colors.grey.shade100),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDark
                                    ? AppTheme.primaryLightGreen
                                    : Colors.grey.shade700)
                              : borderColor,
                        ),
                      ),
                      child: Icon(Icons.block, size: 18, color: textSecondary),
                    ),
                  );
                }
                final icon = widget.availableIcons[index - 1];
                final isSelected = icon == widget.selectedIcon;
                return InkWell(
                  onTap: () => widget.onSelectIcon(icon),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.btnColor.withAlpha(50)
                          : (isDark ? surfaceBg : Colors.grey.shade100),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? widget.btnColor
                            : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: isSelected ? widget.btnColor : textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      children: [
        Text(
          'สีประจำ:',
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.availableColors.length + 1,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = widget.selectedColor == null;
                  return GestureDetector(
                    onTap: () => widget.onSelectColor(null),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? textPrimary : borderColor,
                        ),
                      ),
                      child: Icon(
                        Icons.format_color_reset_rounded,
                        size: 16,
                        color: textSecondary,
                      ),
                    ),
                  );
                }
                final color = widget.availableColors[index - 1];
                final isSelected = color == widget.selectedColor;
                return GestureDetector(
                  onTap: () => widget.onSelectColor(color),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
