import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';

class VitalityBottomNavBar extends StatelessWidget {
  /// Index ของแท็บที่กำลังเลือกอยู่ (0 ถึง 4)
  final int currentIndex;

  /// Callback เมื่อผู้ใช้กดเลือกแท็บ
  final ValueChanged<int> onTap;

  /// รายการ Tab Items (หากไม่ใส่จะใช้ 5 เมนูหลักมาตรฐานของ HealthyMate)
  final List<VitalityNavItem>? customItems;

  const VitalityBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.customItems,
  });

  /// รายการ 5 เมนูหลักมาตรฐาน
  static const List<VitalityNavItem> defaultItems = [
    VitalityNavItem(
      index: 0,
      label: 'หน้าหลัก',
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
    ),
    VitalityNavItem(
      index: 1,
      label: 'ออกกำลังกาย',
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center_rounded,
    ),
    VitalityNavItem(
      index: 2,
      label: 'สุขภาพ',
      icon: Icons.calculate_outlined,
      activeIcon: Icons.calculate_rounded,
      isCenterHighlight: true, // แท็บสุขภาพไอคอนวงกลมเด่นตรงกลาง
    ),
    VitalityNavItem(
      index: 3,
      label: 'กิจวัตร',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
    ),
    VitalityNavItem(
      index: 4,
      label: 'โปรไฟล์',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = customItems ?? defaultItems;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEAEFEA), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E2822).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: items.map((item) {
                return _VitalityStandardNavItemWidget(
                  item: item,
                  isSelected: currentIndex == item.index,
                  onTap: () => onTap(item.index),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// ปุ่มเมนูมาตรฐาน พร้อมแอนิเมชัน Smooth Scale + Soft Pill Highlight เฉพาะแท็บที่เลือก
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
  State<_VitalityStandardNavItemWidget> createState() => _VitalityStandardNavItemWidgetState();
}

class _VitalityStandardNavItemWidgetState extends State<_VitalityStandardNavItemWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                    isSelected ? (widget.item.activeIcon ?? widget.item.icon) : widget.item.icon,
                    size: 24,
                    color: isSelected ? AppTheme.primaryGreen : const Color(0xFF8C9890),
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
                  color: isSelected ? AppTheme.primaryGreen : const Color(0xFF6F7C73),
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
class VitalityNavItem {
  final int index;
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final bool isCenterHighlight;

  const VitalityNavItem({
    required this.index,
    required this.label,
    required this.icon,
    this.activeIcon,
    this.isCenterHighlight = false,
  });
}


