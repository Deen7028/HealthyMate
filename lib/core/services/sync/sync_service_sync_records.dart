part of 'sync_service.dart';

extension SyncServiceSyncRecords on SyncService {
  Future<int> _syncHealthRecords(int currentUserId) async {
    int syncedTotal = 0;
    // 1. ซิงค์ตาราง TbHealthRecords
    final unsyncedHealthRecords = await AppDatabase.instance
        .getUnsyncedHealthRecords(currentUserId);
    for (final map in unsyncedHealthRecords) {
      try {
        final record = TbHealthRecord.fromMap(map);
        final success = await HealthRecordApiService.saveHealthRecord(record);
        if (success) {
          final recordId = (map['nRecordId'] as num?)?.toInt() ?? 0;
          if (recordId > 0) {
            await AppDatabase.instance.markHealthRecordAsSynced(recordId);
            syncedTotal++;
            debugPrint(
              '☁️ [SYNC SUCCESS] [TbHealthRecords] ➜ อัปโหลดประวัติสุขภาพ ID: $recordId ขึ้น Server สำเร็จ (BMI: ${record.nBmi.toStringAsFixed(1)}, TDEE: ${record.nTdee.round()} kcal)',
            );
          }
        }
      } catch (e) {
        debugPrint('SyncService: Error syncing record: $e');
      }
    }
    return syncedTotal;
  }

  Future<int> _syncUsers(int currentUserId) async {
    int syncedTotal = 0;
    // 2. ซิงค์ตาราง TbUsers (โปรไฟล์หรือผู้ใช้ใหม่ที่สมัครตอนออฟไลน์)
    final unsyncedUsers = await AppDatabase.instance.getUnsyncedUsers(
      currentUserId,
    );
    for (final map in unsyncedUsers) {
      try {
        var user = TbUser.fromMap(map);
        var finalProfilePath = user.sProfileImagePath;

        // ถ้าเป็นรูปในเครื่อง (Local Path) ให้อัปโหลดขึ้นโฟลเดอร์ uploads/profile บน Server ก่อน
        if (finalProfilePath.isNotEmpty &&
            !finalProfilePath.startsWith('http') &&
            !finalProfilePath.startsWith('uploads/')) {
          final localFile = File(finalProfilePath);
          if (await localFile.exists()) {
            final remoteUrl = await ActivityApiService.uploadImage(
              finalProfilePath,
              type: 'profile',
            );
            if (remoteUrl != null && remoteUrl.isNotEmpty) {
              finalProfilePath = remoteUrl;
              user = user.copyWith(sProfileImagePath: finalProfilePath);
            }
          }
        }

        final success = await ProfileApiService.updateUserProfile(user.toMap());
        if (success) {
          await AppDatabase.instance.markUserAsSynced(user.nUserId);
          syncedTotal++;
          debugPrint(
            '☁️ [SYNC SUCCESS] [TbUsers] ➜ อัปเดตข้อมูลผู้ใช้ ${user.sFirstName} (ID: ${user.nUserId}) ขึ้น Server สำเร็จ',
          );
        }
      } catch (e) {
        debugPrint('SyncService: Error syncing user: $e');
      }
    }
    return syncedTotal;
  }
}
