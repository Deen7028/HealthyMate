import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/controllers/health_calculator_controller.dart';
import 'bmi_indicator_bar.dart';
import 'calorie_target_card.dart';
import 'result_card.dart';

part 'health_calculator_result_content.dart';

class HealthCalculatorResultSection extends StatelessWidget {
  final HealthCalculatorController state;

  const HealthCalculatorResultSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) => _buildResults(context);
}
