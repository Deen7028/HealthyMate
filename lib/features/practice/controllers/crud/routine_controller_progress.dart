part of '../routine_controller.dart';

// ส่วนจัดการความคืบหน้าของกิจวัตร (RoutineControllerProgress)
// ทำหน้าที่บันทึกการทำสำเร็จ/ยกเลิก, การเพิ่มค่า (เช่น ดื่มน้ำ) และการรีเซ็ตความคืบหน้า
extension RoutineControllerProgress on RoutineController {
  Future<void> toggleRoutineCompletion(int routineId) async {
    // 1. สลับสถานะความสำเร็จในแคชของหน้าจอ
    final currentStatus = todayCompletionMap[routineId] ?? false;
    final newStatus = !currentStatus;
    todayCompletionMap[routineId] = newStatus;

    // 2. ดึงเป้าหมายของกิจวัตรนี้และปรับค่าความคืบหน้า
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

    // 3. เล่นเสียงเอฟเฟกต์ตามประเภทกิจกรรม
    if (newStatus) {
      final title = (r['sTitle'] ?? r['title'] ?? '').toString().toLowerCase();
      if (title.contains('น้ำ') || title.contains('water')) {
        AudioService.instance.playWaterDrop();
      } else {
        AudioService.instance.playSuccess();
      }
    }

    // 4. บันทึกลง SQLite และซิงค์ขึ้นระบบ Remote Server
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

  // ฟังก์ชัน: เพิ่มค่าความคืบหน้าทีละขั้น (Increment Routine Value เช่น ดื่มน้ำทีละแก้ว)
  Future<void> incrementRoutineValue(int routineId, double step) async {
    // 1. ค้นหากิจวัตรตาม ID
    final r = routines.firstWhere(
      (element) => (element['nRoutineId'] as num?)?.toInt() == routineId,
      orElse: () => <String, dynamic>{},
    );
    if (r.isEmpty) return;

    // 2. คำนวณค่าใหม่ และตรวจสอบว่าถึงเป้าหมายหรือยัง
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

    // 3. เล่นเสียงแจ้งเตือนความสำเร็จหรือเสียงน้ำ
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

    // 4. บันทึกค่าลงฐานข้อมูล SQLite และส่งข้อมูลขึ้น Server
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

  // ฟังก์ชัน: รีเซ็ตความคืบหน้าของกิจวัตร (Reset Routine Progress)
  Future<void> resetRoutineProgress(int routineId) async {
    // 1. ตั้งค่าความคืบหน้าเป็น 0 และแจ้งเตือน UI
    todayProgressValues[routineId] = 0.0;
    todayCompletionMap[routineId] = false;
    completedCount = todayCompletionMap.values.where((v) => v).length;
    this._notifyControllerListeners();

    // 2. ล้างข้อมูลใน Local DB และ Remote Server
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
