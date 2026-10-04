// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์โปรไฟล์ การตั้งค่า และบัญชีผู้ใช้ (profile controller account)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'profile_controller.dart';

extension ProfileControllerAccount on ProfileController {
  Future<String?> exportPdf() async {
    final userId = currentUser?.nUserId;
    if (userId == null) return null;
    return await DataExportService.instance.exportDataToPdf(userId);
  }

  /// ลบบัญชีผู้ใช้
  Future<bool> deleteAccount() async {
    final user = currentUser;
    if (user == null) return false;

    isLoading = true;
    this._notifyProfileListeners();

    // Remote deletion must succeed before destroying the only local copy.
    final result = await ProfileApiService.deleteAccount(
      userId: user.nUserId,
      email: user.sEmail,
    );
    if (result['status'] != 'success') {
      isLoading = false;
      this._notifyProfileListeners();
      return false;
    }

    // 0. ลบไฟล์รูปภาพโปรไฟล์จริงในเครื่อง (ถ้ามี)
    final profilePath = user.sProfileImagePath;
    if (profilePath.isNotEmpty && !profilePath.startsWith('http')) {
      try {
        final file = File(profilePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting local profile picture file: $e');
      }
    }

    // 2. ทำลายข้อมูล SQLite ในเครื่อง
    await AppDatabase.instance.deleteUserAccount(user.nUserId);

    // 3. เคลียร์ Google Session & App Session
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    await AuthService.instance.logout();
    return true;
  }

  /// ออกจากระบบ
  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('GoogleSignIn signOut error during logout: $e');
    }
    await AuthService.instance.logout();
  }

  /// เก็บ Gemini API Key ไว้ใน secure storage บนอุปกรณ์เท่านั้น
}
