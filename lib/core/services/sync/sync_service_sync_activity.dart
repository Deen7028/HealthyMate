// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (sync service sync activity)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'sync_service.dart';

extension SyncServiceSyncActivity on SyncService {
  Future<int> _syncWorkouts(int currentUserId) async {
    int syncedTotal = 0;
    // 3. ซิงค์ตาราง TbWorkouts
    final unsyncedWorkouts = await AppDatabase.instance.getUnsyncedWorkouts(
      currentUserId,
    );
    for (final workout in unsyncedWorkouts) {
      try {
        final workoutId = (workout['nWorkoutId'] as num?)?.toInt() ?? 0;
        final success = await ActivityApiService.saveWorkout(workout);
        if (success && workoutId > 0) {
          await AppDatabase.instance.markWorkoutAsSynced(workoutId);
          syncedTotal++;
          debugPrint(
            '☁️ [SYNC SUCCESS] [TbWorkouts] ➜ อัปโหลดการออกกำลังกาย ID: $workoutId (${workout['sType']}, ${workout['nDistance']} กม.) ขึ้น Server สำเร็จ',
          );
        }
      } catch (e) {
        debugPrint('SyncService: Error syncing workout: $e');
      }
    }
    return syncedTotal;
  }

  Future<int> _syncNutrition(int currentUserId) async {
    int syncedTotal = 0;
    // 4. ซิงค์ตาราง TbNutritionLogs
    final unsyncedNutrition = await AppDatabase.instance
        .getUnsyncedNutritionLogs(currentUserId);
    for (final nutrition in unsyncedNutrition) {
      try {
        final nutritionId = (nutrition['nNutritionId'] as num?)?.toInt() ?? 0;
        final Map<String, dynamic> payload = Map<String, dynamic>.from(
          nutrition,
        );
        final localImagePath = payload['sImagePath']?.toString() ?? '';

        // ถ้ามีรูปอาหารที่ถ่ายในเครื่อง ให้อัปโหลดขึ้นโฟลเดอร์ uploads/nutrition บน Server
        if (localImagePath.isNotEmpty &&
            !localImagePath.startsWith('http') &&
            !localImagePath.startsWith('uploads/')) {
          final localFile = File(localImagePath);
          if (await localFile.exists()) {
            final remoteUrl = await ActivityApiService.uploadImage(
              localImagePath,
              type: 'nutrition',
            );
            if (remoteUrl != null && remoteUrl.isNotEmpty) {
              payload['sImagePath'] = remoteUrl;
            }
          }
        }

        final success = await ActivityApiService.saveNutritionLog(payload);
        if (success && nutritionId > 0) {
          await AppDatabase.instance.markNutritionLogAsSynced(nutritionId);
          syncedTotal++;
          debugPrint(
            '☁️ [SYNC SUCCESS] [TbNutritionLogs] ➜ อัปโหลดมื้ออาหาร ID: $nutritionId (${nutrition['sFoodName']} • ${nutrition['nCalories']} kcal) ขึ้น Server สำเร็จ',
          );
        }
      } catch (e) {
        debugPrint('SyncService: Error syncing nutrition log: $e');
      }
    }
    return syncedTotal;
  }

  Future<int> _retryPendingDeletions(int userId) async {
    int syncedTotal = 0;
    // Retry queued deletions after reconnecting; local deletion is already complete.
    final pendingDeletions = await AppDatabase.instance.getPendingDeletions(
      userId,
    );
    for (final deletion in pendingDeletions) {
      final entity = deletion['sEntity']?.toString();
      final remoteId = (deletion['nRemoteId'] as num?)?.toInt() ?? 0;
      final deletionId = (deletion['nDeletionId'] as num?)?.toInt() ?? 0;
      if (remoteId <= 0 || deletionId <= 0) continue;
      var success = false;
      if (entity == 'health_record') {
        success = await HealthRecordApiService.deleteHealthRecordRemote(
          remoteId,
        );
      } else if (entity == 'nutrition_log') {
        success = await ActivityApiService.deleteNutritionLogRemote(remoteId);
      }
      if (success) {
        await AppDatabase.instance.completePendingDeletion(deletionId);
        syncedTotal++;
      }
    }
    return syncedTotal;
  }
}
