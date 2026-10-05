// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine notification page dialogs)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_notification_page.dart';

extension _RoutineNotificationDialogs on _MyRoutinesPageState {
  double _calculateStepAmount(double targetVal, String unit) {
    final u = unit.toLowerCase();
    if (u.contains('มล') || u.contains('ml')) {
      if (targetVal >= 2000) return 250;
      if (targetVal >= 1000) return 200;
      if (targetVal >= 500) return 100;
      return 50;
    }
    if (u.contains('ลิตร') || u.contains('l')) {
      if (targetVal >= 2) return 0.25;
      return 0.1;
    }
    if (u.contains('มื้อ') ||
        u.contains('แก้ว') ||
        u.contains('จาน') ||
        u.contains('ครั้ง') ||
        u.contains('หน้า')) {
      return 1.0;
    }
    if (targetVal <= 5) return 1.0;
    if (targetVal <= 20) return 2.0;
    return (targetVal / 4).roundToDouble().clamp(1.0, targetVal);
  }

  void _showCountdownTimerDialog(
    BuildContext context,
    Map<String, dynamic> routine,
    int durationMinutes,
  ) {
    final title = routine['sTitle']?.toString() ?? 'จับเวลาทำกิจกรรม';
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return RoutineCountdownTimerModal(
          title: title,
          durationMinutes: durationMinutes,
          onTimerCompleted: () async {
            if (mounted) {
              await _controller.toggleRoutineCompletion(routineId);
              this._showSnackBar('🎉 ทำ "$title" ครบเวลาเรียบร้อยแล้ว!');
            }
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildThreeDotsMenu({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('แก้ไข'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('ลบ'),
            ],
          ),
        ),
      ],
    );
  }
}
