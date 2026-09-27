import 'package:flutter/material.dart';
import 'package:healthymate/core/services/routine_state_notifier.dart';
import 'package:healthymate/shared/widgets/fade_slide_entrance.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/features/practice/widgets/add_main_goal_bottom_sheet.dart';
import '../widgets/index.dart';
import '../controllers/dashboard_controller.dart';

class DashboardPageUpdated extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onNavigateToCalculator;
  final VoidCallback? onNavigateToPractice;
  final VoidCallback? onNavigateToProfile;
  final Function(String? workoutCategory)? onNavigateToWorkout;
  final VoidCallback? onStartWorkout;

  const DashboardPageUpdated({
    super.key,
    this.isActive = true,
    this.onNavigateToCalculator,
    this.onNavigateToPractice,
    this.onNavigateToProfile,
    this.onNavigateToWorkout,
    this.onStartWorkout,
  });

  @override
  State<DashboardPageUpdated> createState() => _DashboardPageUpdatedState();
}

class _DashboardPageUpdatedState extends State<DashboardPageUpdated> {
  late final DashboardController _controller;

  // สีหลักอ้างอิงจากดีไซน์
  final Color primaryGreen = const Color(0xFF0F9C58);
  final Color darkGreen = const Color(0xFF006432);
  final Color lightBg = const Color(0xFFF7F9FB);

  @override
  void initState() {
    super.initState();
    _controller = DashboardController()..loadDashboardData();
    RoutineStateNotifier.instance.addListener(_onRoutineStateChanged);
  }

  void _onRoutineStateChanged() {
    if (mounted) {
      _controller.loadDashboardData();
    }
  }

  @override
  void didUpdateWidget(covariant DashboardPageUpdated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.loadDashboardData();
    }
  }

  @override
  void dispose() {
    RoutineStateNotifier.instance.removeListener(_onRoutineStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleStartWorkout([String? category]) {
    final pinnedTitle = _controller.userGoal?['sTitle']?.toString() ?? '';
    final lower = pinnedTitle.toLowerCase();
    if (lower.contains('น้ำหนัก') || lower.contains('ลดน้ำหนัก')) {
      if (widget.onNavigateToCalculator != null) {
        widget.onNavigateToCalculator!();
        return;
      }
    }

    String? targetCategory = category;
    if (targetCategory == null && pinnedTitle.isNotEmpty) {
      if (lower.contains('จักรยาน') || lower.contains('ปั่น')) {
        targetCategory = 'cycling';
      } else if (lower.contains('แคลอรี') || lower.contains('เผาผลาญ')) {
        targetCategory = 'selectingCategory';
      } else if (lower.contains('สมาธิ') || lower.contains('ฝึกสติ')) {
        targetCategory = 'meditation';
      } else if (lower.contains('โยคะ')) {
        targetCategory = 'yoga';
      } else if (lower.contains('เดิน')) {
        targetCategory = 'walking';
      } else if (lower.contains('วิ่ง')) {
        targetCategory = 'running';
      } else {
        targetCategory = 'selectingCategory';
      }
    }

    if (widget.onNavigateToWorkout != null) {
      widget.onNavigateToWorkout!(targetCategory);
    } else if (widget.onStartWorkout != null) {
      widget.onStartWorkout!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('กำลังเข้าสู่โหมดมินิมาราธอน... 🏃‍♂️'),
          backgroundColor: darkGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openAddMainGoalBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const AddMainGoalBottomSheet(),
    );

    if (result != null && _controller.user != null) {
      final title = result['title']?.toString() ?? '';
      final icon = result['icon']?.toString() ?? '🚩';
      final unit = result['unit']?.toString() ?? '';
      final targetVal = (result['targetValue'] as num?)?.toDouble() ?? 1.0;
      final deadlineDate = result['deadlineDate'] as DateTime? ?? DateTime.now().add(const Duration(days: 30));
      final now = DateTime.now();
      final remainingDays = deadlineDate.difference(now).inDays.clamp(1, 9999);
      final deadlineStr = '${deadlineDate.day.toString().padLeft(2, '0')}/${deadlineDate.month.toString().padLeft(2, '0')}/${deadlineDate.year + 543}';
      final remainingText = 'เป้าหมาย: 0 / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unit (เหลือ $remainingDays วัน • สิ้นสุด $deadlineStr)';

      await AppDatabase.instance.saveUserGoal(
        userId: _controller.user!.nUserId,
        nRoutineId: 0,
        title: '$icon $title',
        progress: 0.0,
        remainingText: remainingText,
      );
      RoutineStateNotifier.instance.loadData(userId: _controller.user!.nUserId);

      final isWeightGoal = (result['isWeightGoal'] as bool?) == true ||
          title.contains('ลดน้ำหนัก') ||
          (result['linkedWorkout']?.toString() ?? '') == 'น้ำหนัก';

      if (isWeightGoal && widget.onNavigateToCalculator != null) {
        widget.onNavigateToCalculator!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return Scaffold(
            backgroundColor: lightBg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryGreen),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูลสุขภาพ...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: lightBg,
          body: SafeArea(
            child: RefreshIndicator(
              color: primaryGreen,
              onRefresh: _controller.loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Header
                      FadeSlideEntrance(
                        delayIndex: 0,
                        child: DashboardHeader(
                          userName: _controller.user?.sFirstName ?? 'ผู้ใช้งาน',
                          profilePath:
                              _controller.user?.sProfileImagePath ?? '',
                          thaiDayName: _controller.thaiDayName,
                          weekOfMonth: _controller.weekOfMonth,
                          greetingText: _controller.getGreeting(),
                          greetingEmoji: _controller.getGreetingEmoji(),
                          onProfileTap: widget.onNavigateToProfile,
                          primaryGreen: primaryGreen,
                          darkGreen: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. แถบปฏิทินกิจวัตรประจำสัปดาห์ (Calendar Strip)
                      FadeSlideEntrance(
                        delayIndex: 1,
                        child: CalendarStripWidget(
                          now: _controller.now,
                          thaiMonthName: _controller.thaiMonthName,
                          workoutCount: _controller.workoutCount,
                          totalDistanceKm: _controller.totalDistanceKm,
                          totalCaloriesBurned: _controller.totalCaloriesBurned,
                          darkGreen: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. ข้อมูลสุขภาพส่วนบุคคล (Health Summary Card)
                      FadeSlideEntrance(
                        delayIndex: 2,
                        child: DashboardHealthSummaryCard(
                          user: _controller.user,
                          latestRecord: _controller.latestRecord,
                          now: _controller.now,
                          totalCaloriesBurned: _controller.totalCaloriesBurned,
                          todayNutritionCalories: _controller.todayNutritionCalories,
                          onNavigateToCalculator: widget.onNavigateToCalculator,
                          primaryGreen: primaryGreen,
                          darkGreen: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. เป้าหมายหลักของฉัน (Main Goal Card)
                      FadeSlideEntrance(
                        delayIndex: 3,
                        child: MainGoalCard(
                          controller: _controller,
                          onNavigateToPractice: widget.onNavigateToPractice,
                          onNavigateToCalculator: widget.onNavigateToCalculator,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 5. ปุ่มลัดเริ่มออกกำลังกาย
                      FadeSlideEntrance(
                        delayIndex: 4,
                        child: DashboardActionButtons(
                          userGoal: _controller.userGoal,
                          onStartWorkout: _handleStartWorkout,
                          onNavigateToWorkout: widget.onNavigateToWorkout,
                          onNavigateToCalculator: widget.onNavigateToCalculator,
                          onOpenAddMainGoal: _openAddMainGoalBottomSheet,
                          darkGreen: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 6. เป้าหมายอื่นๆ (Other Goals & Routines)
                      FadeSlideEntrance(
                        delayIndex: 5,
                        child: DashboardOtherGoalsCard(
                          userGoal: _controller.userGoal,
                          routines: _controller.routines,
                          todayCompletionMap: _controller.todayCompletionMap,
                          todayProgressValues: _controller.todayProgressValues,
                          todayWorkoutStats: _controller.todayWorkoutStats,
                          now: _controller.now,
                          darkGreen: darkGreen,
                          lightBg: lightBg,
                          onNavigateToPractice: widget.onNavigateToPractice,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
