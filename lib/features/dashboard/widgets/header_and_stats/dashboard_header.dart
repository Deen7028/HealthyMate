import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:healthymate/shared/widgets/sync_status_badge.dart';

// ส่วนหัวของหน้าแดชบอร์ด (DashboardHeader)
// แสดงคำทักทาย, วันที่/สัปดาห์, รูปโปรไฟล์, แบดจ์ซิงค์ และปุ่มการแจ้งเตือน
class DashboardHeader extends StatelessWidget {
  /// ชื่อของผู้ใช้งาน
  final String userName;
  /// เส้นทางรูปภาพโปรไฟล์ (Local File หรือ Network URL)
  final String profilePath;
  /// ชื่อวันภาษาไทย (เช่น 'พฤหัสบดี')
  final String thaiDayName;
  /// ลำดับสัปดาห์ของเดือน
  final int weekOfMonth;
  /// ข้อความทักทายตามช่วงเวลา (เช่น 'สวัสดีตอนเช้า')
  final String greetingText;
  /// อีโมจิตามช่วงเวลา (เช่น '☀️')
  final String greetingEmoji;
  /// Callback เมื่อกดที่รูปโปรไฟล์
  final VoidCallback? onProfileTap;
  /// Callback เมื่อกดที่ปุ่มการแจ้งเตือน
  final VoidCallback? onNotificationTap;
  /// จำนวนการแจ้งเตือนที่ยังไม่ได้อ่าน
  final int unreadCount;
  /// สีเขียวหลัก
  final Color primaryGreen;
  /// สีเขียวเข้ม
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

  /// ฟังก์ชันช่วย: ตรวจสอบและสร้าง ImageProvider จากพาธของรูปภาพ
  ImageProvider? _getImageProvider(String path) {
    if (path.isEmpty) return null;
    // 1. กรณีเป็นรูปจาก URL บนคลาวด์/อินเทอร์เน็ต
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    // 2. กรณีเป็นไฟล์รูปภาพในเครื่อง (Mobile/Desktop)
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
    // 1. จัดเตรียมข้อมูลธีมและสี
    final imageProvider = _getImageProvider(profilePath);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? const Color(0xFFA0ACA0) : Colors.black54;

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // แถวบน: รูปโปรไฟล์ + โลโก้/สัปดาห์ + แบดจ์ซิงค์ + แจ้งเตือน
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ด้านซ้าย: รูปโปรไฟล์ และ ชื่อแอป/วันที่
              Row(
                children: [
                  // รูปภาพโปรไฟล์ (หรือตัวอักษรแรกหากไม่มีรูป)
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
                  // ชื่อแอป HealthyMate และสถานะวัน/สัปดาห์
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

              // ด้านขวา: สถานะ Sync Status Badge และปุ่มแจ้งเตือนพร้อมตัวเลขนับ (Badge)
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
                      // ตัวเลขนับแจ้งเตือนสีแดง (Unread Count Badge)
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

          // ----------------------------------------------------
          // แถวล่าง: ข้อความทักทายผู้ใช้ (Greeting & Motivational Quote)
          // ----------------------------------------------------
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

