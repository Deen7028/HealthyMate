import 'package:flutter/material.dart';

enum RoutineCategory {
  water('ดื่มน้ำ', Icons.water_drop_rounded, Color(0xFF2E5327)),
  fitness('ออกกำลังกาย', Icons.directions_walk_rounded, Color(0xFF2E5327)),
  mindfulness('ทำสมาธิ', Icons.self_improvement_rounded, Color(0xFF2E5327)),
  nutrition('มื้ออาหาร', Icons.restaurant_rounded, Color(0xFF2E5327)),
  health('สุขภาพ', Icons.favorite_rounded, Color(0xFF2E5327)),
  custom('อื่นๆ', Icons.star_rounded, Color(0xFF2E5327));

  final String label;
  final IconData icon;
  final Color defaultColor;

  const RoutineCategory(this.label, this.icon, this.defaultColor);
}

class RoutineItem {
  final String id;
  String title;
  RoutineCategory category;
  IconData iconData;
  Color color;
  double targetValue;
  double currentValue;
  String unit;
  bool isNotificationEnabled;
  String notificationTime;
  List<String> repeatDays;
  String? linkedWorkoutType; // 🔥 เพิ่มบรรทัดนี้

  RoutineItem({
    required this.id,
    required this.title,
    required this.category,
    required this.iconData,
    required this.color,
    required this.targetValue,
    this.currentValue = 0,
    required this.unit,
    this.isNotificationEnabled = true,
    required this.notificationTime,
    required this.repeatDays,
    this.linkedWorkoutType, // 🔥 เพิ่มบรรทัดนี้
  });

  bool get isCompleted => currentValue >= targetValue;
  double get progressRatio => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
  int get progressPercent => (progressRatio * 100).toInt();

  RoutineItem copyWith({
    String? id,
    String? title,
    RoutineCategory? category,
    IconData? iconData,
    Color? color,
    double? targetValue,
    double? currentValue,
    String? unit,
    bool? isNotificationEnabled,
    String? notificationTime,
    List<String>? repeatDays,
    String? linkedWorkoutType,
  }) {
    return RoutineItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      iconData: iconData ?? this.iconData,
      color: color ?? this.color,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      repeatDays: repeatDays ?? List.from(this.repeatDays),
      linkedWorkoutType: linkedWorkoutType ?? this.linkedWorkoutType,
    );
  }
}
