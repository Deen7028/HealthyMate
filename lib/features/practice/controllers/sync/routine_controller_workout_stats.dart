part of '../routine_controller.dart';

extension RoutineControllerWorkoutStats on RoutineController {
  void _aggregateWorkoutStats(List<Map<String, dynamic>> workouts) {
    todayWorkoutStats.clear();

    for (final w in workouts) {
      final workoutDate = w['dtWorkoutDate']?.toString() ?? '';
      if (workoutDate.startsWith(todayStr)) {
        final type = w['sType']?.toString() ?? 'อื่นๆ';
        final dist = (w['nDistance'] as num?)?.toDouble() ?? 0.0;
        final durationSec = (w['nDuration'] as num?)?.toDouble() ?? 0.0;
        final durationMin = durationSec > 0 ? (durationSec / 60.0) : 0.0;
        final calories = (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;

        final normType = RoutineController.normalizeCategoryType(type);
        final keysToUpdate = {type, normType};

        for (final k in keysToUpdate) {
          todayWorkoutStats.putIfAbsent(
            k,
            () => {'distance': 0.0, 'duration': 0.0, 'caloriesBurned': 0.0},
          );
          todayWorkoutStats[k]!['distance'] =
              (todayWorkoutStats[k]!['distance'] ?? 0) + dist;
          todayWorkoutStats[k]!['duration'] =
              (todayWorkoutStats[k]!['duration'] ?? 0) + durationMin;
          todayWorkoutStats[k]!['caloriesBurned'] =
              (todayWorkoutStats[k]!['caloriesBurned'] ?? 0) + calories;
        }
      }
    }
  }
}
