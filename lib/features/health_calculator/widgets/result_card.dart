// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์เครื่องคำนวณสุขภาพและบันทึกค่าสุขภาพ (result card)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class EnergyMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final double numericValue;
  final String unit;
  final String description;

  const EnergyMetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.numericValue,
    required this.unit,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = AppTheme.getSurfaceColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final primaryColor = isDark ? AppTheme.primaryLightGreen : AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: numericValue),
            duration: const Duration(milliseconds: 2500),
            curve: Curves.easeOutCubic,
            builder: (context, val, _) {
              return RichText(
                text: TextSpan(
                  text: val.toInt().toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 11.5,
              color: textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
