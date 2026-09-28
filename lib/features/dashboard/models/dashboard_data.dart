import 'package:flutter/material.dart';

class DailyChecklistItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  bool isCompleted;

  DailyChecklistItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isCompleted = false,
  });
}

class DashboardStats {
  double distanceKm;
  int activeTimeMinutes;
  int caloriesBurned;
  int stepCount;

  DashboardStats({
    this.distanceKm = 4.2,
    this.activeTimeMinutes = 45,
    this.caloriesBurned = 320,
    this.stepCount = 6840,
  });
}
