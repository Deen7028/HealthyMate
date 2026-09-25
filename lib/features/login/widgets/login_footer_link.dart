import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';

class LoginFooterLink extends StatelessWidget {
  final VoidCallback onRegisterTap;

  const LoginFooterLink({
    super.key,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'ยังไม่มีบัญชีสมาชิก? ',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: onRegisterTap,
          child: const Text(
            'สมัครสมาชิกที่นี่',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}
