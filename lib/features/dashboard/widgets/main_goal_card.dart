import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/routine_state_notifier.dart';
import 'package:healthymate/features/practice/widgets/add_main_goal_bottom_sheet.dart';
import '../controllers/dashboard_controller.dart';
import '../utils/dashboard_ui_helpers.dart';

class MainGoalCard extends StatelessWidget {
  final DashboardController controller;
  final VoidCallback? onNavigateToPractice;
  final VoidCallback? onNavigateToCalculator;

  const MainGoalCard({
    super.key,
    required this.controller,
    this.onNavigateToPractice,
    this.onNavigateToCalculator,
  });

  DateTime? _getGoalDeadline(
    Map<String, dynamic>? goal,
    Map<String, dynamic>? routine,
  ) {
    for (final source in [goal, routine]) {
      if (source == null) continue;
      for (final key in ['dtDeadline', 'deadlineDate']) {
        final value = source[key];
        if (value is DateTime) return value;
        if (value != null) {
          final parsed = DateTime.tryParse(value.toString());
          if (parsed != null) return parsed;
        }
      }
    }

    final remainingText = goal?['sRemainingText']?.toString() ?? '';
    final match = RegExp(
      r'(\d{1,2})/(\d{1,2})/(\d{4})',
    ).firstMatch(remainingText);
    if (match == null) return null;

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    var year = int.parse(match.group(3)!);
    if (year > 2500) {
      year -= 543;
    }

    return DateTime.tryParse(
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final userGoal = controller.userGoal;
    final routines = controller.routines;
    final todayCompletionMap = controller.todayCompletionMap;
    final todayWorkoutStats = controller.todayWorkoutStats;
    final now = controller.now;

    final hasPinnedGoal = userGoal != null;
    final pinnedRoutineId = (userGoal?['nRoutineId'] as num?)?.toInt() ?? 0;

    Map<String, dynamic>? pinnedRoutine;
    if (hasPinnedGoal) {
      for (final r in routines) {
        final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        if ((pinnedRoutineId > 0 && rId == pinnedRoutineId) ||
            (r['sTitle'] == userGoal['sTitle'])) {
          pinnedRoutine = r;
          break;
        }
      }
    }

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
      remainingValText = 'อีก $daysRemaining วัน';
    }

    final thaiYear = deadlineDay != null
        ? (deadlineDay.year > 2500 ? deadlineDay.year : deadlineDay.year + 543)
        : 0;
    final String deadlineSubText = deadlineDay != null
        ? 'สิ้นสุด ${deadlineDay.day.toString().padLeft(2, '0')}/${deadlineDay.month.toString().padLeft(2, '0')}/$thaiYear'
        : '';

    final double progress;
    final String displayTitle;
    String displayDetail;
    final Color goalColor;
    final IconData goalIcon;
    bool isCompleted = false;

    if (pinnedRoutine != null) {
      final title = pinnedRoutine['sTitle']?.toString() ?? 'เป้าหมายหลัก';
      final targetVal =
          (pinnedRoutine['targetValue'] as num?)?.toDouble() ?? 1.0;
      final unitText = pinnedRoutine['unit']?.toString() ?? 'ครั้ง';
      goalColor = DashboardUiHelpers.getRoutineColor(pinnedRoutine, 0);
      goalIcon = DashboardUiHelpers.getRoutineIcon(pinnedRoutine, 0);

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
          'ความคืบหน้าวันนี้: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
    } else if (hasPinnedGoal) {
      displayTitle = userGoal['sTitle']?.toString() ?? 'เป้าหมายหลัก';
      final remaining = userGoal['sRemainingText']?.toString() ?? '';
      final lowerTitle = displayTitle.toLowerCase();

      // ดึง targetVal จาก remainingText (เช่น 'เป้าหมาย: 0 / 3.0 กก.')
      double targetVal = 0.0;
      final targetMatch = RegExp(r'/\s*([\d.]+)\s*(\S+)?').firstMatch(remaining);
      if (targetMatch != null) {
        targetVal = double.tryParse(targetMatch.group(1) ?? '') ?? 0.0;
      }
      if (targetVal <= 0) {
        targetVal = (userGoal['targetValue'] as num?)?.toDouble() ?? 1.0;
      }

      double currentVal = 0.0;
      String unitText = '';

      if (lowerTitle.contains('ลดน้ำหนัก') || lowerTitle.contains('น้ำหนัก')) {
        goalColor = const Color(0xFF0F9C58);
        goalIcon = Icons.monitor_weight_outlined;
        unitText = 'กก.';

        // คำนวณน้ำหนักที่ลดได้จากประวัติสุขภาพ TbHealthRecords
        if (controller.healthRecords.length >= 2) {
          final startWeight = controller.healthRecords.last.nWeight;
          final currentWeight = controller.healthRecords.first.nWeight;
          final diff = startWeight - currentWeight;
          currentVal = diff > 0 ? diff : 0.0;
        } else if (controller.healthRecords.isNotEmpty && controller.user != null) {
          final currentWeight = controller.healthRecords.first.nWeight;
          final userWeight = controller.user?.nWeight ?? 0.0;
          final diff = (userWeight > currentWeight && userWeight > 0)
              ? (userWeight - currentWeight)
              : 0.0;
          currentVal = diff;
        } else {
          currentVal = 0.0;
        }

        progress = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail = 'ลดน้ำหนักได้: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else if (lowerTitle.contains('แคลอรี') || lowerTitle.contains('เผาผลาญ')) {
        goalColor = const Color(0xFFFF9800);
        goalIcon = Icons.local_fire_department_rounded;
        unitText = 'แคล';
        currentVal = controller.totalCaloriesBurned;
        progress = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail = 'เผาผลาญสะสม: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else if (lowerTitle.contains('ปั่น') || lowerTitle.contains('จักรยาน')) {
        goalColor = const Color(0xFF0288D1);
        goalIcon = Icons.directions_bike;
        unitText = 'กม.';
        currentVal = controller.totalCyclingDistanceKm > 0 ? controller.totalCyclingDistanceKm : controller.totalDistanceKm;
        progress = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail = 'ปั่นสะสม: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else if (lowerTitle.contains('วิ่ง')) {
        goalColor = const Color(0xFF4CAF50);
        goalIcon = Icons.directions_run;
        unitText = 'กม.';
        currentVal = controller.totalRunningDistanceKm > 0 ? controller.totalRunningDistanceKm : controller.totalDistanceKm;
        progress = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
        final percent = (progress * 100).toInt();
        isCompleted = progress >= 1.0;
        displayDetail = 'วิ่งสะสม: ${controller.formatNum(currentVal)} / ${controller.formatNum(targetVal)} $unitText ($percent%)';
      } else {
        progress =
            (userGoal['nProgress'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0;
        goalColor = const Color(0xFF0F9C58);
        goalIcon = Icons.flag_rounded;
        isCompleted = progress >= 1.0;
        displayDetail = remaining.isNotEmpty
            ? remaining.replaceAll(RegExp(r'\s*\(\s*เหลือ[^)]*\)'), '').trim()
            : 'ทำสำเร็จแล้ว ${(progress * 100).toInt()}%';
      }
    } else {
      progress = 0.0;
      goalColor = const Color(0xFF0F9C58);
      goalIcon = Icons.push_pin_outlined;
      displayTitle = 'ยังไม่ได้ปักหมุดเป้าหมายหลัก';
      displayDetail =
          'เลือกปักหมุดกิจวัตรสำคัญจากหน้ากิจวัตรเพื่อติดตามความคืบหน้า';
    }

    displayDetail = displayDetail
        .replaceAll(RegExp(r'\s*\(\s*เหลือ[^)]*\)'), '')
        .trim();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasPinnedGoal
              ? goalColor.withValues(alpha: 0.35)
              : borderColor,
          width: hasPinnedGoal ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: goalColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(goalIcon, color: goalColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasPinnedGoal) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.push_pin,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayDetail,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted
                            ? (isDark ? const Color(0xFF90DB89) : Colors.green.shade700)
                            : textSecondary,
                        fontWeight: isCompleted
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!hasPinnedGoal) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result =
                      await showModalBottomSheet<Map<String, dynamic>>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        builder: (context) => const AddMainGoalBottomSheet(),
                      );
                  if (result != null && controller.user != null) {
                    final title = result['title']?.toString() ?? '';
                    final icon = result['icon']?.toString() ?? '🚩';
                    final unit = result['unit']?.toString() ?? '';
                    final targetVal =
                        (result['targetValue'] as num?)?.toDouble() ?? 1.0;
                    final deadlineDate =
                        result['deadlineDate'] as DateTime? ??
                        DateTime.now().add(const Duration(days: 30));
                    final now = DateTime.now();
                    final remainingDays = deadlineDate
                        .difference(now)
                        .inDays
                        .clamp(1, 9999);
                    final deadlineStr =
                        '${deadlineDate.day.toString().padLeft(2, '0')}/${deadlineDate.month.toString().padLeft(2, '0')}/${deadlineDate.year + 543}';
                    final remainingText =
                        'เป้าหมาย: 0 / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unit (เหลือ $remainingDays วัน • สิ้นสุด $deadlineStr)';

                    await AppDatabase.instance.saveUserGoal(
                      userId: controller.user!.nUserId,
                      nRoutineId: 0,
                      title: '$icon $title',
                      progress: 0.0,
                      remainingText: remainingText,
                    );
                    RoutineStateNotifier.instance.loadData(
                      userId: controller.user!.nUserId,
                    );
                  }
                },
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text(
                  '+ ตั้งเป้าหมายหลัก (Set Main Goal)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006432),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),

            CircularPercentIndicator(
              radius: 54.0,
              lineWidth: 9.0,
              percent: progress,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: goalColor,
                    ),
                  ),
                  Text(
                    isCompleted ? 'สำเร็จ!' : 'ความคืบหน้า',
                    style: TextStyle(
                      fontSize: 9,
                      color: isCompleted ? Colors.green.shade800 : Colors.grey,
                      fontWeight: isCompleted
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              progressColor: goalColor,
              backgroundColor: goalColor.withValues(alpha: 0.12),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
            ),
          ],

          if (isCompleted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'ทำเป้าหมายสำเร็จแล้ววันนี้! 🎉',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (hasPinnedGoal) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGoalStatItem(
                  'สถานะ',
                  isCompleted ? 'ทำสำเร็จแล้ว' : 'กำลังดำเนินการ',
                  textPrimary,
                  textSecondary,
                  icon: isCompleted
                      ? Icons.check_circle_outline
                      : Icons.timelapse,
                ),
                Container(height: 28, width: 1, color: borderColor),
                _buildGoalStatItem(
                  'เหลือเวลา',
                  remainingValText,
                  textPrimary,
                  textSecondary,
                  subValue: deadlineSubText,
                  icon: Icons.calendar_today,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalStatItem(
    String title,
    String value,
    Color primaryColor,
    Color secondaryColor, {
    IconData? icon,
    String? subValue,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: secondaryColor),
              const SizedBox(width: 4),
            ],
            Text(
              title,
              style: TextStyle(fontSize: 10, color: secondaryColor),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        if (subValue != null && subValue.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: secondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
