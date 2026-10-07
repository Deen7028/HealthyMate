import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

part 'vitality_bottom_nav_bar_item.dart';

class VitalityBottomNavBar extends StatelessWidget {
  /// Index ของแท็บที่กำลังเลือกอยู่ (0 ถึง 4)
  final int currentIndex;

  /// Callback เมื่อผู้ใช้กดเลือกแท็บ
  final ValueChanged<int> onTap;

  /// Callback เมื่อกดปุ่มกล้อง AI ตรงกลาง (Center FAB)
  final VoidCallback? onCameraTap;

  /// รายการแท็บที่กำหนดเอง (หากต้องการ)
  final List<VitalityNavItem>? customItems;

  const VitalityBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.customItems,
    this.onCameraTap,
  });

  /// รายการ 4 เมนูหลักมาตรฐาน (หน้าหลัก, ออกกำลังกาย, กิจวัตร, โปรไฟล์)
  /// และมีปุ่ม FAB กล้องถ่ายรูปอยู่ตรงกลาง
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = AppTheme.getBackgroundColor(isDark);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : const Color(0xFF1E2822).withValues(alpha: 0.12);

    return BottomAppBar(
      color: navBgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shadowColor: shadowColor,
      shape: const CircularNotchedRectangle(),
      notchMargin: 7.0,
      padding: EdgeInsets.zero,
      height: 64,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // ฝั่งซ้าย: หน้าหลัก (0) และ ออกกำลังกาย (1)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, defaultItems[0]),
                    _buildNavItem(1, defaultItems[1]),
                  ],
                ),
              ),

              // ช่องว่างตรงกลางสำหรับ Center Docked FAB (กล้องถ่ายรูป)
              const SizedBox(width: 60),

              // ฝั่งขวา: กิจวัตร (3) และ โปรไฟล์ (4)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(3, defaultItems[3]),
                    _buildNavItem(4, defaultItems[4]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, VitalityNavItem item) {
    return _VitalityStandardNavItemWidget(
      item: item,
      isSelected: currentIndex == index,
      onTap: () => onTap(index),
    );
  }
}

/// ปุ่มเมนูมาตรฐาน พร้อมแอนิเมชัน Smooth Scale + Soft Pill Highlight เฉพาะแท็บที่เลือก
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
