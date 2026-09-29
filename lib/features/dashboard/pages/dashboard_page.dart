import 'package:flutter/material.dart';
import 'package:healthymate/core/services/routine_state_notifier.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/shared/widgets/fade_slide_entrance.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/features/practice/widgets/add_main_goal_bottom_sheet.dart';
import 'package:healthymate/shared/bottom_sheets/food_source_bottom_sheet.dart';
import '../widgets/index.dart';
import '../controllers/dashboard_controller.dart';

part 'dashboard_page_actions.dart';
part 'dashboard_page_content.dart';

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
  final Color primaryGreen = AppTheme.primaryGreen;
  final Color darkGreen = AppTheme.primaryGreenDark;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController()..loadDashboardData();
    RoutineStateNotifier.instance.addListener(_onRoutineStateChanged);
  }

  void _onRoutineStateChanged() {
    if (mounted) {
      _controller.loadDashboardData(silent: true);
    }
  }

  @override
  void didUpdateWidget(covariant DashboardPageUpdated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.loadDashboardData(silent: true);
    }
  }

  @override
  void dispose() {
    RoutineStateNotifier.instance.removeListener(_onRoutineStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
