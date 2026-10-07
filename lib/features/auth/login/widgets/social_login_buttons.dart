import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGoogleLogin;
  final VoidCallback onBiometricLogin;

  const SocialLoginButtons({
    super.key,
    required this.onGoogleLogin,
    required this.onBiometricLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // เส้นคั่นและข้อความ "หรือเข้าสู่ระบบด้วย"
        const Row(
          children: [
            Expanded(
              child: Divider(color: AppTheme.borderLight, thickness: 1),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'หรือเข้าสู่ระบบด้วย',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: AppTheme.borderLight, thickness: 1),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // แถวปุ่ม Social Login
        Row(
          children: [
            // ปุ่ม Google
            Expanded(
              child: OutlinedButton(
                onPressed: onGoogleLogin,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.subtleSurface,
                  side: const BorderSide(
                    color: AppTheme.borderLight,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      color: AppTheme.textPrimary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: onBiometricLogin,
              tooltip: 'เข้าสู่ระบบด้วย Biometric (FaceID / Fingerprint)',
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(14),
                backgroundColor: AppTheme.subtleSurface,
                side: const BorderSide(color: AppTheme.borderLight, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(
                Icons.fingerprint_rounded,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
