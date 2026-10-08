import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

part 'routine_step_style_modes.dart';
part 'routine_step_style_single_time.dart';
part 'routine_step_style_multiple_times.dart';
part 'routine_step_style_interval.dart';
part 'routine_step_style_content.dart';
part 'routine_step_style_selectors.dart';
//  Step 3: ตั้งค่าการแจ้งเตือน เลือกรูปแบบเวลา loop 
class RoutineStepStyle extends StatefulWidget {
  final Color btnColor;
  final bool isNotificationEnabled;
  final TextEditingController notificationTimeController;
  final ValueChanged<bool> onToggleNotification;
  final IconData? selectedIcon;
  final Color? selectedColor;
  final List<IconData> availableIcons;
  final List<Color> availableColors;
  final ValueChanged<IconData?> onSelectIcon;
  final ValueChanged<Color?> onSelectColor;

  const RoutineStepStyle({
    super.key,
    required this.btnColor,
    required this.isNotificationEnabled,
    required this.notificationTimeController,
    required this.onToggleNotification,
    required this.selectedIcon,
    required this.selectedColor,
    required this.availableIcons,
    required this.availableColors,
    required this.onSelectIcon,
    required this.onSelectColor,
  });

  @override
  State<RoutineStepStyle> createState() => _RoutineStepStyleState();
}

class _RoutineStepStyleState extends State<RoutineStepStyle> {
  int _selectedModeIndex = 0; // 0: เวลาเดียว, 1: หลายช่วงเวลา, 2: ความถี่
  List<String> _multipleTimes = ['08:00', '12:00', '18:00'];
  String _selectedInterval = 'ทุก 2 ชั่วโมง';

  final List<String> _intervalOptions = [
    'ทุก 1 ชั่วโมง',
    'ทุก 2 ชั่วโมง',
    'ทุก 3 ชั่วโมง',
    'ทุก 4 ชั่วโมง',
  ];

  @override
  void initState() {
    super.initState();
    _parseInitialNotificationText();
  }

  void _parseInitialNotificationText() {
    final text = widget.notificationTimeController.text.trim();
    if (text.startsWith('ทุก ')) {
      _selectedModeIndex = 2;
      if (_intervalOptions.contains(text)) {
        _selectedInterval = text;
      }
    } else if (text.contains(',')) {
      _selectedModeIndex = 1;
      final parts = text
          .split(',')
          .map((e) => e.replaceAll('น.', '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        _multipleTimes = parts;
      }
    } else {
      _selectedModeIndex = 0;
    }
  }

  void _updateControllerText() {
    if (_selectedModeIndex == 0) {
      if (widget.notificationTimeController.text.isEmpty ||
          widget.notificationTimeController.text.startsWith('ทุก ') ||
          widget.notificationTimeController.text.contains(',')) {
        widget.notificationTimeController.text = '08:00 น.';
      }
    } else if (_selectedModeIndex == 1) {
      widget.notificationTimeController.text = _multipleTimes
          .map((t) => '$t น.')
          .join(', ');
    } else if (_selectedModeIndex == 2) {
      widget.notificationTimeController.text = _selectedInterval;
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.btnColor,
              onPrimary: Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => _buildStepStyle(context);
}
