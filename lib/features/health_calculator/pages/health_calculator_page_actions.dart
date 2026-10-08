part of 'health_calculator_page.dart';

extension _HealthCalculatorPageActions on _HealthCalculatorPageState {
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
    // ตรวจสอบข้อมูล
    if (ageText.isEmpty) {
      ageErr = 'กรุณาระบุอายุ';
    } else if (age <= 0 || age > 130) {
      ageErr = 'อายุต้องอยู่ระหว่าง 1 - 130 ปี';
    }
    // ตรวจสอบข้อมูล
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
// ปุ่มคำนวณค่า BMR, TDEE & BMI
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
// ปุ่มบันทึกข้อมูล
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
  // เปิดหน้าประวัติการคำนวณ
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
}
