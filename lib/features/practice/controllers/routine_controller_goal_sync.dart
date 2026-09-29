part of 'routine_controller.dart';

extension RoutineControllerGoalSync on RoutineController {
  Future<void> _syncGoalProgress(
    AppDatabase db,
    int userId,
    List<Map<String, dynamic>> workouts,
  ) async {
    // Real-time Goal Sync: อัปเดตความคืบหน้าของเป้าหมายหลักให้ตรงกับ Routine หรือ Workout ล่าสุด
    if (userGoal != null) {
      final pinnedRoutineId = (userGoal!['nRoutineId'] as num?)?.toInt() ?? 0;
      if (pinnedRoutineId > 0) {
        final matchedRoutine = routines.firstWhere(
          (item) =>
              ((item['nRoutineId'] as num?)?.toInt() ?? 0) == pinnedRoutineId,
          orElse: () => {},
        );
        if (matchedRoutine.isNotEmpty) {
          final targetVal =
              (matchedRoutine['targetValue'] as num?)?.toDouble() ??
              (matchedRoutine['nTargetValue'] as num?)?.toDouble() ??
              1.0;
          final currentVal = todayProgressValues[pinnedRoutineId] ?? 0.0;
          final isDone = todayCompletionMap[pinnedRoutineId] ?? false;
          final effectiveVal = isDone ? targetVal : currentVal;
          final progress = targetVal > 0
              ? (effectiveVal / targetVal).clamp(0.0, 1.0)
              : 0.0;
          final percent = (progress * 100).toInt();
          final unitText =
              (matchedRoutine['unit'] ?? matchedRoutine['sUnit'])?.toString() ??
              'ครั้ง';
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
        final targetMatch = RegExp(
          r'/\s*([\d.]+)\s*(\S+)?',
        ).firstMatch(remaining);
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
          if (wDate == null) return false;
          return wDate.isAfter(goalCreatedAt) ||
              wDate.isAtSameMomentAs(goalCreatedAt);
        }).toList();

        double currentVal = 0.0;
        String unitText = '';

        if (lowerTitle.contains('ลดน้ำหนัก') ||
            lowerTitle.contains('น้ำหนัก')) {
          unitText = 'กก.';
          final records = await db.getHealthRecords(userId: userId);
          final userObj = await db.getCurrentUser();
          final validRecords = records.where((r) {
            if (goalCreatedAt == null) return true;
            return r.dtRecordedAt.isAfter(goalCreatedAt) ||
                r.dtRecordedAt.isAtSameMomentAs(goalCreatedAt);
          }).toList();

          double startWeight = 0.0;
          final recordsBeforeOrAt = records.where((r) {
            if (goalCreatedAt == null) return true;
            return r.dtRecordedAt.isBefore(goalCreatedAt) ||
                r.dtRecordedAt.isAtSameMomentAs(goalCreatedAt);
          }).toList();

          if (recordsBeforeOrAt.isNotEmpty) {
            startWeight = recordsBeforeOrAt.first.nWeight;
          } else if (records.isNotEmpty) {
            startWeight = records.last.nWeight;
          } else if (userObj != null) {
            startWeight = userObj.nWeight ?? 0.0;
          }

          if (validRecords.isNotEmpty && startWeight > 0) {
            final curWeight = validRecords.first.nWeight;
            final diff = startWeight - curWeight;
            currentVal = diff > 0 ? diff : 0.0;
          } else {
            currentVal = 0.0;
          }
        } else if (lowerTitle.contains('แคลอรี') ||
            lowerTitle.contains('เผาผลาญ')) {
          unitText = 'แคล';
          double totalBurned = 0.0;
          for (final w in validWorkouts) {
            totalBurned += (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
          }
          currentVal = totalBurned;
        } else if (lowerTitle.contains('ปั่น') ||
            lowerTitle.contains('จักรยาน') ||
            lowerTitle.contains('cycling')) {
          unitText = (userGoal!['unit'] ?? 'กม.').toString();
          double totalCycling = 0.0;
          for (final w in validWorkouts) {
            final type = (w['sType']?.toString() ?? '').toLowerCase();
            if (type.contains('ปั่น') ||
                type.contains('จักรยาน') ||
                type.contains('cycling')) {
              if (unitText.contains('นาที') || unitText.contains('min')) {
                totalCycling +=
                    ((w['nDuration'] as num?)?.toDouble() ?? 0.0) / 60.0;
              } else {
                totalCycling += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
              }
            }
          }
          currentVal = totalCycling;
        } else if (lowerTitle.contains('วิ่ง') ||
            lowerTitle.contains('running')) {
          unitText = (userGoal!['unit'] ?? 'กม.').toString();
          double totalRunning = 0.0;
          for (final w in validWorkouts) {
            final type = (w['sType']?.toString() ?? '').toLowerCase();
            if (type.contains('วิ่ง') || type.contains('running')) {
              if (unitText.contains('นาที') || unitText.contains('min')) {
                totalRunning +=
                    ((w['nDuration'] as num?)?.toDouble() ?? 0.0) / 60.0;
              } else {
                totalRunning += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
              }
            }
          }
          currentVal = totalRunning;
        } else if (lowerTitle.contains('เดิน') ||
            lowerTitle.contains('walking')) {
          unitText = (userGoal!['unit'] ?? 'กม.').toString();
          double totalWalking = 0.0;
          for (final w in validWorkouts) {
            final type = (w['sType']?.toString() ?? '').toLowerCase();
            if (type.contains('เดิน') || type.contains('walking')) {
              if (unitText.contains('นาที') || unitText.contains('min')) {
                totalWalking +=
                    ((w['nDuration'] as num?)?.toDouble() ?? 0.0) / 60.0;
              } else {
                totalWalking += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
              }
            }
          }
          currentVal = totalWalking;
        } else if (lowerTitle.contains('สมาธิ') ||
            lowerTitle.contains('meditation')) {
          unitText = (userGoal!['unit'] ?? 'นาที').toString();
          double totalMeditation = 0.0;
          for (final w in validWorkouts) {
            final type = (w['sType']?.toString() ?? '').toLowerCase();
            if (type.contains('สมาธิ') || type.contains('meditation')) {
              totalMeditation +=
                  ((w['nDuration'] as num?)?.toDouble() ?? 0.0) / 60.0;
            }
          }
          currentVal = totalMeditation;
        } else if (lowerTitle.contains('โยคะ') ||
            lowerTitle.contains('yoga')) {
          unitText = (userGoal!['unit'] ?? 'นาที').toString();
          double totalYoga = 0.0;
          for (final w in validWorkouts) {
            final type = (w['sType']?.toString() ?? '').toLowerCase();
            if (type.contains('โยคะ') || type.contains('yoga')) {
              totalYoga +=
                  ((w['nDuration'] as num?)?.toDouble() ?? 0.0) / 60.0;
            }
          }
          currentVal = totalYoga;
        }

        if (unitText.isNotEmpty && targetVal > 0) {
          final progress = (currentVal / targetVal).clamp(0.0, 1.0);
          final percent = (progress * 100).toInt();

          String deadlinePart = '';
          final matchDeadline =
              RegExp(r'\((เหลือ\s*[^)]*)\)').firstMatch(remaining);
          if (matchDeadline != null) {
            deadlinePart = ' ${matchDeadline.group(0)}';
          } else if (goalCreatedAt != null) {
            final deadlineDate = goalCreatedAt.add(const Duration(days: 30));
            final remainingDays =
                deadlineDate.difference(DateTime.now()).inDays.clamp(0, 9999);
            final thaiYear = deadlineDate.year > 2500
                ? deadlineDate.year
                : deadlineDate.year + 543;
            final deadlineStr =
                '${deadlineDate.day.toString().padLeft(2, '0')}/${deadlineDate.month.toString().padLeft(2, '0')}/$thaiYear';
            deadlinePart = ' (เหลือ $remainingDays วัน • สิ้นสุด $deadlineStr)';
          }

          final detailText =
              'ความคืบหน้า: ${currentVal == currentVal.toInt() ? currentVal.toInt() : currentVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unitText ($percent%)$deadlinePart';

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
  }
}
