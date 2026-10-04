// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine gps sync option)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class RoutineGpsSyncOption extends StatelessWidget {
  final bool isDark;
  final bool isAutoLinked;
  final Color surfaceBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final String? selectedLinkedWorkout;
  final String? autoDetected;
  final ValueChanged<bool> onToggleAutoLink;

  const RoutineGpsSyncOption({
    super.key,
    required this.isDark,
    required this.isAutoLinked,
    required this.surfaceBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.selectedLinkedWorkout,
    required this.autoDetected,
    required this.onToggleAutoLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAutoLinked
            ? (isDark ? const Color(0xFF23352A) : const Color(0xFFE8F3EB))
            : surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAutoLinked
              ? (isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327))
              : borderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      color: isAutoLinked
                          ? (isDark
                                ? AppTheme.primaryLightGreen
                                : const Color(0xFF2E5327))
                          : textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '🔗 เชื่อมโยงข้อมูล GPS ออกกำลังกายอัตโนมัติ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isAutoLinked
                              ? (isDark
                                    ? AppTheme.primaryLightGreen
                                    : const Color(0xFF2E5327))
                              : textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isAutoLinked,
                onChanged: onToggleAutoLink,
                activeThumbColor: isDark
                    ? AppTheme.primaryLightGreen
                    : const Color(0xFF2E5327),
              ),
            ],
          ),
          if (isAutoLinked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ตรวจจับกิจกรรม: "${selectedLinkedWorkout ?? autoDetected}" Auto Sync',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.primaryLightGreen
                          : const Color(0xFF2E5327),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
