import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/index.dart';
// การด์สำหรับแสดงข้อมูลบัญชี
class AccountCard extends StatelessWidget {
  final int activeDeviceCount;
  final VoidCallback onPersonalInfoTap;
  final VoidCallback onConnectedDevicesTap;
  final VoidCallback onExportPdfTap;
  final VoidCallback onDeleteAccountTap;
  final VoidCallback onLogoutTap;

  const AccountCard({
    super.key,
    required this.activeDeviceCount,
    required this.onPersonalInfoTap,
    required this.onConnectedDevicesTap,
    required this.onExportPdfTap,
    required this.onDeleteAccountTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(isDark),
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
            iconBgColor: AppTheme.infoBlueBg,
            iconColor: AppTheme.infoBlue,
            title: 'ข้อมูลส่วนตัว',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiaryDark, size: 20),
            onTap: onPersonalInfoTap,
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 20,
            color: AppTheme.getBorderColor(isDark),
          ),

          // 2. อุปกรณ์ที่เชื่อมต่อ
          _buildActionRow(
            isDark: isDark,
            icon: Icons.devices_rounded,
            iconBgColor: AppTheme.infoBlueBg,
            iconColor: AppTheme.infoBlue,
            title: 'อุปกรณ์ที่เชื่อมต่อ (HealthKit/Connect)',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiaryDark, size: 20),
            onTap: onConnectedDevicesTap,
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 20,
            color: AppTheme.getBorderColor(isDark),
          ),

          // 4. ส่งออกข้อมูล PDF
          _buildActionRow(
            isDark: isDark,
            icon: Icons.picture_as_pdf_outlined,
            iconBgColor: AppTheme.warningOrangeBg,
            iconColor: AppTheme.warningOrange,
            title: 'ส่งออกรายงานสรุปสุขภาพ (PDF)',
            subtitle: 'สร้างรายงานรูปแบบเอกสารสวยงาม',
            trailing: const Icon(Icons.file_download_outlined, color: AppTheme.textTertiaryDark, size: 20),
            onTap: onExportPdfTap,
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 20,
            color: AppTheme.getBorderColor(isDark),
          ),

          // 5. ลบบัญชีและข้อมูลทั้งหมด (PDPA/GDPR)
          _buildActionRow(
            isDark: isDark,
            icon: Icons.delete_forever_rounded,
            iconBgColor: AppTheme.deleteRedBg,
            iconColor: AppTheme.deleteRed,
            title: 'ลบบัญชีและข้อมูลทั้งหมด',
            subtitle: 'ทำลายข้อมูลส่วนบุคคลตามกฎหมาย PDPA/GDPR',
            titleColor: AppTheme.deleteRed,
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.deleteRed, size: 20),
            onTap: onDeleteAccountTap,
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 20,
            color: AppTheme.getBorderColor(isDark),
          ),

          // 6. ออกจากระบบ
          _buildActionRow(
            isDark: isDark,
            icon: Icons.logout_rounded,
            iconBgColor: const Color(0xFFF5F5F5),
            iconColor: const Color(0xFF616161),
            title: 'ออกจากระบบ',
            titleColor: isDark ? Colors.white70 : const Color(0xFF616161),
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
