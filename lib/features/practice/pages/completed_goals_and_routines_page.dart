import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

part 'completed_goals_history.dart';
part 'completed_goals_tab.dart';
part 'completed_routines_tab.dart';
part 'completed_goals_empty_state.dart';
part 'completed_goals_page_content.dart';

class CompletedGoalsAndRoutinesPage extends StatefulWidget {
  final int initialTabIndex;

  const CompletedGoalsAndRoutinesPage({super.key, this.initialTabIndex = 0});

  @override
  State<CompletedGoalsAndRoutinesPage> createState() =>
      _CompletedGoalsAndRoutinesPageState();
}

class _CompletedGoalsAndRoutinesPageState
    extends State<CompletedGoalsAndRoutinesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _completedGoals = [];
  List<Map<String, dynamic>> _completedRoutines = [];

  final Color primaryGreen = AppTheme.primaryGreen;
  final Color darkGreen = AppTheme.primaryGreenDark;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadHistoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildHistoryPage(context);
}
