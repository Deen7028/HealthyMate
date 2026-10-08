part of 'add_main_goal_bottom_sheet.dart';
// ส่วน UI ปุ่มกดบันทึก/ยืนยัน และช่องปรับแต่งค่าเป้าหมายใน BottomSheet
extension _AddMainGoalBottomSheetActionsUi on _AddMainGoalBottomSheetState {
  List<Widget> _buildDeadlineSection(
    bool isDark,
    Color surfaceBg,
    Color borderColor,
    Color textPrimary,
  ) => [
    // ส่วนที่ 3 กำหนดวันเสร็จสิ้นเป้าหมายหลัก
    Text(
      'ส่วนที่ 3: กำหนดเส้นตาย (Deadline)',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF006432),
      ),
    ),
    const SizedBox(height: 10),
    Row(
      children: [
        Expanded(
          child: _buildDeadlineOption(
            isDark: isDark,
            surfaceBg: surfaceBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            type: '1_week',
            label: '1 สัปดาห์\n(7 วัน)',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDeadlineOption(
            isDark: isDark,
            surfaceBg: surfaceBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            type: '1_month',
            label: '1 เดือน\n(30 วัน)',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDeadlineOption(
            isDark: isDark,
            surfaceBg: surfaceBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            type: 'custom',
            label: _deadlineType == 'custom'
                ? '${_customDeadlineDate.day}/${_customDeadlineDate.month}/${_customDeadlineDate.year}'
                : 'เลือกวันเอง\n(Custom)',
            onTapCustom: _pickCustomDate,
          ),
        ),
      ],
    ),
    const SizedBox(height: 24),
  ];
  List<Widget> _buildSaveButton(bool isDark) => [
    //  ปุ่มยืนยันการตั้งเป้าหมายหลัก
    SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? const Color(0xFF2E5327)
              : const Color(0xFF006432),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'ยืนยันการตั้งเป้าหมายหลัก',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  ];
  List<Widget> _buildTargetSection(
    bool isDark,
    Color surfaceBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    MainGoalTemplate selectedTemplate,
  ) => [
    // ส่วนที่ 2 กำหนดเส้นชัย
    Text(
      'ส่วนที่ 2: กำหนดเส้นชัย (Target & Unit)',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF006432),
      ),
    ),
    const SizedBox(height: 10),
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: _targetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              labelText: 'ตัวเลขเป้าหมาย',
              labelStyle: TextStyle(color: textSecondary),
              hintText: 'เช่น 50',
              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
              prefixIcon: Icon(
                Icons.track_changes,
                color: isDark
                    ? AppTheme.primaryLightGreen
                    : const Color(0xFF0F9C58),
              ),
              filled: true,
              fillColor: surfaceBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? AppTheme.primaryLightGreen
                      : const Color(0xFF0F9C58),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF23352A) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  (isDark
                          ? AppTheme.primaryLightGreen
                          : const Color(0xFF0F9C58))
                      .withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            selectedTemplate.defaultUnit,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.primaryLightGreen
                  : const Color(0xFF006432),
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 20),
  ];
}
