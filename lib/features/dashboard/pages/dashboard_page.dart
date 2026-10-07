// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (dashboard page)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/core/services/routine_state/routine_state_notifier.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/shared/widgets/fade_slide_entrance.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/features/practice/widgets/add_main_goal_bottom_sheet.dart';
import 'package:healthymate/shared/bottom_sheets/food_source_bottom_sheet.dart';
import 'package:healthymate/features/notifications/pages/notifications_page.dart';
import '../widgets/index.dart';
import '../controllers/dashboard_controller.dart';

part 'dashboard_page_actions.dart';
part 'dashboard_page_content.dart';

/// หน้าจอหลักของแอปพลิเคชัน (Dashboard Main Page Widget)
/// ศูนย์รวมสรุปข้อมูลสุขภาพ กิจกรรมประจำวัน การออกกำลังกาย แคลอรี และความก้าวหน้าเป้าหมาย
class DashboardPageUpdated extends StatefulWidget {
  /// สถานะแท็บปัจจุบันเปิดอยู่นี้หรือไม่
  final bool isActive;

  /// คอลแบ็กสลับไปหน้าคำนวณสุขภาพ (Health Calculator)
  final VoidCallback? onNavigateToCalculator;

  /// คอลแบ็กสลับไปหน้าฝึกปฏิบัติ/เป้าหมาย (Practice / Routine)
  final VoidCallback? onNavigateToPractice;

  /// คอลแบ็กสลับไปหน้าโปรไฟล์ส่วนตัว (Profile)
  final VoidCallback? onNavigateToProfile;

  /// คอลแบ็กนำทางไปหน้าออกกำลังกายตามหมวดหมู่ที่เลือก (Workout Page)
  final Function(String? workoutCategory)? onNavigateToWorkout;

  /// คอลแบ็กสลับแท็บใดๆ พร้อมพารามิเตอร์
  final Function(int tabIndex, [String? workoutCategory, int? targetDurationMinutes])? onNavigateTab;

  /// คอลแบ็กเริ่มออกกำลังกายทันที
  final VoidCallback? onStartWorkout;

  const DashboardPageUpdated({
    super.key,
    this.isActive = true,
    this.onNavigateToCalculator,
    this.onNavigateToPractice,
    this.onNavigateToProfile,
    this.onNavigateToWorkout,
    this.onNavigateTab,
    this.onStartWorkout,
  });

  @override
  State<DashboardPageUpdated> createState() => _DashboardPageUpdatedState();
}

class _DashboardPageUpdatedState extends State<DashboardPageUpdated> {
  late final DashboardController _controller;

  // สีหลักอ้างอิงจากดีไซน์
  final Color primaryGreen = AppTheme.primaryGreen;
  final Color darkGreen = AppTheme.primaryGreenDark;

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลครั้งแรก และติดตามการเปลี่ยนแปลง routine เพื่อรีเฟรชสรุปบนแดชบอร์ด
    _controller = DashboardController()..loadDashboardData();
    RoutineStateNotifier.instance.addListener(_onRoutineStateChanged);
  }

  void _onRoutineStateChanged() {
    if (mounted) {
      _controller.loadDashboardData(silent: true);
    }
  }

  @override
  void didUpdateWidget(covariant DashboardPageUpdated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.loadDashboardData(silent: true);
    }
  }

  @override
  void dispose() {
    // ถอด listener และปิด controller เมื่อออกจากหน้านี้ เพื่อไม่ให้มีงานค้าง
    RoutineStateNotifier.instance.removeListener(_onRoutineStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
