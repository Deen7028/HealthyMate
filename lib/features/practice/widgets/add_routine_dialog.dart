import 'package:flutter/material.dart';
import '../models/routine_item.dart';

class AddRoutineDialog extends StatefulWidget {
  // เพิ่มตัวแปรสำหรับรับข้อมูลเก่ากรณีแก้ไข
  final Map<String, dynamic>? initialRoutine;

  const AddRoutineDialog({super.key, this.initialRoutine});

  @override
  State<AddRoutineDialog> createState() => _AddRoutineDialogState();
}

class _AddRoutineDialogState extends State<AddRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController(text: '10');
  final _unitController = TextEditingController(text: 'นาที');
  final _notificationTimeController = TextEditingController(text: '08:00 น.');

  // เพิ่มตัวแปรเก็บค่าประเภทออกกำลังกายที่ลิงก์ไว้
  String? _selectedLinkedWorkout;
  final List<String> _workoutTypes = [
    'วิ่ง',
    'เดิน',
    'ปั่นจักรยาน',
    'ลู่วิ่งในร่ม',
  ];

  // เพิ่ม Controller และตัวแปรสำหรับระยะเวลาเป้าหมาย
  final _durationController = TextEditingController(text: '1');
  String _durationUnit = 'เดือน'; // ค่าเริ่มต้น

  RoutineCategory _selectedCategory = RoutineCategory.health;

  // เปลี่ยนเป็น nullable (?) เพื่อให้สามารถเลือก "ไม่เอาไอคอน" หรือ "ไม่เอาสี" ได้
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

      // 🔥 ดึงค่าการลิงก์ออกกำลังกายจาก DB มาแสดง (สมมติว่าใช้ชื่อฟิลด์ sLinkedWorkout)
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // เนื่องจาก RoutineItem ต้องการ IconData และ Color ที่ห้ามเป็น null
      // จึงใส่ค่า Fallback สีเทา/โปร่งใส หากผู้ใช้เลือก "ไม่เอาไอคอน/สี"
      final finalIcon = _selectedIcon ?? Icons.lens;
      final finalColor = _selectedColor ?? Colors.grey.shade400;

      final newItem = RoutineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        category: _selectedCategory,
        iconData: finalIcon,
        color: finalColor,
        targetValue: double.tryParse(_targetController.text.trim()) ?? 1,
        unit: _unitController.text.trim(),
        isNotificationEnabled: _isNotificationEnabled,
        notificationTime: _notificationTimeController.text.trim(),
        repeatDays: ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'],
        linkedWorkoutType: _selectedLinkedWorkout,
      );

      // หมายเหตุ: ค่าระยะเวลา ( _durationController.text และ _durationUnit )
      // สามารถนำไปขยายผลส่งเข้า Database ได้ที่นี่ หากมีการเพิ่ม Field ใน RoutineItem
      debugPrint(
        'เป้าหมายระยะเวลา: ${_durationController.text} $_durationUnit',
      );

      Navigator.of(context).pop(newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    // สีหลักสำหรับปุ่มบันทึก หากไม่ได้เลือกสีให้ใช้สีเขียวเริ่มต้น
    final btnColor = _selectedColor ?? const Color(0xFF2E5327);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header indicator
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    // เปลี่ยนข้อความตามโหมด
                    widget.initialRoutine != null
                        ? 'แก้ไขกิจวัตร'
                        : 'เพิ่มกิจวัตรใหม่',
                    style: const TextStyle(
                      fontSize: 20,
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
              const SizedBox(height: 16),

              // Habit Title Input
              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'ชื่อกิจวัตร / นิสัย *',
                  hintText: 'เช่น ดื่มน้ำ 1 แก้วใหญ่, วิ่งจ๊อกกิ้ง 30 นาที',
                  prefixIcon: Icon(Icons.edit_note_rounded, color: btnColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อกิจวัตร';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selector Chips
              const Text(
                'หมวดหมู่กิจวัตร',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                    onSelected: (_) => _onCategoryChanged(cat),
                    selectedColor: cat.defaultColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Target & Unit Inputs
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'เป้าหมายประจำวัน *',
                        prefixIcon: const Icon(Icons.track_changes_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'ใส่ตัวเลข';
                        return null;
                      },
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
              const SizedBox(height: 16),

              // *** ระยะเวลาเป้าหมาย (ใหม่) ***
              const Text(
                'ระยะเวลาของเป้าหมาย',
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
                      value: _durationUnit,
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
              const SizedBox(height: 16),

              const SizedBox(height: 16),

              // *** เลือกซิงค์ข้อมูลออกกำลังกาย (ใหม่) ***
              const Text(
                'เชื่อมโยงข้อมูลออกกำลังกาย (อัปเดตอัตโนมัติ)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedLinkedWorkout,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.sync_rounded),
                  hintText: 'ไม่ซิงค์ข้อมูล',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('ไม่ซิงค์ข้อมูล'),
                  ),
                  ..._workoutTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                ],
                onChanged: (String? val) {
                  setState(() => _selectedLinkedWorkout = val);
                },
              ),

              // Notification Settings
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
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
                            const SizedBox(width: 10),
                            const Text(
                              'เปิดใช้งานการแจ้งเตือน',
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
                      const SizedBox(height: 10),
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
              const SizedBox(height: 16),

              // *** ไอคอน (มีปุ่มไม่เอาไอคอน) ***
              Row(
                children: [
                  const Text(
                    'ไอคอน:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            _availableIcons.length + 1, // +1 สำหรับปุ่ม "None"
                        separatorBuilder: (ctx, idx) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected = _selectedIcon == null;
                            return InkWell(
                              onTap: () => setState(() => _selectedIcon = null),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade100,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.block,
                                  size: 20,
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            );
                          }
                          final icon = _availableIcons[index - 1];
                          final isSelected = icon == _selectedIcon;
                          return InkWell(
                            onTap: () => setState(() => _selectedIcon = icon),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? btnColor.withAlpha(50)
                                    : Colors.grey.shade100,
                                border: Border.all(
                                  color: isSelected
                                      ? btnColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                size: 20,
                                color: isSelected
                                    ? btnColor
                                    : Colors.grey.shade700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // *** สีประจำ (มีปุ่มไม่เอาสี) ***
              Row(
                children: [
                  const Text(
                    'สีประจำ:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            _availableColors.length + 1, // +1 สำหรับปุ่ม "None"
                        separatorBuilder: (ctx, idx) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected = _selectedColor == null;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedColor = null),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.grey.shade300,
                                    width: 2.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.format_color_reset_rounded,
                                  size: 18,
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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                  label: const Text(
                    'บันทึกกิจวัตร',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
