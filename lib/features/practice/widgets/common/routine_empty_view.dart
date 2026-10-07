import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

// วิดเจ็ตแสดงสถานะเมื่อยังไม่มีรายการกิจวัตรในระบบ (Routine Empty View Widget)
// แสดงข้อความและไอคอนแนะนำให้ผู้ใช้กดเพิ่มกิจวัตรประจำวันใหม่
class RoutineEmptyView extends StatelessWidget {
  const RoutineEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.playlist_add_check_rounded,
            size: 64,
            color: isDark ? const Color(0xFF4A584E) : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีกิจวัตร',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กดปุ่ม + ด้านล่างเพื่อเพิ่มกิจวัตรประจำวัน\nเช่น ดื่มน้ำ, ออกกำลังกาย, นั่งสมาธิ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
        ],
      ),
    );
  }
}
