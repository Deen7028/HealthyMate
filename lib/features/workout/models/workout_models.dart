import 'package:flutter/material.dart';

/// ประเภทกิจกรรมการออกกำลังกาย
class WorkoutCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final double metValue;

  const WorkoutCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.metValue,
  });

  bool get isMoving => id == 'running' || id == 'walking' || id == 'cycling';

  static const List<WorkoutCategory> categories = [
    WorkoutCategory(
      id: 'running',
      title: 'วิ่ง (Running)',
      subtitle: 'ติดตามเส้นทาง GPS และความเร็ว',
      icon: Icons.directions_run_rounded,
      metValue: 8.5,
    ),
    WorkoutCategory(
      id: 'walking',
      title: 'เดิน (Walking)',
      subtitle: 'ออกกำลังกายเบาๆ เผาผลาญไขมัน',
      icon: Icons.directions_walk_rounded,
      metValue: 3.8,
    ),
    WorkoutCategory(
      id: 'cycling',
      title: 'ปั่นจักรยาน (Cycling)',
      subtitle: 'บันทึกระยะทางและความเร็วรอบขา',
      icon: Icons.directions_bike_rounded,
      metValue: 7.5,
    ),
    WorkoutCategory(
      id: 'meditation',
      title: 'ทำสมาธิ (Meditation)',
      subtitle: 'ฝึกสติ ผ่อนคลายความเครียด และฟื้นฟูจิตใจ',
      icon: Icons.self_improvement_rounded,
      metValue: 1.5,
    ),
    WorkoutCategory(
      id: 'yoga',
      title: 'โยคะ (Yoga)',
      subtitle: 'ยืดเหยียดกล้ามเนื้อ เสริมความยืดหยุ่นและสมดุล',
      icon: Icons.spa_rounded,
      metValue: 3.0,
    ),
  ];

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
