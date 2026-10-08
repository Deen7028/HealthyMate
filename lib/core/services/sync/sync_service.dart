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

// สถานะของการซิงค์ข้อมูล (พร้อมทำงาน, กำลังตรวจสอบ, กำลังซิงค์, ซิงค์เสร็จแล้ว, ออฟไลน์, เกิดข้อผิดพลาด)
enum SyncStatus { idle, checking, syncing, synced, offline, error }

// บริการจัดการระบบ Offline-First และ Background Data Synchronization
// คอยตรวจจับสัญญาณอินเทอร์เน็ต และซิงค์ข้อมูลอัตโนมัติระหว่าง SQLite กับ Remote Server
class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  void _notifySyncListeners() => notifyListeners();
  // ตรวจสอบสัญญาณอินเทอร์เน็ตและซิงค์ข้อมูล
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

  // อ่านสถานะการเชื่อมต่ออินเทอร์เน็ต (Online / Offline)
  bool get isOnline => _isOnline;
  // อ่านสถานะว่ากำลังอยู่ในกระบวนการซิงค์ข้อมูลหรือไม่
  bool get isSyncing => _isSyncing;
  // สถานะ Enum ปัจจุบัน
  SyncStatus get status => _status;
  // ข้อความบรรยายสถานะภาษาไทยสำหรับแสดงบน UI
  String get statusMessage => _statusMessage;
  // เวลาที่มีการซิงค์สำเร็จล่าสุด
  DateTime? get lastSyncTime => _lastSyncTime;
  // จำนวนแถวข้อมูลในเครื่องที่ค้างรอซิงค์ขึ้น Server (isSynced = 0)
  int get pendingCount => _pendingCount;

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    super.dispose();
  }
}
