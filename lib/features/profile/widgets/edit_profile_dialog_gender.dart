// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์โปรไฟล์ การตั้งค่า และบัญชีผู้ใช้ (edit profile dialog gender)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'edit_profile_dialog.dart';

extension EditProfileDialogGender on _EditProfileDialogState {
  Widget _buildGenderDropdown(Color primaryColor) {
    return DropdownButtonFormField<String>(
      initialValue: _currentGender,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E2822),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF8A958E),
      ),
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
          _currentGender == 'female'
              ? Icons.female_rounded
              : Icons.male_rounded,
          size: 20,
          color: const Color(0xFF8A958E),
        ),
        filled: true,
        fillColor: const Color(0xFFF7F9F8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
        DropdownMenuItem(value: 'male', child: Text('ชาย')),
        DropdownMenuItem(value: 'female', child: Text('หญิง')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() => _currentGender = val);
        }
      },
    );
  }
}
