// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (notification service scheduling)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'notification_service.dart';

extension NotificationServiceScheduling on NotificationService {
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

      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        targetNative,
        tz.local,
      );

      debugPrint(
        '⏳ กำลังสั่งตั้งเวลาแจ้งเตือน ID: $id ตอน $hour:$minute (Target: $scheduledDate, Now: $nowNative)...',
      );

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_channel_v4',
          'การแจ้งเตือนกิจวัตร',
          channelDescription: 'แจ้งเตือนเวลาทำกิจวัตร',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
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
          '⚠️ exactAllowWhileIdle พัง fallback เป็น inexact: $scheduleError',
        );
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
          'routine_channel_v4',
          'การแจ้งเตือนกิจวัตร',
          channelDescription: 'แจ้งเตือนกิจวัตรแบบวนรอบ',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
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
}
