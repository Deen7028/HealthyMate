// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์การเข้าสู่ระบบ (login footer link)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

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
