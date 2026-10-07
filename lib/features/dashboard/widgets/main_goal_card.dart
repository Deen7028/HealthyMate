import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/routine_state/routine_state_notifier.dart';
import 'package:healthymate/features/practice/widgets/add_main_goal_bottom_sheet.dart';
import '../controllers/dashboard_controller.dart';
import '../utils/dashboard_ui_helpers.dart';
import 'main_goal_card_presentation.dart';

part 'main_goal_card_stat_ui.dart';
part 'main_goal_card_calculations.dart';

/// การ์ดแสดงผลเป้าหมายหลัก คำนวณความก้าวหน้า คำนวนแคลอรี/ระยะทางเป้าหมายประจำวัน
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
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      var year = int.parse(match.group(3)!);
      if (year > 2500) {
        year -= 543;
      }
      final parsed = DateTime.tryParse(
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
      );
      if (parsed != null) return parsed;
    }

    final rawCreatedAt = goal?['dtCreatedAt']?.toString();
    if (rawCreatedAt != null && rawCreatedAt.isNotEmpty) {
      final createdAt = DateTime.tryParse(rawCreatedAt);
      if (createdAt != null) {
        return createdAt.add(const Duration(days: 30));
      }
    } else if (goal != null) {
      return DateTime.now().add(const Duration(days: 30));
    }

    return null;
  }

  Future<void> _createGoal(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const AddMainGoalBottomSheet(),
    );
    if (result != null && controller.user != null) {
      final title = result['title']?.toString() ?? '';
      final icon = result['icon']?.toString() ?? '🚩';
      final unit = result['unit']?.toString() ?? '';
      final targetVal = (result['targetValue'] as num?)?.toDouble() ?? 1.0;
      final deadlineDate =
          result['deadlineDate'] as DateTime? ??
          DateTime.now().add(const Duration(days: 30));
      final now = DateTime.now();
      final remainingDays = deadlineDate.difference(now).inDays.clamp(1, 9999);
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
        dtCreatedAt: now.toIso8601String(),
      );
      RoutineStateNotifier.instance.loadData(userId: controller.user!.nUserId);
    }
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

    final goalState = _calculateGoalState(
      userGoal: userGoal,
      pinnedRoutine: pinnedRoutine,
      hasPinnedGoal: hasPinnedGoal,
      todayCompletionMap: todayCompletionMap,
      todayWorkoutStats: todayWorkoutStats,
    );
    final progress = goalState.progress;
    final displayTitle = goalState.displayTitle;
    final displayDetail = goalState.displayDetail
        .replaceAll(RegExp(r'\s*\(\s*เหลือ[^)]*\)'), '')
        .trim();
    final goalColor = goalState.goalColor;
    final goalIcon = goalState.goalIcon;
    final isCompleted = goalState.isCompleted;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);

    return MainGoalCardPresentation(
      hasPinnedGoal: hasPinnedGoal,
      goalColor: goalColor,
      goalIcon: goalIcon,
      displayTitle: displayTitle,
      displayDetail: displayDetail,
      isCompleted: isCompleted,
      progress: progress,
      remainingValText: remainingValText,
      deadlineSubText: deadlineSubText,
      isDark: isDark,
      cardBg: cardBg,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      borderColor: borderColor,
      onCreateGoal: () => _createGoal(context),
      buildGoalStatItem: _buildGoalStatItem,
    );
  }
}
