import 'package:flutter/material.dart';
import 'package:healthymate/features/notifications/controllers/notification_controller.dart';
import 'package:healthymate/features/notifications/models/notification_item.dart';
import 'package:healthymate/features/notifications/pages/notification_settings_page.dart';
import 'package:healthymate/features/notifications/widgets/notification_empty_view.dart';
import 'package:healthymate/features/notifications/widgets/notification_filter_bar.dart';
import 'package:healthymate/features/notifications/widgets/notification_item_card.dart';
import 'package:healthymate/shared/bottom_sheets/food_source_bottom_sheet.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

/// ศูนย์การแจ้งเตือนสุขภาพ (HealthyMate Notification Center)
class NotificationsPage extends StatefulWidget {
  final int userId;
  final Function(int tabIndex, [String? workoutCategory])? onNavigateTab;

  const NotificationsPage({
    super.key,
    required this.userId,
    this.onNavigateTab,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotificationController();
    _controller.addListener(_onControllerChanged);
    _controller.init(widget.userId);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  /// จัดการการแตะแจ้งเตือนเพื่อนำทาง (Deep Linking)
  void _handleNotificationTap(AppNotificationItem item) {
    _controller.markAsRead(item.id);

    if (item.actionType.isNotEmpty) {
      switch (item.actionType) {
        case 'navigate_workout':
          Navigator.of(context).pop();
          widget.onNavigateTab?.call(1); // แท็บ Workout
          break;
        case 'navigate_food_log':
          Navigator.of(context).pop();
          FoodSourceBottomSheet.show(context);
          break;
        case 'navigate_practice':
          Navigator.of(context).pop();
          widget.onNavigateTab?.call(3); // แท็บ Routine
          break;
        case 'navigate_profile':
          Navigator.of(context).pop();
          widget.onNavigateTab?.call(4); // แท็บ Profile
          break;
        case 'navigate_calculator':
          Navigator.of(context).pop();
          widget.onNavigateTab?.call(2); // แท็บ Calculator
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);

    final unreadCount = _controller.unreadCount;
    final filteredList = _controller.filteredNotifications;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'การแจ้งเตือน',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: textPrimary,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // ปุ่มตั้งค่าแจ้งเตือน
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: textPrimary,
              size: 22,
            ),
            tooltip: 'ตั้งค่าการแจ้งเตือน',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsPage(),
                ),
              );
            },
          ),
          // ปุ่มเมนูเพิ่มเติม (อ่านทั้งหมด / ล้างทั้งหมด)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: textPrimary),
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _controller.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ทำเครื่องหมายว่าอ่านทั้งหมดแล้ว'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              } else if (value == 'clear_all') {
                _controller.clearAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ลบการแจ้งเตือนทั้งหมดแล้ว'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(
                      Icons.done_all_rounded,
                      size: 18,
                      color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
                    ),
                    const SizedBox(width: 8),
                    Text('อ่านทั้งหมดแล้ว', style: TextStyle(color: textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: const Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 18, color: Color(0xFFEF4444)),
                    SizedBox(width: 8),
                    Text('ลบทั้งหมด', style: TextStyle(color: Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : Column(
              children: [
                const SizedBox(height: 14),
                // 1. แถบเลือก Filter หมวดหมู่
                NotificationFilterBar(
                  selectedCategory: _controller.selectedCategoryFilter,
                  onSelectCategory: (catId) => _controller.setSelectedCategory(catId),
                ),
                const SizedBox(height: 12),

                // 2. รายการการ์ดแจ้งเตือน
                Expanded(
                  child: filteredList.isEmpty
                      ? NotificationEmptyView(
                          onRefresh: () => _controller.loadNotifications(),
                        )
                      : RefreshIndicator(
                          color: AppTheme.primaryGreen,
                          backgroundColor: cardBg,
                          onRefresh: () => _controller.loadNotifications(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 350),
                                curve: Interval(
                                  (index * 0.05).clamp(0.0, 1.0),
                                  1.0,
                                  curve: Curves.easeOutCubic,
                                ),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 16 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: NotificationItemCard(
                                  item: item,
                                  onTap: () => _handleNotificationTap(item),
                                  onDelete: () => _controller.deleteNotification(item.id),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
