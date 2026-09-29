import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'routine_gps_sync_option.dart';

part 'routine_step_goal_content.dart';
part 'routine_step_goal_unit_button.dart';

class RoutineStepGoal extends StatelessWidget {
  final TextEditingController targetController;
  final TextEditingController unitController;
  final String? selectedLinkedWorkout;
  final String? autoDetected;
  final bool showGpsSyncOption;
  final ValueChanged<bool> onToggleAutoLink;
  final ValueChanged<String> onSelectUnit;

  const RoutineStepGoal({
    super.key,
    required this.targetController,
    required this.unitController,
    required this.selectedLinkedWorkout,
    required this.autoDetected,
    this.showGpsSyncOption = true,
    required this.onToggleAutoLink,
    required this.onSelectUnit,
  });

  @override
  Widget build(BuildContext context) => _buildStepGoal(context);
}
