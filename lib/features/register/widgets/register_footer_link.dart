import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class RegisterFooterLink extends StatelessWidget {
  final VoidCallback onLoginTap;

  const RegisterFooterLink({
    super.key,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'มีบัญชีผู้ใช้งานอยู่แล้วใช่ไหม? ',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: onLoginTap,
          child: const Text(
            'เข้าสู่ระบบ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
