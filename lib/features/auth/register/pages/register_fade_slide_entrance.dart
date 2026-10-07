import 'package:flutter/material.dart';

/// Widget สำหรับทำแอนิเมชัน Fade & Slide ขึ้นแบบ Staggered เมื่อเปิดหน้าจอ
class FadeSlideEntrance extends StatelessWidget {
  final Widget child;
  final int delayIndex;

  const FadeSlideEntrance({
    super.key,
    required this.child,
    required this.delayIndex,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (delayIndex * 120)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
