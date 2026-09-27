import 'package:flutter/material.dart';

class MainGoalTemplate {
  final String title;
  final String icon;
  final String defaultUnit;
  final String linkedWorkout;
  final double defaultTarget;

  const MainGoalTemplate({
    required this.title,
    required this.icon,
    required this.defaultUnit,
    required this.linkedWorkout,
    required this.defaultTarget,
  });
}

class AddMainGoalBottomSheet extends StatefulWidget {
  const AddMainGoalBottomSheet({super.key});

  @override
  State<AddMainGoalBottomSheet> createState() => _AddMainGoalBottomSheetState();
}

class _AddMainGoalBottomSheetState extends State<AddMainGoalBottomSheet> {
  static const List<MainGoalTemplate> templates = [
    MainGoalTemplate(
      title: 'วิ่งสะสมระยะทาง',
      icon: '🏃♂️',
      defaultUnit: 'กม.',
      linkedWorkout: 'วิ่ง',
      defaultTarget: 50.0,
    ),
    MainGoalTemplate(
      title: 'ปั่นจักรยานสะสมระยะทาง',
      icon: '🚴♂️',
      defaultUnit: 'กม.',
      linkedWorkout: 'ปั่นจักรยาน',
      defaultTarget: 100.0,
    ),
    MainGoalTemplate(
      title: 'เผาผลาญแคลอรีรวม',
      icon: '🔥',
      defaultUnit: 'แคล',
      linkedWorkout: 'แคลอรี',
      defaultTarget: 5000.0,
    ),
    MainGoalTemplate(
      title: 'เป้าหมายลดน้ำหนัก',
      icon: '⚖️',
      defaultUnit: 'กก.',
      linkedWorkout: 'น้ำหนัก',
      defaultTarget: 3.0,
    ),
  ];

  int _selectedTemplateIndex = 0;
  late TextEditingController _targetController;
  
  // Deadline selection: '1_week', '1_month', 'custom'
  String _deadlineType = '1_month';
  DateTime _customDeadlineDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(
      text: templates[0].defaultTarget == templates[0].defaultTarget.toInt()
          ? templates[0].defaultTarget.toInt().toString()
          : templates[0].defaultTarget.toString(),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _onSelectTemplate(int index) {
    setState(() {
      _selectedTemplateIndex = index;
      final t = templates[index];
      _targetController.text = t.defaultTarget == t.defaultTarget.toInt()
          ? t.defaultTarget.toInt().toString()
          : t.defaultTarget.toString();
    });
  }

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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F9C58),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C2819),
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

    final selectedTemplate = templates[_selectedTemplateIndex];
    final deadlineDate = _getCalculatedDeadline();

    Navigator.pop(context, {
      'title': selectedTemplate.title,
      'icon': selectedTemplate.icon,
      'unit': selectedTemplate.defaultUnit,
      'targetValue': targetVal,
      'linkedWorkout': selectedTemplate.linkedWorkout,
      'deadlineDate': deadlineDate,
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTemplate = templates[_selectedTemplateIndex];

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flag_rounded, color: Color(0xFF0F9C58), size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ตั้งเป้าหมายหลัก (Set Main Goal)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C2819),
                      ),
                    ),
                    Text(
                      'เป้าหมายระยะยาวพร้อมยอดสะสมและวันสิ้นสุด',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 1: Goal Type Selection
            const Text(
              'ส่วนที่ 1: เลือกประเภทความท้าทาย (Goal Type)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF006432)),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final t = templates[index];
                final isSelected = index == _selectedTemplateIndex;

                return InkWell(
                  onTap: () => _onSelectTemplate(index),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0F9C58) : Colors.grey.shade200,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(t.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF006432) : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Section 2: Target & Unit
            const Text(
              'ส่วนที่ 2: กำหนดเส้นชัย (Target & Unit)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF006432)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'ตัวเลขเป้าหมาย',
                      hintText: 'เช่น 50',
                      prefixIcon: const Icon(Icons.track_changes, color: Color(0xFF0F9C58)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF0F9C58), width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0F9C58).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    selectedTemplate.defaultUnit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006432),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 3: Deadline Selection
            const Text(
              'ส่วนที่ 3: กำหนดเส้นตาย (Deadline)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF006432)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDeadlineOption(
                    type: '1_week',
                    label: '1 สัปดาห์\n(7 วัน)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDeadlineOption(
                    type: '1_month',
                    label: '1 เดือน\n(30 วัน)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDeadlineOption(
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

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006432),
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
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineOption({
    required String type,
    required String label,
    VoidCallback? onTapCustom,
  }) {
    final isSelected = _deadlineType == type;

    return InkWell(
      onTap: () {
        if (type == 'custom') {
          if (onTapCustom != null) onTapCustom();
        } else {
          setState(() {
            _deadlineType = type;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F9C58) : Colors.grey.shade200,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              type == 'custom' ? Icons.calendar_month : Icons.timer_outlined,
              size: 20,
              color: isSelected ? const Color(0xFF0F9C58) : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF006432) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
