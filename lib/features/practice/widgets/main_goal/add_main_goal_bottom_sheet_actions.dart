part of 'add_main_goal_bottom_sheet.dart';
// ตรรกะการทำงานและการบันทึกข้อมูลเป้าหมายหลักลงฐานข้อมูล
extension _AddMainGoalBottomSheetActions on _AddMainGoalBottomSheetState {
  void _onSelectTemplate(int index) {
    setState(() {
      _selectedTemplateIndex = index;
      final t = _AddMainGoalBottomSheetState.templates[index];
      _targetController.text = t.defaultTarget == t.defaultTarget.toInt()
          ? t.defaultTarget.toInt().toString()
          : t.defaultTarget.toString();
    });
  }
  // คำนวณวันที่เสร็จสิ้นเป้าหมายหลัก
  DateTime _getCalculatedDeadline() {
    final now = DateTime.now();
    if (_deadlineType == '1_week') {
      return now.add(const Duration(days: 7));
    } else if (_deadlineType == '1_month') {
      return now.add(const Duration(days: 30));
    } else {
      return _customDeadlineDate;
    }
  }
  // ฟังก์ชันเปิดปฏิทินเพื่อเลือกวันที่กำหนดเอง
  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDeadlineDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      locale: const Locale('th', 'TH'),
      helpText: 'เลือกวันที่',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
      fieldHintText: 'วัน/เดือน/ปี',
      fieldLabelText: 'กรอกวันที่',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDark
                  ? AppTheme.primaryLightGreen
                  : const Color(0xFF0F9C58),
              onPrimary: Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF1C2819),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _deadlineType = 'custom';
        _customDeadlineDate = picked;
      });
    }
  }
  // ฟังก์ชันบันทึกข้อมูลเป้าหมายหลัก
  void _submit() {
    final targetText = _targetController.text.trim();
    final targetVal = double.tryParse(targetText) ?? 0.0;
    if (targetVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกตัวเลขเป้าหมายที่ถูกต้อง'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    final selectedTemplate =
        _AddMainGoalBottomSheetState.templates[_selectedTemplateIndex];
    final deadlineDate = _getCalculatedDeadline();
    // ส่งข้อมูลกลับไปที่หน้าจอหลัก
    Navigator.pop(context, {
      'title': selectedTemplate.title,
      'icon': selectedTemplate.icon,
      'unit': selectedTemplate.defaultUnit,
      'targetValue': targetVal,
      'linkedWorkout': selectedTemplate.linkedWorkout,
      'deadlineDate': deadlineDate,
    });
  }
}
