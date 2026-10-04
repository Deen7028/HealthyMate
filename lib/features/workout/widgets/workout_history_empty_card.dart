// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์การติดตามและประวัติการออกกำลังกาย (workout history empty card)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

/// วิดเจ็ตแสดงผลกรณีไม่มีประวัติการออกกำลังกาย (Workout History Empty Card Widget)
class WorkoutHistoryEmptyCard extends StatelessWidget {
  /// คอลแบ็กเมื่อกดปุ่มดึงข้อมูล Sync จาก Cloud
  final VoidCallback onSyncTap;

  const WorkoutHistoryEmptyCard({
    super.key,
    required this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF23352A) : const Color(0xFFE8F1E7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF354E3C) : const Color(0xFFD4E6D2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      size: 48,
                      color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ยังไม่มีประวัติการออกกำลังกาย',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'เลื่อนลงเพื่อดึงข้อมูลจาก Cloud หรือเริ่มบันทึกกิจกรรมวิ่ง เดิน หรือปั่นจักรยานใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: onSyncTap,
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text('ดึงข้อมูลทั้งหมดจาก Server'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppTheme.primaryLightGreen : AppTheme.primaryGreen,
                      side: BorderSide(
                        color: isDark ? AppTheme.primaryLightGreen : AppTheme.primaryGreen,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
