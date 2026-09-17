import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/state/health_calculator_state.dart';
import 'package:healthymate/features/health_calculator/widgets/index.dart';

class HealthCalculatorScreen extends StatefulWidget {
  final HealthCalculatorState state;

  const HealthCalculatorScreen({super.key, required this.state});

  @override
  State<HealthCalculatorScreen> createState() => _HealthCalculatorScreenState();
}

class _HealthCalculatorScreenState extends State<HealthCalculatorScreen> {
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  late FocusNode _ageFocusNode;
  late FocusNode _heightFocusNode;
  late FocusNode _weightFocusNode;

  String? _ageError;
  String? _heightError;
  String? _weightError;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(
      text: widget.state.age > 0 ? widget.state.age.toString() : '',
    );
    _heightController = TextEditingController(
      text: widget.state.height > 0
          ? widget.state.height.toStringAsFixed(0)
          : '',
    );
    _weightController = TextEditingController(
      text: widget.state.weight > 0
          ? widget.state.weight.toStringAsFixed(0)
          : '',
    );

    _ageFocusNode = FocusNode();
    _heightFocusNode = FocusNode();
    _weightFocusNode = FocusNode();

    widget.state.addListener(_syncControllersWithState);
  }

  void _syncControllersWithState() {
    if (!mounted) return;
    final stateAge = widget.state.age > 0 ? widget.state.age.toString() : '';
    final stateHeight = widget.state.height > 0
        ? widget.state.height.toStringAsFixed(0)
        : '';
    final stateWeight = widget.state.weight > 0
        ? widget.state.weight.toStringAsFixed(0)
        : '';

    // ป้องกัน Controller Synchronization Bug:
    // ไม่แทนที่ค่าในช่องหากผู้ใช้กำลัง Focus หรือพิมพ์อยู่ เพื่อป้องกันข้อความกระตุกหรือถูกลบกลางคัน
    if (!_ageFocusNode.hasFocus &&
        _ageController.text != stateAge &&
        stateAge.isNotEmpty) {
      _ageController.text = stateAge;
    }
    if (!_heightFocusNode.hasFocus &&
        _heightController.text != stateHeight &&
        stateHeight.isNotEmpty) {
      _heightController.text = stateHeight;
    }
    if (!_weightFocusNode.hasFocus &&
        _weightController.text != stateWeight &&
        stateWeight.isNotEmpty) {
      _weightController.text = stateWeight;
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_syncControllersWithState);
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageFocusNode.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final ageText = _ageController.text.trim();
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    final age = int.tryParse(ageText) ?? 0;
    final height = double.tryParse(heightText) ?? 0.0;
    final weight = double.tryParse(weightText) ?? 0.0;

    String? ageErr;
    String? heightErr;
    String? weightErr;

    if (ageText.isEmpty) {
      ageErr = 'กรุณาระบุอายุ';
    } else if (age <= 0 || age > 130) {
      ageErr = 'อายุต้องอยู่ระหว่าง 1 - 130 ปี';
    }

    if (heightText.isEmpty) {
      heightErr = 'กรุณาระบุส่วนสูง';
    } else if (height <= 0 || height > 280) {
      heightErr = 'ส่วนสูงต้องอยู่ระหว่าง 30 - 280 ซม.';
    }

    if (weightText.isEmpty) {
      weightErr = 'กรุณาระบุน้ำหนัก';
    } else if (weight <= 0 || weight > 500) {
      weightErr = 'น้ำหนักต้องอยู่ระหว่าง 10 - 500 กก.';
    }

    setState(() {
      _ageError = ageErr;
      _heightError = heightErr;
      _weightError = weightErr;
    });

    return ageErr == null && heightErr == null && weightErr == null;
  }

  Future<void> _onCalculate() async {
    if (!_validateInputs()) {
      return;
    }

    final age = int.tryParse(_ageController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0.0;
    final weight = double.tryParse(_weightController.text) ?? 0.0;

    widget.state.setAge(age);
    widget.state.setHeight(height);
    widget.state.setWeight(weight);
    await widget.state.calculate(recordHistory: false);

    if (!mounted) return;

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

  Future<void> _onSaveToDashboard() async {
    if (!_validateInputs()) {
      return;
    }

    final age = int.tryParse(_ageController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0.0;
    final weight = double.tryParse(_weightController.text) ?? 0.0;

    widget.state.setAge(age);
    widget.state.setHeight(height);
    widget.state.setWeight(weight);
    await widget.state.saveToProfileAndDashboard();

    if (!mounted) return;

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
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryGreen,
          onRefresh: () => widget.state.loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section (ใช้ ListenableBuilder เฉพาะส่วนแสดงชื่อผู้ใช้เพื่อลดการ rebuild ทั้งหน้า)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'เครื่องคำนวณสุขภาพ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ListenableBuilder(
                            listenable: widget.state,
                            builder: (context, _) {
                              final user = widget.state.currentUser;
                              return Text(
                                user != null
                                    ? 'ข้อมูลของคุณ (${user.sFirstName})'
                                    : 'ติดตามและคำนวณ BMI, BMR และ TDEE ของคุณ',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
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

                const SizedBox(height: 16),

                // Loading State Banner / Skeleton ระหว่างดึงข้อมูลจาก Server
                ListenableBuilder(
                  listenable: widget.state,
                  builder: (context, _) {
                    if (!widget.state.isLoading) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.subtleSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'กำลังโหลดข้อมูลสุขภาพล่าสุดจากเซิร์ฟเวอร์...',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Gender Selector (ฟังเฉพาะ gender state)
                ListenableBuilder(
                  listenable: widget.state,
                  builder: (context, _) => GenderSelector(
                    selectedGender: widget.state.gender,
                    onGenderChanged: (gender) => widget.state.setGender(gender),
                  ),
                ),

                const SizedBox(height: 18),

                // Age Input with inline Error feedback
                _buildInputField(
                  label: 'อายุ',
                  controller: _ageController,
                  focusNode: _ageFocusNode,
                  suffixText: 'ปี',
                  keyboardType: TextInputType.number,
                  errorText: _ageError,
                  onChanged: (_) {
                    if (_ageError != null) {
                      setState(() => _ageError = null);
                    }
                  },
                ),

                const SizedBox(height: 18),

                // Height Input with inline Error feedback
                _buildInputField(
                  label: 'ส่วนสูง',
                  controller: _heightController,
                  focusNode: _heightFocusNode,
                  suffixText: 'ซม.',
                  keyboardType: TextInputType.number,
                  errorText: _heightError,
                  onChanged: (_) {
                    if (_heightError != null) {
                      setState(() => _heightError = null);
                    }
                  },
                ),

                const SizedBox(height: 18),

                // Weight Input with inline Error feedback
                _buildInputField(
                  label: 'น้ำหนัก',
                  controller: _weightController,
                  focusNode: _weightFocusNode,
                  suffixText: 'กก.',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  errorText: _weightError,
                  onChanged: (_) {
                    if (_weightError != null) {
                      setState(() => _weightError = null);
                    }
                  },
                ),

                const SizedBox(height: 22),

                // Activity Level Picker (ฟังเฉพาะ activityLevel)
                ListenableBuilder(
                  listenable: widget.state,
                  builder: (context, _) => ActivityLevelPicker(
                    selectedLevel: widget.state.activityLevel,
                    onLevelChanged: (level) => widget.state.setActivityLevel(level),
                  ),
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

                // Results Section (ครอบด้วย ListenableBuilder เฉพาะส่วนนี้เพื่อลด Over-Rebuilding UI)
                ListenableBuilder(
                  listenable: widget.state,
                  builder: (context, _) => _buildResultSection(widget.state),
                ),

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
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String suffixText,
    required TextInputType keyboardType,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null;

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
            border: Border.all(
              color: hasError ? Colors.redAccent : AppTheme.borderLight,
              width: hasError ? 1.5 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
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
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: Colors.redAccent),
                const SizedBox(width: 4),
                Text(
                  errorText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
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
