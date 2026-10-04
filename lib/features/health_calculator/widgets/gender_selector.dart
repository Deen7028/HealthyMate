// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์เครื่องคำนวณสุขภาพและบันทึกค่าสุขภาพ (gender selector)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/core/utils/health_calculator.dart';

class GenderSelector extends StatelessWidget {
  final Gender selectedGender;
  final ValueChanged<Gender> onGenderChanged;

  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เพศ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                gender: Gender.male,
                label: 'ชาย',
                icon: Icons.male_rounded,
                isSelected: selectedGender == Gender.male,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderOption(
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                gender: Gender.female,
                label: 'หญิง',
                icon: Icons.female_rounded,
                isSelected: selectedGender == Gender.female,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Gender gender,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final selectedBg = isDark ? const Color(0xFF23352A) : const Color(0xFFF3F8F4);
    final selectedColor = isDark ? AppTheme.primaryLightGreen : AppTheme.primaryGreen;
    final unselectedText = AppTheme.getTextPrimaryColor(isDark);
    final unselectedIcon = AppTheme.getTextSecondaryColor(isDark);

    return InkWell(
      onTap: () => onGenderChanged(gender),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : borderColor,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? selectedColor : unselectedIcon,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
