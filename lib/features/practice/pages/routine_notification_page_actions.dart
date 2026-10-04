// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine notification page actions)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_notification_page.dart';

extension _RoutineNotificationActions on _MyRoutinesPageState {
  Future<void> _openAddMainGoalBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const AddMainGoalBottomSheet(),
    );

    if (result != null) {
      await _controller.setCustomMainGoal(
        title: result['title']?.toString() ?? '',
        icon: result['icon']?.toString() ?? '🚩',
        unit: result['unit']?.toString() ?? '',
        targetValue: (result['targetValue'] as num?)?.toDouble() ?? 1.0,
        linkedWorkout: result['linkedWorkout']?.toString() ?? '',
        deadlineDate:
            result['deadlineDate'] as DateTime? ??
            DateTime.now().add(const Duration(days: 30)),
      );
      this._showSnackBar('ตั้งเป้าหมายหลัก "${result['title']}" เรียบร้อย!');
    }
  }

  Future<void> _openAddRoutineDialog() async {
    final RoutineItem? newRoutine = await showModalBottomSheet<RoutineItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const AddRoutineDialog(),
    );

    if (newRoutine != null) {
      await _controller.addRoutine(newRoutine);
      this._showSnackBar('เพิ่ม "${newRoutine.title}" ในกิจวัตรสำเร็จ!');
    }
  }

  Future<void> _deleteRoutine(int routineId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการลบ'),
        content: Text(
          'ต้องการลบกิจวัตร "$title" หรือไม่?\nข้อมูลที่เช็คไว้จะถูกลบทั้งหมด',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _controller.deleteRoutine(routineId, title);
      this._showSnackBar('ลบ "$title" เรียบร้อย');
    }
  }

  Future<void> _editRoutine(Map<String, dynamic> routine) async {
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;

    final RoutineItem? updatedRoutine = await showModalBottomSheet<RoutineItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => AddRoutineDialog(initialRoutine: routine),
    );

    if (updatedRoutine != null) {
      await _controller.editRoutine(routineId, updatedRoutine);
      this._showSnackBar('อัปเดตกิจวัตรเรียบร้อยแล้ว');
    }
  }

  RoutineButtonType _getRoutineButtonType(
    Map<String, dynamic> routine,
    bool isWorkoutRoutine,
  ) {
    if (isWorkoutRoutine) return RoutineButtonType.workout;

    final unit = (routine['unit']?.toString() ?? '').toLowerCase();
    final title = (routine['sTitle']?.toString() ?? '').toLowerCase();
    final targetVal = (routine['targetValue'] as num?)?.toDouble() ?? 1.0;

    if (unit.contains('นาที') ||
        unit.contains('min') ||
        unit.contains('ชม') ||
        unit.contains('hr') ||
        title.contains('สมาธิ') ||
        title.contains('หายใจ') ||
        title.contains('โฟกัส')) {
      return RoutineButtonType.timer;
    }

    if ((unit.contains('มล') ||
            unit.contains('ml') ||
            unit.contains('ลิตร') ||
            unit.contains('มื้อ') ||
            unit.contains('แก้ว') ||
            unit.contains('จาน') ||
            unit.contains('หน้า') ||
            unit.contains('ครั้ง')) &&
        targetVal > 1.0) {
      return RoutineButtonType.stepAdd;
    }

    return RoutineButtonType.singleCheck;
  }
}
