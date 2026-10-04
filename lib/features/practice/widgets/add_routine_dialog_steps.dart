// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (add routine dialog steps)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'add_routine_dialog.dart';

extension _AddRoutineDialogSteps on _AddRoutineDialogState {
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
