part of '../routine_controller.dart';

// ส่วนโหลดข้อมูลกิจวัตร (RoutineControllerLoading)
// ทำหน้าที่ดึงข้อมูลผู้ใช้, กิจวัตร, ประวัติ, เป้าหมาย และสถิติการออกกำลังกาย
extension RoutineControllerLoading on RoutineController {
  // ฟังก์ชัน: โหลดข้อมูลทั้งหมด (Load All Routine Data)
  Future<void> loadData() async {
    // 1. ตั้งสถานะกำลังโหลด และแจ้งเตือนหน้าจอ
    isLoading = true;
    this._notifyControllerListeners();

    try {
      final db = AppDatabase.instance;
      // 2. ดึงข้อมูลโปรไฟล์ผู้ใช้ปัจจุบัน
      user = await db.getCurrentUser();

      if (user == null) {
        isLoading = false;
        this._notifyControllerListeners();
        return;
      }

      final userId = user!.nUserId;

      // 3. ดึงรายการกิจวัตรและประวัติการทำของวันนี้
      await this._loadRoutinesAndLogs(db, userId);

      // 4. ดึงเป้าหมายหลักของผู้ใช้ (Main Goal)
      userGoal = await db.getUserGoal(userId);

      // 5. ดึงประวัติการออกกำลังกายและคำนวณสถิติเพื่อนำมานับความคืบหน้าของกิจวัตรที่เชื่อมโยง
      final workouts = await db.getWorkouts(userId: userId);
      this._aggregateWorkoutStats(workouts);
      await this._syncWorkoutRoutineProgress(db);

      // 6. คำนวณจำนวนกิจวัตรที่ทำสำเร็จแล้วในวันนี้
      completedCount = todayCompletionMap.values.where((v) => v).length;

      // 7. คำนวณความคืบหน้าของเป้าหมายหลัก และความคืบหน้ารวมทั้งหมด
      await this._syncGoalProgress(db, userId, workouts);
      this._updateOverallProgress();

      // 8. สิ้นสุดการโหลด และแจ้งเตือน UI แสดงข้อมูล
      isLoading = false;
      this._notifyControllerListeners();

      // 9. ตั้งค่าเวลาการแจ้งเตือนในระบบ และซิงค์ข้อมูลล่าสุดจากเซิร์ฟเวอร์
      this._resyncAllActiveNotifications();
      this._syncRoutinesFromServer(userId);
    } catch (e) {
      isLoading = false;
      this._notifyControllerListeners();
    }
  }
}
