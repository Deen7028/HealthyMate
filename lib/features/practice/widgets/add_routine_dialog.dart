import 'package:flutter/material.dart';
import '../models/routine_item.dart';

class AddRoutineDialog extends StatefulWidget {
  const AddRoutineDialog({super.key});

  @override
  State<AddRoutineDialog> createState() => _AddRoutineDialogState();
}

class _AddRoutineDialogState extends State<AddRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController(text: '10');
  final _unitController = TextEditingController(text: 'นาที');
  final _notificationTimeController = TextEditingController(text: '08:00 น.');

  RoutineCategory _selectedCategory = RoutineCategory.health;
  late IconData _selectedIcon;
  late Color _selectedColor;
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    _notificationTimeController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(RoutineCategory category) {
    setState(() {
      _selectedCategory = category;
      _selectedIcon = category.icon;
      _selectedColor = category.defaultColor;

      // Suggest default units based on category
      switch (category) {
        case RoutineCategory.water:
          _targetController.text = '2000';
          _unitController.text = 'มล.';
          _notificationTimeController.text = 'ทุก 2 ชั่วโมง (08:00 - 20:00)';
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
      final newItem = RoutineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        category: _selectedCategory,
        iconData: _selectedIcon,
        color: _selectedColor,
        targetValue: double.tryParse(_targetController.text.trim()) ?? 1,
        unit: _unitController.text.trim(),
        isNotificationEnabled: _isNotificationEnabled,
        notificationTime: _notificationTimeController.text.trim(),
        repeatDays: ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'],
      );
      Navigator.of(context).pop(newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'เพิ่มกิจวัตรใหม่',
                    style: TextStyle(
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
                  prefixIcon: Icon(Icons.edit_note_rounded, color: _selectedColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
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
                        Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.defaultColor),
                        const SizedBox(width: 6),
                        Text(cat.label),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => _onCategoryChanged(cat),
                    selectedColor: cat.defaultColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'ใส่ตัวเลข';
                        if (double.tryParse(value) == null) return 'ตัวเลขไม่ถูกต้อง';
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
                        hintText: 'มล. / ก้าว / นาที',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'ใส่หน่วย';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notification Settings Switch & Time Input
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
                              color: _isNotificationEnabled ? Colors.amber.shade800 : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'เปิดใช้งานการแจ้งเตือน',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                          activeThumbColor: _selectedColor,
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Color & Icon Customization Grid
              Row(
                children: [
                  const Text('ไอคอน:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableIcons.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final icon = _availableIcons[index];
                          final isSelected = icon == _selectedIcon;
                          return InkWell(
                            onTap: () => setState(() => _selectedIcon = icon),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? _selectedColor.withAlpha(50) : Colors.grey.shade100,
                                border: Border.all(
                                  color: isSelected ? _selectedColor : Colors.transparent,
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, size: 20, color: isSelected ? _selectedColor : Colors.grey.shade700),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('สีประจำ:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableColors.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final color = _availableColors[index];
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
                                  color: isSelected ? Colors.black : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
