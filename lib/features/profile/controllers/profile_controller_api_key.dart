part of 'profile_controller.dart';

// ส่วนการจัดการคีย์ปัญญาประดิษฐ์ (ProfileControllerApiKey)
// ทำหน้าที่บันทึกและอัปเดต Gemini API Key ลงใน Secure Storage ของอุปกรณ์
extension ProfileControllerApiKey on ProfileController {
  // ฟังก์ชัน: อัปเดตและบันทึก Gemini API Key สำหรับใช้งาน AI สแกนอาหาร
  Future<void> updateGeminiApiKey(String key) async {
    geminiApiKey = key;
    this._notifyProfileListeners();

    final uId = currentUser?.nUserId;
    if (uId == null) return;

    // บันทึกลง Secure Storage ประจำเครื่อง
    await AppDatabase.instance.saveGeminiApiKey(uId, key);
  }
}
