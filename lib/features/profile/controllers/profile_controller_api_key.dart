// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์โปรไฟล์ การตั้งค่า และบัญชีผู้ใช้ (profile controller api key)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'profile_controller.dart';

extension ProfileControllerApiKey on ProfileController {
  Future<void> updateGeminiApiKey(String key) async {
    geminiApiKey = key;
    this._notifyProfileListeners();

    final uId = currentUser?.nUserId;
    if (uId == null) return;

    // 1. บันทึกลง secure storage
    await AppDatabase.instance.saveGeminiApiKey(uId, key);
  }
}
