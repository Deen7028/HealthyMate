import 'package:flutter/material.dart';

// วิดเจ็ตครอบเพื่อสร้างแอนิเมชันเปิดตัวแบบเลื่อนและค่อยๆ ปรากฏ (Fade & Slide Entrance Animation)

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
