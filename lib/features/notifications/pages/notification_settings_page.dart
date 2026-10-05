import 'package:flutter/material.dart';
import 'package:healthymate/core/services/notification_service.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// หน้าจอตั้งค่าการแจ้งเตือน (Notification Settings Page)
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _workoutReminder = true;
  bool _routineReminder = true;
  bool _badgeReminder = true;
  bool _weeklyReportReminder = true;
  bool _isLoaded = false;

  // SharedPreferences keys
  static const _kWorkout = 'notif_workout';
  static const _kRoutine = 'notif_routine';
  static const _kBadge = 'notif_badge';
  static const _kWeekly = 'notif_weekly';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workoutReminder = prefs.getBool(_kWorkout) ?? true;
      _routineReminder = prefs.getBool(_kRoutine) ?? true;
      _badgeReminder = prefs.getBool(_kBadge) ?? true;
      _weeklyReportReminder = prefs.getBool(_kWeekly) ?? true;
      _isLoaded = true;
    });
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'ตั้งค่าการแจ้งเตือน',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: !_isLoaded
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildSectionHeader('การออกกำลังกายและเป้าหมาย', textSecondary),
          _buildSettingTile(
            title: 'เตือนการออกกำลังกาย',
            subtitle: 'แจ้งเตือนเมื่อถึงเวลาออกกำลังกายตามเป้าหมายประจำวัน',
            icon: Icons.directions_run_rounded,
            iconColor: const Color(0xFF10B981),
            value: _workoutReminder,
            onChanged: (val) {
              setState(() => _workoutReminder = val);
              _setPref(_kWorkout, val);
            },
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 16),

          // โภชนาการและบันทึกอาหารเอาออกตามคำขอ
          // การตั้งค่าเตือนดื่มน้ำและบันทึกอาหารถูกลบออก

          _buildSectionHeader('กิจวัตรและความสำเร็จ', textSecondary),
          _buildSettingTile(
            title: 'แจ้งเตือนตามกิจวัตร (Routines)',
            subtitle: 'แจ้งเตือนตามเวลาที่คุณกำหนดไว้ในแต่ละกิจวัตร',
            icon: Icons.alarm_rounded,
            iconColor: const Color(0xFF8B5CF6),
            value: _routineReminder,
            onChanged: (val) {
              setState(() => _routineReminder = val);
              _setPref(_kRoutine, val);
            },
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 10),
          _buildSettingTile(
            title: 'ปลดล็อกเหรียญและรางวัล',
            subtitle: 'แจ้งเตือนเมื่อคุณทำภารกิจสำเร็จหรือปลดล็อกเหรียญใหม่',
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFFEAB308),
            value: _badgeReminder,
            onChanged: (val) {
              setState(() => _badgeReminder = val);
              _setPref(_kBadge, val);
            },
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 10),
          _buildSettingTile(
            title: 'รายงานสุขภาพประจำสัปดาห์',
            subtitle: 'สรุปภาพรวมความคืบหน้าทุกวันอาทิตย์',
            icon: Icons.insights_rounded,
            iconColor: const Color(0xFF06B6D4),
            value: _weeklyReportReminder,
            onChanged: (val) {
              setState(() => _weeklyReportReminder = val);
              _setPref(_kWeekly, val);
            },
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppTheme.primaryGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
