import 'package:flutter/material.dart';
import 'package:healthymate/core/services/theme_service.dart';

class LogoutConfirmDialog extends StatelessWidget {
  const LogoutConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'ออกจากระบบ',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF1E2822),
        ),
      ),
      content: Text(
        'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ HealthyMate?',
        style: TextStyle(
          color: isDark ? const Color(0xFFA0ACA0) : const Color(0xFF6F7A72),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD93838),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('ออกจากระบบ', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
