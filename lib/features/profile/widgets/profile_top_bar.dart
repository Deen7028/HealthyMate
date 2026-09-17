import 'package:flutter/material.dart';
import 'package:healthymate/core/services/theme_service.dart';

class ProfileTopBar extends StatelessWidget {
  final ImageProvider avatarProvider;
  final VoidCallback? onNotificationTap;

  const ProfileTopBar({
    super.key,
    required this.avatarProvider,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;

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
              image: DecorationImage(
                image: avatarProvider,
                fit: BoxFit.cover,
              ),
            ),
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
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF2E6339),
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
