// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';

/// ตัวช่วยจัดเตรียม Icon และ Color สำหรับ UI ของ Dashboard ตามประเภทของกิจวัตร/เป้าหมาย
class DashboardUiHelpers {
  /// แมป IconData ที่ใช้บ่อยตามรหัส codePoint
  static const Map<int, IconData> knownIcons = {
    0xe6de: Icons.water_drop_rounded,
    0xe1e1: Icons.directions_walk_rounded,
    0xf0153: Icons.self_improvement_rounded,
    0xf322: Icons.restaurant_rounded,
    0xe25b: Icons.favorite_rounded,
    0xe28d: Icons.fitness_center_rounded,
    0xf592: Icons.bedtime_rounded,
    0xe0ef: Icons.book_rounded,
    0xe1e0: Icons.directions_run_rounded,
    0xf0027: Icons.nature_people_rounded,
    0xe4c3: Icons.pool_rounded,
    0xe5f9: Icons.star_rounded,
    0xe08f: Icons.flag_rounded,
    0xe072: Icons.alarm_rounded,
    0xe3d9: Icons.medical_services_rounded,
  };

  static IconData iconFromCodePoint(int codePoint, {IconData fallback = Icons.star_rounded}) {
    return knownIcons[codePoint] ?? fallback;
  }

  static Color getRoutineColor(Map<String, dynamic> routine, int index) {
    if (routine['color'] != null) return Color((routine['color'] as num).toInt());
    final title = routine['sTitle']?.toString().toLowerCase() ?? '';
    if (title.contains('น้ำ') || title.contains('drink') || title.contains('water')) return const Color(0xFF0288D1);
    if (title.contains('วิ่ง') || title.contains('เดิน') || title.contains('work')) return const Color(0xFF4CAF50);
    if (title.contains('สมาธิ') || title.contains('นอน') || title.contains('sleep')) return const Color(0xFF7E57C2);
    if (title.contains('อาหาร') || title.contains('กิน') || title.contains('eat')) return const Color(0xFFFF9800);
    if (title.contains('ยา') || title.contains('pill') || title.contains('health')) return const Color(0xFFE91E63);
    const defaultColors = [Color(0xFF0F9C58), Color(0xFF0288D1), Color(0xFFFF9800), Color(0xFF7E57C2), Color(0xFFE91E63)];
    return defaultColors[index % defaultColors.length];
  }

  static IconData getRoutineIcon(Map<String, dynamic> routine, int index) {
    if (routine['iconData'] != null) {
      final codePoint = (routine['iconData'] as num).toInt();
      final icon = knownIcons[codePoint];
      if (icon != null) return icon;
    }
    final title = routine['sTitle']?.toString().toLowerCase() ?? '';
    if (title.contains('น้ำ') || title.contains('drink') || title.contains('water')) return Icons.water_drop_rounded;
    if (title.contains('วิ่ง') || title.contains('เดิน') || title.contains('work')) return Icons.directions_walk_rounded;
    if (title.contains('สมาธิ') || title.contains('นอน') || title.contains('sleep')) return Icons.self_improvement_rounded;
    if (title.contains('อาหาร') || title.contains('กิน') || title.contains('eat')) return Icons.restaurant_rounded;
    if (title.contains('ยา') || title.contains('pill') || title.contains('health')) return Icons.medical_services_rounded;
    const defaultIcons = [Icons.flag_rounded, Icons.alarm_rounded, Icons.star_rounded, Icons.favorite_rounded];
    return defaultIcons[index % defaultIcons.length];
  }
}