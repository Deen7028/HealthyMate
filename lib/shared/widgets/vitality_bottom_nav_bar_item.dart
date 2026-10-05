// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ที่หลายฟีเจอร์นำไปใช้ร่วมกัน (vitality bottom nav bar item)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'vitality_bottom_nav_bar.dart';

class _VitalityStandardNavItemWidget extends StatefulWidget {
  final VitalityNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _VitalityStandardNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_VitalityStandardNavItemWidget> createState() =>
      _VitalityStandardNavItemWidgetState();
}

class _VitalityStandardNavItemWidgetState
    extends State<_VitalityStandardNavItemWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedIconColor = isDark
        ? const Color(0xFFA0ACA0)
        : const Color(0xFF8C9890);
    final unselectedTextColor = isDark
        ? const Color(0xFFA0ACA0)
        : const Color(0xFF6F7C73);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Future.microtask(widget.onTap);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container with animated background badge - ไฮไลต์สีเขียวเฉพาะเมื่อเลือกแท็บนี้เท่านั้น
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected
                        ? (widget.item.activeIcon ?? widget.item.icon)
                        : widget.item.icon,
                    size: 24,
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : unselectedIconColor,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // Animated Text Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : unselectedTextColor,
                  letterSpacing: isSelected ? 0.1 : 0.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Model สำหรับแต่ละปุ่มในแถบเมนู
