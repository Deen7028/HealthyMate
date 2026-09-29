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
