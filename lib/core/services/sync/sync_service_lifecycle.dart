part of 'sync_service.dart';

extension SyncServiceLifecycle on SyncService {
  Future<void> init() async {
    // ตั้งค่าสถานะเครือข่ายเริ่มต้นก่อนสมัครรับ event เพื่อแสดงผลและเริ่มซิงค์ได้ถูกต้อง
    // 1. ตรวจสอบสถานะการเชื่อมต่อเริ่มต้น
    await checkConnection();

    // 2. ดักฟังการเปลี่ยนแปลง Network Hardware (Wi-Fi, Mobile Data, Ethernet)
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      final hasHardwareConnection = results.any(
        (r) => r != ConnectivityResult.none,
      );
      if (hasHardwareConnection) {
        // ทดสอบว่ามีอินเทอร์เน็ตใช้งานได้จริง (DNS lookup / Ping check)
        await _verifyAndSync();
      } else {
        _isOnline = false;
        _status = SyncStatus.offline;
        _statusMessage = 'ออฟไลน์ (ใช้งานบนฐานข้อมูลภายในเครื่อง)';
        this._notifySyncListeners();
      }
    });

    // 3. ดักฟัง Internet Connection Checker Plus (Internet Status Stream)
    _internetSubscription = _internetChecker.onStatusChange.listen((status) {
      if (status == InternetStatus.connected) {
        _isOnline = true;
        _statusMessage = 'เชื่อมต่ออินเทอร์เน็ตแล้ว';
        this._notifySyncListeners();
        syncPendingData();
      } else {
        _isOnline = false;
        _status = SyncStatus.offline;
        _statusMessage = 'ไม่มีสัญญาณอินเทอร์เน็ต (ใช้งานออฟไลน์)';
        this._notifySyncListeners();
      }
    });

    // นับจำนวนข้อมูลที่ค้างรอซิงค์ครั้งแรก
    await updatePendingCount();
  }

  /// ตรวจสอบการเชื่อมต่อ 2 ระดับอย่างละเอียด
  Future<bool> checkConnection() async {
    try {
      // แยกการมีสัญญาณเครือข่ายออกจากการเข้าถึงอินเทอร์เน็ตจริง
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasHardware = connectivityResults.any(
        (r) => r != ConnectivityResult.none,
      );

      if (!hasHardware) {
        _isOnline = false;
        _status = SyncStatus.offline;
        _statusMessage = 'ไม่มีการเชื่อมต่อเครือข่าย';
        this._notifySyncListeners();
        return false;
      }

      // ตรวจสอบอินเทอร์เน็ตจริง
      final hasInternet = await _internetChecker.hasInternetAccess;
      _isOnline = hasInternet;
      if (hasInternet) {
        _status = SyncStatus.idle;
        _statusMessage = 'เชื่อมต่ออินเทอร์เน็ตเรียบร้อย';
      } else {
        _status = SyncStatus.offline;
        _statusMessage = 'เชื่อมต่อเครือข่ายแต่ไม่มีอินเทอร์เน็ต (Offline)';
      }
      this._notifySyncListeners();
      return hasInternet;
    } catch (e) {
      debugPrint('SyncService: Connection check error: $e');
      _isOnline = false;
      return false;
    }
  }

  Future<void> _verifyAndSync() async {
    final hasInternet = await _internetChecker.hasInternetAccess;
    _isOnline = hasInternet;
    if (hasInternet) {
      await syncPendingData();
    } else {
      _status = SyncStatus.offline;
      _statusMessage = 'ไม่มีสัญญาณอินเทอร์เน็ต';
      this._notifySyncListeners();
    }
  }

  /// อัปเดตจำนวนแถวข้อมูลที่ค้างอยู่ในเครื่องที่ยังไม่ได้ซิงค์ (isSynced = 0)
  Future<int> updatePendingCount() async {
    try {
      final count = await AppDatabase.instance.getPendingSyncCount();
      _pendingCount = count;
      this._notifySyncListeners();
      return count;
    } catch (e) {
      debugPrint('Error getting pending count: $e');
      return 0;
    }
  }

  /// กระบวนการดึงข้อมูลที่ `isSynced = 0` ขึ้น Remote Server (Upstream Data Sync)
}
