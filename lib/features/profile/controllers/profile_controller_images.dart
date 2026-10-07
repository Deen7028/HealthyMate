part of 'profile_controller.dart';

// ส่วนการจัดการรูปภาพโปรไฟล์ (ProfileControllerImages)
// ทำหน้าที่เลือกรูปภาพจากกล้อง/คลังภาพ, บันทึกลง Documents Directory ถาวร และอัปโหลดขึ้นเซิร์ฟเวอร์
extension ProfileControllerImages on ProfileController {
  // ฟังก์ชัน: จัดการการเลือกรูปภาพจาก Camera / Gallery
  Future<bool> handleImagePick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      await saveImageLocally(picked.path);
      return true;
    }
    return false;
  }

  // ฟังก์ชัน: บันทึกรูปลง Documents Directory ถาวร พร้อมลบรูปเดิมเพื่อประหยัดพื้นที่
  Future<void> saveImageLocally(String tempPath) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final userId = currentUser?.nUserId;
      if (userId == null) return;
      final rawExt = tempPath.contains('.')
          ? tempPath.split('.').last.toLowerCase()
          : 'jpg';
      final fileExtension = (rawExt.length <= 4 && !rawExt.contains('/'))
          ? rawExt
          : 'jpg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final permanentPath =
          '${docDir.path}/profile_avatar_${userId}_$timestamp.$fileExtension';

      // 1. ลบรูปโปรไฟล์เดิมทิ้งก่อนเพื่อป้องกัน Storage Leak
      final oldPath = currentUser?.sProfileImagePath ?? '';
      if (oldPath.isNotEmpty && !oldPath.startsWith('http')) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      // 2. คัดลอกไฟล์จาก Temp Directory ไปยัง Documents ถาวร
      final tempFile = File(tempPath);
      await tempFile.copy(permanentPath);

      // 3. ลบ Temp File ชั่วคราว
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await updateProfileImagePath(permanentPath);
    } catch (e) {
      debugPrint('Error saving image permanently: $e');
      await updateProfileImagePath(tempPath);
    }
  }

  // ฟังก์ชัน: อัปเดตที่อยู่รูปภาพทั้งในเครื่อง (SQLite) และอัปโหลดขึ้น Cloud
  Future<void> updateProfileImagePath(String path) async {
    if (currentUser == null) return;

    isUploadingImage = true;
    this._notifyProfileListeners();

    try {
      final updated = currentUser!.copyWith(sProfileImagePath: path);

      // 1. อัปเดตลงฐานข้อมูล SQLite ภายในเครื่องทันที
      await AppDatabase.instance.updateUser(updated);
      currentUser = updated;
      this._notifyProfileListeners();

      // 2. อัปโหลดไฟล์ขึ้น Remote Cloud Storage
      String finalPathForRemote = path;
      if (path.isNotEmpty && !path.startsWith('http')) {
        final remoteUrl = await ActivityApiService.uploadImage(
          path,
          type: 'profile',
        );
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          finalPathForRemote = remoteUrl;
        }
      }

      final remotePayload = updated.copyWith(
        sProfileImagePath: finalPathForRemote,
      );
      final isSynced = await ProfileApiService.updateUserProfile(remotePayload);

      if (!isSynced) {
        await SyncService.instance.updatePendingCount();
      }
    } catch (e) {
      debugPrint('Error updating profile image path: $e');
    } finally {
      isUploadingImage = false;
      this._notifyProfileListeners();
    }
  }
}
