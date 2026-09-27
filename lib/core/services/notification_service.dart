import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

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

  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
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

  /// 1. ตั้งแจ้งเตือนแบบ "ระบุเวลาประจำวัน" (Daily Routine)
  Future<void> scheduleDailyRoutine({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      await init();

      final DateTime nowNative = DateTime.now();
      DateTime targetNative = DateTime(
        nowNative.year,
        nowNative.month,
        nowNative.day,
        hour,
        minute,
      );

      if (targetNative.isBefore(nowNative)) {
        targetNative = targetNative.add(const Duration(days: 1));
      }

      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.from(targetNative, tz.local);

      debugPrint(
          '⏳ กำลังสั่งตั้งเวลาแจ้งเตือน ID: $id ตอน $hour:$minute (Target: $scheduledDate, Now: $nowNative)...');

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_channel_v3',
          'การแจ้งเตือนกิจวัตร',
          channelDescription: 'แจ้งเตือนเวลาทำกิจวัตร',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (scheduleError) {
        debugPrint(
            '⚠️ exactAllowWhileIdle พัง fallback เป็น inexact: $scheduleError');
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      debugPrint('✅ สั่ง OS ตั้งปลุกสำเร็จแล้ว! ID: $id ($hour:$minute)');
    } catch (e) {
      debugPrint('❌ พัง! ตั้งแจ้งเตือนไม่ได้ สาเหตุ: $e');
    }
  }


  /// 2. ตั้งแจ้งเตือนแบบ "ความถี่วนรอบ" (Periodic Routine - เช่น ทุกชั่วโมง)
  Future<void> schedulePeriodicRoutine({
    required int id,
    required String title,
    required String body,
    required RepeatInterval interval,
  }) async {
    try {
      await init();

      debugPrint('⏳ กำลังสั่งตั้งเวลาแจ้งเตือนความถี่วนรอบ ID: $id...');

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_channel_v3',
          'การแจ้งเตือนกิจวัตร',
          channelDescription: 'แจ้งเตือนกิจวัตรแบบวนรอบ',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
      );

      try {
        await _notificationsPlugin.periodicallyShow(
          id: id,
          title: title,
          body: body,
          repeatInterval: interval,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('⚠️ periodicallyShow exact พัง fallback เป็น inexact: $e');
        await _notificationsPlugin.periodicallyShow(
          id: id,
          title: title,
          body: body,
          repeatInterval: interval,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      debugPrint('✅ สั่ง OS ตั้งปลุกความถี่วนรอบสำเร็จแล้ว! ID: $id');
    } catch (e) {
      debugPrint('❌ พัง! ตั้งแจ้งเตือนวนรอบไม่ได้ สาเหตุ: $e');
    }
  }

  /// 3. ยกเลิกการแจ้งเตือนตาม routineId
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  /// 4. ยกเลิกการแจ้งเตือนทั้งหมด
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }
}
