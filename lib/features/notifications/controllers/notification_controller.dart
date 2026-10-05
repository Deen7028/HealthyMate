import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/features/notifications/models/notification_item.dart';

/// คอนโทรลเลอร์บริหารจัดการ State สำหรับหน้าศูนย์การแจ้งเตือน (NotificationsPage)
class NotificationController extends ChangeNotifier {
  int _userId = 0;
  bool isLoading = true;
  List<AppNotificationItem> _notifications = [];
  String _selectedCategoryFilter = 'all';
  bool _isDisposed = false;

  int get userId => _userId;
  String get selectedCategoryFilter => _selectedCategoryFilter;

  List<AppNotificationItem> get allNotifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// รายการแจ้งเตือนที่ผ่านการกรองตามหมวดหมู่
  List<AppNotificationItem> get filteredNotifications {
    if (_selectedCategoryFilter == 'all') {
      return _notifications;
    }
    return _notifications
        .where((n) => n.category.id == _selectedCategoryFilter)
        .toList();
  }

  void setSelectedCategory(String categoryId) {
    if (_selectedCategoryFilter != categoryId) {
      _selectedCategoryFilter = categoryId;
      _safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed && hasListeners) {
      notifyListeners();
    }
  }

  /// โหลดข้อมูลการแจ้งเตือน
  Future<void> init(int userId) async {
    _userId = userId;
    await loadNotifications();
  }

  Future<void> loadNotifications() async {
    isLoading = true;
    _safeNotifyListeners();

    try {
      // 1. ตรวจสอบว่ามีข้อมูลแจ้งเตือนเริ่มต้นหรือยัง หากยังไม่มีให้สร้าง Welcome/Smart Insights ตั้งต้น
      final rawList = await AppDatabase.instance.getNotifications(_userId);

      if (rawList.isEmpty) {
        await _seedInitialSmartNotifications();
      }

      final updatedList = await AppDatabase.instance.getNotifications(_userId);
      _notifications = updatedList.map((m) => AppNotificationItem.fromMap(m)).toList();
    } catch (e) {
      debugPrint('NotificationController.loadNotifications error: $e');
    } finally {
      isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// สร้างแจ้งเตือนอัจฉริยะเริ่มต้นเพื่อให้ผู้ใช้ได้รับคำแนะนำสุขภาพ
  Future<void> _seedInitialSmartNotifications() async {
    // 1. แจ้งเตือนยินดีต้อนรับสู่ HealthyMate
    await AppDatabase.instance.insertNotification(
      userId: _userId,
      type: 'routine',
      title: 'ยินดีต้อนรับสู่ HealthyMate 🍏',
      message: 'เริ่มต้นเส้นทางสุขภาพที่ดี ติดตามการออกกำลังกาย บันทึกอาหาร และพิชิตเป้าหมายประจำวันของคุณ',
      actionType: 'navigate_practice',
    );

    // 2. แจ้งเตือนดื่มน้ำ
    await AppDatabase.instance.insertNotification(
      userId: _userId,
      type: 'nutrition',
      title: '💧 อย่าลืมดื่มน้ำให้เพียงพอ',
      message: 'การดื่มน้ำอย่างน้อยวันละ 8 แก้วช่วยเพิ่มการเผาผลาญและทำให้ผิวพรรณสดใส',
      actionType: 'navigate_food_log',
    );

    // 3. แจ้งเตือนออกกำลังกาย
    await AppDatabase.instance.insertNotification(
      userId: _userId,
      type: 'workout',
      title: '🏃‍♂️ ขยับร่างกายเพื่อสุขภาพที่ดี',
      message: 'วันนี้คุณมีแผนจะออกไปวิ่งหรือเดินเร็วหรือยัง? แตะเพื่อเริ่มจับเวลากิจกรรมเลย',
      actionType: 'navigate_workout',
    );

    // 4. แจ้งเตือนเหรียญรางวัล
    await AppDatabase.instance.insertNotification(
      userId: _userId,
      type: 'badge',
      title: '🏆 มีเหรียญรางวัลใหม่รอคุณอยู่!',
      message: 'ออกกำลังกายครั้งแรกหรือบันทึกมื้ออาหารเพื่อปลดล็อกเหรียญความสำเร็จในโปรไฟล์',
      actionType: 'navigate_profile',
    );
  }

  /// เพิ่มแจ้งเตือนใหม่เข้าระบบ
  Future<void> addNotification({
    required String type,
    required String title,
    required String message,
    String actionType = '',
    String actionPayload = '',
  }) async {
    if (_userId <= 0) return;
    await AppDatabase.instance.insertNotification(
      userId: _userId,
      type: type,
      title: title,
      message: message,
      actionType: actionType,
      actionPayload: actionPayload,
    );
    await loadNotifications();
  }

  /// ทำเครื่องหมายว่าอ่านแล้ว
  Future<void> markAsRead(int notificationId) async {
    await AppDatabase.instance.markNotificationAsRead(notificationId);
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _safeNotifyListeners();
    }
  }

  /// ทำเครื่องหมายว่าอ่านแล้วทั้งหมด
  Future<void> markAllAsRead() async {
    await AppDatabase.instance.markAllNotificationsAsRead(_userId);
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _safeNotifyListeners();
  }

  /// ลบการแจ้งเตือนรายการเดียว
  Future<void> deleteNotification(int notificationId) async {
    await AppDatabase.instance.deleteNotification(notificationId);
    _notifications.removeWhere((n) => n.id == notificationId);
    _safeNotifyListeners();
  }

  /// ล้างการแจ้งเตือนทั้งหมด
  Future<void> clearAll() async {
    await AppDatabase.instance.clearAllNotifications(_userId);
    _notifications.clear();
    _safeNotifyListeners();
  }
}
