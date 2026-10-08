part of 'add_routine_dialog.dart';
// ส่วนต่างๆของหน้าต่างเพิ่มกิจกรรมใหม่
extension _AddRoutineDialogSteps on _AddRoutineDialogState {
  // ขั้นตอนที่ 1 เลือกประเภทและชื่อกิจกรรม
  Widget _buildStep1Goal(Color btnColor) {
    return RoutineStepCategory(
      selectedCategory: _selectedCategory,
      titleController: _titleController,
      onCategoryChanged: _onCategoryChanged,
      onTitleChanged: (val) {
        final detected = _detectLinkedWorkout(val, _selectedCategory);
        if (detected != _selectedLinkedWorkout) {
          setState(() {
            _selectedLinkedWorkout = detected;
          });
        }
      },
    );
  }
  // ขั้นตอนที่ 2 กำหนดระยะเวลาและการเชื่อมโยงกับแอปภายนอก
  Widget _buildStep2DurationAndSync(Color btnColor) {
    final title = _titleController.text.trim();
    final autoDetected = _detectLinkedWorkout(title, _selectedCategory);
    final lowerTitle = title.toLowerCase();
    final isNonWorkout =
        lowerTitle.contains('น้ำ') ||
        lowerTitle.contains('สมาธิ') ||
        lowerTitle.contains('นอน') ||
        lowerTitle.contains('กิน') ||
        lowerTitle.contains('อาหาร') ||
        lowerTitle.contains('ยา') ||
        lowerTitle.contains('อ่าน');
    final isWorkoutCategory = _selectedCategory == RoutineCategory.fitness;
    final showGpsSyncOption =
        !isNonWorkout && (autoDetected != null || isWorkoutCategory);

    return RoutineStepGoal(
      targetController: _targetController,
      unitController: _unitController,
      selectedLinkedWorkout: _selectedLinkedWorkout,
      autoDetected: autoDetected,
      showGpsSyncOption: showGpsSyncOption,
      onToggleAutoLink: (val) {
        setState(() {
          _selectedLinkedWorkout = val ? (autoDetected ?? 'วิ่ง') : '';
        });
      },
      onSelectUnit: (unit) {
        setState(() {
          _unitController.text = unit;
        });
      },
    );
  }
  // ขั้นตอนที่ 3 ตั้งค่าการแจ้งเตือนและรูปแบบกิจกรรม
  Widget _buildStep3NotifyAndStyle(Color btnColor) {
    return RoutineStepStyle(
      btnColor: btnColor,
      isNotificationEnabled: _isNotificationEnabled,
      notificationTimeController: _notificationTimeController,
      onToggleNotification: (val) {
        setState(() {
          _isNotificationEnabled = val;
        });
      },
      selectedIcon: _selectedIcon,
      selectedColor: _selectedColor,
      availableIcons: _availableIcons,
      availableColors: _availableColors,
      onSelectIcon: (icon) => setState(() => _selectedIcon = icon),
      onSelectColor: (color) => setState(() => _selectedColor = color),
    );
  }
}
