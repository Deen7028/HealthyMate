// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/dashboard/utils/dashboard_ui_helpers.dart';
import 'package:healthymate/features/practice/models/routine_item.dart';
import '../steps/routine_step_category.dart';
import '../steps/routine_step_goal.dart';
import '../style/routine_step_style.dart';

part 'add_routine_dialog_actions.dart';
part 'add_routine_dialog_content.dart';
part 'add_routine_dialog_steps.dart';

// เพิ่มกิจวัตรใหม่
class AddRoutineDialog extends StatefulWidget {
  final Map<String, dynamic>? initialRoutine;

  const AddRoutineDialog({super.key, this.initialRoutine});

  @override
  State<AddRoutineDialog> createState() => _AddRoutineDialogState();
}

class _AddRoutineDialogState extends State<AddRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  int _currentStep = 0; //
  // ตัวควบคุมสำหรับฟอร์ม
  final _titleController = TextEditingController();
  final _targetController = TextEditingController(text: '10');
  final _unitController = TextEditingController(text: 'นาที');
  final _notificationTimeController = TextEditingController(text: '08:00 น.');
  final _durationController = TextEditingController(text: '1');

  final String _durationUnit = 'เดือน';
  String? _selectedLinkedWorkout;
  final List<String> _workoutTypes = [
    'วิ่ง',
    'เดิน',
    'ปั่นจักรยาน',
    'ลู่วิ่งในร่ม',
  ];
  // ตัวแปรสำหรับเก็บข้อมูลกิจกรรม
  RoutineCategory _selectedCategory = RoutineCategory.health;
  IconData? _selectedIcon;
  Color? _selectedColor;
  bool _isNotificationEnabled = true;
  // ไอคอนที่ใช้สำหรับกิจกรรม
  final List<IconData> _availableIcons = [
    Icons.water_drop_rounded,
    Icons.directions_walk_rounded,
    Icons.self_improvement_rounded,
    Icons.restaurant_rounded,
    Icons.favorite_rounded,
    Icons.fitness_center_rounded,
    Icons.bedtime_rounded,
    Icons.book_rounded,
    Icons.directions_run_rounded,
    Icons.nature_people_rounded,
    Icons.pool_rounded,
    Icons.star_rounded,
  ];

  final List<Color> _availableColors = [
    const Color(0xFF0288D1),
    const Color(0xFF4CAF50),
    const Color(0xFF7E57C2),
    const Color(0xFFFF9800),
    const Color(0xFFE91E63),
    const Color(0xFF009688),
    const Color(0xFF3F51B5),
    const Color(0xFFFF5722),
  ];

  @override
  void initState() {
    super.initState();
    // กำหนดค่าเริ่มต้น
    _selectedIcon = _selectedCategory.icon;
    _selectedColor = _selectedCategory.defaultColor;
    // ตรวจสอบข้อมูล หัวข้อกิจกรรม
    if (widget.initialRoutine != null) {
      final r = widget.initialRoutine!;
      _titleController.text = (r['sTitle'] ?? r['title'])?.toString() ?? '';
      _notificationTimeController.text =
          (r['sTime'] ?? r['time'] ?? r['notificationTime'])?.toString() ?? '';

      final targetVal =
          (r['targetValue'] as num?)?.toDouble() ??
          (r['nTargetValue'] as num?)?.toDouble();
      if (targetVal != null && targetVal > 0) {
        _targetController.text = targetVal == targetVal.toInt()
            ? targetVal.toInt().toString()
            : targetVal.toString();
      }

      final unitStr = (r['unit'] ?? r['sUnit'])?.toString();
      if (unitStr != null && unitStr.isNotEmpty) {
        _unitController.text = unitStr;
      }

      final isNotif = r['isNotificationActive'] ?? r['isNotificationEnabled'];
      if (isNotif != null) {
        _isNotificationEnabled = isNotif is bool
            ? isNotif
            : (isNotif as num).toInt() == 1;
      }

      final linked = (r['sLinkedWorkout'] ?? r['linkedWorkoutType'])
          ?.toString();
      if (linked != null &&
          linked.isNotEmpty &&
          _workoutTypes.contains(linked)) {
        _selectedLinkedWorkout = linked;
      }

      final unitLower = (_unitController.text).toLowerCase();
      final titleLower = (_titleController.text).toLowerCase();
      if (unitLower.contains('มล') || titleLower.contains('ดื่มน้ำ')) {
        _selectedCategory = RoutineCategory.water;
      } else if (unitLower.contains('ก้าว') ||
          titleLower.contains('วิ่ง') ||
          titleLower.contains('เดิน') ||
          titleLower.contains('ปั่น')) {
        _selectedCategory = RoutineCategory.fitness;
      } else if (unitLower.contains('มื้อ') ||
          titleLower.contains('ทาน') ||
          titleLower.contains('กิน')) {
        _selectedCategory = RoutineCategory.nutrition;
      } else if (titleLower.contains('สมาธิ') || titleLower.contains('นอน')) {
        _selectedCategory = RoutineCategory.mindfulness;
      }

      final iconCode =
          (r['iconData'] as num?)?.toInt() ?? (r['nIconData'] as num?)?.toInt();
      if (iconCode != null && iconCode > 0) {
        _selectedIcon = DashboardUiHelpers.iconFromCodePoint(
          iconCode,
          fallback: _selectedCategory.icon,
        );
      } else {
        _selectedIcon = _selectedCategory.icon;
      }

      final colorVal =
          (r['color'] as num?)?.toInt() ?? (r['nColor'] as num?)?.toInt();
      if (colorVal != null && colorVal != 0) {
        _selectedColor = Color(colorVal);
      } else {
        _selectedColor = _selectedCategory.defaultColor;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    _notificationTimeController.dispose();
    _durationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildDialog(context);
}
