import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';

class RegisterConsentSection extends StatelessWidget {
  final bool acceptTerms;
  final bool acceptPrivacy;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onPrivacyChanged;
  final VoidCallback onShowTerms;
  final VoidCallback onShowPrivacy;

  const RegisterConsentSection({
    super.key,
    required this.acceptTerms,
    required this.acceptPrivacy,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.onShowTerms,
    required this.onShowPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Terms of Service Checkbox
        InkWell(
          onTap: () => onTermsChanged(!acceptTerms),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: acceptTerms,
                  onChanged: (val) => onTermsChanged(val ?? false),
                  activeColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  children: [
                    const Text(
                      'ฉันยอมรับ ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: onShowTerms,
                      child: const Text(
                        'เงื่อนไขการให้บริการ (Terms of Service)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Privacy Policy Checkbox
        InkWell(
          onTap: () => onPrivacyChanged(!acceptPrivacy),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: acceptPrivacy,
                  onChanged: (val) => onPrivacyChanged(val ?? false),
                  activeColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  children: [
                    const Text(
                      'ฉันยอมรับ ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: onShowPrivacy,
                      child: const Text(
                        'นโยบายความเป็นส่วนตัว (Privacy Policy)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(
                      ' เพื่อความโปร่งใสในการจัดเก็บข้อมูลสุขภาพและพิกัด GPS',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
