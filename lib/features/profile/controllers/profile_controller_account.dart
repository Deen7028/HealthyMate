part of 'profile_controller.dart';

// ส่วนการจัดการบัญชีผู้ใช้และส่งออกข้อมูล (ProfileControllerAccount)
// ทำหน้าที่ส่งออกข้อมูลรายงาน PDF, ลบบัญชีผู้ใช้ถาวร และออกจากระบบ
extension ProfileControllerAccount on ProfileController {
  // ฟังก์ชัน: ส่งออกรายงานสุขภาพและกิจกรรมเป็นไฟล์ PDF
  Future<String?> exportPdf() async {
    final userId = currentUser?.nUserId;
    if (userId == null) return null;
    return await DataExportService.instance.exportDataToPdf(userId);
  }

  // ฟังก์ชัน: ลบบัญชีผู้ใช้ถาวร (Delete Account)
  Future<bool> deleteAccount() async {
    final user = currentUser;
    if (user == null) return false;

    isLoading = true;
    this._notifyProfileListeners();

    // 1. สั่งลบบัญชีบน Remote Server ก่อน
    final result = await ProfileApiService.deleteAccount(
      userId: user.nUserId,
      email: user.sEmail,
    );
    if (result['status'] != 'success') {
      isLoading = false;
      this._notifyProfileListeners();
      return false;
    }

    // 2. ลบไฟล์รูปภาพโปรไฟล์ในเครื่อง (ถ้ามี)
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

    // 3. ทำลายข้อมูล SQLite ภายในเครื่อง
    await AppDatabase.instance.deleteUserAccount(user.nUserId);

    // 4. เคลียร์ Session บัญชี Google และ App Session
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    await AuthService.instance.logout();
    return true;
  }

  // ฟังก์ชัน: ออกจากระบบ (Logout)
  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('GoogleSignIn signOut error during logout: $e');
    }
    await AuthService.instance.logout();
  }
}
