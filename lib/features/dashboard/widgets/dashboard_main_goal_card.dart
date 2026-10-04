// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (dashboard main goal card)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/features/dashboard/utils/dashboard_ui_helpers.dart';
import 'dashboard_main_goal_card_presentation.dart';
part 'dashboard_main_goal_card_helpers.dart';

/// การ์ดแสดงเป้าหมายหลักประจำวัน (Main Goal Card Component)
class DashboardMainGoalCard extends StatelessWidget {
  final Map<String, dynamic>? userGoal;
  final List<Map<String, dynamic>> routines;
  final Map<int, bool> todayCompletionMap;
  final Map<String, Map<String, double>> todayWorkoutStats;
  final DateTime now;
  final VoidCallback? onNavigateToPractice;
  final Color primaryGreen;
  final Color darkGreen;
  const DashboardMainGoalCard({
    super.key,
    required this.userGoal,
    required this.routines,
    required this.todayCompletionMap,
    required this.todayWorkoutStats,
    required this.now,
    this.onNavigateToPractice,
    this.primaryGreen = const Color(0xFF0F9C58),
    this.darkGreen = const Color(0xFF006432),
  });
  @override
  Widget build(BuildContext context) {
    final hasPinnedGoal = userGoal != null;
    final pinnedRoutineId = (userGoal?['nRoutineId'] as num?)?.toInt() ?? 0;
    Map<String, dynamic>? pinnedRoutine;
    if (hasPinnedGoal) {
      for (final r in routines) {
        final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        if ((pinnedRoutineId > 0 && rId == pinnedRoutineId) ||
            (r['sTitle'] == userGoal!['sTitle'])) {
          pinnedRoutine = r;
          break;
        }
      }
    }
    final double progress;
    final String displayTitle;
    String displayDetail;
    final Color goalColor;
    final IconData goalIcon;
    bool isCompleted = false;
    bool isWorkoutGoal = false;
    if (pinnedRoutine != null) {
      final title = pinnedRoutine['sTitle']?.toString() ?? 'เป้าหมายหลัก';
      final targetVal =
          (pinnedRoutine['targetValue'] as num?)?.toDouble() ?? 1.0;
      final unitText = pinnedRoutine['unit']?.toString() ?? 'ครั้ง';
      goalColor = _getRoutineColor(pinnedRoutine, 0);
      goalIcon = _getRoutineIcon(pinnedRoutine, 0);

      final lowerTitle = title.toLowerCase();
      String matchedType = pinnedRoutine['sLinkedWorkout']?.toString() ?? '';
      if (matchedType.isEmpty) {
        if (lowerTitle.contains('วิ่ง')) {
          matchedType = 'วิ่ง';
        } else if (lowerTitle.contains('เดิน')) {
          matchedType = 'เดิน';
        } else if (lowerTitle.contains('จักรยาน') ||
            lowerTitle.contains('ปั่น')) {
          matchedType = 'ปั่นจักรยาน';
        } else if (lowerTitle.contains('ลู่วิ่ง')) {
          matchedType = 'ลู่วิ่งในร่ม';
        }
      }

      double? workoutVal;
      if (matchedType.isNotEmpty) {
        isWorkoutGoal = true;
      }

      if (matchedType.isNotEmpty &&
          todayWorkoutStats.containsKey(matchedType)) {
        final stats = todayWorkoutStats[matchedType]!;
        if (unitText.contains('กม') ||
            unitText.contains('กิโล') ||
            unitText.contains('km')) {
          workoutVal = stats['distance'];
        } else if (unitText.contains('ชม') ||
            unitText.contains('ชั่วโมง') ||
            unitText.contains('hour') ||
            unitText.contains('hr')) {
          workoutVal = (stats['duration'] ?? 0.0) / 60.0;
        } else if (unitText.contains('นาที') ||
            unitText.contains('min') ||
            unitText.contains('เวลา')) {
          workoutVal = stats['duration'];
        } else if (unitText.contains('แคล') || unitText.contains('cal')) {
          workoutVal = stats['caloriesBurned'];
        }
      }

      final routineId = (pinnedRoutine['nRoutineId'] as num?)?.toInt() ?? 0;
      final isDone = todayCompletionMap[routineId] ?? false;
      final currentVal =
          workoutVal ??
          (isDone
              ? targetVal
              : ((pinnedRoutine['currentValue'] as num?)?.toDouble() ?? 0.0));

      progress = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
      final percent = (progress * 100).toInt();
      isCompleted = progress >= 1.0 || isDone;

      displayTitle = title;
      displayDetail =
          'ความคืบหน้าวันนี้: ${_formatNum(currentVal)} / ${_formatNum(targetVal)} $unitText ($percent%)';
    } else if (hasPinnedGoal) {
      displayTitle = userGoal!['sTitle']?.toString() ?? 'เป้าหมายหลัก';
      final remaining = userGoal!['sRemainingText']?.toString() ?? '';
      final lowerTitle = displayTitle.toLowerCase();

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

      if (lowerTitle.contains('ลดน้ำหนัก') || lowerTitle.contains('น้ำหนัก')) {
        goalColor = primaryGreen;
        goalIcon = Icons.monitor_weight_outlined;
        progress =
            (userGoal!['nProgress'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail = remaining.isNotEmpty
            ? remaining.replaceAll(RegExp(r'\s*\(\s*เหลือ[^)]*\)'), '').trim()
            : 'ทำสำเร็จแล้ว $percent%';
      } else {
        progress =
            (userGoal!['nProgress'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0;
        goalColor = primaryGreen;
        goalIcon = Icons.flag_rounded;
        isCompleted = progress >= 1.0;
        displayDetail = remaining.isNotEmpty
            ? remaining.replaceAll(RegExp(r'\s*\(\s*เหลือ[^)]*\)'), '').trim()
            : 'ทำสำเร็จแล้ว ${(progress * 100).toInt()}%';
      }
    } else {
      progress = 0.0;
      goalColor = primaryGreen;
      goalIcon = Icons.push_pin_outlined;
      displayTitle = 'ยังไม่ได้ปักหมุดเป้าหมายหลัก';
      displayDetail =
          'เลือกปักหมุดกิจวัตรสำคัญจากหน้ากิจวัตรเพื่อติดตามความคืบหน้า';
    }

    displayDetail = displayDetail
        .replaceAll(RegExp(r'\s*\(\s*เหลือ[^)]*\)'), '')
        .trim();

    final deadline = _getGoalDeadline(userGoal, pinnedRoutine);
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = deadline == null
        ? null
        : DateTime(deadline.year, deadline.month, deadline.day);
    final daysRemaining = deadlineDay?.difference(today).inDays;

    final String remainingValText;
    if (daysRemaining == null) {
      remainingValText = 'ไม่กำหนด';
    } else if (daysRemaining < 0) {
      remainingValText = 'เลยกำหนด ${daysRemaining.abs()} วัน';
    } else if (daysRemaining == 0) {
      remainingValText = 'เหลือวันนี้';
    } else {
      remainingValText = 'เหลืออีก $daysRemaining วัน';
    }

    final thaiYear = deadlineDay != null
        ? (deadlineDay.year > 2500 ? deadlineDay.year : deadlineDay.year + 543)
        : 0;
    final String deadlineSubText = deadlineDay != null
        ? 'สิ้นสุด ${deadlineDay.day.toString().padLeft(2, '0')}/${deadlineDay.month.toString().padLeft(2, '0')}/$thaiYear'
        : '';

    return DashboardMainGoalCardPresentation(
      hasPinnedGoal: hasPinnedGoal,
      goalColor: goalColor,
      goalIcon: goalIcon,
      displayTitle: displayTitle,
      displayDetail: displayDetail,
      isCompleted: isCompleted,
      isWorkoutGoal: isWorkoutGoal,
      progress: progress,
      remainingValText: remainingValText,
      deadlineSubText: deadlineSubText,
      primaryGreen: primaryGreen,
      onNavigateToPractice: onNavigateToPractice,
      buildGoalStatItem: _buildGoalStatItem,
    );
  }
}
