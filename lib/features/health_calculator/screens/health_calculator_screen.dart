import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/state/health_calculator_state.dart';
import 'package:healthymate/features/health_calculator/widgets/activity_level_picker.dart';
import 'package:healthymate/features/health_calculator/widgets/bmi_indicator_bar.dart';
import 'package:healthymate/features/health_calculator/widgets/calorie_target_card.dart';
import 'package:healthymate/features/health_calculator/widgets/gender_selector.dart';
import 'package:healthymate/features/health_calculator/widgets/history_bottom_sheet.dart';
import 'package:healthymate/features/health_calculator/widgets/result_card.dart';

class HealthCalculatorScreen extends StatefulWidget {
  final HealthCalculatorState state;

  const HealthCalculatorScreen({
    super.key,
    required this.state,
  });

  @override
  State<HealthCalculatorScreen> createState() => _HealthCalculatorScreenState();
}

class _HealthCalculatorScreenState extends State<HealthCalculatorScreen> {
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: widget.state.age.toString());
    _heightController = TextEditingController(text: widget.state.height.toStringAsFixed(0));
    _weightController = TextEditingController(text: widget.state.weight.toStringAsFixed(0));
    widget.state.addListener(_syncControllersWithState);
  }

  void _syncControllersWithState() {
    if (!mounted) return;
    if (_ageController.text != widget.state.age.toString()) {
      _ageController.text = widget.state.age.toString();
    }
    if (_heightController.text != widget.state.height.toStringAsFixed(0)) {
      _heightController.text = widget.state.height.toStringAsFixed(0);
    }
    if (_weightController.text != widget.state.weight.toStringAsFixed(0)) {
      _weightController.text = widget.state.weight.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_syncControllersWithState);
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onCalculate() {
    final age = int.tryParse(_ageController.text) ?? widget.state.age;
    final height = double.tryParse(_heightController.text) ?? widget.state.height;
    final weight = double.tryParse(_weightController.text) ?? widget.state.weight;

    widget.state.setAge(age);
    widget.state.setHeight(height);
    widget.state.setWeight(weight);
    widget.state.calculate(recordHistory: false);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('คำนวณค่าดัชนีสุขภาพเรียบร้อยแล้ว'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onSaveToDashboard() {
    final age = int.tryParse(_ageController.text) ?? widget.state.age;
    final height = double.tryParse(_heightController.text) ?? widget.state.height;
    final weight = double.tryParse(_weightController.text) ?? widget.state.weight;

    widget.state.setAge(age);
    widget.state.setHeight(height);
    widget.state.setWeight(weight);
    widget.state.saveToProfileAndDashboard();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'บันทึกข้อมูลและอัปเดตเข้า Dashboard สำเร็จแล้ว!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) => HistoryBottomSheet(
          historyList: widget.state.historyList,
          onDeleteRecord: (id) => widget.state.deleteHistoryItem(id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final state = widget.state;

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              color: AppTheme.primaryGreen,
              onRefresh: () => widget.state.loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'เครื่องคำนวณสุขภาพ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ติดตามและคำนวณ BMI, BMR และ TDEE ของคุณ',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // History Button (TbCalculationHistory)
                      InkWell(
                        onTap: _openHistorySheet,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.subtleSurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: AppTheme.textPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Gender Selector
                  GenderSelector(
                    selectedGender: state.gender,
                    onGenderChanged: (gender) => state.setGender(gender),
                  ),

                  const SizedBox(height: 18),

                  // Age Input
                  _buildInputField(
                    label: 'อายุ',
                    controller: _ageController,
                    suffixText: 'ปี',
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 18),

                  // Height Input
                  _buildInputField(
                    label: 'ส่วนสูง',
                    controller: _heightController,
                    suffixText: 'ซม.',
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 18),

                  // Weight Input
                  _buildInputField(
                    label: 'น้ำหนัก',
                    controller: _weightController,
                    suffixText: 'กก.',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),

                  const SizedBox(height: 22),

                  // Activity Level Picker
                  ActivityLevelPicker(
                    selectedLevel: state.activityLevel,
                    onLevelChanged: (level) => state.setActivityLevel(level),
                  ),

                  const SizedBox(height: 24),

                  // Calculate Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _onCalculate,
                      icon: const Icon(Icons.calculate_outlined, size: 22),
                      label: const Text(
                        'คำนวณค่า BMR, TDEE & BMI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Results Container
                  _buildResultSection(state),

                  const SizedBox(height: 20),

                  // Save to Dashboard Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _onSaveToDashboard,
                      icon: const Icon(Icons.cloud_upload_outlined, size: 22),
                      label: const Text(
                        'บันทึกและอัปเดตข้อมูลเข้า Dashboard',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A24),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String suffixText,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight, width: 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  suffixText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection(HealthCalculatorState state) {
    final bmiCategory = state.bmiCategory;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      size: 20,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ผลลัพธ์การวิเคราะห์',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bmiCategory.badgeText,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 16),

          // BMI Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ดัชนีมวลกาย (BMI)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      text: state.bmi.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -1,
                      ),
                      children: const [
                        TextSpan(
                          text: ' kg/m²',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'เกณฑ์สุขภาพดี',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '18.5 - 22.9',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // BMI Indicator Bar
          BMIIndicatorBar(bmi: state.bmi, category: bmiCategory),

          const SizedBox(height: 20),

          // BMR & TDEE 2 Cards
          Row(
            children: [
              Expanded(
                child: EnergyMetricCard(
                  icon: Icons.hotel_outlined,
                  title: 'BMR (ขณะพัก)',
                  value: state.bmr.toInt().toString(),
                  unit: 'kcal',
                  description: 'พลังงานต่ำสุดที่ร่างกายต้องการ',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EnergyMetricCard(
                  icon: Icons.local_fire_department_outlined,
                  title: 'TDEE (ใช้จริง/วัน)',
                  value: state.tdee.toInt().toString(),
                  unit: 'kcal',
                  description: 'พลังงานรวมที่เผาผลาญต่อวัน',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Calorie Targets Section
          CalorieTargetSection(targets: state.targets),
        ],
      ),
    );
  }
}
