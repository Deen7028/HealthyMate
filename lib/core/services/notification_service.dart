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
          AndroidInitializationSettings('@mipmap/launch_background');

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

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_routines',
            'กิจวัตรประจำวัน',
            channelDescription: 'แจ้งเตือนเวลาทำกิจวัตร',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launch_background',
          ),
          iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling daily routine notification: $e');
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

      await _notificationsPlugin.periodicallyShow(
        id: id,
        title: title,
        body: body,
        repeatInterval: interval,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'periodic_routines',
            'แจ้งเตือนความถี่สูง',
            channelDescription: 'แจ้งเตือนกิจวัตรแบบวนรอบ',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launch_background',
          ),
          iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Error scheduling periodic routine notification: $e');
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
