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
      // ดึงข้อมูล User ที่ล็อกอินอยู่ในปัจจุบัน
      final db = AppDatabase.instance;
      final loggedInEmail = await db.getLoggedInUserEmail();
      TbUser? activeUser;
      if (loggedInEmail != null && loggedInEmail.isNotEmpty) {
        activeUser = await db.getUserByEmail(loggedInEmail);
      }
      activeUser ??= await db.getUser();
      final currentUserId = activeUser?.nUserId ?? 1;

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
              debugPrint('☁️ [SYNC SUCCESS] [TbHealthRecords] ➜ อัปโหลดประวัติสุขภาพ ID: $recordId ขึ้น Server สำเร็จ (BMI: ${record.nBmi.toStringAsFixed(1)}, TDEE: ${record.nTdee.round()} kcal)');
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
            debugPrint('☁️ [SYNC SUCCESS] [TbUsers] ➜ อัปเดตข้อมูลผู้ใช้ ${user.sFirstName} (ID: ${user.nUserId}) ขึ้น Server สำเร็จ');
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
            debugPrint('☁️ [SYNC SUCCESS] [TbWorkouts] ➜ อัปโหลดการออกกำลังกาย ID: $workoutId (${workout['sType']}, ${workout['nDistance']} กม.) ขึ้น Server สำเร็จ');
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
            debugPrint('☁️ [SYNC SUCCESS] [TbNutritionLogs] ➜ อัปโหลดมื้ออาหาร ID: $nutritionId (${nutrition['sFoodName']} • ${nutrition['nCalories']} kcal) ขึ้น Server สำเร็จ');
          }
        } catch (e) {
          debugPrint('SyncService: Error syncing nutrition log: $e');
        }
      }

      // 5. ซิงค์ตาราง TbRoutines & TbRoutineLogs
      if (currentUserId > 0) {
        final localRoutines = await AppDatabase.instance.getRoutines(userId: currentUserId);
        final serverResult = await HealthApiService.fetchRoutines(userId: currentUserId);
        if (serverResult != null && serverResult['status'] == 'success') {
          final serverRoutines = (serverResult['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final serverTitles = serverRoutines.map((sr) => sr['sTitle']?.toString().trim() ?? '').toSet();

          for (final lr in localRoutines) {
            final title = lr['sTitle']?.toString().trim() ?? '';
            if (title.isNotEmpty && !serverTitles.map((t) => t.toLowerCase()).contains(title.toLowerCase())) {
              final newId = await HealthApiService.insertRoutineRemote(
                userId: currentUserId,
                title: title,
                time: lr['sTime']?.toString() ?? '',
                targetValue: (lr['targetValue'] as num?)?.toDouble() ?? 1.0,
                unit: lr['unit']?.toString() ?? 'ครั้ง',
                linkedWorkout: lr['sLinkedWorkout']?.toString() ?? '',
                color: (lr['color'] as num?)?.toInt(),
                iconData: (lr['iconData'] as num?)?.toInt(),
                isNotificationActive: ((lr['isNotificationActive'] as num?)?.toInt() ?? 1) == 1,
              );
              if (newId > 0) {
                syncedTotal++;
                final localId = (lr['nRoutineId'] as num?)?.toInt() ?? 0;
                if (localId > 0 && localId != newId) {
                  await AppDatabase.instance.deleteRoutine(localId);
                }
                debugPrint('☁️ [SYNC SUCCESS] [TbRoutines] ➜ อัปโหลดกิจวัตรใหม่ "$title" (Server ID: $newId) ขึ้น Server สำเร็จ');
              }
            }
          }
          await AppDatabase.instance.deduplicateRoutines(userId: currentUserId);

          // ดึงรายการกิจวัตรล่าสุดจาก Server มาทำแผนที่ Title -> Server nRoutineId
          final freshServerRes = await HealthApiService.fetchRoutines(userId: currentUserId);
          final Map<String, int> titleToServerId = {};
          final Set<int> validServerRoutineIds = {};
          if (freshServerRes != null && freshServerRes['status'] == 'success') {
            final list = (freshServerRes['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
            for (final item in list) {
              final sId = (item['nRoutineId'] as num?)?.toInt() ?? 0;
              final sTitle = (item['sTitle']?.toString() ?? '').trim().toLowerCase();
              if (sId > 0) {
                validServerRoutineIds.add(sId);
                if (sTitle.isNotEmpty) {
                  titleToServerId[sTitle] = sId;
                }
              }
            }
          }

          // ซิงค์ RoutineLogs ของวันนี้ขึ้น Server
          final todayStr = DateTime.now().toIso8601String().substring(0, 10);
          final todayLogs = await AppDatabase.instance.getRoutineLogsForDate(userId: currentUserId, dateStr: todayStr);
          for (final log in todayLogs) {
            int targetRoutineId = (log['nRoutineId'] as num?)?.toInt() ?? 0;
            final routineTitle = (log['sTitle']?.toString() ?? '').trim().toLowerCase();

            // หาก ID ในเครื่องยังไม่ใช่ ID ของ Server ให้แปลงโดยอิงจากชื่อกิจวัตร
            if (!validServerRoutineIds.contains(targetRoutineId) && titleToServerId.containsKey(routineTitle)) {
              targetRoutineId = titleToServerId[routineTitle]!;
            }

            final isCompleted = (log['isCompleted'] as num?)?.toInt() == 1;
            final progressValue = (log['nProgressValue'] as num?)?.toDouble() ?? 0.0;
            if (targetRoutineId > 0 && validServerRoutineIds.contains(targetRoutineId)) {
              final ok = await HealthApiService.updateRoutineProgressRemote(
                routineId: targetRoutineId,
                date: todayStr,
                progressValue: progressValue,
                isCompleted: isCompleted,
              );
              if (ok) {
                syncedTotal++;
                debugPrint('☁️ [SYNC SUCCESS] [TbRoutineLogs] ➜ อัปเดต Log กิจวัตร "$routineTitle" (Server ID: $targetRoutineId, $todayStr: คืบหน้า $progressValue, เสร็จสิ้น: $isCompleted) ขึ้น Server สำเร็จ');
              }
            }
          }
        }

        // 6. ซิงค์ตาราง TbGoals
        final localGoal = await AppDatabase.instance.getUserGoal(currentUserId);
        if (localGoal != null) {
          final success = await HealthApiService.saveMainGoalRemote(
            userId: currentUserId,
            routineId: (localGoal['nRoutineId'] as num?)?.toInt() ?? 0,
            title: localGoal['sTitle']?.toString() ?? '',
            progress: (localGoal['nProgress'] as num?)?.toDouble() ?? 0.0,
            remainingText: localGoal['sRemainingText']?.toString() ?? '',
          );
          if (success) {
            syncedTotal++;
            debugPrint('☁️ [SYNC SUCCESS] [TbGoals] ➜ ซิงค์เป้าหมายหลัก "${localGoal['sTitle']}" (ความคืบหน้า: ${(localGoal['nProgress'] * 100).toInt()}%) ขึ้น Server สำเร็จ');
          }
        }

        // 7. ซิงค์ตาราง TbUserPreferences
        final unitPref = await AppDatabase.instance.getUserUnitPreference(currentUserId);
        final apiKey = await AppDatabase.instance.getGeminiApiKey(currentUserId);
        final okPref = await HealthApiService.saveUserPreferencesRemote(
          userId: currentUserId,
          unitLabel: unitPref,
          geminiApiKey: apiKey,
        );
        if (okPref) {
          debugPrint('☁️ [SYNC SUCCESS] [TbUserPreferences] ➜ ซิงค์การตั้งค่าหน่วยวัด ($unitPref) ขึ้น Server สำเร็จ');
        }
      }

      // อัปเดตสถานะและจำนวนแถวที่เหลือ
      _lastSyncTime = DateTime.now();
      await updatePendingCount();

      if (_pendingCount == 0) {
        _status = SyncStatus.synced;
        _statusMessage = 'ข้อมูลทั้งหมดเป็นปัจจุบันแล้ว (ซิงค์แล้ว $syncedTotal รายการ)';
        debugPrint('🎉 [SYNC COMPLETED] ข้อมูลทั้งหมดในเครื่องซิงค์ขึ้น Server เรียบร้อยแล้ว ($syncedTotal รายการ)');
      } else {
        _status = SyncStatus.idle;
        _statusMessage = 'เหลือข้อมูลคอยซิงค์ $_pendingCount รายการ';
        debugPrint('ℹ️ [SYNC STATUS] เหลือรายการค้างซิงค์: $_pendingCount รายการ');
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

  /// กระบวนการดึงข้อมูลจาก Database Server ลงมาที่ SQLite ในเครื่อง (Pull Synchronization / Downstream Sync / Initial Data Hydration)
  /// - userId: รหัสผู้ใช้ที่ต้องการดึงข้อมูล
  /// - forceInitial: บังคับดึงข้อมูลทั้งหมด (Initial Hydration) หรือดึงเฉพาะ Delta (เฉพาะที่ใหม่กว่า lastSyncTimestamp)
  Future<int> pullDownstreamWorkouts(int userId, {bool forceInitial = false}) async {
    final hasInternet = await checkConnection();
    if (!hasInternet) {
      debugPrint('SyncService: Offline. Cannot pull downstream data.');
      return 0;
    }

    _isSyncing = true;
    _status = SyncStatus.syncing;
    _statusMessage = 'กำลังดาวน์โหลดข้อมูลล่าสุดจากเซิร์ฟเวอร์...';
    notifyListeners();

    int pulledCount = 0;
    try {
      // 1. ตรวจสอบว่าใน SQLite ว่างเปล่าหรือไม่
      final localCount = await AppDatabase.instance.getWorkoutCount(userId: userId);
      final isLocalEmpty = localCount == 0;

      // 2. ดึง Timestamp ล่าสุดของการซิงค์
      String? lastSyncTimestamp;
      if (!isLocalEmpty && !forceInitial) {
        lastSyncTimestamp = await AppDatabase.instance.getLastWorkoutSyncTimestamp(userId);
      }

      // 3. ยิง Request ไปยัง Backend API
      debugPrint('SyncService: Pulling workouts for user $userId (since: $lastSyncTimestamp, isLocalEmpty: $isLocalEmpty)');
      final serverWorkouts = await HealthApiService.fetchWorkouts(
        userId: userId,
        since: lastSyncTimestamp,
      );

      // 4. เขียนลง SQLite ด้วยเทคนิค UPSERT (INSERT OR REPLACE)
      if (serverWorkouts.isNotEmpty) {
        pulledCount = await AppDatabase.instance.upsertWorkoutsFromServer(serverWorkouts);
        debugPrint('SyncService: Successfully hydrated $pulledCount workouts into SQLite');
      }

      // 5. บันทึกเวลาซิงค์ล่าสุด (Save Last Sync Timestamp)
      final nowTimestamp = DateTime.now().toIso8601String();
      await AppDatabase.instance.setLastWorkoutSyncTimestamp(userId, nowTimestamp);
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
      notifyListeners();
    }

    return pulledCount;
  }


  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    super.dispose();
  }
}
