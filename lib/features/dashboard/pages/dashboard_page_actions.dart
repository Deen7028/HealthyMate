part of 'dashboard_page.dart';

/// Extension ส่วนจัดการ Action / Event Callbacks ของหน้า Dashboard
extension _DashboardPageActions on _DashboardPageUpdatedState {
  /// จัดการเมื่อผู้ใช้กดปุ่มเริ่มออกกำลังกายตามประเภทหรือเป้าหมายที่เลือกไว้
  void _handleStartWorkout([String? category]) {
    final pinnedTitle = _controller.userGoal?['sTitle']?.toString() ?? '';
    final lower = pinnedTitle.toLowerCase();
    if (lower.contains('น้ำหนัก') || lower.contains('ลดน้ำหนัก')) {
      if (widget.onNavigateToCalculator != null) {
        widget.onNavigateToCalculator!();
        return;
      }
    }

    String? targetCategory = category;
    if (targetCategory == null && pinnedTitle.isNotEmpty) {
      if (lower.contains('จักรยาน') || lower.contains('ปั่น')) {
        targetCategory = 'cycling';
      } else if (lower.contains('แคลอรี') || lower.contains('เผาผลาญ')) {
        targetCategory = 'selectingCategory';
      } else if (lower.contains('สมาธิ') || lower.contains('ฝึกสติ')) {
        targetCategory = 'meditation';
      } else if (lower.contains('โยคะ')) {
        targetCategory = 'yoga';
      } else if (lower.contains('เดิน')) {
        targetCategory = 'walking';
      } else if (lower.contains('วิ่ง')) {
        targetCategory = 'running';
      } else {
        targetCategory = 'selectingCategory';
      }
    }

    if (widget.onNavigateToWorkout != null) {
      widget.onNavigateToWorkout!(targetCategory);
    } else if (widget.onStartWorkout != null) {
      widget.onStartWorkout!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('กำลังเข้าสู่โหมดมินิมาราธอน... 🏃‍♂️'),
          backgroundColor: darkGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// เปิด Bottom Sheet สำหรับตั้งค่า/แก้ไขเป้าหมายหลักใหม่
  Future<void> _openAddMainGoalBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const AddMainGoalBottomSheet(),
    );

    if (result != null && _controller.user != null) {
      final title = result['title']?.toString() ?? '';
      final icon = result['icon']?.toString() ?? '🚩';
      final unit = result['unit']?.toString() ?? '';
      final targetVal = (result['targetValue'] as num?)?.toDouble() ?? 1.0;
      final deadlineDate =
          result['deadlineDate'] as DateTime? ??
          DateTime.now().add(const Duration(days: 30));
      final now = DateTime.now();
      final remainingDays = deadlineDate.difference(now).inDays.clamp(1, 9999);
      final deadlineStr =
          '${deadlineDate.day.toString().padLeft(2, '0')}/${deadlineDate.month.toString().padLeft(2, '0')}/${deadlineDate.year + 543}';
      final remainingText =
          'เป้าหมาย: 0 / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unit (เหลือ $remainingDays วัน • สิ้นสุด $deadlineStr)';

      await AppDatabase.instance.saveUserGoal(
        userId: _controller.user!.nUserId,
        nRoutineId: 0,
        title: '$icon $title',
        progress: 0.0,
        remainingText: remainingText,
      );
      RoutineStateNotifier.instance.loadData(userId: _controller.user!.nUserId);

      final isWeightGoal =
          (result['isWeightGoal'] as bool?) == true ||
          title.contains('ลดน้ำหนัก') ||
          (result['linkedWorkout']?.toString() ?? '') == 'น้ำหนัก';

      if (isWeightGoal && widget.onNavigateToCalculator != null) {
        widget.onNavigateToCalculator!();
      }
    }
  }
}
