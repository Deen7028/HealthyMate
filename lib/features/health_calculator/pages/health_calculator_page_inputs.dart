// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์เครื่องคำนวณสุขภาพและบันทึกค่าสุขภาพ (health calculator page inputs)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'health_calculator_page.dart';

extension _HealthCalculatorPageInputs on _HealthCalculatorPageState {
  List<Widget> _buildInputsSection() {
    return [
      // Age Input with inline Error feedback
      HealthCalculatorInputField(
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
      HealthCalculatorInputField(
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
      HealthCalculatorInputField(
        label: 'น้ำหนัก',
        controller: _weightController,
        focusNode: _weightFocusNode,
        suffixText: 'กก.',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'คำนวณค่า BMR, TDEE & BMI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
    ];
  }
}
