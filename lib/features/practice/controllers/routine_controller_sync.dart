part of 'routine_controller.dart';

extension RoutineControllerSyncing on RoutineController {
  Future<void> _resyncAllActiveNotifications() async {
    for (final r in routines) {
      final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
      final isNotifyActive =
          (r['isNotificationActive'] as num?)?.toInt() == 1 ||
          (r['isNotificationActive'] as bool? ?? false);
      if (routineId > 0 && isNotifyActive) {
        final title = r['sTitle']?.toString() ?? r['title']?.toString() ?? '';
        final timeStr = r['sTime']?.toString() ?? r['time']?.toString() ?? '';
        final item = RoutineItem(
          id: routineId.toString(),
          title: title,
          category: RoutineCategory.custom,
          targetValue: (r['targetValue'] as num?)?.toDouble() ?? 1.0,
          unit: r['unit']?.toString() ?? 'ครั้ง',
          notificationTime: timeStr,
          isNotificationEnabled: true,
          repeatDays: const ['ทุกวัน'],
          color: const Color(0xFF2E5327),
          iconData: Icons.check,
        );
        await this._syncLocalNotification(routineId, item);
      }
    }
  }

  Future<void> _syncRoutinesFromServer(int userId) async {
    try {
      final localRoutines = await AppDatabase.instance.getRoutines(
        userId: userId,
      );
      final serverResult = await RoutineApiService.fetchRoutines(
        userId: userId,
      );

      if (serverResult != null && serverResult['status'] == 'success') {
        final serverRoutines =
            (serverResult['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        final serverTitles = serverRoutines
            .map((sr) => (sr['sTitle']?.toString() ?? '').trim().toLowerCase())
            .toSet();

        // 🟢 ดันกิจวัตรในเครื่องที่ยังไม่มีบน Server ขึ้น MySQL ทันที
        bool hasNewUploaded = false;
        for (final r in localRoutines) {
          final title = (r['sTitle']?.toString() ?? '').trim();
          if (title.isNotEmpty && !serverTitles.contains(title.toLowerCase())) {
            final time = r['sTime']?.toString() ?? '';
            final targetVal = (r['targetValue'] as num?)?.toDouble() ?? 1.0;
            final unit = r['unit']?.toString() ?? 'ครั้ง';
            final linkedWorkout = r['sLinkedWorkout']?.toString() ?? '';
            final color = (r['color'] as num?)?.toInt();
            final iconData = (r['iconData'] as num?)?.toInt();
            final isNotif = r['isNotificationActive'] is bool
                ? (r['isNotificationActive'] as bool)
                : ((r['isNotificationActive'] as num?)?.toInt() ?? 1) == 1;

            final newId = await RoutineApiService.insertRoutineRemote(
              userId: userId,
              title: title,
              time: time,
              targetValue: targetVal,
              unit: unit,
              linkedWorkout: linkedWorkout,
              color: color,
              iconData: iconData,
              isNotificationActive: isNotif,
            );
            if (newId > 0) {
              hasNewUploaded = true;
              // ถ้า Server สร้าง ID ใหม่ ให้ลบแถว Local เก่าที่ ID ไม่ตรงออก ป้องกันซ้ำ
              final localId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
              if (localId > 0 && localId != newId) {
                await AppDatabase.instance.deleteRoutine(localId);
              }
            }
          }
        }

        // หากมีการดันกิจวัตรขึ้นใหม่ ให้ดึงรายการสดล่าสุดจาก Server
        if (hasNewUploaded) {
          final refreshedResult = await RoutineApiService.fetchRoutines(
            userId: userId,
          );
          if (refreshedResult != null &&
              refreshedResult['status'] == 'success') {
            final refreshedRoutines =
                (refreshedResult['data'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
            if (refreshedRoutines.isNotEmpty) {
              await AppDatabase.instance.upsertRoutinesFromServer(
                userId,
                refreshedRoutines,
              );
            }
          }
        } else if (serverRoutines.isNotEmpty) {
          await AppDatabase.instance.upsertRoutinesFromServer(
            userId,
            serverRoutines,
          );
        }

        await AppDatabase.instance.deduplicateRoutines(userId: userId);
        routines = await AppDatabase.instance.getRoutines(userId: userId);

        for (final r in serverRoutines) {
          final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
          if (routineId == 0) continue;

          bool isDone = false;
          double progVal = 0.0;

          if (r.containsKey('todayCompleted') && r['todayCompleted'] != null) {
            isDone = (r['todayCompleted'] as num?)?.toInt() == 1;
            if (isDone) {
              todayCompletionMap[routineId] = true;
            }
          }
          if (r.containsKey('todayProgressValue') &&
              r['todayProgressValue'] != null) {
            final serverVal =
                (r['todayProgressValue'] as num?)?.toDouble() ?? 0.0;
            final currentLocal = todayProgressValues[routineId] ?? 0.0;
            progVal = serverVal > currentLocal ? serverVal : currentLocal;
            if (serverVal > currentLocal) {
              todayProgressValues[routineId] = serverVal;
            }
          }

          if (isDone || progVal > 0) {
            await AppDatabase.instance.insertOrUpdateRoutineLog(
              routineId: routineId,
              dateStr: todayStr,
              progressValue: progVal,
              isCompleted: isDone,
            );
          }
        }
        completedCount = todayCompletionMap.values.where((v) => v).length;
        this._notifyControllerListeners();
      }
    } catch (e) {
      debugPrint('[RoutineController] _syncRoutinesFromServer error: $e');
    }
  }
}
