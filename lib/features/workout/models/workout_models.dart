// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';

/// ประเภทกิจกรรมการออกกำลังกาย
class WorkoutCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final double metValue;
  final bool? _isMovingOverride;

  const WorkoutCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.metValue,
    bool? isMoving,
  }) : _isMovingOverride = isMoving;

  bool get isMoving =>
      _isMovingOverride ??
      (id == 'running' || id == 'walking' || id == 'cycling');

  static const List<WorkoutCategory> defaultCategories = [
    WorkoutCategory(
      id: 'running',
      title: 'วิ่ง (Running)',
      subtitle: 'ติดตามเส้นทาง GPS และความเร็ว',
      icon: Icons.directions_run_rounded,
      metValue: 8.5,
      isMoving: true,
    ),
    WorkoutCategory(
      id: 'walking',
      title: 'เดิน (Walking)',
      subtitle: 'ออกกำลังกายเบาๆ เผาผลาญไขมัน',
      icon: Icons.directions_walk_rounded,
      metValue: 3.8,
      isMoving: true,
    ),
    WorkoutCategory(
      id: 'cycling',
      title: 'ปั่นจักรยาน (Cycling)',
      subtitle: 'บันทึกระยะทางและความเร็วรอบขา',
      icon: Icons.directions_bike_rounded,
      metValue: 7.5,
      isMoving: true,
    ),
    WorkoutCategory(
      id: 'meditation',
      title: 'ทำสมาธิ (Meditation)',
      subtitle: 'ฝึกสติ ผ่อนคลายความเครียด และฟื้นฟูจิตใจ',
      icon: Icons.self_improvement_rounded,
      metValue: 1.5,
      isMoving: false,
    ),
    WorkoutCategory(
      id: 'yoga',
      title: 'โยคะ (Yoga)',
      subtitle: 'ยืดเหยียดกล้ามเนื้อ เสริมความยืดหยุ่นและสมดุล',
      icon: Icons.spa_rounded,
      metValue: 3.0,
      isMoving: false,
    ),
  ];

  static List<WorkoutCategory> _cachedCategories = defaultCategories;

  static List<WorkoutCategory> get categories => _cachedCategories;

  static void updateCategories(List<WorkoutCategory> newCategories) {
    if (newCategories.isNotEmpty) {
      _cachedCategories = List.unmodifiable(newCategories);
    }
  }

  static WorkoutCategory fromMap(Map<String, dynamic> map) {
    final id = map['sCategoryId']?.toString() ?? 'running';
    final title = map['sTitle']?.toString() ?? 'ออกกำลังกาย';
    final subtitle = map['sSubtitle']?.toString() ?? '';
    final met = (map['nMetValue'] as num?)?.toDouble() ?? 1.0;
    final isMoving = ((map['isMoving'] as num?)?.toInt() ?? 0) == 1;

    IconData iconData = Icons.directions_run_rounded;
    final cleanId = id.toLowerCase().trim();
    if (cleanId == 'walking' || cleanId.contains('เดิน')) {
      iconData = Icons.directions_walk_rounded;
    } else if (cleanId == 'cycling' || cleanId.contains('ปั่น')) {
      iconData = Icons.directions_bike_rounded;
    } else if (cleanId == 'meditation' || cleanId.contains('สมาธิ')) {
      iconData = Icons.self_improvement_rounded;
    } else if (cleanId == 'yoga' || cleanId.contains('โยคะ')) {
      iconData = Icons.spa_rounded;
    } else {
      iconData = Icons.directions_run_rounded;
    }

    return WorkoutCategory(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: iconData,
      metValue: met,
      isMoving: isMoving,
    );
  }

  static WorkoutCategory fromIdOrTitle(String? categoryStr) {
    if (categoryStr == null || categoryStr.isEmpty) return categories.first;
    final lower = categoryStr.toLowerCase();
    for (final c in categories) {
      if (c.id == lower ||
          lower.contains(c.id) ||
          c.title.toLowerCase().contains(lower) ||
          (lower.contains('ปั่น') && c.id == 'cycling') ||
          (lower.contains('วิ่ง') && c.id == 'running') ||
          (lower.contains('เดิน') && c.id == 'walking') ||
          (lower.contains('สมาธิ') && c.id == 'meditation') ||
          (lower.contains('โยคะ') && c.id == 'yoga')) {
        return c;
      }
    }
    return categories.first;
  }
}

/// รูปแบบการแสดงผลของแผนที่
enum AppMapType {
  standard('มาตรฐาน (Standard)', Icons.map_outlined),
  satellite('ดาวเทียม (Satellite)', Icons.satellite_alt_outlined),
  hybrid('ไฮบริด (Hybrid)', Icons.layers_outlined);

  final String label;
  final IconData icon;
  const AppMapType(this.label, this.icon);
}

/// สถานะการทำงานของการติดตามกิจกรรม
enum WorkoutState { selectingCategory, initial, running, paused }
