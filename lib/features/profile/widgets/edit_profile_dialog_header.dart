// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์โปรไฟล์ การตั้งค่า และบัญชีผู้ใช้ (edit profile dialog header)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'edit_profile_dialog.dart';

extension EditProfileDialogHeader on _EditProfileDialogState {
  Widget _buildDialogHeader(
    BuildContext context,
    Color primaryColor,
    bool isDark,
  ) {
    final row = Row(
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'แก้ไขข้อมูลโปรไฟล์',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E2822),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'อัปเดตข้อมูลส่วนตัวและสัดส่วนของคุณ',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A958E)),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close_rounded,
            color: Color(0xFF8A958E),
            size: 22,
          ),
          splashRadius: 20,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
    return row;
  }
}
