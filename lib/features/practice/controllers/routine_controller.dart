import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/notification_service.dart';
import 'package:healthymate/core/services/routine_state_notifier.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import '../models/routine_item.dart';

class RoutineController extends ChangeNotifier {
  bool isLoading = true;
  TbUser? user;
  List<Map<String, dynamic>> routines = [];
  Map<int, bool> todayCompletionMap = {};
  Map<int, double> todayProgressValues = {};
  int completedCount = 0;
  Map<String, dynamic>? userGoal;
  Map<String, Map<String, double>> todayWorkoutStats = {};
  double overallProgressRatio = 0.0;

  static String normalizeCategoryType(String rawType) {
    if (rawType.isEmpty) return 'อื่นๆ';
    final lower = rawType.toLowerCase();
    if (rawType.contains('วิ่ง') || lower.contains('running')) {
      if (rawType.contains('ลู่วิ่ง') || lower.contains('treadmill')) return 'ลู่วิ่งในร่ม';
      return 'วิ่ง';
    }
    if (rawType.contains('เดิน') || lower.contains('walking')) return 'เดิน';
    if (rawType.contains('จักรยาน') || rawType.contains('ปั่น') || lower.contains('cycling')) return 'ปั่นจักรยาน';
    if (rawType.contains('สมาธิ') || lower.contains('meditation')) return 'ทำสมาธิ';
    if (rawType.contains('โยคะ') || lower.contains('yoga')) return 'โยคะ';
    if (rawType.contains(' (')) {
      return rawType.split(' (').first.trim();
    }
    return rawType.trim();
  }

  String get todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    try {
      final db = AppDatabase.instance;
      final email = await db.getLoggedInUserEmail();
      if (email != null && email.isNotEmpty) {
        user = await db.getUserByEmail(email);
      }
      user ??= await db.getUser(userId: 1);

      if (user == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final userId = user!.nUserId;
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
        final targetVal = (r['targetValue'] as num?)?.toDouble() ??
            (r['nTargetValue'] as num?)?.toDouble() ??
            1.0;
        final log = logsMap[routineId];
        final isDone = (log?['isCompleted'] as num?)?.toInt() == 1;
        final logProgress = (log?['nProgressValue'] as num?)?.toDouble() ??
            (log?['progressValue'] as num?)?.toDouble();

        todayCompletionMap[routineId] = isDone;
        todayProgressValues[routineId] = logProgress ?? (isDone ? targetVal : 0.0);
      }

      userGoal = await db.getUserGoal(userId);

      final workouts = await db.getWorkouts(userId: userId);
      todayWorkoutStats.clear();

      for (final w in workouts) {
        final workoutDate = w['dtWorkoutDate']?.toString() ?? '';
        if (workoutDate.startsWith(todayStr)) {
          final type = w['sType']?.toString() ?? 'อื่นๆ';
          final dist = (w['nDistance'] as num?)?.toDouble() ?? 0.0;
          final durationSec = (w['nDuration'] as num?)?.toDouble() ?? 0.0;
          final durationMin = durationSec > 0 ? (durationSec / 60.0) : 0.0;
          final calories = (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;

          final normType = normalizeCategoryType(type);
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

      // Auto-GPS Sync: ประเมินความสำเร็จของกิจวัตรประเภทการออกกำลังกายจากสถิติ GPS วันนี้
      for (final r in routines) {
        final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        final targetVal = (r['targetValue'] as num?)?.toDouble() ??
            (r['nTargetValue'] as num?)?.toDouble() ??
            1.0;
        final title = (r['sTitle'] as String? ?? '').toLowerCase();
        final unit = (r['unit'] as String? ?? (r['sUnit'] as String? ?? '')).toLowerCase();

        const workoutKeywords = ['วิ่ง', 'เดิน', 'ปั่นจักรยาน', 'จักรยาน', 'ลู่วิ่ง', 'คาร์ดิโอ', 'ออกกำลังกาย'];
        final bool hasWorkoutKeyword = workoutKeywords.any((kw) => title.contains(kw));
        final bool isNonWorkout = !hasWorkoutKeyword && (
            title.contains('น้ำ') ||
            title.contains('สมาธิ') ||
            title.contains('นอน') ||
            title.contains('กิน') ||
            title.contains('อาหาร') ||
            title.contains('ยา') ||
            title.contains('อ่าน')
        );

        String matchedType = r['sLinkedWorkout']?.toString() ?? '';
        if (matchedType.isEmpty && !isNonWorkout) {
          if (title.contains('วิ่ง')) {
            matchedType = 'วิ่ง';
          } else if (title.contains('เดิน')) {
            matchedType = 'เดิน';
          } else if (title.contains('จักรยาน') || title.contains('ปั่น')) {
            matchedType = 'ปั่นจักรยาน';
          } else if (title.contains('ลู่วิ่ง')) {
            matchedType = 'ลู่วิ่งในร่ม';
          }
        }

        final bool isWorkout = !isNonWorkout &&
            (matchedType.isNotEmpty ||
                workoutKeywords.any((kw) => title.contains(kw)));

        if (isWorkout && matchedType.isNotEmpty && todayWorkoutStats.containsKey(matchedType)) {
          final stats = todayWorkoutStats[matchedType]!;
          double workoutVal = 0.0;
          if (unit.contains('กม') || unit.contains('กิโล') || unit.contains('km')) {
            workoutVal = stats['distance'] ?? 0.0;
          } else if (unit.contains('ชม') || unit.contains('ชั่วโมง') || unit.contains('hour') || unit.contains('hr')) {
            workoutVal = (stats['duration'] ?? 0.0) / 60.0;
          } else if (unit.contains('นาที') || unit.contains('min') || unit.contains('เวลา')) {
            workoutVal = stats['duration'] ?? 0.0;
          } else if (unit.contains('แคล') || unit.contains('cal')) {
            workoutVal = stats['caloriesBurned'] ?? 0.0;
          }
          if (workoutVal > 0) {
            todayProgressValues[routineId] = workoutVal;
            if (workoutVal >= targetVal) {
              todayCompletionMap[routineId] = true;
            }
          }
        }
      }

      completedCount = todayCompletionMap.values.where((v) => v).length;

      double totalRatioSum = 0.0;
      for (final r in routines) {
        final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        final targetVal = (r['targetValue'] as num?)?.toDouble() ??
            (r['nTargetValue'] as num?)?.toDouble() ??
            1.0;
        final currentVal = todayProgressValues[routineId] ?? 0.0;
        final isDone = todayCompletionMap[routineId] ?? false;
        final ratio = isDone
            ? 1.0
            : (targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0);
        totalRatioSum += ratio;
      }
      overallProgressRatio = routines.isNotEmpty ? (totalRatioSum / routines.length) : 0.0;
      isLoading = false;
      notifyListeners();

      _syncRoutinesFromServer(userId);
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncRoutinesFromServer(int userId) async {
    try {
      final serverResult = await HealthApiService.fetchRoutines(userId: userId);
      if (serverResult != null && serverResult['status'] == 'success') {
        final serverRoutines =
            (serverResult['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        if (serverRoutines.isNotEmpty) {
          await AppDatabase.instance.upsertRoutinesFromServer(userId, serverRoutines);
          routines = await AppDatabase.instance.getRoutines(userId: userId);

          for (final r in serverRoutines) {
            final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
            if (routineId == 0) continue;

            if (r.containsKey('todayCompleted') && r['todayCompleted'] != null) {
              final isDone = (r['todayCompleted'] as num?)?.toInt() == 1;
              if (isDone) {
                todayCompletionMap[routineId] = true;
              }
            }
            if (r.containsKey('todayProgressValue') &&
                r['todayProgressValue'] != null) {
              final serverVal = (r['todayProgressValue'] as num?)?.toDouble() ?? 0.0;
              final currentLocal = todayProgressValues[routineId] ?? 0.0;
              if (serverVal > currentLocal) {
                todayProgressValues[routineId] = serverVal;
              }
            }
          }
          completedCount = todayCompletionMap.values.where((v) => v).length;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> addRoutine(RoutineItem newRoutine) async {
    if (user == null) return;
    final userId = user!.nUserId;

    final routineId = await AppDatabase.instance.insertRoutine(
      userId: userId,
      title: newRoutine.title,
      time: newRoutine.notificationTime,
      targetValue: newRoutine.targetValue,
      unit: newRoutine.unit,
      linkedWorkout: newRoutine.linkedWorkoutType ?? '',
      color: newRoutine.color.toARGB32(),
      iconData: newRoutine.iconData.codePoint,
      isNotificationActive: newRoutine.isNotificationEnabled,
    );

    HealthApiService.insertRoutineRemote(
      userId: userId,
      title: newRoutine.title,
      time: newRoutine.notificationTime,
      targetValue: newRoutine.targetValue,
      unit: newRoutine.unit,
      linkedWorkout: newRoutine.linkedWorkoutType ?? '',
      color: newRoutine.color.toARGB32(),
      iconData: newRoutine.iconData.codePoint,
      isNotificationActive: newRoutine.isNotificationEnabled,
    );

    // 🟢 ระบบการแจ้งเตือน Local Notifications
    await _syncLocalNotification(routineId, newRoutine);

    await loadData();
  }

  Future<void> _syncLocalNotification(int routineId, RoutineItem routine) async {
    if (routineId <= 0) return;

    if (routine.isNotificationEnabled) {
      final hasPermission = await NotificationService.instance.requestPermission();
      if (hasPermission) {
        final timeStr = routine.notificationTime;
        if (timeStr.contains('ทุก') || timeStr.contains('ชั่วโมง')) {
          await NotificationService.instance.schedulePeriodicRoutine(
            id: routineId,
            title: 'ถึงเวลาทำกิจวัตร! 🎯',
            body: 'ได้เวลา: ${routine.title} แล้วครับ',
            interval: RepeatInterval.hourly,
          );
        } else {
          final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeStr);
          if (match != null) {
            final hour = int.parse(match.group(1)!);
            final minute = int.parse(match.group(2)!);
            await NotificationService.instance.scheduleDailyRoutine(
              id: routineId,
              title: 'กิจวัตรของคุณ 🌟',
              body: 'อย่าลืมทำ ${routine.title} นะครับ',
              hour: hour,
              minute: minute,
            );
          }
        }
      }
    } else {
      await NotificationService.instance.cancelNotification(routineId);
    }
  }

  Future<void> toggleRoutineCompletion(int routineId) async {
    final currentStatus = todayCompletionMap[routineId] ?? false;
    final newStatus = !currentStatus;
    todayCompletionMap[routineId] = newStatus;

    final r = routines.firstWhere(
      (element) => (element['nRoutineId'] as num?)?.toInt() == routineId,
      orElse: () => <String, dynamic>{},
    );
    final targetVal = (r['targetValue'] as num?)?.toDouble() ??
        (r['nTargetValue'] as num?)?.toDouble() ??
        1.0;
    todayProgressValues[routineId] = newStatus ? targetVal : 0.0;
    completedCount = todayCompletionMap.values.where((v) => v).length;
    notifyListeners();

    if (user != null) {
      await AppDatabase.instance.toggleRoutineLog(
        routineId: routineId,
        dateStr: todayStr,
      );

      HealthApiService.toggleRoutineLogRemote(
        routineId: routineId,
        date: todayStr,
      );

      RoutineStateNotifier.instance.loadData(userId: user!.nUserId);
    }
  }

  Future<void> incrementRoutineValue(int routineId, double step) async {
    final r = routines.firstWhere(
      (element) => (element['nRoutineId'] as num?)?.toInt() == routineId,
      orElse: () => <String, dynamic>{},
    );
    if (r.isEmpty) return;

    final targetVal = (r['targetValue'] as num?)?.toDouble() ??
        (r['nTargetValue'] as num?)?.toDouble() ??
        1.0;
    final currentVal = todayProgressValues[routineId] ?? 0.0;
    final newVal = (currentVal + step).clamp(0.0, targetVal * 2);

    todayProgressValues[routineId] = newVal;
    final isDone = newVal >= targetVal;
    todayCompletionMap[routineId] = isDone;
    completedCount = todayCompletionMap.values.where((v) => v).length;
    notifyListeners();

    if (user != null) {
      await AppDatabase.instance.insertOrUpdateRoutineLog(
        routineId: routineId,
        dateStr: todayStr,
        progressValue: newVal,
        isCompleted: isDone,
      );

      HealthApiService.updateRoutineProgressRemote(
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
    notifyListeners();

    if (user != null) {
      await AppDatabase.instance.insertOrUpdateRoutineLog(
        routineId: routineId,
        dateStr: todayStr,
        progressValue: 0,
        isCompleted: false,
      );

      HealthApiService.updateRoutineProgressRemote(
        routineId: routineId,
        date: todayStr,
        progressValue: 0,
        isCompleted: false,
      );
    }
  }

  Future<void> pinAsMainGoal(Map<String, dynamic> routine) async {
    final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final targetVal = (routine['targetValue'] as num?)?.toDouble() ?? 1.0;
    final unitText = routine['unit']?.toString() ?? 'ครั้ง';

    final lowerTitle = title.toLowerCase();
    String matchedType = routine['sLinkedWorkout']?.toString() ?? '';
    if (matchedType.isEmpty) {
      if (lowerTitle.contains('วิ่ง')) {
        matchedType = 'วิ่ง';
      } else if (lowerTitle.contains('เดิน')) {
        matchedType = 'เดิน';
      } else if (lowerTitle.contains('จักรยาน') || lowerTitle.contains('ปั่น')) {
        matchedType = 'ปั่นจักรยาน';
      } else if (lowerTitle.contains('ลู่วิ่ง')) {
        matchedType = 'ลู่วิ่งในร่ม';
      }
    }

    double currentVal = 0.0;
    if (matchedType.isNotEmpty && todayWorkoutStats.containsKey(matchedType)) {
      final stats = todayWorkoutStats[matchedType]!;
      if (unitText.contains('กม') || unitText.contains('กิโล') || unitText.contains('km')) {
        currentVal = stats['distance'] ?? 0.0;
      } else if (unitText.contains('ชม') || unitText.contains('ชั่วโมง') || unitText.contains('hour') || unitText.contains('hr')) {
        currentVal = (stats['duration'] ?? 0.0) / 60.0;
      } else if (unitText.contains('นาที') || unitText.contains('min') || unitText.contains('เวลา')) {
        currentVal = stats['duration'] ?? 0.0;
      }
    } else {
      final isDone = todayCompletionMap[routineId] ?? false;
      currentVal = isDone ? targetVal : 0.0;
    }

    final double progress = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
    final int percent = (progress * 100).toInt();
    final String remainingText =
        'ความคืบหน้า: ${currentVal == currentVal.toInt() ? currentVal.toInt() : currentVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unitText ($percent%)';

    userGoal = {
      'nRoutineId': routineId,
      'sTitle': title,
      'nProgress': progress,
      'sRemainingText': remainingText,
    };
    notifyListeners();

    if (user != null) {
      try {
        await AppDatabase.instance.saveUserGoal(
          userId: user!.nUserId,
          nRoutineId: routineId,
          title: title,
          progress: progress,
          remainingText: remainingText,
        );
        RoutineStateNotifier.instance.loadData(userId: user!.nUserId);
      } catch (_) {}
    }
  }

  Future<void> setCustomMainGoal({
    required String title,
    required String icon,
    required String unit,
    required double targetValue,
    required String linkedWorkout,
    required DateTime deadlineDate,
  }) async {
    final now = DateTime.now();
    final remainingDays = deadlineDate.difference(now).inDays.clamp(1, 9999);
    final deadlineStr = '${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year}';
    final remainingText = 'เป้าหมาย: 0 / ${targetValue == targetValue.toInt() ? targetValue.toInt() : targetValue.toStringAsFixed(1)} $unit (เหลือ $remainingDays วัน • สิ้นสุด $deadlineStr)';

    userGoal = {
      'nRoutineId': 0,
      'sTitle': '$icon $title',
      'nProgress': 0.0,
      'sRemainingText': remainingText,
      'targetValue': targetValue,
      'unit': unit,
      'linkedWorkout': linkedWorkout,
      'dtDeadline': deadlineDate.toIso8601String(),
    };
    notifyListeners();

    if (user != null) {
      try {
        await AppDatabase.instance.saveUserGoal(
          userId: user!.nUserId,
          nRoutineId: 0,
          title: '$icon $title',
          progress: 0.0,
          remainingText: remainingText,
        );
        RoutineStateNotifier.instance.loadData(userId: user!.nUserId);
      } catch (_) {}
    }
  }

  Future<void> unpinMainGoal() async {

    userGoal = null;
    notifyListeners();

    if (user != null) {
      try {
        await AppDatabase.instance.clearUserGoal(user!.nUserId);
        RoutineStateNotifier.instance.loadData(userId: user!.nUserId);
      } catch (_) {}
    }
  }

  Future<void> deleteRoutine(int routineId, String title) async {
    await AppDatabase.instance.deleteRoutine(routineId);
    await NotificationService.instance.cancelNotification(routineId);

    if (userGoal != null) {
      final pinnedId = (userGoal!['nRoutineId'] as num?)?.toInt() ?? 0;
      if (pinnedId == routineId || userGoal!['sTitle'] == title) {
        userGoal = null;
        if (user != null) {
          await AppDatabase.instance.clearUserGoal(user!.nUserId);
        }
      }
    }

    HealthApiService.deleteRoutineRemote(routineId);
    await loadData();
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

    HealthApiService.updateRoutineRemote(
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

    await _syncLocalNotification(routineId, updatedRoutine);

    await loadData();
  }
}
