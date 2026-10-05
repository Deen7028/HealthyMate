// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine notification page grouping)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_notification_page.dart';

extension _RoutineNotificationGrouping on _MyRoutinesPageState {
  Map<String, List<Map<String, dynamic>>> _groupRoutinesByTime(
    List<Map<String, dynamic>> routines,
  ) {
    final groups = <String, List<Map<String, dynamic>>>{
      'morning': [],
      'afternoon': [],
      'night': [],
      'other': [],
    };
    for (final routine in routines) {
      final time = routine['sTime']?.toString() ?? '';
      final block = _getTimeBlock(time);
      (groups[block] ?? groups['other']!).add(routine);
    }
    return groups;
  }
}
