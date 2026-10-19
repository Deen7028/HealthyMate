part of '../routine_controller.dart';

extension RoutineControllerWorkoutStats on RoutineController {
  void _aggregateWorkoutStats(List<Map<String, dynamic>> workouts) {
    todayWorkoutStats.clear();

    for (final w in workouts) {
      final sDate = w['dtWorkoutDate']?.toString() ?? '';
      if (!sDate.startsWith(todayStr)) continue;

      final sType = w['sType']?.toString() ?? 'อื่นๆ';
      final nDist = (w['nDistance'] as num?)?.toDouble() ?? 0.0;
      final nSec = (w['nDuration'] as num?)?.toDouble() ?? 0.0;
      final nMin = nSec > 0 ? (nSec / 60.0) : 0.0;
      final nCal = (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
      final nSteps = (w['nSteps'] as num?)?.toDouble() ?? 0.0;

      final sNormType = RoutineController.normalizeCategoryType(sType);
      for (final sKey in {sType, sNormType}) {
        todayWorkoutStats.putIfAbsent(
          sKey,
          () => {'distance': 0.0, 'duration': 0.0, 'caloriesBurned': 0.0, 'steps': 0.0},
        );
        todayWorkoutStats[sKey]!['distance'] =
            (todayWorkoutStats[sKey]!['distance'] ?? 0) + nDist;
        todayWorkoutStats[sKey]!['duration'] =
            (todayWorkoutStats[sKey]!['duration'] ?? 0) + nMin;
        todayWorkoutStats[sKey]!['caloriesBurned'] =
            (todayWorkoutStats[sKey]!['caloriesBurned'] ?? 0) + nCal;
        todayWorkoutStats[sKey]!['steps'] =
            (todayWorkoutStats[sKey]!['steps'] ?? 0) + nSteps;
      }
    }

    _mergeLiveStepTrackerStats(workouts);
  }

  void _mergeLiveStepTrackerStats(List<Map<String, dynamic>> workouts) {
    final int nLiveSteps = StepTrackerService.instance.nTodaySteps;
    final double nLiveDist = StepTrackerService.instance.nTodayDistanceKm;
    final double nLiveKcal = StepTrackerService.instance.nTodayCalories;
    if (nLiveSteps <= 0 && nLiveDist <= 0) return;

    todayWorkoutStats.putIfAbsent(
      'เดิน',
      () => {'distance': 0.0, 'duration': 0.0, 'caloriesBurned': 0.0, 'steps': 0.0},
    );

    final bool hasSummary = workouts.any((w) =>
        (w['dtWorkoutDate']?.toString() ?? '').startsWith(todayStr) &&
        w['sType']?.toString() == 'เดิน' &&
        ((w['nDuration'] as num?)?.toInt() ?? 0) == 0);

    if (!hasSummary) {
      double nDist = nLiveDist > 0
          ? nLiveDist
          : StepTrackerService.instance.calculateDistanceKm(
              nLiveSteps,
              user?.nHeight?.toDouble() ?? 170.0,
              user?.sGender ?? 'male',
            );
      todayWorkoutStats['เดิน']!['steps'] =
          (todayWorkoutStats['เดิน']!['steps'] ?? 0) + nLiveSteps;
      todayWorkoutStats['เดิน']!['distance'] =
          (todayWorkoutStats['เดิน']!['distance'] ?? 0) + nDist;
      todayWorkoutStats['เดิน']!['caloriesBurned'] =
          (todayWorkoutStats['เดิน']!['caloriesBurned'] ?? 0) + nLiveKcal;
    }
  }
}
