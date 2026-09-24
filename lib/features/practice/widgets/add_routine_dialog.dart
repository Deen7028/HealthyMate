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
        linkedWorkoutType: autoLinkedWorkout,
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

  // --- Step 1: Visual Category Picker (การ์ดหมวดหมู่ขนาดใหญ่ สไตล์ CategorySelectionView) ---
  Widget _buildStep1Goal(Color btnColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1: เลือกหมวดหมู่ & ชื่อกิจวัตร 🎯',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E281F),
            ),
          ),
          const SizedBox(height: 12),

          // 2.1 Visual Category Picker (เลือกหมวดหมู่ด้วยการ์ดใหญ่)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: RoutineCategory.values.map((cat) {
              final isSelected = cat == _selectedCategory;
              return InkWell(
                onTap: () => _onCategoryChanged(cat),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2E5327)
                        : const Color(0xFFF4F7F4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2E5327) : const Color(0xFFE2E9E0),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2E5327).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : const Color(0xFFE8F3EB),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat.icon,
                          size: 20,
                          color: isSelected ? Colors.white : const Color(0xFF2E5327),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF1E281F),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            onChanged: (val) {
              // 2.2 Smart Workout Auto-Link (ตรวจจับ Keyword อัตโนมัติขณะพิมพ์)
              final detected = _detectLinkedWorkout(val, _selectedCategory);
              if (detected != _selectedLinkedWorkout) {
                setState(() {
                  _selectedLinkedWorkout = detected;
                });
              }
            },
            decoration: InputDecoration(
              labelText: 'ชื่อกิจวัตร / นิสัย *',
              hintText: 'เช่น วิ่งสเปรดเช้า, ปั่นจักรยานรอบสวน, ดื่มน้ำ 2000 มล.',
              prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2E5327)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E9E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2E5327), width: 1.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Smart Workout Auto-Link & Target Commitment ---
  Widget _buildStep2DurationAndSync(Color btnColor) {
    final autoDetected = _detectLinkedWorkout(_titleController.text.trim(), _selectedCategory);
    final isAutoLinked = _selectedLinkedWorkout != null && _selectedLinkedWorkout!.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2: เป้าหมาย & เชื่อมโยง GPS ออกกำลังกาย 🔗',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E281F),
            ),
          ),
          const SizedBox(height: 14),

          // 2.3 Target & Goal Commitment (การกำหนดเป้าหมายที่ยืดหยุ่น)
          const Text(
            'กำหนดเป้าหมายเชิงปริมาณ',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),

          // Quick Selector สำหรับเลือกหน่วย (สไตล์เดียวกับตัวเลือกแผนที่ Standard, Satellite, Hybrid)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E9E0)),
            ),
            child: Row(
              children: [
                _buildQuickUnitButton('กม.', 'ระยะทาง'),
                _buildQuickUnitButton('นาที', 'เวลา'),
                _buildQuickUnitButton('ครั้ง', 'จำนวน'),
                _buildQuickUnitButton('มล.', 'โภชนาการ'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'เป้าหมายต่อวัน *',
                    hintText: 'เช่น 5, 30, 2000',
                    prefixIcon: const Icon(Icons.flag_rounded, color: Color(0xFF2E5327)),
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
                    labelText: 'หน่วยวัด',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2.2 Smart Workout Auto-Link (ระบบตรวจจับกีฬาอัตโนมัติ)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isAutoLinked ? const Color(0xFFE8F3EB) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAutoLinked ? const Color(0xFF2E5327) : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.link_rounded,
                            color: isAutoLinked ? const Color(0xFF2E5327) : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '🔗 เชื่อมโยงข้อมูล GPS ออกกำลังกายอัตโนมัติ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isAutoLinked ? const Color(0xFF2E5327) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isAutoLinked,
                      onChanged: (val) {
                        setState(() {
                          _selectedLinkedWorkout = val ? (autoDetected ?? 'วิ่ง') : null;
                        });
                      },
                      activeThumbColor: const Color(0xFF2E5327),
                    ),
                  ],
                ),
                if (isAutoLinked) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBE3D3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          'ตรวจจับกีฬา: "${_selectedLinkedWorkout ?? autoDetected}" Auto-GPS Sync',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E5327),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickUnitButton(String unit, String label) {
    final isSelected = _unitController.text.trim() == unit;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _unitController.text = unit;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E5327) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                unit,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
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
