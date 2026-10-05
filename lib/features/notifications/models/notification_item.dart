import 'package:flutter/material.dart';

/// ประเภทของการแจ้งเตือนในระบบ HealthyMate
enum NotificationCategoryType {
  all('all', 'ทั้งหมด', Icons.grid_view_rounded, Color(0xFF10B981)),
  workout('workout', 'ออกกำลังกาย', Icons.directions_run_rounded, Color(0xFF10B981)),
  nutrition('nutrition', 'อาหารและน้ำ', Icons.restaurant_rounded, Color(0xFFF59E0B)),
  routine('routine', 'กิจวัตร', Icons.alarm_rounded, Color(0xFF8B5CF6)),
  badge('badge', 'เหรียญรางวัล', Icons.emoji_events_rounded, Color(0xFFEAB308)),
  health('health', 'สุขภาพ', Icons.favorite_rounded, Color(0xFFEF4444));

  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const NotificationCategoryType(this.id, this.label, this.icon, this.color);

  static NotificationCategoryType fromString(String? typeStr) {
    if (typeStr == null || typeStr.isEmpty) return NotificationCategoryType.routine;
    final lower = typeStr.toLowerCase().trim();
    for (final cat in NotificationCategoryType.values) {
      if (cat.id == lower || lower.contains(cat.id)) return cat;
    }
    if (lower.contains('วิ่ง') || lower.contains('ออกกำลัง') || lower.contains('workout')) {
      return NotificationCategoryType.workout;
    }
    if (lower.contains('อาหาร') || lower.contains('น้ำ') || lower.contains('food') || lower.contains('meal')) {
      return NotificationCategoryType.nutrition;
    }
    if (lower.contains('เหรียญ') || lower.contains('badge') || lower.contains('รางวัล')) {
      return NotificationCategoryType.badge;
    }
    if (lower.contains('bmi') || lower.contains('น้ำหนัก') || lower.contains('health')) {
      return NotificationCategoryType.health;
    }
    return NotificationCategoryType.routine;
  }
}

/// โมเดลข้อมูลการแจ้งเตือน
class AppNotificationItem {
  final int id;
  final int userId;
  final NotificationCategoryType category;
  final String title;
  final String message;
  final String actionType;
  final String actionPayload;
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationItem({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.message,
    this.actionType = '',
    this.actionPayload = '',
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotificationItem.fromMap(Map<String, dynamic> map) {
    return AppNotificationItem(
      id: (map['nNotificationId'] as num?)?.toInt() ?? 0,
      userId: (map['nUserId'] as num?)?.toInt() ?? 0,
      category: NotificationCategoryType.fromString(map['sType']?.toString()),
      title: map['sTitle']?.toString() ?? 'แจ้งเตือน',
      message: map['sMessage']?.toString() ?? '',
      actionType: map['sActionType']?.toString() ?? '',
      actionPayload: map['sActionPayload']?.toString() ?? '',
      isRead: ((map['isRead'] as num?)?.toInt() ?? 0) == 1,
      createdAt: map['dtCreatedAt'] != null
          ? DateTime.tryParse(map['dtCreatedAt'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AppNotificationItem copyWith({
    int? id,
    int? userId,
    NotificationCategoryType? category,
    String? title,
    String? message,
    String? actionType,
    String? actionPayload,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      actionType: actionType ?? this.actionType,
      actionPayload: actionPayload ?? this.actionPayload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
