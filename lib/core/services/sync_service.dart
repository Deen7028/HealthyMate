import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

enum SyncStatus {
  idle,
  checking,
  syncing,
  synced,
  offline,
  error,
}

/// Service สำหรับจัดการ Offline-First และ Background Synchronization
/// - คอยดักฟังสัญญาณเครือข่าย 2 ระดับ: (1) connectivity_plus (2) internet_connection_checker_plus
/// - เมื่อมีสัญญาณอินเทอร์เน็ตจริง จะทำการ Upstream Sync ข้อมูลแถวที่ `isSynced = 0` ขึ้น PHP API
/// - อัปเดตสถานะใน SQLite เป็น `isSynced = 1` เมื่อ Backend ตอบกลับ 200 OK
class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection.createInstance(
    customCheckOptions: [
      InternetCheckOption(uri: Uri.parse('https://one.one.one.one')),
      InternetCheckOption(uri: Uri.parse('https://www.google.com')),
    ],
  );

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetStatus>? _internetSubscription;

  bool _isOnline = false;
  bool _isSyncing = false;
  SyncStatus _status = SyncStatus.idle;
  String _statusMessage = 'พร้อมทำงานแบบออฟไลน์';
  DateTime? _lastSyncTime;
  int _pendingCount = 0;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  SyncStatus get status => _status;
  String get statusMessage => _statusMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingCount => _pendingCount;

  /// เริ่มต้นระบบตรวจสอบเน็ตและเริ่ม Auto Sync ในเบื้องหลัง
  Future<void> init() async {
    // 1. ตรวจสอบสถานะการเชื่อมต่อเริ่มต้น
    await checkConnection();

    // 2. ดักฟังการเปลี่ยนแปลง Network Hardware (Wi-Fi, Mobile Data, Ethernet)
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) async {
      final hasHardwareConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasHardwareConnection) {
        // ทดสอบว่ามีอินเทอร์เน็ตใช้งานได้จริง (DNS lookup / Ping check)
        await _verifyAndSync();
      } else {
        _isOnline = false;
        _status = SyncStatus.offline;
        _statusMessage = 'ออฟไลน์ (ใช้งานบนฐานข้อมูลภายในเครื่อง)';
        notifyListeners();
      }
    });

    // 3. ดักฟัง Internet Connection Checker Plus (Internet Status Stream)
    _internetSubscription = _internetChecker.onStatusChange.listen((status) {
      if (status == InternetStatus.connected) {
        _isOnline = true;
        _statusMessage = 'เชื่อมต่ออินเทอร์เน็ตแล้ว';
        notifyListeners();
        syncPendingData();
      } else {
        _isOnline = false;
        _status = SyncStatus.offline;
        _statusMessage = 'ไม่มีสัญญาณอินเทอร์เน็ต (ใช้งานออฟไลน์)';
        notifyListeners();
      }
    });

    // นับจำนวนข้อมูลที่ค้างรอซิงค์ครั้งแรก
    await updatePendingCount();
  }

  /// ตรวจสอบการเชื่อมต่อ 2 ระดับอย่างละเอียด
  Future<bool> checkConnection() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasHardware = connectivityResults.any((r) => r != ConnectivityResult.none);

      if (!hasHardware) {
        _isOnline = false;
        _status = SyncStatus.offline;
        _statusMessage = 'ไม่มีการเชื่อมต่อเครือข่าย';
        notifyListeners();
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
      notifyListeners();
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
      notifyListeners();
    }
  }

  /// อัปเดตจำนวนแถวข้อมูลที่ค้างอยู่ในเครื่องที่ยังไม่ได้ซิงค์ (isSynced = 0)
  Future<int> updatePendingCount() async {
    try {
      final count = await AppDatabase.instance.getPendingSyncCount();
      _pendingCount = count;
      notifyListeners();
      return count;
    } catch (e) {
      debugPrint('Error getting pending count: $e');
      return 0;
    }
  }

  /// กระบวนการดึงข้อมูลที่ `isSynced = 0` ขึ้น Remote Server (Upstream Data Sync)
  Future<void> syncPendingData() async {
    if (_isSyncing) return;

    final hasInternet = await checkConnection();
    if (!hasInternet) {
      debugPrint('SyncService: Device is offline. Sync skipped.');
      return;
    }

    _isSyncing = true;
    _status = SyncStatus.syncing;
    _statusMessage = 'กำลังซิงค์ข้อมูลกับเซิร์ฟเวอร์...';
    notifyListeners();

    int syncedTotal = 0;

    try {
      // 1. ซิงค์ตาราง TbHealthRecords
      final unsyncedHealthRecords = await AppDatabase.instance.getUnsyncedHealthRecords();
      for (final map in unsyncedHealthRecords) {
        try {
          final record = TbHealthRecord.fromMap(map);
          final success = await HealthApiService.saveHealthRecord(record);
          if (success) {
            final recordId = (map['nRecordId'] as num?)?.toInt() ?? 0;
            if (recordId > 0) {
              await AppDatabase.instance.markHealthRecordAsSynced(recordId);
              syncedTotal++;
            }
          }
        } catch (e) {
          debugPrint('SyncService: Error syncing record: $e');
        }
      }

      // 2. ซิงค์ตาราง TbUsers (โปรไฟล์หรือผู้ใช้ใหม่ที่สมัครตอนออฟไลน์)
      final unsyncedUsers = await AppDatabase.instance.getUnsyncedUsers();
      for (final map in unsyncedUsers) {
        try {
          final user = TbUser.fromMap(map);
          final success = await HealthApiService.updateUserProfile(user.toMap());
          if (success) {
            await AppDatabase.instance.markUserAsSynced(user.nUserId);
            syncedTotal++;
          }
        } catch (e) {
          debugPrint('SyncService: Error syncing user: $e');
        }
      }

      // 3. ซิงค์ตาราง TbWorkouts
      final unsyncedWorkouts = await AppDatabase.instance.getUnsyncedWorkouts();
      for (final workout in unsyncedWorkouts) {
        try {
          final workoutId = (workout['nWorkoutId'] as num?)?.toInt() ?? 0;
          final success = await HealthApiService.saveWorkout(workout);
          if (success && workoutId > 0) {
            await AppDatabase.instance.markWorkoutAsSynced(workoutId);
            syncedTotal++;
          }
        } catch (e) {
          debugPrint('SyncService: Error syncing workout: $e');
        }
      }

      // 4. ซิงค์ตาราง TbNutritionLogs
      final unsyncedNutrition = await AppDatabase.instance.getUnsyncedNutritionLogs();
      for (final nutrition in unsyncedNutrition) {
        try {
          final nutritionId = (nutrition['nNutritionId'] as num?)?.toInt() ?? 0;
          final success = await HealthApiService.saveNutritionLog(nutrition);
          if (success && nutritionId > 0) {
            await AppDatabase.instance.markNutritionLogAsSynced(nutritionId);
            syncedTotal++;
          }
        } catch (e) {
          debugPrint('SyncService: Error syncing nutrition log: $e');
        }
      }

      // อัปเดตสถานะและจำนวนแถวที่เหลือ
      _lastSyncTime = DateTime.now();
      await updatePendingCount();

      if (_pendingCount == 0) {
        _status = SyncStatus.synced;
        _statusMessage = 'ข้อมูลทั้งหมดเป็นปัจจุบันแล้ว (ซิงค์แล้ว $syncedTotal รายการ)';
      } else {
        _status = SyncStatus.idle;
        _statusMessage = 'เหลือข้อมูลคอยซิงค์ $_pendingCount รายการ';
      }
    } catch (e) {
      debugPrint('SyncService error: $e');
      _status = SyncStatus.error;
      _statusMessage = 'เกิดข้อผิดพลาดในการซิงค์ข้อมูล: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    super.dispose();
  }
}
