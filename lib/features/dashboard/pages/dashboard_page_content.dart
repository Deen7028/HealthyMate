part of 'dashboard_page.dart';

/// Extension สำหรับสร้าง UI layout และโครงสร้างหน้าจอ Dashboard
extension _DashboardPageContent on _DashboardPageUpdatedState {
  /// สร้าง UI ส่วนประกอบทั้งหมดของหน้า Dashboard
  Widget _buildPage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldColor(isDark);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return Scaffold(
            backgroundColor: scaffoldBg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryGreen),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูลสุขภาพ...',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: RefreshIndicator(
              color: primaryGreen,
              onRefresh: () => _controller.loadDashboardData(silent: true),
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
                          todayNutritionCalories:
                              _controller.todayNutritionCalories,
                          todayScannedFoodCount:
                              _controller.todayScannedFoodCount,
                          todayNutritionLogs: _controller.todayNutritionLogs,
                          onNavigateToCalculator: widget.onNavigateToCalculator,
                          onOpenFoodScanner: () async {
                            await FoodSourceBottomSheet.show(context);
                            if (mounted) {
                              _controller.loadDashboardData(silent: true);
                            }
                          },
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
                          lightBg: scaffoldBg,
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
