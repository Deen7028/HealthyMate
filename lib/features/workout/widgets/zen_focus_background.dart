import 'package:flutter/material.dart';

class ZenFocusBackground extends StatefulWidget {
  const ZenFocusBackground({super.key});

  @override
  State<ZenFocusBackground> createState() => _ZenFocusBackgroundState();
}

class _ZenFocusBackgroundState extends State<ZenFocusBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    // จังหวะหายใจ: เข้า 4 วินาที ออก 4 วินาที
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F3EB), Color(0xFFCBE3D3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _breatheController,
          builder: (context, child) {
            // คำนวณขนาดรัศมีให้ยืดหดอย่างนุ่มนวล
            final scale = 1.0 + (_breatheController.value * 0.4);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF90DB89).withValues(alpha: 0.25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF90DB89).withValues(alpha: 0.35),
                      blurRadius: 50,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.self_improvement_rounded,
                    size: 64,
                    color: Color(0xFF2E5327),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
