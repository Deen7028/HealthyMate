part of 'routine_controller.dart';

extension RoutineControllerCreation on RoutineController {
  Future<void> addRoutine(RoutineItem newRoutine) async {
    if (user == null) return;
    final userId = user!.nUserId;

    // 1. บันทึกลง SQLite
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

    // หาก Server สร้าง ID ใหม่ที่ต่างจาก Local ให้ลบ Local เก่าป้องกันซ้ำ
    final notificationRoutineId = serverId > 0 ? serverId : localId;
    if (serverId > 0 && serverId != localId && localId > 0) {
      await AppDatabase.instance.deleteRoutine(localId);
    }

    // 🟢 ระบบการแจ้งเตือน Local Notifications
    await this._syncLocalNotification(notificationRoutineId, newRoutine);

    await this.loadData();
  }

  Future<void> _syncLocalNotification(
    int routineId,
    RoutineItem routine,
  ) async {
    if (routineId <= 0) return;

    for (int i = 0; i < 10; i++) {
      await NotificationService.instance.cancelNotification(
        (routineId * 10) + i,
      );
    }

    if (routine.isNotificationEnabled) {
      final hasPermission = await NotificationService.instance
          .requestPermission();
      if (hasPermission) {
        final timeStr = routine.notificationTime;
        final intIntervalMatch = RegExp(
          r'ทุก\s*(\d+)\s*ชั่วโมง',
        ).firstMatch(timeStr);

        if (intIntervalMatch != null) {
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
          await NotificationService.instance.schedulePeriodicRoutine(
            id: routineId * 10,
            title: 'ถึงเวลาทำกิจวัตร! 🎯',
            body: 'ได้เวลา: ${routine.title} แล้วครับ',
            interval: RepeatInterval.hourly,
          );
        } else {
          // ดึงเวลาทั้งหมดในข้อความ ไม่ว่าจะคั่นด้วย comma, &, หรือ "และ"
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
            // ค่าเริ่มต้นกรณีระบุเวลาลอยๆ
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
  }
}
