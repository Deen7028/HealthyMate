part of 'sync_service.dart';

extension SyncServiceUpstream on SyncService {
  Future<void> syncPendingData() async {
    if (_isSyncing) return;

    final hasInternet = await checkConnection();
    if (!hasInternet) {
      debugPrint('SyncService: Device is offline. Sync skipped.');
      return;
    }

    final activeUser = await AppDatabase.instance.getCurrentUser();
    if (activeUser == null) {
      await updatePendingCount();
      return;
    }
    final currentUserId = activeUser.nUserId;

    _isSyncing = true;
    _status = SyncStatus.syncing;
    _statusMessage = 'กำลังซิงค์ข้อมูลกับเซิร์ฟเวอร์...';
    this._notifySyncListeners();

    int syncedTotal = 0;
    try {
      syncedTotal += await this._syncHealthRecords(currentUserId);
      syncedTotal += await this._syncUsers(currentUserId);
      syncedTotal += await this._syncWorkouts(currentUserId);
      syncedTotal += await this._syncNutrition(currentUserId);
      syncedTotal += await this._retryPendingDeletions(currentUserId);
      syncedTotal += await this._syncRoutinesGoalsAndPreferences(currentUserId);

      _lastSyncTime = DateTime.now();
      await updatePendingCount();

      if (_pendingCount == 0) {
        _status = SyncStatus.synced;
        _statusMessage =
            'ข้อมูลทั้งหมดเป็นปัจจุบันแล้ว (ซิงค์แล้ว $syncedTotal รายการ)';
        debugPrint(
          '🎉 [SYNC COMPLETED] ข้อมูลทั้งหมดในเครื่องซิงค์ขึ้น Server เรียบร้อยแล้ว ($syncedTotal รายการ)',
        );
      } else {
        _status = SyncStatus.idle;
        _statusMessage = 'เหลือข้อมูลคอยซิงค์ $_pendingCount รายการ';
        debugPrint(
          'ℹ️ [SYNC STATUS] เหลือรายการค้างซิงค์: $_pendingCount รายการ',
        );
      }
    } catch (e) {
      debugPrint('SyncService error: $e');
      _status = SyncStatus.error;
      _statusMessage = 'เกิดข้อผิดพลาดในการซิงค์ข้อมูล: $e';
    } finally {
      _isSyncing = false;
      this._notifySyncListeners();
    }
  }
}
