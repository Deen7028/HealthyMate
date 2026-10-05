// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (add routine dialog actions)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'add_routine_dialog.dart';

extension _AddRoutineDialogActions on _AddRoutineDialogState {
  void _onCategoryChanged(RoutineCategory category) {
    setState(() {
      _selectedCategory = category;
      _selectedIcon = category.icon;
      _selectedColor = category.defaultColor;

      if (widget.initialRoutine == null) {
        switch (category) {
          case RoutineCategory.water:
            _targetController.text = '2000';
            _unitController.text = 'มล.';
            _notificationTimeController.text = 'ทุก 2 ชั่วโมง';
            break;
          case RoutineCategory.fitness:
            _targetController.text = '10';
            _unitController.text = 'กม.';
            _notificationTimeController.text = '12:00 & 18:00';
            break;
          case RoutineCategory.mindfulness:
            _targetController.text = '15';
            _unitController.text = 'นาที';
            _notificationTimeController.text = '21:30 น.';
            break;
          case RoutineCategory.nutrition:
            _targetController.text = '3';
            _unitController.text = 'มื้อ';
            _notificationTimeController.text = '08:00, 12:30, 18:30';
            break;
          default:
            _targetController.text = '1';
            _unitController.text = 'ครั้ง';
            _notificationTimeController.text = '09:00 น.';
        }
      }
    });
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณากรอกชื่อกิจวัตร'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final targetVal = double.tryParse(_targetController.text.trim());
      if (targetVal == null || targetVal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เป้าหมายต้องเป็นตัวเลขที่มากกว่า 0'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String? _detectLinkedWorkout(String title, RoutineCategory category) {
    final lower = title.toLowerCase();
    const workoutKeywords = [
      'วิ่ง',
      'เดิน',
      'ปั่นจักรยาน',
      'จักรยาน',
      'ลู่วิ่ง',
      'คาร์ดิโอ',
      'ออกกำลังกาย',
      'run',
      'walk',
      'bike',
      'cycle',
      'สมาธิ',
      'meditation',
      'โยคะ',
      'yoga',
    ];
    final bool hasWorkout = workoutKeywords.any((kw) => lower.contains(kw));
    final isNonWorkout =
        !hasWorkout &&
        (lower.contains('น้ำ') ||
            lower.contains('นอน') ||
            lower.contains('กิน') ||
            lower.contains('อาหาร') ||
            lower.contains('ยา') ||
            lower.contains('อ่าน'));

    if (isNonWorkout) return null;

    if (lower.contains('วิ่ง') || lower.contains('run')) {
      return 'วิ่ง';
    } else if (lower.contains('ลู่วิ่ง') || lower.contains('treadmill')) {
      return 'ลู่วิ่งในร่ม';
    } else if (lower.contains('เดิน') ||
        lower.contains('walk') ||
        lower.contains('ก้าว') ||
        lower.contains('step')) {
      return 'เดิน';
    } else if (lower.contains('จักรยาน') ||
        lower.contains('ปั่น') ||
        lower.contains('bike') ||
        lower.contains('cycle')) {
      return 'ปั่นจักรยาน';
    } else if (lower.contains('สมาธิ') || lower.contains('meditation')) {
      return 'ทำสมาธิ';
    } else if (lower.contains('โยคะ') || lower.contains('yoga')) {
      return 'โยคะ';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final finalIcon = _selectedIcon ?? Icons.lens;
      final finalColor = _selectedColor ?? Colors.grey.shade400;
      final title = _titleController.text.trim();
      final autoLinkedWorkout = _detectLinkedWorkout(title, _selectedCategory);

      final newItem = RoutineItem(
        id: widget.initialRoutine != null
            ? (widget.initialRoutine!['nRoutineId']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString())
            : DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        category: _selectedCategory,
        iconData: finalIcon,
        color: finalColor,
        targetValue: double.tryParse(_targetController.text.trim()) ?? 1,
        unit: _unitController.text.trim(),
        isNotificationEnabled: _isNotificationEnabled,
        notificationTime: _notificationTimeController.text.trim(),
        repeatDays: ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'],
        linkedWorkoutType: _selectedLinkedWorkout ?? autoLinkedWorkout,
      );

      debugPrint(
        'เป้าหมายระยะเวลา: ${_durationController.text} $_durationUnit (Auto-link: $autoLinkedWorkout)',
      );

      Navigator.of(context).pop(newItem);
    }
  }
}
