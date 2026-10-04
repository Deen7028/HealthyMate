// ส่วนนี้อธิบายบทบาทของไฟล์: ฟังก์ชันช่วยคำนวณหรือจัดรูปแบบข้อมูล ในฟีเจอร์การสมัครสมาชิก (password validator)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

/// Helper utility for checking password strength and requirements
class PasswordValidator {
  static bool hasMinLength(String password) => password.length >= 8;
  static bool hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  static bool hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);
  static bool hasDigits(String password) => RegExp(r'[0-9]').hasMatch(password);

  static bool isPasswordValid(String password) {
    return hasMinLength(password) &&
        hasUppercase(password) &&
        hasLowercase(password) &&
        hasDigits(password);
  }
}
