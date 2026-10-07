part of '../routine_controller.dart';

// ส่วนสร้างกิจวัตรใหม่และการตั้งการแจ้งเตือน (RoutineControllerCreation)
// ทำหน้าที่บันทึกกิจวัตรใหม่ลง SQLite + Remote Server และตั้งเวลาแจ้งเตือนท้องถิ่น
extension RoutineControllerCreation on RoutineController {
  // ฟังก์ชัน: เพิ่มกิจวัตรใหม่ (Add New Routine)
  Future<void> addRoutine(RoutineItem newRoutine) async {
    if (user == null) return;
    final userId = user!.nUserId;

    // 1. บันทึกลงฐานข้อมูล SQLite ประจำเครื่อง
    final localId = await AppDatabase.instance.insertRoutine(
      userId: userId,
      title: newRoutine.title,
      time: newRoutine.notificationTime,
      targetValue: newRoutine.targetValue,
      unit: newRoutine.unit,
      linkedWorkout: newRoutine.linkedWorkoutType ?? '',
      color: newRoutine.color.toARGB32(),
      iconData: newRoutine.iconData.codePoint,
      isNotificationActive: newRoutine.isNotificationEnabled,
    );

    // 2. บันทึกขึ้น Remote Server
    final serverId = await RoutineApiService.insertRoutineRemote(
      userId: userId,
      title: newRoutine.title,
      time: newRoutine.notificationTime,
      targetValue: newRoutine.targetValue,
      unit: newRoutine.unit,
      linkedWorkout: newRoutine.linkedWorkoutType ?? '',
      color: newRoutine.color.toARGB32(),
      iconData: newRoutine.iconData.codePoint,
      isNotificationActive: newRoutine.isNotificationEnabled,
    );

    // 3. ปรับ ID และป้องกันข้อมูลซ้ำกรณี Server สร้าง ID ให้ใหม่
    final notificationRoutineId = serverId > 0 ? serverId : localId;
    if (serverId > 0 && serverId != localId && localId > 0) {
      await AppDatabase.instance.deleteRoutine(localId);
    }

    // 4. ตั้งค่าระบบแจ้งเตือน Local Notifications ตามรอบเวลา
    await this._syncLocalNotification(notificationRoutineId, newRoutine);

    // 5. โหลดข้อมูลใหม่ทั้งหมดเพื่ออัปเดตหน้าจอ
    await this.loadData();
  }

  // ฟังก์ชัน: ซิงค์การตั้งเวลาแจ้งเตือน Local Notification
  Future<void> _syncLocalNotification(
    int routineId,
    RoutineItem routine,
  ) async {
    if (routineId <= 0) return;

    // 1. ลบการแจ้งเตือนเดิมทั้งหมดของกิจวัตรนี้
    for (int i = 0; i < 10; i++) {
      await NotificationService.instance.cancelNotification(
        (routineId * 10) + i,
      );
    }

    if (!routine.isNotificationEnabled) return;

    // 2. ขอสิทธิ์ส่งการแจ้งเตือน
    await NotificationService.instance.requestPermission();

    final timeStr = routine.notificationTime;
    final intIntervalMatch = RegExp(
      r'ทุก\s*(\d+)\s*ชั่วโมง',
    ).firstMatch(timeStr);

    // 3. ตรวจสอบเงื่อนไขความถี่ของการแจ้งเตือน
    if (intIntervalMatch != null) {
      // กรณี: ทุกๆ N ชั่วโมง (เช่น ทุก 2 ชั่วโมง ระหว่าง 08:00 - 22:00)
      final step = int.parse(intIntervalMatch.group(1)!);
      int slotIndex = 0;
      for (int h = 8; h <= 22 && slotIndex < 10; h += step) {
        await NotificationService.instance.scheduleDailyRoutine(
          id: (routineId * 10) + slotIndex,
          title: 'ถึงเวลาทำกิจวัตร! 🎯',
          body: 'ได้เวลา: ${routine.title} แล้วครับ',
          hour: h,
          minute: 0,
        );
        slotIndex++;
      }
    } else if (timeStr.contains('ทุกชั่วโมง')) {
      // กรณี: ทุกชั่วโมง
      await NotificationService.instance.schedulePeriodicRoutine(
        id: routineId * 10,
        title: 'ถึงเวลาทำกิจวัตร! 🎯',
        body: 'ได้เวลา: ${routine.title} แล้วครับ',
        interval: RepeatInterval.hourly,
      );
    } else {
      // กรณี: ระบุเวลาเจาะจง (เช่น 08:00, 12:00, 20:00)
      final matches = RegExp(
        r'(\d{1,2})[:\.](\d{2})',
      ).allMatches(timeStr).toList();
      if (matches.isNotEmpty) {
        for (int i = 0; i < matches.length && i < 10; i++) {
          final match = matches[i];
          final hour = int.parse(match.group(1)!);
          final minute = int.parse(match.group(2)!);
          await NotificationService.instance.scheduleDailyRoutine(
            id: (routineId * 10) + i,
            title: 'กิจวัตรของคุณ 🌟',
            body: 'อย่าลืมทำ ${routine.title} นะครับ',
            hour: hour,
            minute: minute,
          );
        }
      } else {
        // ค่าเริ่มต้น 08:00 หากไม่ได้ระบุเวลาไว้ชัดเจน
        await NotificationService.instance.scheduleDailyRoutine(
          id: routineId * 10,
          title: 'กิจวัตรของคุณ 🌟',
          body: 'อย่าลืมทำ ${routine.title} นะครับ',
          hour: 8,
          minute: 0,
        );
      }
    }
  }
}
