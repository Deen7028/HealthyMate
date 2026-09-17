import 'package:flutter/material.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

class EditProfileDialog extends StatefulWidget {
  final TbUser? currentUser;
  final Future<void> Function({
    required String firstName,
    required String lastName,
    required String gender,
    required int age,
    required double height,
    required double weight,
  }) onSave;

  const EditProfileDialog({
    super.key,
    required this.currentUser,
    required this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late String _currentGender;

  @override
  void initState() {
    super.initState();
    final user = widget.currentUser;
    _firstCtrl = TextEditingController(text: user?.sFirstName ?? 'Alex');
    _lastCtrl = TextEditingController(text: user?.sLastName ?? 'Morgan');
    _ageCtrl = TextEditingController(
      text: user?.nAge != null && user!.nAge > 0 ? user.nAge.toString() : '26',
    );
    _heightCtrl = TextEditingController(
      text: user?.nHeight != null && user!.nHeight > 0
          ? user.nHeight.toStringAsFixed(0)
          : '168',
    );
    _weightCtrl = TextEditingController(
      text: user?.nWeight != null && user!.nWeight > 0
          ? user.nWeight.toStringAsFixed(1)
          : '54.0',
    );
    _currentGender = user?.sGender ?? 'female';
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'แก้ไขข้อมูลโปรไฟล์',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2822)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _firstCtrl,
              decoration: InputDecoration(
                labelText: 'ชื่อ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastCtrl,
              decoration: InputDecoration(
                labelText: 'นามสกุล',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _currentGender,
              decoration: InputDecoration(
                labelText: 'เพศ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'female', child: Text('หญิง')),
                DropdownMenuItem(value: 'male', child: Text('ชาย')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _currentGender = val);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'อายุ (ปี)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ส่วนสูง (ซม.)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'น้ำหนัก (กก.)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E6339),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            final fName = _firstCtrl.text.trim();
            final lName = _lastCtrl.text.trim();
            final age = int.tryParse(_ageCtrl.text) ?? 26;
            final height = double.tryParse(_heightCtrl.text) ?? 168.0;
            final weight = double.tryParse(_weightCtrl.text) ?? 54.0;

            await widget.onSave(
              firstName: fName,
              lastName: lName,
              gender: _currentGender,
              age: age,
              height: height,
              weight: weight,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
