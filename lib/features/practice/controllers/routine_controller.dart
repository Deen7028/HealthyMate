import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/audio_service.dart';
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
      user = await db.getCurrentUser();

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

        const workoutKeywords = ['วิ่ง', 'เดิน', 'ปั่นจักรยาน', 'จักรยาน', 'ลู่วิ่ง', 'คาร์ดิโอ', 'ออกกำลังกาย', 'สมาธิ', 'ทำสมาธิ', 'โยคะ'];
        final bool hasWorkoutKeyword = workoutKeywords.any((kw) => title.contains(kw));
        final bool isNonWorkout = !hasWorkoutKeyword && (
            title.contains('น้ำ') ||
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
          } else if (title.contains('สมาธิ')) {
            matchedType = 'ทำสมาธิ';
          } else if (title.contains('โยคะ')) {
            matchedType = 'โยคะ';
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
            final isDone = workoutVal >= targetVal;
            if (isDone) {
              todayCompletionMap[routineId] = true;
            }

            // บันทึกลง SQLite และซิงค์ขึ้น Server ตาราง TbRoutineLogs
            await db.insertOrUpdateRoutineLog(
              routineId: routineId,
              dateStr: todayStr,
              progressValue: workoutVal,
              isCompleted: isDone,
            );
            HealthApiService.updateRoutineProgressRemote(
              routineId: routineId,
              date: todayStr,
              progressValue: workoutVal,
              isCompleted: isDone,
            );
          }
        }
      }

      completedCount = todayCompletionMap.values.where((v) => v).length;

      // Real-time Goal Sync: อัปเดตความคืบหน้าของเป้าหมายหลักให้ตรงกับ Routine หรือ Workout ล่าสุด
      if (userGoal != null) {
        final pinnedRoutineId = (userGoal!['nRoutineId'] as num?)?.toInt() ?? 0;
        if (pinnedRoutineId > 0) {
          final matchedRoutine = routines.firstWhere(
            (item) => ((item['nRoutineId'] as num?)?.toInt() ?? 0) == pinnedRoutineId,
            orElse: () => {},
          );
          if (matchedRoutine.isNotEmpty) {
            final targetVal = (matchedRoutine['targetValue'] as num?)?.toDouble() ??
                (matchedRoutine['nTargetValue'] as num?)?.toDouble() ?? 1.0;
            final currentVal = todayProgressValues[pinnedRoutineId] ?? 0.0;
            final isDone = todayCompletionMap[pinnedRoutineId] ?? false;
            final effectiveVal = isDone ? targetVal : currentVal;
            final progress = targetVal > 0 ? (effectiveVal / targetVal).clamp(0.0, 1.0) : 0.0;
            final percent = (progress * 100).toInt();
            final unitText = (matchedRoutine['unit'] ?? matchedRoutine['sUnit'])?.toString() ?? 'ครั้ง';
            final remainingText =
                'ความคืบหน้า: ${effectiveVal == effectiveVal.toInt() ? effectiveVal.toInt() : effectiveVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unitText ($percent%)';

            userGoal = {
              ...userGoal!,
              'nProgress': progress,
              'sRemainingText': remainingText,
            };

            await db.saveUserGoal(
              userId: userId,
              nRoutineId: pinnedRoutineId,
              title: matchedRoutine['sTitle']?.toString() ?? userGoal!['sTitle'],
              progress: progress,
              remainingText: remainingText,
            );
          }
        } else {
          // เป้าหมายแบบกำหนดเอง (Custom Goal เช่น ลดน้ำหนัก, วิ่งสะสม, ปั่นสะสม, เผาผลาญ)
          final title = userGoal!['sTitle']?.toString() ?? '';
          final lowerTitle = title.toLowerCase();
          final remaining = userGoal!['sRemainingText']?.toString() ?? '';
          double targetVal = 0.0;
          final targetMatch = RegExp(r'/\s*([\d.]+)\s*(\S+)?').firstMatch(remaining);
          if (targetMatch != null) {
            targetVal = double.tryParse(targetMatch.group(1) ?? '') ?? 0.0;
          }
          if (targetVal <= 0) {
            targetVal = (userGoal!['targetValue'] as num?)?.toDouble() ?? 1.0;
          }

          // กรองกิจกรรมไม่ให้นับข้อมูลที่เกิดขึ้นก่อนเวลาที่สร้างเป้าหมาย (Goal Creation Time Condition)
          DateTime? goalCreatedAt;
          final rawCreatedAt = userGoal!['dtCreatedAt']?.toString();
          if (rawCreatedAt != null && rawCreatedAt.isNotEmpty) {
            goalCreatedAt = DateTime.tryParse(rawCreatedAt);
          }

          final validWorkouts = workouts.where((w) {
            if (goalCreatedAt == null) return true;
            final wDateStr = w['dtWorkoutDate']?.toString() ?? '';
            final wDate = DateTime.tryParse(wDateStr);
            if (wDate == null) return true;
            return wDate.isAfter(goalCreatedAt) || wDate.isAtSameMomentAs(goalCreatedAt);
          }).toList();

          double currentVal = 0.0;
          String unitText = '';

          if (lowerTitle.contains('ลดน้ำหนัก') || lowerTitle.contains('น้ำหนัก')) {
            unitText = 'กก.';
            final records = await db.getHealthRecords(userId: userId);
            final userObj = await db.getCurrentUser();
            final validRecords = records.where((r) {
              if (goalCreatedAt == null) return true;
              return r.dtRecordedAt.isAfter(goalCreatedAt) || r.dtRecordedAt.isAtSameMomentAs(goalCreatedAt);
            }).toList();

            if (validRecords.length >= 2) {
              final startWeight = validRecords.last.nWeight;
              final curWeight = validRecords.first.nWeight;
              final diff = startWeight - curWeight;
              currentVal = diff > 0 ? diff : 0.0;
            } else if (validRecords.isNotEmpty && userObj != null) {
              final curWeight = validRecords.first.nWeight;
              final userWeight = userObj.nWeight ?? 0.0;
              final diff = (userWeight > curWeight && userWeight > 0) ? (userWeight - curWeight) : 0.0;
              currentVal = diff;
            }
          } else if (lowerTitle.contains('แคลอรี') || lowerTitle.contains('เผาผลาญ')) {
            unitText = 'แคล';
            double totalBurned = 0.0;
            for (final w in validWorkouts) {
              totalBurned += (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
            }
            currentVal = totalBurned;
          } else if (lowerTitle.contains('ปั่น') || lowerTitle.contains('จักรยาน')) {
            unitText = 'กม.';
            double totalCycling = 0.0;
            for (final w in validWorkouts) {
              final type = (w['sType']?.toString() ?? '').toLowerCase();
              if (type.contains('ปั่น') || type.contains('จักรยาน') || type.contains('cycling')) {
                totalCycling += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
              }
            }
            currentVal = totalCycling;
          } else if (lowerTitle.contains('วิ่ง')) {
            unitText = 'กม.';
            double totalRunning = 0.0;
            for (final w in validWorkouts) {
              final type = (w['sType']?.toString() ?? '').toLowerCase();
              if (type.contains('วิ่ง') || type.contains('running')) {
                totalRunning += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
              }
            }
            currentVal = totalRunning;
          }

          if (unitText.isNotEmpty && targetVal > 0) {
            final progress = (currentVal / targetVal).clamp(0.0, 1.0);
            final percent = (progress * 100).toInt();
            final detailText = 'ความคืบหน้า: ${currentVal == currentVal.toInt() ? currentVal.toInt() : currentVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unitText ($percent%)';

            userGoal = {
              ...userGoal!,
              'nProgress': progress,
              'sRemainingText': detailText,
            };

            await db.saveUserGoal(
              userId: userId,
              nRoutineId: 0,
              title: title,
              progress: progress,
              remainingText: detailText,
            );
          }
        }
      }

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

      _resyncAllActiveNotifications();
      _syncRoutinesFromServer(userId);
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _resyncAllActiveNotifications() async {
    for (final r in routines) {
      final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
      final isNotifyActive = (r['isNotificationActive'] as num?)?.toInt() == 1 ||
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
        await _syncLocalNotification(routineId, item);
      }
    }
  }

  Future<void> _syncRoutinesFromServer(int userId) async {
    try {
      final localRoutines = await AppDatabase.instance.getRoutines(userId: userId);
      final serverResult = await HealthApiService.fetchRoutines(userId: userId);

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
            final isNotif = ((r['isNotificationActive'] as num?)?.toInt() ?? 1) == 1;

            final newId = await HealthApiService.insertRoutineRemote(
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
          final refreshedResult = await HealthApiService.fetchRoutines(userId: userId);
          if (refreshedResult != null && refreshedResult['status'] == 'success') {
            final refreshedRoutines =
                (refreshedResult['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
            if (refreshedRoutines.isNotEmpty) {
              await AppDatabase.instance.upsertRoutinesFromServer(userId, refreshedRoutines);
            }
          }
        } else if (serverRoutines.isNotEmpty) {
          await AppDatabase.instance.upsertRoutinesFromServer(userId, serverRoutines);
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
            final serverVal = (r['todayProgressValue'] as num?)?.toDouble() ?? 0.0;
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
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[RoutineController] _syncRoutinesFromServer error: $e');
    }
  }

  Future<void> addRoutine(RoutineItem newRoutine) async {
    if (user == null) return;
    final userId = user!.nUserId;

    // 1. บันทึกลง SQLite
    final localId = await AppDatabase.instance.insertRoutine(
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

    // 2. บันทึกขึ้น Remote Server
    final serverId = await HealthApiService.insertRoutineRemote(
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

    // หาก Server สร้าง ID ใหม่ที่ต่างจาก Local ให้ลบ Local เก่าป้องกันซ้ำ
    final notificationRoutineId = serverId > 0 ? serverId : localId;
    if (serverId > 0 && serverId != localId && localId > 0) {
      await AppDatabase.instance.deleteRoutine(localId);
    }

    // 🟢 ระบบการแจ้งเตือน Local Notifications
    await _syncLocalNotification(notificationRoutineId, newRoutine);

    await loadData();
  }

  Future<void> _syncLocalNotification(int routineId, RoutineItem routine) async {
    if (routineId <= 0) return;

    for (int i = 0; i < 10; i++) {
      await NotificationService.instance.cancelNotification((routineId * 10) + i);
    }

    if (routine.isNotificationEnabled) {
      final hasPermission = await NotificationService.instance.requestPermission();
      if (hasPermission) {
        final timeStr = routine.notificationTime;
        final intIntervalMatch = RegExp(r'ทุก\s*(\d+)\s*ชั่วโมง').firstMatch(timeStr);

        if (intIntervalMatch != null) {
          final step = int.parse(intIntervalMatch.group(1)!);
          int slotIndex = 0;
          for (int h = 8; h <= 22 && slotIndex < 10; h += step) {
            await NotificationService.instance.scheduleDailyRoutine(
              id: (routineId * 10) + slotIndex,
              title: 'ถึงเวลาทำกิจวัตร! 🎯',
              body: 'ได้เวลา: ${routine.title} แล้วครับ',
              hour: h,
              minute: 0,
            );
            slotIndex++;
          }
        } else if (timeStr.contains('ทุกชั่วโมง')) {
          await NotificationService.instance.schedulePeriodicRoutine(
            id: routineId * 10,
            title: 'ถึงเวลาทำกิจวัตร! 🎯',
            body: 'ได้เวลา: ${routine.title} แล้วครับ',
            interval: RepeatInterval.hourly,
          );
        } else {
          // ดึงเวลาทั้งหมดในข้อความ ไม่ว่าจะคั่นด้วย comma, &, หรือ "และ"
          final matches = RegExp(r'(\d{1,2})[:\.](\d{2})').allMatches(timeStr).toList();
          if (matches.isNotEmpty) {
            for (int i = 0; i < matches.length && i < 10; i++) {
              final match = matches[i];
              final hour = int.parse(match.group(1)!);
              final minute = int.parse(match.group(2)!);
              await NotificationService.instance.scheduleDailyRoutine(
                id: (routineId * 10) + i,
                title: 'กิจวัตรของคุณ 🌟',
                body: 'อย่าลืมทำ ${routine.title} นะครับ',
                hour: hour,
                minute: minute,
              );
            }
          } else {
            // ค่าเริ่มต้นกรณีระบุเวลาลอยๆ
            await NotificationService.instance.scheduleDailyRoutine(
              id: routineId * 10,
              title: 'กิจวัตรของคุณ 🌟',
              body: 'อย่าลืมทำ ${routine.title} นะครับ',
              hour: 8,
              minute: 0,
            );
          }
        }
      }
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
        final success = await HealthApiService.updateRoutineProgressRemote(
          routineId: routineId,
          date: todayStr,
          progressValue: newStatus ? targetVal : 0.0,
          isCompleted: newStatus,
        );
        debugPrint('☁️ [ROUTINE_LOG] ➤ อัปเดตความสำเร็จกิจวัตร ID: $routineId ($todayStr, isCompleted: $newStatus) ขึ้น Server: $success');
      } catch (e) {
        debugPrint('❌ [ROUTINE_LOG] ➤ ซิงค์สถานะกิจวัตร ID: $routineId ขึ้น Server ผิดพลาด: $e');
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

    final title = (r['sTitle'] ?? r['title'] ?? '').toString().toLowerCase();
    final unit = (r['unit'] ?? r['sUnit'] ?? '').toString().toLowerCase();
    if (title.contains('น้ำ') || title.contains('water') || unit.contains('มล') || unit.contains('ml') || unit.contains('ลิตร')) {
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
        await HealthApiService.saveMainGoalRemote(
          userId: user!.nUserId,
          routineId: routineId,
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

    final createdAtStr = now.toIso8601String();
    userGoal = {
      'nRoutineId': 0,
      'sTitle': '$icon $title',
      'nProgress': 0.0,
      'sRemainingText': remainingText,
      'targetValue': targetValue,
      'unit': unit,
      'linkedWorkout': linkedWorkout,
      'dtDeadline': deadlineDate.toIso8601String(),
      'dtCreatedAt': createdAtStr,
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
        await HealthApiService.saveMainGoalRemote(
          userId: user!.nUserId,
          routineId: 0,
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
        await HealthApiService.clearMainGoalRemote(user!.nUserId);
        RoutineStateNotifier.instance.loadData(userId: user!.nUserId);
      } catch (_) {}
    }
  }

  Future<void> deleteRoutine(int routineId, String title) async {
    await AppDatabase.instance.deleteRoutine(routineId);
    for (int i = 0; i < 10; i++) {
      await NotificationService.instance.cancelNotification((routineId * 10) + i);
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

    await HealthApiService.deleteRoutineRemote(routineId);
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

    await HealthApiService.updateRoutineRemote(
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
