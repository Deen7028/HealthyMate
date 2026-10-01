import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/index.dart';

part 'settings_card_action_row.dart';

class SettingsCard extends StatelessWidget {
  final bool isLocationEnabled;
  final String selectedUnit;
  final bool hasGeminiApiKey;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onLocationTap;
  final VoidCallback onUnitPickerTap;
  final VoidCallback onGeminiApiKeyTap;

  const SettingsCard({
    super.key,
    required this.isLocationEnabled,
    required this.selectedUnit,
    this.hasGeminiApiKey = false,
    required this.onDarkModeChanged,
    required this.onLocationTap,
    required this.onUnitPickerTap,
    required this.onGeminiApiKeyTap,
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
          // 1. โหมดมืด
          _buildActionRow(
            isDark: isDark,
            iconWidget: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween<double>(begin: 0.75, end: 1.0).animate(animation),
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                key: ValueKey(isDark),
                color: isDark
                    ? const Color(0xFF8C9EFF)
                    : AppTheme.warningOrange,
                size: 20,
              ),
            ),
            iconBgColor: isDark
                ? const Color(0xFF1A237E).withValues(alpha: 0.35)
                : AppTheme.warningOrangeBg,
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
            color: AppTheme.getBorderColor(isDark),
          ),

          // 2. บริการตำแหน่ง
          _buildActionRow(
            isDark: isDark,
            icon: Icons.location_on_rounded,
            iconBgColor: AppTheme.infoBlueBg,
            iconColor: AppTheme.infoBlue,
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
                    color: isLocationEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiaryDark,
                  size: 20,
                ),
              ],
            ),
            onTap: onLocationTap,
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 20,
            color: AppTheme.getBorderColor(isDark),
          ),

          // 3. หน่วยวัด
          _buildActionRow(
            isDark: isDark,
            icon: Icons.square_foot_rounded,
            iconBgColor: AppTheme.infoBlueBg,
            iconColor: AppTheme.infoBlue,
            title: 'หน่วยวัด',
            subtitle: selectedUnit,
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiaryDark,
              size: 20,
            ),
            onTap: onUnitPickerTap,
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 20,
            color: AppTheme.getBorderColor(isDark),
          ),

          // 4. Gemini AI Key (สำหรับสแกนอาหาร)
          _buildActionRow(
            isDark: isDark,
            icon: Icons.vpn_key_rounded,
            iconBgColor: AppTheme.successGreenBg,
            iconColor: AppTheme.successGreen,
            title: 'Google Gemini API Key',
            subtitle: hasGeminiApiKey
                ? 'ตั้งค่าแล้ว (พร้อมใช้งาน AI จริง)'
                : 'ยังไม่ได้ตั้งค่า (กดเพื่อกรอก Key)',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasGeminiApiKey)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreenBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AI Active',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiaryDark,
                  size: 20,
                ),
              ],
            ),
            onTap: onGeminiApiKeyTap,
          ),
        ],
      ),
    );
  }
}
