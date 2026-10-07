part of 'profile_controller.dart';

extension ProfileControllerImages on ProfileController {
  Future<bool> handleImagePick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      await saveImageLocally(picked.path);
      return true;
    }
    return false;
  }

  /// บันทึกรูปลง Documents Directory ถาวร พร้อมลบรูปเดิมป้องกัน Storage Leak
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

      // 2. คัดลอกไฟล์จาก temp ไปยัง Documents ถาวร
      final tempFile = File(tempPath);
      await tempFile.copy(permanentPath);

      // 3. ลบ temp file ชั่วคราว
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await updateProfileImagePath(permanentPath);
    } catch (e) {
      debugPrint('Error saving image permanently: $e');
      await updateProfileImagePath(tempPath);
    }
  }

  /// อัปเดตรูปโปรไฟล์ทั้ง SQLite และ Remote Server พร้อมระบบ State Management ระหว่างอัปโหลด (isUploadingImage)
  Future<void> updateProfileImagePath(String path) async {
    if (currentUser == null) return;

    isUploadingImage = true;
    this._notifyProfileListeners();

    try {
      final updated = currentUser!.copyWith(sProfileImagePath: path);

      // 1. อัปเดต SQLite ภายในเครื่องทันที
      await AppDatabase.instance.updateUser(updated);
      currentUser = updated;
      this._notifyProfileListeners();

      // 2. ซิงค์ขึ้น Remote Server
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

  /// จัดการเมื่อผู้ใช้กดเปลี่ยนสถานะ Location Services
}
