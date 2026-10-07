part of 'sync_service.dart';

extension SyncServiceSyncRoutines on SyncService {
  Future<int> _syncRoutinesGoalsAndPreferences(int currentUserId) async {
    int syncedTotal = 0;
    // 5. ซิงค์ตาราง TbRoutines & TbRoutineLogs
    if (currentUserId > 0) {
      final localRoutines = await AppDatabase.instance.getRoutines(
        userId: currentUserId,
      );
      final serverResult = await RoutineApiService.fetchRoutines(
        userId: currentUserId,
      );
      if (serverResult != null && serverResult['status'] == 'success') {
        final serverRoutines =
            (serverResult['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final serverTitles = serverRoutines
            .map((sr) => sr['sTitle']?.toString().trim() ?? '')
            .toSet();

        for (final lr in localRoutines) {
          final title = lr['sTitle']?.toString().trim() ?? '';
          if (title.isNotEmpty &&
              !serverTitles
                  .map((t) => t.toLowerCase())
                  .contains(title.toLowerCase())) {
            final newId = await RoutineApiService.insertRoutineRemote(
              userId: currentUserId,
              title: title,
              time: lr['sTime']?.toString() ?? '',
              targetValue: (lr['targetValue'] as num?)?.toDouble() ?? 1.0,
              unit: lr['unit']?.toString() ?? 'ครั้ง',
              linkedWorkout: lr['sLinkedWorkout']?.toString() ?? '',
              color: (lr['color'] as num?)?.toInt(),
              iconData: (lr['iconData'] as num?)?.toInt(),
              isNotificationActive: lr['isNotificationActive'] is bool
                  ? (lr['isNotificationActive'] as bool)
                  : ((lr['isNotificationActive'] as num?)?.toInt() ?? 1) == 1,
            );
            if (newId > 0) {
              syncedTotal++;
              final localId = (lr['nRoutineId'] as num?)?.toInt() ?? 0;
              if (localId > 0 && localId != newId) {
                await AppDatabase.instance.deleteRoutine(localId);
              }
              debugPrint(
                '☁️ [SYNC SUCCESS] [TbRoutines] ➜ อัปโหลดกิจวัตรใหม่ "$title" (Server ID: $newId) ขึ้น Server สำเร็จ',
              );
            }
          }
        }
        await AppDatabase.instance.deduplicateRoutines(userId: currentUserId);

        // ดึงรายการกิจวัตรล่าสุดจาก Server มาทำแผนที่ Title -> Server nRoutineId
        final freshServerRes = await RoutineApiService.fetchRoutines(
          userId: currentUserId,
        );
        final Map<String, int> titleToServerId = {};
        final Set<int> validServerRoutineIds = {};
        if (freshServerRes != null && freshServerRes['status'] == 'success') {
          final list =
              (freshServerRes['data'] as List?)?.cast<Map<String, dynamic>>() ??
              [];
          for (final item in list) {
            final sId = (item['nRoutineId'] as num?)?.toInt() ?? 0;
            final sTitle = (item['sTitle']?.toString() ?? '')
                .trim()
                .toLowerCase();
            if (sId > 0) {
              validServerRoutineIds.add(sId);
              if (sTitle.isNotEmpty) {
                titleToServerId[sTitle] = sId;
              }
            }
          }
        }

        // ซิงค์ RoutineLogs ของวันนี้ขึ้น Server
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final todayLogs = await AppDatabase.instance.getRoutineLogsForDate(
          userId: currentUserId,
          dateStr: todayStr,
        );
        for (final log in todayLogs) {
          int targetRoutineId = (log['nRoutineId'] as num?)?.toInt() ?? 0;
          final routineTitle = (log['sTitle']?.toString() ?? '')
              .trim()
              .toLowerCase();

          // หาก ID ในเครื่องยังไม่ใช่ ID ของ Server ให้แปลงโดยอิงจากชื่อกิจวัตร
          if (!validServerRoutineIds.contains(targetRoutineId) &&
              titleToServerId.containsKey(routineTitle)) {
            targetRoutineId = titleToServerId[routineTitle]!;
          }

          final isCompleted = (log['isCompleted'] as num?)?.toInt() == 1;
          final progressValue =
              (log['nProgressValue'] as num?)?.toDouble() ?? 0.0;
          if (targetRoutineId > 0 &&
              validServerRoutineIds.contains(targetRoutineId)) {
            final ok = await GoalApiService.updateRoutineProgressRemote(
              routineId: targetRoutineId,
              date: todayStr,
              progressValue: progressValue,
              isCompleted: isCompleted,
            );
            if (ok) {
              syncedTotal++;
              debugPrint(
                '☁️ [SYNC SUCCESS] [TbRoutineLogs] ➜ อัปเดต Log กิจวัตร "$routineTitle" (Server ID: $targetRoutineId, $todayStr: คืบหน้า $progressValue, เสร็จสิ้น: $isCompleted) ขึ้น Server สำเร็จ',
              );
            }
          }
        }
      }

      // 6. ซิงค์ตาราง TbGoals
      final localGoal = await AppDatabase.instance.getUserGoal(currentUserId);
      if (localGoal != null) {
        final success = await GoalApiService.saveMainGoalRemote(
          userId: currentUserId,
          routineId: (localGoal['nRoutineId'] as num?)?.toInt() ?? 0,
          title: localGoal['sTitle']?.toString() ?? '',
          progress: (localGoal['nProgress'] as num?)?.toDouble() ?? 0.0,
          remainingText: localGoal['sRemainingText']?.toString() ?? '',
        );
        if (success) {
          syncedTotal++;
          debugPrint(
            '☁️ [SYNC SUCCESS] [TbGoals] ➜ ซิงค์เป้าหมายหลัก "${localGoal['sTitle']}" (ความคืบหน้า: ${(localGoal['nProgress'] * 100).toInt()}%) ขึ้น Server สำเร็จ',
          );
        }
      }

      // 7. ซิงค์ตาราง TbUserPreferences
      final unitPref = await AppDatabase.instance.getUserUnitPreference(
        currentUserId,
      );
      final okPref = await GoalApiService.saveUserPreferencesRemote(
        userId: currentUserId,
        unitLabel: unitPref,
      );
      if (okPref) {
        debugPrint(
          '☁️ [SYNC SUCCESS] [TbUserPreferences] ➜ ซิงค์การตั้งค่าหน่วยวัด ($unitPref) ขึ้น Server สำเร็จ',
        );
      }
    }
    return syncedTotal;
  }
}
