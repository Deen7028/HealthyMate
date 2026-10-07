part of '../routine_controller.dart';

extension RoutineControllerOverallProgress on RoutineController {
  void _updateOverallProgress() {
    double totalRatioSum = 0.0;
    for (final r in routines) {
      final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
      final targetVal =
          (r['targetValue'] as num?)?.toDouble() ??
          (r['nTargetValue'] as num?)?.toDouble() ??
          1.0;
      final currentVal = todayProgressValues[routineId] ?? 0.0;
      final isDone = todayCompletionMap[routineId] ?? false;
      final ratio = isDone
          ? 1.0
          : (targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0);
      totalRatioSum += ratio;
    }
    overallProgressRatio = routines.isNotEmpty
        ? (totalRatioSum / routines.length)
        : 0.0;
  }
}
