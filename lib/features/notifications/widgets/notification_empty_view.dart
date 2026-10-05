import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

/// หน้าจอเมื่อไม่มีรายการแจ้งเตือน (Empty Notifications View)
class NotificationEmptyView extends StatelessWidget {
  final VoidCallback onRefresh;

  const NotificationEmptyView({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF23352A)
                    : const Color(0xFFE8F3EB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                size: 44,
                color: isDark
                    ? AppTheme.primaryLightGreen
                    : const Color(0xFF2E5327),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ไม่มีการแจ้งเตือนใหม่',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'คุณอัปเดตข้อมูลสุขภาพและกิจวัตรครบถ้วนแล้ว\nระบบจะแจ้งเตือนเมื่อถึงเวลาออกกำลังกายหรือบันทึกอาหาร',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'รีเฟรชข้อมูล',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppTheme.primaryGreen
                    : const Color(0xFF2E5327),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}
