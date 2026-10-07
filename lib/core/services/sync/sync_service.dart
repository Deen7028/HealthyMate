// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (sync service)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

part 'sync_service_lifecycle.dart';
part 'sync_service_upstream.dart';
part 'sync_service_sync_records.dart';
part 'sync_service_sync_activity.dart';
part 'sync_service_sync_routines.dart';
part 'sync_service_downstream.dart';

enum SyncStatus { idle, checking, syncing, synced, offline, error }

/// Service สำหรับจัดการ Offline-First และ Background Synchronization
/// - คอยดักฟังสัญญาณเครือข่าย 2 ระดับ: (1) connectivity_plus (2) internet_connection_checker_plus
/// - เมื่อมีสัญญาณอินเทอร์เน็ตจริง จะทำการ Upstream Sync ข้อมูลแถวที่ `isSynced = 0` ขึ้น PHP API
/// - อัปเดตสถานะใน SQLite เป็น `isSynced = 1` เมื่อ Backend ตอบกลับ 200 OK
class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  void _notifySyncListeners() => notifyListeners();

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
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    super.dispose();
  }
}
