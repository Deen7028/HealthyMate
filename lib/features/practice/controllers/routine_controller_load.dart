// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine controller load)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_controller.dart';

extension RoutineControllerLoading on RoutineController {
  Future<void> loadData() async {
    isLoading = true;
    this._notifyControllerListeners();

    try {
      final db = AppDatabase.instance;
      user = await db.getCurrentUser();

      if (user == null) {
        isLoading = false;
        this._notifyControllerListeners();
        return;
      }

      final userId = user!.nUserId;
      await this._loadRoutinesAndLogs(db, userId);
      userGoal = await db.getUserGoal(userId);

      final workouts = await db.getWorkouts(userId: userId);
      this._aggregateWorkoutStats(workouts);
      await this._syncWorkoutRoutineProgress(db);
      completedCount = todayCompletionMap.values.where((v) => v).length;
      await this._syncGoalProgress(db, userId, workouts);
      this._updateOverallProgress();

      isLoading = false;
      this._notifyControllerListeners();

      this._resyncAllActiveNotifications();
      this._syncRoutinesFromServer(userId);
    } catch (e) {
      isLoading = false;
      this._notifyControllerListeners();
    }
  }
}
