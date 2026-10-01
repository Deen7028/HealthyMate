part of 'routine_controller.dart';

extension RoutineControllerMutations on RoutineController {
  Future<void> deleteRoutine(int routineId, String title) async {
    await AppDatabase.instance.deleteRoutine(routineId);
    for (int i = 0; i < 10; i++) {
      await NotificationService.instance.cancelNotification(
        (routineId * 10) + i,
      );
    }

    if (userGoal != null) {
      final pinnedId = (userGoal!['nRoutineId'] as num?)?.toInt() ?? 0;
      if (pinnedId == routineId || userGoal!['sTitle'] == title) {
        userGoal = null;
        if (user != null) {
          await AppDatabase.instance.clearUserGoal(user!.nUserId);
        }
      }
    }

    await RoutineApiService.deleteRoutineRemote(routineId);
    await this.loadData();
  }

  Future<void> editRoutine(int routineId, RoutineItem updatedRoutine) async {
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

    await this._syncLocalNotification(routineId, updatedRoutine);

    await this.loadData();
  }
}
