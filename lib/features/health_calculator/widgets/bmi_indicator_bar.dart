// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์เครื่องคำนวณสุขภาพและบันทึกค่าสุขภาพ (bmi indicator bar)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/core/utils/health_calculator.dart';

class BMIIndicatorBar extends StatelessWidget {
  final double bmi;
  final BMICategory category;

  const BMIIndicatorBar({
    super.key,
    required this.bmi,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final segments = [
      AppTheme.bmiUnderweight,
      AppTheme.bmiNormal,
      AppTheme.bmiOverweight,
      AppTheme.bmiObese,
    ];

    return Column(
      children: [
        Row(
          children: List.generate(4, (index) {
            final isActive = category.index == index;
            final isFirst = index == 0;
            final isLast = index == 3;

            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                margin: EdgeInsets.only(
                  left: isFirst ? 0 : 2.5,
                  right: isLast ? 0 : 2.5,
                ),
                height: isActive ? 10 : 6,
                decoration: BoxDecoration(
                  color: segments[index].withValues(alpha: isActive ? 1.0 : 0.45),
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst ? const Radius.circular(4) : Radius.zero,
                    right: isLast ? const Radius.circular(4) : Radius.zero,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: segments[index].withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
