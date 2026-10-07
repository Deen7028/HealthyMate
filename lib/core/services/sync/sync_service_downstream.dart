part of 'sync_service.dart';

extension SyncServiceDownstream on SyncService {
  Future<int> pullDownstreamWorkouts(
    int userId, {
    bool forceInitial = false,
  }) async {
    final hasInternet = await checkConnection();
    if (!hasInternet) {
      debugPrint('SyncService: Offline. Cannot pull downstream data.');
      return 0;
    }

    _isSyncing = true;
    _status = SyncStatus.syncing;
    _statusMessage = 'กำลังดาวน์โหลดข้อมูลล่าสุดจากเซิร์ฟเวอร์...';
    this._notifySyncListeners();

    int pulledCount = 0;
    try {
      // 1. ตรวจสอบว่าใน SQLite ว่างเปล่าหรือไม่
      final localCount = await AppDatabase.instance.getWorkoutCount(
        userId: userId,
      );
      final isLocalEmpty = localCount == 0;

      // 2. ดึง Timestamp ล่าสุดของการซิงค์
      String? lastSyncTimestamp;
      if (!isLocalEmpty && !forceInitial) {
        lastSyncTimestamp = await AppDatabase.instance
            .getLastWorkoutSyncTimestamp(userId);
      }

      // 3. ยิง Request ไปยัง Backend API
      debugPrint(
        'SyncService: Pulling workouts for user $userId (since: $lastSyncTimestamp, isLocalEmpty: $isLocalEmpty)',
      );
      final serverWorkouts = await ActivityApiService.fetchWorkouts(
        userId: userId,
        since: lastSyncTimestamp,
      );

      // 4. เขียนลง SQLite ด้วยเทคนิค UPSERT (INSERT OR REPLACE)
      if (serverWorkouts.isNotEmpty) {
        pulledCount = await AppDatabase.instance.upsertWorkoutsFromServer(
          userId,
          serverWorkouts,
        );
        debugPrint(
          'SyncService: Successfully hydrated $pulledCount workouts into SQLite',
        );
      }

      // 5. บันทึกเวลาซิงค์ล่าสุด (Save Last Sync Timestamp)
      final nowTimestamp = DateTime.now().toIso8601String();
      await AppDatabase.instance.setLastWorkoutSyncTimestamp(
        userId,
        nowTimestamp,
      );
      _lastSyncTime = DateTime.now();

      _status = SyncStatus.synced;
      _statusMessage = pulledCount > 0
          ? 'อัปเดตข้อมูลจากเซิร์ฟเวอร์เรียบร้อย ($pulledCount รายการ)'
          : 'ข้อมูลบนเครื่องเป็นเวอร์ชันล่าสุดแล้ว';
    } catch (e) {
      debugPrint('SyncService: Error during pull downstream sync: $e');
      _status = SyncStatus.error;
      _statusMessage = 'เกิดข้อผิดพลาดในการดึงข้อมูลจากเซิร์ฟเวอร์';
    } finally {
      _isSyncing = false;
      this._notifySyncListeners();
    }

    return pulledCount;
  }
}
