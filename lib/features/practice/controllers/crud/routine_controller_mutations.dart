part of '../routine_controller.dart';

// ส่วนจัดการการแก้ไขและลบกิจวัตร (RoutineControllerMutations)
// ทำหน้าที่แก้ไขข้อมูลกิจวัตร และลบกิจวัตรพร้อมยกเลิกการแจ้งเตือน
extension RoutineControllerMutations on RoutineController {
  // ฟังก์ชัน: ลบกิจวัตร (Delete Routine)
  Future<void> deleteRoutine(int routineId, String title) async {
    // 1. ลบข้อมูลออกจากฐานข้อมูล SQLite
    await AppDatabase.instance.deleteRoutine(routineId);

    // 2. ยกเลิกการแจ้งเตือนทั้งหมดของกิจวัตรนี้ (สูงสุด 10 สล็อตต่อกิจวัตร)
    for (int i = 0; i < 10; i++) {
      await NotificationService.instance.cancelNotification(
        (routineId * 10) + i,
      );
    }

    // 3. หากกิจวัตรนี้ถูกตั้งเป็นเป้าหมายหลัก ให้ปลดออกด้วย
    if (userGoal != null) {
      final pinnedId = (userGoal!['nRoutineId'] as num?)?.toInt() ?? 0;
      if (pinnedId == routineId || userGoal!['sTitle'] == title) {
        userGoal = null;
        if (user != null) {
          await AppDatabase.instance.clearUserGoal(user!.nUserId);
        }
      }
    }

    // 4. สั่งลบข้อมูลบนเซิร์ฟเวอร์ Remote API
    await RoutineApiService.deleteRoutineRemote(routineId);

    // 5. โหลดข้อมูลใหม่ทั้งหมดเพื่ออัปเดตหน้าจอ
    await this.loadData();
  }

  // ฟังก์ชัน: แก้ไขกิจวัตร (Edit Routine)
  Future<void> editRoutine(int routineId, RoutineItem updatedRoutine) async {
    // 1. บันทึกข้อมูลที่แก้ไขลงฐานข้อมูลท้องถิ่น SQLite
    await AppDatabase.instance.updateRoutine(
      routineId: routineId,
      title: updatedRoutine.title,
      time: updatedRoutine.notificationTime,
      targetValue: updatedRoutine.targetValue,
      unit: updatedRoutine.unit,
      linkedWorkout: updatedRoutine.linkedWorkoutType ?? '',
      color: updatedRoutine.color.toARGB32(),
      iconData: updatedRoutine.iconData.codePoint,
      isNotificationActive: updatedRoutine.isNotificationEnabled,
    );

    // 2. อัปเดตข้อมูลขึ้นเซิร์ฟเวอร์ Remote API
    await RoutineApiService.updateRoutineRemote(
      routineId: routineId,
      title: updatedRoutine.title,
      time: updatedRoutine.notificationTime,
      targetValue: updatedRoutine.targetValue,
      unit: updatedRoutine.unit,
      linkedWorkout: updatedRoutine.linkedWorkoutType ?? '',
      color: updatedRoutine.color.toARGB32(),
      iconData: updatedRoutine.iconData.codePoint,
      isNotificationActive: updatedRoutine.isNotificationEnabled,
    );

    // 3. ตั้งเวลาการแจ้งเตือนใหม่ตามเวลาที่แก้ไข
    await this._syncLocalNotification(routineId, updatedRoutine);

    // 4. โหลดข้อมูลใหม่ทั้งหมดเพื่ออัปเดตสถานะ UI
    await this.loadData();
  }
}
