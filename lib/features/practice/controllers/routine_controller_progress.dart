// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine controller progress)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_controller.dart';

extension RoutineControllerProgress on RoutineController {
  Future<void> toggleRoutineCompletion(int routineId) async {
    final currentStatus = todayCompletionMap[routineId] ?? false;
    final newStatus = !currentStatus;
    todayCompletionMap[routineId] = newStatus;

    final r = routines.firstWhere(
      (element) => (element['nRoutineId'] as num?)?.toInt() == routineId,
      orElse: () => <String, dynamic>{},
    );
    final targetVal =
        (r['targetValue'] as num?)?.toDouble() ??
        (r['nTargetValue'] as num?)?.toDouble() ??
        1.0;
    todayProgressValues[routineId] = newStatus ? targetVal : 0.0;
    completedCount = todayCompletionMap.values.where((v) => v).length;
    this._notifyControllerListeners();

    if (newStatus) {
      final title = (r['sTitle'] ?? r['title'] ?? '').toString().toLowerCase();
      if (title.contains('น้ำ') || title.contains('water')) {
        AudioService.instance.playWaterDrop();
      } else {
        AudioService.instance.playSuccess();
      }
    }

    if (user != null) {
      await AppDatabase.instance.insertOrUpdateRoutineLog(
        routineId: routineId,
        dateStr: todayStr,
        progressValue: newStatus ? targetVal : 0.0,
        isCompleted: newStatus,
      );

      try {
        final success = await GoalApiService.updateRoutineProgressRemote(
          routineId: routineId,
          date: todayStr,
          progressValue: newStatus ? targetVal : 0.0,
          isCompleted: newStatus,
        );
        debugPrint(
          '☁️ [ROUTINE_LOG] ➤ อัปเดตความสำเร็จกิจวัตร ID: $routineId ($todayStr, isCompleted: $newStatus) ขึ้น Server: $success',
        );
      } catch (e) {
        debugPrint(
          '❌ [ROUTINE_LOG] ➤ ซิงค์สถานะกิจวัตร ID: $routineId ขึ้น Server ผิดพลาด: $e',
        );
      }

      RoutineStateNotifier.instance.loadData(userId: user!.nUserId);
    }
  }

  Future<void> incrementRoutineValue(int routineId, double step) async {
    final r = routines.firstWhere(
      (element) => (element['nRoutineId'] as num?)?.toInt() == routineId,
      orElse: () => <String, dynamic>{},
    );
    if (r.isEmpty) return;

    final targetVal =
        (r['targetValue'] as num?)?.toDouble() ??
        (r['nTargetValue'] as num?)?.toDouble() ??
        1.0;
    final currentVal = todayProgressValues[routineId] ?? 0.0;
    final newVal = (currentVal + step).clamp(0.0, targetVal * 2);

    todayProgressValues[routineId] = newVal;
    final isDone = newVal >= targetVal;
    todayCompletionMap[routineId] = isDone;
    completedCount = todayCompletionMap.values.where((v) => v).length;
    this._notifyControllerListeners();

    final title = (r['sTitle'] ?? r['title'] ?? '').toString().toLowerCase();
    final unit = (r['unit'] ?? r['sUnit'] ?? '').toString().toLowerCase();
    if (title.contains('น้ำ') ||
        title.contains('water') ||
        unit.contains('มล') ||
        unit.contains('ml') ||
        unit.contains('ลิตร')) {
      if (isDone) {
        AudioService.instance.playSuccess();
      } else {
        AudioService.instance.playWaterDrop();
      }
    } else {
      AudioService.instance.playSuccess();
    }

    if (user != null) {
      await AppDatabase.instance.insertOrUpdateRoutineLog(
        routineId: routineId,
        dateStr: todayStr,
        progressValue: newVal,
        isCompleted: isDone,
      );

      GoalApiService.updateRoutineProgressRemote(
        routineId: routineId,
        date: todayStr,
        progressValue: newVal,
        isCompleted: isDone,
      );

      RoutineStateNotifier.instance.loadData(userId: user!.nUserId);
    }
  }

  Future<void> resetRoutineProgress(int routineId) async {
    todayProgressValues[routineId] = 0.0;
    todayCompletionMap[routineId] = false;
    completedCount = todayCompletionMap.values.where((v) => v).length;
    this._notifyControllerListeners();

    if (user != null) {
      await AppDatabase.instance.insertOrUpdateRoutineLog(
        routineId: routineId,
        dateStr: todayStr,
        progressValue: 0,
        isCompleted: false,
      );

      GoalApiService.updateRoutineProgressRemote(
        routineId: routineId,
        date: todayStr,
        progressValue: 0,
        isCompleted: false,
      );
    }
  }
}
