// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์เครื่องคำนวณสุขภาพและบันทึกค่าสุขภาพ (health calculator page)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/controllers/health_calculator_controller.dart';
import 'package:healthymate/features/health_calculator/widgets/index.dart';

part 'health_calculator_page_actions.dart';
part 'health_calculator_page_content.dart';
part 'health_calculator_page_inputs.dart';

class HealthCalculatorPage extends StatefulWidget {
  final bool isActive;
  final HealthCalculatorController state;

  const HealthCalculatorPage({
    super.key,
    this.isActive = true,
    required this.state,
  });

  @override
  State<HealthCalculatorPage> createState() => _HealthCalculatorPageState();
}

class _HealthCalculatorPageState extends State<HealthCalculatorPage> {
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

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
