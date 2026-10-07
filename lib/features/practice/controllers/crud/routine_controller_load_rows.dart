part of '../routine_controller.dart';

extension RoutineControllerLoadRows on RoutineController {
  Future<void> _loadRoutinesAndLogs(AppDatabase db, int userId) async {
    routines = await db.getRoutines(userId: userId);

    final allLogsToday = await db.getRoutineLogsForDate(
      userId: userId,
      dateStr: todayStr,
    );

    final Map<int, Map<String, dynamic>> logsMap = {};
    for (final log in allLogsToday) {
      final rId = (log['nRoutineId'] as num?)?.toInt() ?? 0;
      logsMap[rId] = log;
    }

    todayCompletionMap.clear();
    todayProgressValues.clear();

    for (final r in routines) {
      final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
      final targetVal =
          (r['targetValue'] as num?)?.toDouble() ??
          (r['nTargetValue'] as num?)?.toDouble() ??
          1.0;
      final log = logsMap[routineId];
      final isDone = (log?['isCompleted'] as num?)?.toInt() == 1;
      final logProgress =
          (log?['nProgressValue'] as num?)?.toDouble() ??
          (log?['progressValue'] as num?)?.toDouble();

      todayCompletionMap[routineId] = isDone;
      todayProgressValues[routineId] =
          logProgress ?? (isDone ? targetVal : 0.0);
    }
  }
}
