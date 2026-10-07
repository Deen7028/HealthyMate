part of 'profile_controller.dart';

extension ProfileControllerDevices on ProfileController {
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

  /// สลับสถานะเปิด/ปิดอุปกรณ์ที่เชื่อมต่อ
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

  /// ลบอุปกรณ์ที่เชื่อมต่อ
  Future<void> deleteConnectedDevice(int integrationId) async {
    final userId = currentUser?.nUserId;
    if (userId == null) return;
    await AppDatabase.instance.deleteConnectedDevice(integrationId);
    connectedDevices = await AppDatabase.instance.getConnectedDevices(userId);
    this._notifyProfileListeners();
  }

  /// ส่งออก PDF
}
