import 'package:flutter/material.dart';
import 'package:healthymate/core/services/theme_service.dart';

class AccountCard extends StatelessWidget {
  final int activeDeviceCount;
  final VoidCallback onPersonalInfoTap;
  final VoidCallback onConnectedDevicesTap;
  final VoidCallback onLogoutTap;

  const AccountCard({
    super.key,
    required this.activeDeviceCount,
    required this.onPersonalInfoTap,
    required this.onConnectedDevicesTap,
    required this.onLogoutTap,
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
          // 1. ข้อมูลส่วนตัว
          _buildActionRow(
            isDark: isDark,
            icon: Icons.badge_outlined,
            iconBgColor: const Color(0xFFD7E5F5),
            iconColor: const Color(0xFF3F77B0),
            title: 'ข้อมูลส่วนตัว',
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF8C968E), size: 20),
            onTap: onPersonalInfoTap,
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 20,
            color: isDark ? const Color(0xFF2E3D34) : const Color(0xFFF0F2EE),
          ),

          // 2. อุปกรณ์ที่เชื่อมต่อ
          _buildActionRow(
            isDark: isDark,
            icon: Icons.devices_rounded,
            iconBgColor: const Color(0xFFDCEAF7),
            iconColor: const Color(0xFF4587CA),
            title: 'อุปกรณ์ที่เชื่อมต่อ',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E7DF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activeDeviceCount Active',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A6559),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF8C968E), size: 20),
              ],
            ),
            onTap: onConnectedDevicesTap,
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 20,
            color: isDark ? const Color(0xFF2E3D34) : const Color(0xFFF0F2EE),
          ),

          // 3. ออกจากระบบ
          _buildActionRow(
            isDark: isDark,
            icon: Icons.logout_rounded,
            iconBgColor: const Color(0xFFFFEBEE),
            iconColor: const Color(0xFFD93838),
            title: 'ออกจากระบบ',
            titleColor: const Color(0xFFD93838),
            trailing: const SizedBox.shrink(),
            onTap: onLogoutTap,
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
    Color? titleColor,
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
                      color: titleColor ?? defaultTitleColor,
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
