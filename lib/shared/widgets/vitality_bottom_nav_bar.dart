import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';

/// แถบเมนูนำทางด้านล่าง (Bottom Navigation Bar) สไตล์ Vitality Logic
///
/// สามารถเรียกใช้ได้โดย:
/// ```dart
/// import 'package:healthymate/shared/widgets/vitality_bottom_nav_bar.dart';
/// // หรือ
/// import 'package:healthymate/shared/index.dart';
///
/// VitalityBottomNavBar(
///   currentIndex: _selectedIndex,
///   onTap: (index) => setState(() => _selectedIndex = index),
/// )
/// ```
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
    ),
    VitalityNavItem(
      index: 1,
      label: 'ออกกำลังกาย',
      icon: Icons.fitness_center_rounded,
    ),
    VitalityNavItem(
      index: 2,
      label: 'สุขภาพ',
      icon: Icons.calculate_outlined,
      isCenterHighlight: true, // แท็บสุขภาพไอคอนวงกลมเด่นตรงกลาง
    ),
    VitalityNavItem(
      index: 3,
      label: 'กิจวัตร',
      icon: Icons.calendar_month_outlined,
    ),
    VitalityNavItem(
      index: 4,
      label: 'โปรไฟล์',
      icon: Icons.person_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = customItems ?? defaultItems;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppTheme.borderLight, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          if (item.isCenterHighlight) {
            return _buildCenterHighlightItem(item);
          }
          return _buildStandardItem(item);
        }).toList(),
      ),
    );
  }

  Widget _buildStandardItem(VitalityNavItem item) {
    final isSelected = currentIndex == item.index;

    return InkWell(
      onTap: () => onTap(item.index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 24,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterHighlightItem(VitalityNavItem item) {
    final isSelected = currentIndex == item.index;

    return InkWell(
      onTap: () => onTap(item.index),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.activeTabGreen : const Color(0xFFE8F3EB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 24,
              color: isSelected ? Colors.white : AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Model สำหรับแต่ละปุ่มในแถบเมนู
class VitalityNavItem {
  final int index;
  final String label;
  final IconData icon;
  final bool isCenterHighlight;

  const VitalityNavItem({
    required this.index,
    required this.label,
    required this.icon,
    this.isCenterHighlight = false,
  });
}

