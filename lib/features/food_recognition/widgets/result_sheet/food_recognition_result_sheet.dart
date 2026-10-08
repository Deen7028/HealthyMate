import 'dart:io';
import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/routine_state/routine_state_notifier.dart';
import 'package:healthymate/core/services/sync/sync_service.dart';
import 'package:healthymate/features/food_recognition/models/food_recognition_models.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/shared/widgets/fade_slide_entrance.dart';
import '../index.dart';

part 'food_recognition_result_sheet_actions.dart';
part 'food_recognition_result_sheet_save.dart';
part 'food_recognition_result_sheet_content.dart';
part 'food_recognition_result_sheet_body.dart';
part 'food_recognition_result_sheet_chrome.dart';
part 'food_recognition_result_sheet_items.dart';
// หน้าต่างแสดงผลการวิเคราะห์อาหารจากกล้อง
class FoodRecognitionResultSheet extends StatefulWidget {
  final MealNutritionScanResult scanResult;
  final VoidCallback? onSavedSuccessfully;

  const FoodRecognitionResultSheet({
    super.key,
    required this.scanResult,
    this.onSavedSuccessfully,
  });

  @override
  State<FoodRecognitionResultSheet> createState() =>
      _FoodRecognitionResultSheetState();
}

class _FoodRecognitionResultSheetState
    extends State<FoodRecognitionResultSheet> {
  late MealNutritionScanResult _result;
  bool _isSaving = false;
  double _userWeight = 65.0;

  @override
  void initState() {
    super.initState();
    _result = widget.scanResult;
    _loadUserWeight();
  }

  @override
  Widget build(BuildContext context) => _buildResultSheet(context);
}
