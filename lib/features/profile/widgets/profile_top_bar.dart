// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์โปรไฟล์ การตั้งค่า และบัญชีผู้ใช้ (profile top bar)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/core/services/theme_service.dart';

class ProfileTopBar extends StatelessWidget {
  final ImageProvider? avatarProvider;
  final VoidCallback? onNotificationTap;

  const ProfileTopBar({
    super.key,
    this.avatarProvider,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User Avatar Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
              image: avatarProvider != null
                  ? DecorationImage(
                      image: avatarProvider!,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarProvider == null
                ? const Icon(
                    Icons.person,
                    size: 20,
                    color: Colors.white,
                  )
                : null,
          ),
          // App Title
          Text(
            'HealthyMate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1C2819),
              letterSpacing: -0.3,
            ),
          ),
          // Notification Bell
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: primaryColor,
              size: 24,
            ),
            onPressed: onNotificationTap ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ไม่มีการแจ้งเตือนใหม่'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          ),
        ],
      ),
    );
  }
}
