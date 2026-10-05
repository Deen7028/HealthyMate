// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์การติดตามและประวัติการออกกำลังกาย (workout history page)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/workout/controllers/workout_history_controller.dart';
import '../widgets/index.dart';

/// หน้าแสดงประวัติการออกกำลังกายย้อนหลังของผู้ใช้ (Workout History Page)
/// ดึงข้อมูลจากฐานข้อมูล SQLite Local (`TbWorkouts`) และรองรับการดึงข้อมูลจาก Server (Delta Sync)
class WorkoutHistoryPage extends StatefulWidget {
  /// รหัสผู้ใช้ (UserId)
  final int userId;

  const WorkoutHistoryPage({super.key, required this.userId});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  /// คอนโทรลเลอร์บริหารจัดการดึงประวัติการออกกำลังกายและ Sync ข้อมูล
  late final WorkoutHistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WorkoutHistoryController();
    _controller.addListener(_onControllerChanged);
    _controller.init(widget.userId);
  }

  /// อัปเดต UI เมื่อ Controller มีการเปลี่ยนแปลงสถานะข้อมูล
  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  /// จัดการการรีเฟรชดึงข้อมูลล่าสุดจากเซิร์ฟเวอร์ (Delta Sync / Downstream)
  Future<void> _handlePullSync({bool isInitial = false}) async {
    final pulledCount = await _controller.pullDownstreamData(
      isInitial: isInitial,
    );
    if (pulledCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.cloud_download_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('ดึงข้อมูลสำเร็จ $pulledCount รายการ'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'ประวัติการออกกำลังกาย',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textPrimary,
          ),
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
          if (_controller.isPulling)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark
                        ? AppTheme.primaryLightGreen
                        : const Color(0xFF2E5327),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.sync_rounded,
                color: isDark
                    ? AppTheme.primaryLightGreen
                    : const Color(0xFF2E5327),
              ),
              onPressed: () => _handlePullSync(isInitial: false),
              tooltip: 'ดึงข้อมูลล่าสุดจากเซิร์ฟเวอร์ (Delta Sync)',
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        backgroundColor: cardBg,
        onRefresh: () => _handlePullSync(isInitial: false),
        child: _controller.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            : _controller.workouts.isEmpty
            ? _buildEmptyState()
            : _buildHistoryList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return WorkoutHistoryEmptyCard(
      onSyncTap: () => _handlePullSync(isInitial: true),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      itemCount: _controller.workouts.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            1.0,
            curve: Curves.easeOutCubic,
          ),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: child,
              ),
            );
          },
          child: WorkoutHistoryItemCard(
            workoutItem: _controller.workouts[index],
          ),
        );
      },
    );
  }
}
