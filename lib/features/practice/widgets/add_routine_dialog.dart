// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';
import '../models/routine_item.dart';
import 'routine_step_category.dart';
import 'routine_step_goal.dart';
import 'routine_step_style.dart';

class AddRoutineDialog extends StatefulWidget {
  final Map<String, dynamic>? initialRoutine;

  const AddRoutineDialog({super.key, this.initialRoutine});

  @override
  State<AddRoutineDialog> createState() => _AddRoutineDialogState();
}

class _AddRoutineDialogState extends State<AddRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  int _currentStep = 0; // 0: Step 1 (Target), 1: Step 2 (Duration & Sync), 2: Step 3 (Notify & Style)

  // Controllers & Form fields
  final _titleController = TextEditingController();
  final _targetController = TextEditingController(text: '10');
  final _unitController = TextEditingController(text: 'นาที');
  final _notificationTimeController = TextEditingController(text: '08:00 น.');
  final _durationController = TextEditingController(text: '1');

  final String _durationUnit = 'เดือน';
  String? _selectedLinkedWorkout;
  final List<String> _workoutTypes = [
    'วิ่ง',
    'เดิน',
    'ปั่นจักรยาน',
    'ลู่วิ่งในร่ม',
  ];

  RoutineCategory _selectedCategory = RoutineCategory.health;
  IconData? _selectedIcon;
  Color? _selectedColor;
  bool _isNotificationEnabled = true;

  final List<IconData> _availableIcons = [
    Icons.water_drop_rounded,
    Icons.directions_walk_rounded,
    Icons.self_improvement_rounded,
    Icons.restaurant_rounded,
    Icons.favorite_rounded,
    Icons.fitness_center_rounded,
    Icons.bedtime_rounded,
    Icons.book_rounded,
    Icons.directions_run_rounded,
    Icons.nature_people_rounded,
    Icons.pool_rounded,
    Icons.star_rounded,
  ];

  final List<Color> _availableColors = [
    const Color(0xFF0288D1),
    const Color(0xFF4CAF50),
    const Color(0xFF7E57C2),
    const Color(0xFFFF9800),
    const Color(0xFFE91E63),
    const Color(0xFF009688),
    const Color(0xFF3F51B5),
    const Color(0xFFFF5722),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIcon = _selectedCategory.icon;
    _selectedColor = _selectedCategory.defaultColor;

    if (widget.initialRoutine != null) {
      final r = widget.initialRoutine!;
      _titleController.text = (r['sTitle'] ?? r['title'])?.toString() ?? '';
      _notificationTimeController.text =
          (r['sTime'] ?? r['time'] ?? r['notificationTime'])?.toString() ?? '';

      final targetVal = (r['targetValue'] as num?)?.toDouble() ??
          (r['nTargetValue'] as num?)?.toDouble();
      if (targetVal != null && targetVal > 0) {
        _targetController.text = targetVal == targetVal.toInt()
            ? targetVal.toInt().toString()
            : targetVal.toString();
      }

      final unitStr = (r['unit'] ?? r['sUnit'])?.toString();
      if (unitStr != null && unitStr.isNotEmpty) {
        _unitController.text = unitStr;
      }

      final isNotif = r['isNotificationActive'] ?? r['isNotificationEnabled'];
      if (isNotif != null) {
        _isNotificationEnabled =
            isNotif is bool ? isNotif : (isNotif as num).toInt() == 1;
      }

      final linked =
          (r['sLinkedWorkout'] ?? r['linkedWorkoutType'])?.toString();
      if (linked != null &&
          linked.isNotEmpty &&
          _workoutTypes.contains(linked)) {
        _selectedLinkedWorkout = linked;
      }

      final unitLower = (_unitController.text).toLowerCase();
      final titleLower = (_titleController.text).toLowerCase();
      if (unitLower.contains('มล') || titleLower.contains('ดื่มน้ำ')) {
        _selectedCategory = RoutineCategory.water;
      } else if (unitLower.contains('ก้าว') ||
          titleLower.contains('วิ่ง') ||
          titleLower.contains('เดิน') ||
          titleLower.contains('ปั่น')) {
        _selectedCategory = RoutineCategory.fitness;
      } else if (unitLower.contains('มื้อ') ||
          titleLower.contains('ทาน') ||
          titleLower.contains('กิน')) {
        _selectedCategory = RoutineCategory.nutrition;
      } else if (titleLower.contains('สมาธิ') || titleLower.contains('นอน')) {
        _selectedCategory = RoutineCategory.mindfulness;
      }

      final iconCode =
          (r['iconData'] as num?)?.toInt() ?? (r['nIconData'] as num?)?.toInt();
      if (iconCode != null && iconCode > 0) {
        _selectedIcon = IconData(iconCode, fontFamily: 'MaterialIcons');
      } else {
        _selectedIcon = _selectedCategory.icon;
      }

      final colorVal =
          (r['color'] as num?)?.toInt() ?? (r['nColor'] as num?)?.toInt();
      if (colorVal != null && colorVal != 0) {
        _selectedColor = Color(colorVal);
      } else {
        _selectedColor = _selectedCategory.defaultColor;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    _notificationTimeController.dispose();
    _durationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

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
    const workoutKeywords = ['วิ่ง', 'เดิน', 'ปั่นจักรยาน', 'จักรยาน', 'ลู่วิ่ง', 'คาร์ดิโอ', 'ออกกำลังกาย', 'run', 'walk', 'bike', 'cycle'];
    final bool hasWorkout = workoutKeywords.any((kw) => lower.contains(kw));
    final isNonWorkout = !hasWorkout && (
        lower.contains('น้ำ') ||
        lower.contains('สมาธิ') ||
        lower.contains('นอน') ||
        lower.contains('กิน') ||
        lower.contains('อาหาร') ||
        lower.contains('ยา') ||
        lower.contains('อ่าน')
    );

    if (isNonWorkout) return null;

    if (lower.contains('วิ่ง') || lower.contains('run')) {
      return 'วิ่ง';
    } else if (lower.contains('ลู่วิ่ง') || lower.contains('treadmill')) {
      return 'ลู่วิ่งในร่ม';
    } else if (lower.contains('เดิน') || lower.contains('walk') || lower.contains('ก้าว') || lower.contains('step')) {
      return 'เดิน';
    } else if (lower.contains('จักรยาน') || lower.contains('ปั่น') || lower.contains('bike') || lower.contains('cycle')) {
      return 'ปั่นจักรยาน';
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

  @override
  Widget build(BuildContext context) {
    final btnColor = _selectedColor ?? const Color(0xFF2E5327);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicator handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title Header & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialRoutine != null
                        ? 'แก้ไขกิจวัตร (Step ${_currentStep + 1}/3)'
                        : 'สร้างกิจวัตรใหม่ (Step ${_currentStep + 1}/3)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // Wizard Progress Bar
              Row(
                children: List.generate(3, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: 4,
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: isActive ? btnColor : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Page Content Wizard
              SizedBox(
                height: 380,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1Goal(btnColor),
                    _buildStep2DurationAndSync(btnColor),
                    _buildStep3NotifyAndStyle(btnColor),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Wizard Bottom Controls Navigation
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('ย้อนกลับ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _nextStep,
                      icon: Icon(
                        _currentStep == 2
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        _currentStep == 2 ? 'บันทึกกิจวัตร' : 'ถัดไป',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

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
    final isNonWorkout = lowerTitle.contains('น้ำ') ||
        lowerTitle.contains('สมาธิ') ||
        lowerTitle.contains('นอน') ||
        lowerTitle.contains('กิน') ||
        lowerTitle.contains('อาหาร') ||
        lowerTitle.contains('ยา') ||
        lowerTitle.contains('อ่าน');
    final isWorkoutCategory = _selectedCategory == RoutineCategory.fitness;
    final showGpsSyncOption = !isNonWorkout && (autoDetected != null || isWorkoutCategory);

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
