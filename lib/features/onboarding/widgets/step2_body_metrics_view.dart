// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์ขั้นตอนเริ่มต้นใช้งานและตั้งค่าเป้าหมาย (step2 body metrics view)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/features/health_calculator/models/activity_level.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class Step2BodyMetricsView extends StatelessWidget {
  final String gender;
  final TextEditingController ageController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final String selectedActivityLevel;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onActivityLevelChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isLoading;

  const Step2BodyMetricsView({
    super.key,
    required this.gender,
    required this.ageController,
    required this.weightController,
    required this.heightController,
    required this.selectedActivityLevel,
    required this.onGenderChanged,
    required this.onActivityLevelChanged,
    required this.onNext,
    required this.onBack,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'กรอกข้อมูลสุขภาพพื้นฐาน',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ข้อมูลนี้จะถูกนำไปคำนวณค่า BMR, TDEE, BMI และพลังงานที่เผาผลาญขณะออกกำลังกายอย่างแม่นยำ',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // 1. Gender Selection
          Text(
            'เพศ (Gender)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(
                  title: 'ชาย (Male)',
                  icon: Icons.male_rounded,
                  isSelected: gender == 'male',
                  onTap: () => onGenderChanged('male'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderCard(
                  title: 'หญิง (Female)',
                  icon: Icons.female_rounded,
                  isSelected: gender == 'female',
                  onTap: () => onGenderChanged('female'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Age, Weight, Height Inputs
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'อายุ (ปี)',
                  controller: ageController,
                  hint: 'เช่น 25',
                  unit: 'ปี',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  label: 'น้ำหนัก (กก.)',
                  controller: weightController,
                  hint: 'เช่น 65.0',
                  unit: 'kg',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  label: 'ส่วนสูง (ซม.)',
                  controller: heightController,
                  hint: 'เช่น 175',
                  unit: 'cm',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // 3. Activity Level Selection
          Text(
            'ระดับกิจกรรมประจำวัน (Activity Level)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...ActivityLevel.options.map((option) {
            final isSelected = selectedActivityLevel == option.id;
            return GestureDetector(
              onTap: () => onActivityLevelChanged(option.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppTheme.primaryGreen.withAlpha(50) : AppTheme.primaryGreenLight)
                      : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : borderColor,
                    width: isSelected ? 2.0 : 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: isSelected ? AppTheme.primaryGreen : textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppTheme.primaryGreen : textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Navigation Action Buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'ย้อนกลับ',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ถัดไป',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGenderCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.primaryGreen.withAlpha(50) : AppTheme.primaryGreenLight)
              : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : borderColor,
            width: isSelected ? 2.0 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryGreen : (isDark ? Colors.white70 : const Color(0xFF5A6559)),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primaryGreen : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String unit,
    required TextInputType keyboardType,
    required bool isDark,
  }) {
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13, color: textSecondary.withAlpha(150)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
