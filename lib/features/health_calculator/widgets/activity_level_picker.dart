// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์เครื่องคำนวณสุขภาพและบันทึกค่าสุขภาพ (activity level picker)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/models/activity_level.dart';

class ActivityLevelPicker extends StatelessWidget {
  final ActivityLevel selectedLevel;
  final ValueChanged<ActivityLevel> onLevelChanged;

  const ActivityLevelPicker({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ระดับกิจกรรมทางกายภาพ (Activity Level)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ActivityLevel.options.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final option = ActivityLevel.options[index];
            final isSelected = option.id == selectedLevel.id;
            final selectedBg = isDark ? const Color(0xFF23352A) : const Color(0xFFF3F8F4);
            final selectedBorder = isDark ? AppTheme.primaryLightGreen : AppTheme.primaryGreen;

            return InkWell(
              onTap: () => onLevelChanged(option),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBg : cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? selectedBorder : borderColor,
                    width: isSelected ? 1.8 : 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? AppTheme.primaryLightGreen : AppTheme.primaryGreen)
                              : (isDark ? const Color(0xFF6B7E72) : AppTheme.textTertiary),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? AppTheme.primaryLightGreen : AppTheme.primaryGreen,
                                ),
                              ),
                            )
                          : null,
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
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.description,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
