part of 'health_calculator_controller.dart';

// ส่วนการบันทึกและจัดการประวัติสุขภาพ (HealthCalculatorPersistence)
// ทำหน้าที่บันทึกข้อมูลเข้าโปรไฟล์ผู้ใช้และ Dashboard รวมถึงการลบประวัติสุขภาพ
extension HealthCalculatorPersistence on HealthCalculatorController {
  // ฟังก์ชัน: บันทึกค่าสุขภาพลง Profile และ Dashboard
  Future<void> saveToProfileAndDashboard() async {
    // 1. คำนวณค่าสุขภาพล่าสุดพร้อมสั่งบันทึกลงฐานข้อมูล
    await calculate(recordHistory: true, syncToDb: true);

    // 2. ปรับสถานะการซิงค์และเวลาล่าสุด
    _isSyncedToDashboard = true;
    _lastSyncedAt = DateTime.now();

    // 3. สั่งให้ State Notifier ของกิจวัตรอัปเดตข้อมูลตาม
    RoutineStateNotifier.instance.loadData(userId: _currentUser?.nUserId);
    _safeNotifyListeners();
  }

  // ฟังก์ชัน: ลบรายการประวัติสุขภาพตาม ID
  Future<void> deleteHistoryItem(int recordId) async {
    try {
      // 1. สั่งลบออกจาก SQLite
      await _db.deleteHealthRecord(recordId);

      // 2. ลบออกจากรายการในหน่วยความจำ
      _historyList.removeWhere((item) => item.nRecordId == recordId);

      // 3. รีเฟรช State กิจวัตรและหน้าจอ
      RoutineStateNotifier.instance.loadData(userId: _currentUser?.nUserId);
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error deleting health record from db: $e');
    }
  }
}
