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
    _firstCtrl = TextEditingController(text: user?.sFirstName ?? '');
    _lastCtrl = TextEditingController(text: user?.sLastName ?? '');
    _ageCtrl = TextEditingController(
      text: user?.nAge != null && user!.nAge > 0 ? user.nAge.toString() : '',
    );
    _heightCtrl = TextEditingController(
      text: user?.nHeight != null && user!.nHeight > 0
          ? user.nHeight.toStringAsFixed(0)
          : '',
    );
    _weightCtrl = TextEditingController(
      text: user?.nWeight != null && user!.nWeight > 0
          ? user.nWeight.toStringAsFixed(1)
          : '',
    );
    _currentGender = (user?.sGender.isNotEmpty == true) ? user!.sGender : 'male';
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_rounded, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'แก้ไขข้อมูลโปรไฟล์',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2822),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'อัปเดตข้อมูลส่วนตัวและสัดส่วนของคุณ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A958E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF8A958E), size: 22),
                    splashRadius: 20,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Full Name Section
              _buildSectionLabel('ชื่อ - นามสกุล'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstCtrl,
                      label: 'ชื่อ',
                      hint: 'ชื่อจริง',
                      prefixIcon: Icons.badge_outlined,
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastCtrl,
                      label: 'นามสกุล',
                      hint: 'นามสกุล',
                      prefixIcon: Icons.badge_outlined,
                      primaryColor: primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Gender & Age Section
              _buildSectionLabel('ข้อมูลทั่วไป'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildGenderDropdown(primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: _buildTextField(
                      controller: _ageCtrl,
                      label: 'อายุ',
                      hint: 'เช่น 25',
                      suffixText: 'ปี',
                      prefixIcon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      primaryColor: primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Body Metrics Section
              _buildSectionLabel('สัดส่วนร่างกาย'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _heightCtrl,
                      label: 'ส่วนสูง',
                      hint: 'เช่น 175',
                      suffixText: 'ซม.',
                      prefixIcon: Icons.height_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _weightCtrl,
                      label: 'น้ำหนัก',
                      hint: 'เช่น 65.5',
                      suffixText: 'กก.',
                      prefixIcon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      primaryColor: primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFE0E5E2)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
                          color: Color(0xFF6F7A72),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _handleSave(context),
                      child: const Text(
                        'บันทึกข้อมูล',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6F7A72),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    required Color primaryColor,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E2822),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFA5AEA8),
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF6F7A72),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF8A958E)),
        suffixText: suffixText,
        suffixStyle: const TextStyle(
          color: Color(0xFF8A958E),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F9F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4E9E6), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(Color primaryColor) {
    return DropdownButtonFormField<String>(
      initialValue: _currentGender,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E2822),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8A958E)),
      decoration: InputDecoration(
        labelText: 'เพศ',
        labelStyle: const TextStyle(
          color: Color(0xFF6F7A72),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          _currentGender == 'female' ? Icons.female_rounded : Icons.male_rounded,
          size: 20,
          color: const Color(0xFF8A958E),
        ),
        filled: true,
        fillColor: const Color(0xFFF7F9F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4E9E6), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.8),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'male',
          child: Text('ชาย'),
        ),
        DropdownMenuItem(
          value: 'female',
          child: Text('หญิง'),
        ),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() => _currentGender = val);
        }
      },
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    final fName = _firstCtrl.text.trim();
    final lName = _lastCtrl.text.trim();

    if (fName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อ'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final age = int.tryParse(_ageCtrl.text) ?? widget.currentUser?.nAge ?? 0;
    if (age < 0 || age > 130) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อายุต้องอยู่ระหว่าง 1 - 130 ปี'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final height = double.tryParse(_heightCtrl.text) ?? widget.currentUser?.nHeight ?? 0.0;
    if (height < 0.0 || height > 280.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ส่วนสูงต้องอยู่ระหว่าง 30 - 280 ซม.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final weight = double.tryParse(_weightCtrl.text) ?? widget.currentUser?.nWeight ?? 0.0;
    if (weight < 0.0 || weight > 500.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('น้ำหนักต้องอยู่ระหว่าง 10 - 500 กก.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await widget.onSave(
      firstName: fName,
      lastName: lName,
      gender: _currentGender,
      age: age,
      height: height,
      weight: weight,
    );
    if (context.mounted) Navigator.pop(context);
  }
}
