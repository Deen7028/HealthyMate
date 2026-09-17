import 'package:flutter/material.dart';
import 'package:healthymate/core/services/theme_service.dart';

class SettingsCard extends StatelessWidget {
  final bool isLocationEnabled;
  final String selectedUnit;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onLocationTap;
  final VoidCallback onUnitPickerTap;

  const SettingsCard({
    super.key,
    required this.isLocationEnabled,
    required this.selectedUnit,
    required this.onDarkModeChanged,
    required this.onLocationTap,
    required this.onUnitPickerTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. โหมดมืด
          _buildActionRow(
            isDark: isDark,
            icon: Icons.nightlight_round,
            iconBgColor: const Color(0xFFD6E4FF),
            iconColor: const Color(0xFF3366FF),
            title: 'โหมดมืด',
            subtitle: 'Switch between light and dark themes',
            trailing: Switch(
              value: isDark,
              activeTrackColor: Theme.of(context).colorScheme.primary,
              activeThumbColor: Colors.white,
              onChanged: onDarkModeChanged,
            ),
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 20,
            color: isDark ? const Color(0xFF2E3D34) : const Color(0xFFF0F2EE),
          ),

          // 2. บริการตำแหน่ง
          _buildActionRow(
            isDark: isDark,
            icon: Icons.location_on_rounded,
            iconBgColor: const Color(0xFFD6E8FE),
            iconColor: const Color(0xFF2D7FF9),
            title: 'บริการตำแหน่ง',
            subtitle: 'Used for tracking outdoor runs and routes',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLocationEnabled ? 'เปิดใช้งาน' : 'ปิดอยู่',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isLocationEnabled ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF8C968E), size: 20),
              ],
            ),
            onTap: onLocationTap,
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 20,
            color: isDark ? const Color(0xFF2E3D34) : const Color(0xFFF0F2EE),
          ),

          // 3. หน่วยวัด
          _buildActionRow(
            isDark: isDark,
            icon: Icons.square_foot_rounded,
            iconBgColor: const Color(0xFFD3E6FD),
            iconColor: const Color(0xFF3278D8),
            title: 'หน่วยวัด',
            subtitle: selectedUnit,
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF8C968E), size: 20),
            onTap: onUnitPickerTap,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required bool isDark,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final defaultTitleColor = isDark ? Colors.white : const Color(0xFF1E2822);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: defaultTitleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8C968E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
