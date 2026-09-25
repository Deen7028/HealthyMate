import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';

class PasswordRequirementsCard extends StatelessWidget {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigits;

  const PasswordRequirementsCard({
    super.key,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.subtleSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เงื่อนไขความปลอดภัยของรหัสผ่าน:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _buildRequirementItem('อย่างน้อย 8 ตัวอักษร', hasMinLength),
          _buildRequirementItem('มีตัวพิมพ์ใหญ่ (A-Z)', hasUppercase),
          _buildRequirementItem('มีตัวพิมพ์เล็ก (a-z)', hasLowercase),
          _buildRequirementItem('มีตัวเลข (0-9)', hasDigits),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isSatisfied) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(
            isSatisfied
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isSatisfied ? AppTheme.primaryGreen : AppTheme.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color:
                  isSatisfied ? AppTheme.primaryGreen : AppTheme.textSecondary,
              fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
