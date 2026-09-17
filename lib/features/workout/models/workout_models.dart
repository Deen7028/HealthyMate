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

  static const List<WorkoutCategory> categories = [
    WorkoutCategory(
      id: 'running',
      title: 'วิ่งกลางแจ้ง (Outdoor Run)',
      subtitle: 'ติดตามเส้นทาง GPS และความเร็ว',
      icon: Icons.directions_run_rounded,
      metValue: 8.5,
    ),
    WorkoutCategory(
      id: 'walking',
      title: 'เดินเร็ว (Brisk Walk)',
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
      id: 'treadmill',
      title: 'ลู่วิ่งในร่ม (Treadmill)',
      subtitle: 'วิ่งในฟิตเนสหรือที่บ้าน',
      icon: Icons.fitness_center_rounded,
      metValue: 7.5,
    ),
  ];
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
