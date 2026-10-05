// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ที่หลายฟีเจอร์นำไปใช้ร่วมกัน (fade slide entrance)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';

/// Widget สำหรับทำแอนิเมชัน Fade & Slide ขึ้นแบบ Staggered เมื่อเปิดหน้าจอ
class FadeSlideEntrance extends StatelessWidget {
  final Widget child;
  final int delayIndex;
  final int durationMs;

  const FadeSlideEntrance({
    super.key,
    required this.child,
    required this.delayIndex,
    this.durationMs = 500,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: durationMs + (delayIndex * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
