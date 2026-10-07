import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:healthymate/shared/widgets/sync_status_badge.dart';

/// ส่วนหัวของหน้า Dashboard แสดงทักทายผู้ใช้ วันที่/สัปดาห์ รูปโปรไฟล์ และสถานะการเชื่อมต่อ (Sync Status)
class DashboardHeader extends StatelessWidget {
  final String userName;
  final String profilePath;
  final String thaiDayName;
  final int weekOfMonth;
  final String greetingText;
  final String greetingEmoji;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final int unreadCount;
  final Color primaryGreen;
  final Color darkGreen;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.profilePath,
    required this.thaiDayName,
    required this.weekOfMonth,
    required this.greetingText,
    required this.greetingEmoji,
    this.onProfileTap,
    this.onNotificationTap,
    this.unreadCount = 0,
    this.primaryGreen = const Color(0xFF0F9C58),
    this.darkGreen = const Color(0xFF006432),
  });

  ImageProvider? _getImageProvider(String path) {
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (!kIsWeb) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (e) {
        debugPrint('DashboardHeader image load error: $e');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _getImageProvider(profilePath);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? const Color(0xFFA0ACA0) : Colors.black54;

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onProfileTap,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryGreen.withValues(alpha: 0.2),
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: darkGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HealthyMate',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, color: primaryGreen, size: 8),
                          const SizedBox(width: 4),
                          Text(
                            'เข้าสู่วัน$thaiDayName • สัปดาห์ที่ $weekOfMonth',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFA0ACA0) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  const SyncStatusBadge(),
                  const SizedBox(width: 6),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: onNotificationTap,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style: TextStyle(color: primaryTextColor, fontSize: 24),
              children: [
                TextSpan(
                  text: '$greetingText, $userName! $greetingEmoji\n',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: 'พร้อมออกไปวิ่งรับพลังงานและดูแลสุขภาพที่ดีหรือยัง?',
                  style: TextStyle(fontSize: 14, color: secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
