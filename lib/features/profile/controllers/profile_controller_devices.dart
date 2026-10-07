part of 'profile_controller.dart';

// ส่วนการจัดการอุปกรณ์ที่เชื่อมต่อ (ProfileControllerDevices)
// ทำหน้าที่เพิ่มอุปกรณ์เชื่อมต่อ (Integrations), สลับสถานะเปิด/ปิด และลบอุปกรณ์
extension ProfileControllerDevices on ProfileController {
  // ฟังก์ชัน: เพิ่มอุปกรณ์หรือบริการที่เชื่อมต่อใหม่ (เช่น Google Fit, Apple Health)
  Future<void> addConnectedDevice(String providerName) async {
    final userId = currentUser?.nUserId;
    if (userId == null) return;
    await AppDatabase.instance.insertConnectedDevice(
      userId: userId,
      providerName: providerName,
      isSynced: true,
    );
    connectedDevices = await AppDatabase.instance.getConnectedDevices(userId);
    this._notifyProfileListeners();
  }

  // ฟังก์ชัน: สลับสถานะเปิด/ปิดการซิงค์ของอุปกรณ์ที่เชื่อมต่อ
  Future<void> toggleConnectedDeviceStatus(
    int integrationId,
    bool isActive,
  ) async {
    final userId = currentUser?.nUserId;
    if (userId == null) return;
    await AppDatabase.instance.updateConnectedDeviceStatus(
      integrationId: integrationId,
      isSynced: isActive,
    );
    connectedDevices = await AppDatabase.instance.getConnectedDevices(userId);
    this._notifyProfileListeners();
  }

  // ฟังก์ชัน: ลบอุปกรณ์ที่เชื่อมต่อออกจากระบบ
  Future<void> deleteConnectedDevice(int integrationId) async {
    final userId = currentUser?.nUserId;
    if (userId == null) return;
    await AppDatabase.instance.deleteConnectedDevice(integrationId);
    connectedDevices = await AppDatabase.instance.getConnectedDevices(userId);
    this._notifyProfileListeners();
  }
}
