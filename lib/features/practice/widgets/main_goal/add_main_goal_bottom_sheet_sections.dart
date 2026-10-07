part of 'add_main_goal_bottom_sheet.dart';

extension _AddMainGoalBottomSheetSections on _AddMainGoalBottomSheetState {
  List<Widget> _buildHeader(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) => [
    // Header Title
    Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF23352A) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.flag_rounded,
            color: isDark
                ? AppTheme.primaryLightGreen
                : const Color(0xFF0F9C58),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ตั้งเป้าหมายหลัก (Set Main Goal)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            Text(
              'เป้าหมายระยะยาวพร้อมยอดสะสมและวันสิ้นสุด',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
      ],
    ),
    const SizedBox(height: 20),
  ];
  List<Widget> _buildGoalTypeSection(
    bool isDark,
    Color surfaceBg,
    Color borderColor,
    Color textPrimary,
  ) => [
    // Section 1: Goal Type Selection
    Text(
      'ส่วนที่ 1: เลือกประเภทความท้าทาย (Goal Type)',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF006432),
      ),
    ),
    const SizedBox(height: 10),
    GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _AddMainGoalBottomSheetState.templates.length,
      itemBuilder: (context, index) {
        final t = _AddMainGoalBottomSheetState.templates[index];
        final isSelected = index == _selectedTemplateIndex;

        return InkWell(
          onTap: () => _onSelectTemplate(index),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFF23352A) : const Color(0xFFE8F5E9))
                  : surfaceBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? (isDark
                          ? AppTheme.primaryLightGreen
                          : const Color(0xFF0F9C58))
                    : borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Text(t.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? (isDark
                                ? AppTheme.primaryLightGreen
                                : const Color(0xFF006432))
                          : textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
    const SizedBox(height: 20),
  ];
}
