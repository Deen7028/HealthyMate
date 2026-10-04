// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine notification page)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthymate/core/services/routine_state_notifier.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/dashboard/utils/dashboard_ui_helpers.dart';
import '../models/routine_item.dart';
import '../widgets/index.dart';
import '../controllers/routine_controller.dart';
import 'completed_goals_and_routines_page.dart';

part 'routine_notification_page_actions.dart';
part 'routine_notification_page_dialogs.dart';
part 'routine_notification_page_sections.dart';
part 'routine_notification_page_card.dart';
part 'routine_notification_page_card_actions.dart';
part 'routine_notification_page_content.dart';
part 'routine_notification_page_grouping.dart';

class MyRoutinesPage extends StatefulWidget {
  final bool isActive;
  final Function(String? workoutCategory, [int? targetDurationMinutes])?
  onNavigateToWorkout;

  const MyRoutinesPage({
    super.key,
    this.isActive = true,
    this.onNavigateToWorkout,
  });

  @override
  State<MyRoutinesPage> createState() => _MyRoutinesPageState();
}

class _MyRoutinesPageState extends State<MyRoutinesPage> {
  late final RoutineController _controller;

  final Color primaryGreen = AppTheme.primaryGreen;
  final Color darkGreen = AppTheme.primaryGreenDark;

  @override
  void initState() {
    super.initState();
    _controller = RoutineController()..loadData();
    RoutineStateNotifier.instance.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) {
      _controller.loadData();
    }
  }

  @override
  void didUpdateWidget(covariant MyRoutinesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.loadData();
    }
  }

  @override
  void dispose() {
    RoutineStateNotifier.instance.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  static const _routineIcons = [
    Icons.check_circle_outline,
    Icons.fitness_center,
    Icons.self_improvement,
    Icons.water_drop,
    Icons.directions_walk,
    Icons.bedtime,
    Icons.restaurant,
    Icons.favorite,
  ];

  IconData _getRoutineIcon(int index) =>
      _routineIcons[index % _routineIcons.length];

  @override
  Widget build(BuildContext context) => _buildRoutinePage(context);
}
