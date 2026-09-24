import 'package:flutter/material.dart';
import '../models/routine_item.dart';

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

  String _durationUnit = 'เดือน';
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
      _titleController.text =
          widget.initialRoutine!['sTitle']?.toString() ?? '';
      _notificationTimeController.text =
          widget.initialRoutine!['sTime']?.toString() ?? '';

      final isNotif = widget.initialRoutine!['isNotificationActive'];
      if (isNotif != null) {
        _isNotificationEnabled = (isNotif as num).toInt() == 1;
      }

      final linked = widget.initialRoutine!['sLinkedWorkout']?.toString();
      if (linked != null &&
          linked.isNotEmpty &&
          _workoutTypes.contains(linked)) {
        _selectedLinkedWorkout = linked;
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

      switch (category) {
        case RoutineCategory.water:
          _targetController.text = '2000';
          _unitController.text = 'มล.';
          _notificationTimeController.text = 'ทุก 2 ชั่วโมง';
          break;
        case RoutineCategory.fitness:
          _targetController.text = '10000';
          _unitController.text = 'ก้าว';
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
    if (lower.contains('วิ่ง') || lower.contains('run')) {
      return 'วิ่ง';
    } else if (lower.contains('ลู่วิ่ง') || lower.contains('treadmill')) {
      return 'ลู่วิ่งในร่ม';
    } else if (lower.contains('เดิน') || lower.contains('walk') || lower.contains('ก้าว') || lower.contains('step')) {
      return 'เดิน';
    } else if (lower.contains('จักรยาน') || lower.contains('ปั่น') || lower.contains('bike') || lower.contains('cycle')) {
      return 'ปั่นจักรยาน';
    } else if (category == RoutineCategory.fitness) {
      return 'เดิน';
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
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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
                    child: Container(
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

  // --- Step 1: เป้าหมายหลัก และหมวดหมู่ ---
  Widget _buildStep1Goal(Color btnColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1: กำหนดเป้าหมายกิจกรรม 🎯',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'ชื่อกิจวัตร / นิสัย *',
              hintText: 'เช่น ดื่มน้ำ 1 แก้วใหญ่, วิ่งจ๊อกกิ้ง 30 นาที',
              prefixIcon: Icon(Icons.edit_note_rounded, color: btnColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'เลือกหมวดหมู่กิจกรรม',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: RoutineCategory.values.map((cat) {
              final isSelected = cat == _selectedCategory;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : cat.defaultColor,
                    ),
                    const SizedBox(width: 6),
                    Text(cat.label),
                  ],
                ),
                selected: isSelected,
                selectedColor: btnColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => _onCategoryChanged(cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'เป้าหมายต่อวัน *',
                    hintText: 'เช่น 2000, 30',
                    prefixIcon: const Icon(Icons.flag_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    labelText: 'หน่วย *',
                    hintText: 'มล. / นาที',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Step 2: ระยะเวลาของเป้าหมาย & การเชื่อมโยงข้อมูลออกกำลังกาย ---
  Widget _buildStep2DurationAndSync(Color btnColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2: ความต่อเนื่อง และการซิงค์ข้อมูล 🔄',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'ระยะเวลาการทำสัญญาพฤติกรรม (Goal Commitment)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'จำนวนเวลา',
                    prefixIcon: const Icon(Icons.date_range_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  initialValue: _durationUnit,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: ['วัน', 'เดือน', 'ปี'].map((String unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (String? val) {
                    if (val != null) setState(() => _durationUnit = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFF0EA5E9), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ระบบตรวจจับการออกกำลังกายอัตโนมัติ ⚡',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'เมื่อระบุคำว่า วิ่ง, เดิน, ปั่นจักรยาน หรือลู่วิ่ง ระบบจะซิงค์สถิติกับกิจกรรมสุขภาพให้อัตโนมัติโดยไม่จำเป็นต้องเลือกซิงค์ด้วยตนเอง',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 3: การแจ้งเตือน และการตกแต่งดีไซน์ ---
  Widget _buildStep3NotifyAndStyle(Color btnColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 3: การแจ้งเตือนและธีมกิจวัตร 🔔🎨',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),

          // Notification Settings Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isNotificationEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          color: _isNotificationEnabled
                              ? Colors.amber.shade800
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'การแจ้งเตือนประจำวัน',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isNotificationEnabled,
                      onChanged: (val) {
                        setState(() {
                          _isNotificationEnabled = val;
                        });
                      },
                      activeThumbColor: btnColor,
                    ),
                  ],
                ),
                if (_isNotificationEnabled) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notificationTimeController,
                    decoration: InputDecoration(
                      labelText: 'เวลา / ความถี่การแจ้งเตือน',
                      hintText: 'เช่น 08:00 น. หรือ ทุก 2 ชั่วโมง',
                      prefixIcon: const Icon(Icons.access_time_rounded),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Icon Picker
          Row(
            children: [
              const Text('ไอคอน:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableIcons.length + 1,
                    separatorBuilder: (ctx, idx) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedIcon == null;
                        return InkWell(
                          onTap: () => setState(() => _selectedIcon = null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: const Icon(Icons.block, size: 18, color: Colors.grey),
                          ),
                        );
                      }
                      final icon = _availableIcons[index - 1];
                      final isSelected = icon == _selectedIcon;
                      return InkWell(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? btnColor.withAlpha(50)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? btnColor : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: 18,
                            color: isSelected ? btnColor : Colors.grey.shade700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Color Picker
          Row(
            children: [
              const Text('สีประจำ:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableColors.length + 1,
                    separatorBuilder: (ctx, idx) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedColor == null;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = null),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: const Icon(
                              Icons.format_color_reset_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      final color = _availableColors[index - 1];
                      final isSelected = color == _selectedColor;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
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
          ),
        ],
      ),
    );
  }
}
