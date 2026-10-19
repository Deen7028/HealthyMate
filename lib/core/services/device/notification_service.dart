import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

part 'notification_service_scheduling.dart';

// บริการจัดการระบบแจ้งเตือนภายในเครื่อง (Flutter Local Notifications Core Service)
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // กำหนดค่าเริ่มต้นระบบแจ้งเตือน (Channel, ไอคอนแอป และเขตเวลา Timezone ของไทย)
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked payload: ${details.payload}');
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  // ขอสิทธิ์การแจ้งเตือนจากผู้ใช้ (รองรับ Android 13+ และ iOS)
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImplementation != null) {
          await androidImplementation.requestNotificationsPermission();
          await androidImplementation.requestExactAlarmsPermission();
        }
      }
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  // แสดงหรืออัปเดตแถบแจ้งเตือนนับก้าว 24/7 แบบเกาะติดหน้าจอ (Ongoing Step Tracker Notification)
  Future<void> updateStepTrackerNotification({
    required int nSteps,
    required int nTargetSteps,
    required double nDistanceKm,
    required double nCaloriesBurned,
  }) async {
    try {
      await init();
      final nValidTarget = nTargetSteps > 0 ? nTargetSteps : 8000;
      final nPercent = ((nSteps / nValidTarget) * 100).toInt().clamp(0, 100);
      final sKcalText = nCaloriesBurned.toStringAsFixed(1);

      // จัดรูปแบบตัวหนังสือแบบ 2 คอลัมน์ (ก้าวเดิน | แคลอรี) ตรงตามตัวอย่าง UI
      final sBigText =
          '<b><big>👣  $nSteps ก้าว</big></b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b><big>🔥  $sKcalText Kcal</big></b><br><small><font color="#94A3B8">เป้าหมาย $nValidTarget ก้าว ($nPercent%)  •  📍 ${nDistanceKm.toStringAsFixed(2)} กม.</font></small>';

      final bigTextStyleInfo = BigTextStyleInformation(
        sBigText,
        htmlFormatBigText: true,
        contentTitle: '<b>HealthyMate</b>',
        htmlFormatContentTitle: true,
        summaryText: 'ติดตามก้าวเดิน 24/7',
        htmlFormatSummaryText: true,
      );

      final androidDetails = AndroidNotificationDetails(
        'step_tracker_channel_v3',
        'การติดตามก้าวเดิน 24/7',
        channelDescription: 'แถบแสดงจำนวนก้าวและแคลอรีสะสมประจำวัน',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: nValidTarget,
        progress: nSteps.clamp(0, nValidTarget),
        color: const Color(0xFF10B981),
        styleInformation: bigTextStyleInfo,
        subText: 'ก้าวเดิน & แคลอรี',
        actions: const [
          AndroidNotificationAction(
            'open_app',
            '➔  เปิดแอป',
            showsUserInterface: true,
          ),
        ],
        onlyAlertOnce: true,
        enableVibration: false,
        playSound: false,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentSound: false,
        presentBadge: false,
        presentAlert: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final sTitle = '👣 $nSteps ก้าว     |     🔥 $sKcalText Kcal';
      final sBody =
          'เป้าหมาย $nValidTarget ก้าว ($nPercent%)  •  📍 ${nDistanceKm.toStringAsFixed(2)} กม.';

      await _notificationsPlugin.show(
        id: 9999,
        title: sTitle,
        body: sBody,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Error updating step tracker notification: $e');
    }
  }

  // ยกเลิกแถบแจ้งเตือนนับก้าว 24/7
  Future<void> cancelStepTrackerNotification() async {
    await cancelNotification(9999);
  }

  // ยกเลิกการแจ้งเตือนตาม ID ที่ระบุ
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  // ยกเลิกการแจ้งเตือนทั้งหมดในระบบ
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }
}
