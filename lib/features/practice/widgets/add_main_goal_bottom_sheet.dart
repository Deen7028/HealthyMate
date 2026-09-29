import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'main_goal_template.dart';
part 'add_main_goal_bottom_sheet_sections.dart';
part 'add_main_goal_bottom_sheet_actions_ui.dart';
part 'add_main_goal_bottom_sheet_actions.dart';

class AddMainGoalBottomSheet extends StatefulWidget {
  const AddMainGoalBottomSheet({super.key});
  @override
  State<AddMainGoalBottomSheet> createState() => _AddMainGoalBottomSheetState();
}

class _AddMainGoalBottomSheetState extends State<AddMainGoalBottomSheet> {
  static const List<MainGoalTemplate> templates = [
    MainGoalTemplate(
      title: 'วิ่งสะสมระยะทาง',
      icon: '🏃♂️',
      defaultUnit: 'กม.',
      linkedWorkout: 'วิ่ง',
      defaultTarget: 50.0,
    ),
    MainGoalTemplate(
      title: 'ปั่นจักรยานสะสมระยะทาง',
      icon: '🚴♂️',
      defaultUnit: 'กม.',
      linkedWorkout: 'ปั่นจักรยาน',
      defaultTarget: 100.0,
    ),
    MainGoalTemplate(
      title: 'เผาผลาญแคลอรีรวม',
      icon: '🔥',
      defaultUnit: 'แคล',
      linkedWorkout: 'แคลอรี',
      defaultTarget: 5000.0,
    ),
    MainGoalTemplate(
      title: 'เป้าหมายลดน้ำหนัก',
      icon: '⚖️',
      defaultUnit: 'กก.',
      linkedWorkout: 'น้ำหนัก',
      defaultTarget: 3.0,
    ),
  ];
  int _selectedTemplateIndex = 0;
  late TextEditingController _targetController;
  // Deadline selection: '1_week', '1_month', 'custom'
  String _deadlineType = '1_month';
  DateTime _customDeadlineDate = DateTime.now().add(const Duration(days: 30));
  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(
      text: templates[0].defaultTarget == templates[0].defaultTarget.toInt()
          ? templates[0].defaultTarget.toInt().toString()
          : templates[0].defaultTarget.toString(),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final surfaceBg = AppTheme.getSurfaceColor(isDark);
    final selectedTemplate = templates[_selectedTemplateIndex];
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF4A584E)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._buildHeader(isDark, textPrimary, textSecondary),
            ..._buildGoalTypeSection(
              isDark,
              surfaceBg,
              borderColor,
              textPrimary,
            ),
            ..._buildTargetSection(
              isDark,
              surfaceBg,
              borderColor,
              textPrimary,
              textSecondary,
              selectedTemplate,
            ),
            ..._buildDeadlineSection(
              isDark,
              surfaceBg,
              borderColor,
              textPrimary,
            ),
            ..._buildSaveButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineOption({
    required bool isDark,
    required Color surfaceBg,
    required Color borderColor,
    required Color textPrimary,
    required String type,
    required String label,
    VoidCallback? onTapCustom,
  }) {
    final isSelected = _deadlineType == type;
    return InkWell(
      onTap: () {
        if (type == 'custom') {
          if (onTapCustom != null) onTapCustom();
        } else {
          setState(() {
            _deadlineType = type;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF23352A) : const Color(0xFFE8F5E9))
              : surfaceBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark
                      ? AppTheme.primaryLightGreen
                      : const Color(0xFF0F9C58))
                : borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              type == 'custom' ? Icons.calendar_month : Icons.timer_outlined,
              size: 20,
              color: isSelected
                  ? (isDark
                        ? AppTheme.primaryLightGreen
                        : const Color(0xFF0F9C58))
                  : (isDark ? const Color(0xFF6B7E72) : Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark
                          ? AppTheme.primaryLightGreen
                          : const Color(0xFF006432))
                    : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
