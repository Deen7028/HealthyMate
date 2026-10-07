part of 'routine_notification_page.dart';

extension _RoutineNotificationContent on _MyRoutinesPageState {
  Widget _buildRoutinePage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldColor(isDark);
    final cardGreenBg = isDark
        ? const Color(0xFF1E2822)
        : const Color(0xFFE8F5E9);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return Scaffold(
            backgroundColor: scaffoldBg,
            appBar: this._buildAppBar(isDark),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryGreen),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดกิจวัตร...',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final pinnedRoutineId =
            (_controller.userGoal?['nRoutineId'] as num?)?.toInt() ?? 0;
        final pinnedTitle = _controller.userGoal?['sTitle']?.toString() ?? '';

        final displayRoutines = _controller.routines.where((r) {
          final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
          final rTitle = r['sTitle']?.toString() ?? '';
          if (pinnedRoutineId > 0 && rId == pinnedRoutineId) return false;
          if (pinnedRoutineId == 0 &&
              pinnedTitle.isNotEmpty &&
              rTitle == pinnedTitle) {
            return false;
          }
          return true;
        }).toList();

        final displayCompletedCount = displayRoutines.where((r) {
          final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
          return _controller.todayCompletionMap[rId] ?? false;
        }).length;

        final routineGroups = _groupRoutinesByTime(displayRoutines);
        final morningRoutines = routineGroups['morning']!;
        final afternoonRoutines = routineGroups['afternoon']!;
        final nightRoutines = routineGroups['night']!;
        final otherRoutines = routineGroups['other']!;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: this._buildAppBar(isDark),
          body: RefreshIndicator(
            color: primaryGreen,
            onRefresh: _controller.loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RoutineTopOverviewBanner(
                      completedCount: displayCompletedCount,
                      totalCount: displayRoutines.length,
                      todayWorkoutStats: _controller.todayWorkoutStats,
                      overallProgressRatio: _controller.overallProgressRatio,
                    ),
                    const SizedBox(height: 20),

                    RoutineMainGoalCard(
                      userGoal: _controller.userGoal,
                      completedCount: displayCompletedCount,
                      totalRoutinesCount: displayRoutines.length,
                      onSetMainGoal: this._openAddMainGoalBottomSheet,
                      onNavigateToWorkout: widget.onNavigateToWorkout,
                      onUnpin: () async {
                        await _controller.unpinMainGoal();
                        this._showSnackBar('ยกเลิกการปักหมุดเป้าหมายหลักแล้ว');
                      },
                      cardGreenBg: cardGreenBg,
                      primaryGreen: primaryGreen,
                      darkGreen: darkGreen,
                    ),

                    this._buildDailyRoutinesHeader(isDark),
                    const SizedBox(height: 16),
                    if (displayRoutines.isEmpty) this._buildEmptyState(),

                    if (morningRoutines.isNotEmpty) ...[
                      this._buildTimeBlockHeader(
                        '☀️ ช่วงเช้า (Morning)',
                        '06:00 - 11:00',
                        isDark,
                      ),
                      ...morningRoutines.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: this._buildRoutineCardFromDb(
                            r,
                            displayRoutines.indexOf(r),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (afternoonRoutines.isNotEmpty) ...[
                      this._buildTimeBlockHeader(
                        '🏃 ระหว่างวัน (Afternoon)',
                        '12:00 - 18:00',
                        isDark,
                      ),
                      ...afternoonRoutines.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: this._buildRoutineCardFromDb(
                            r,
                            displayRoutines.indexOf(r),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (nightRoutines.isNotEmpty) ...[
                      this._buildTimeBlockHeader(
                        '🌙 ก่อนนอน (Night)',
                        '21:00 - 23:00',
                        isDark,
                      ),
                      ...nightRoutines.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: this._buildRoutineCardFromDb(
                            r,
                            displayRoutines.indexOf(r),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (otherRoutines.isNotEmpty) ...[
                      this._buildTimeBlockHeader(
                        '⭐ กิจวัตรอื่นๆ',
                        'ตลอดทั้งวัน',
                        isDark,
                      ),
                      ...otherRoutines.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: this._buildRoutineCardFromDb(
                            r,
                            displayRoutines.indexOf(r),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: this._openAddRoutineDialog,
            backgroundColor: darkGreen,
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        );
      },
    );
  }
}
