part of '../../app_database.dart';

// ส่วนการจัดการอุปกรณ์เชื่อมต่อในฐานข้อมูล (AppDatabaseDevicesDao)
// ทำหน้าที่ดึงรายการอุปกรณ์ที่เชื่อมต่อ, เพิ่มอุปกรณ์, สลับสถานะเปิด/ปิด และลบอุปกรณ์
extension AppDatabaseDevicesDao on AppDatabase {
  // ฟังก์ชัน: ดึงรายการอุปกรณ์ที่เชื่อมต่อทั้งหมดของผู้ใช้จากตาราง TbHealthIntegrations
  Future<List<Map<String, dynamic>>> getConnectedDevices(int userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    return await db.query(
      AppDatabase.tableHealthIntegrations,
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'nIntegrationId ASC',
    );
  }

  // ฟังก์ชัน: เพิ่มอุปกรณ์หรือบริการสุขภาพใหม่ลงในฐานข้อมูล
  Future<int> insertConnectedDevice({
    required int userId,
    required String providerName,
    bool isSynced = true,
  }) async {
    if (kIsWeb) return 0;
    final db = await database;
    if (db == null) return 0;
    return await db.insert(AppDatabase.tableHealthIntegrations, {
      'nUserId': userId,
      'sProviderName': providerName,
      'isSynced': isSynced ? 1 : 0,
      'dtLastSyncedAt': DateTime.now().toIso8601String(),
    });
  }

  // ฟังก์ชัน: อัปเดตสถานะการเปิด/ปิดการเชื่อมต่อของอุปกรณ์
  Future<void> updateConnectedDeviceStatus({
    required int integrationId,
    required bool isSynced,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.update(
      AppDatabase.tableHealthIntegrations,
      {
        'isSynced': isSynced ? 1 : 0,
        'dtLastSyncedAt': DateTime.now().toIso8601String(),
      },
      where: 'nIntegrationId = ?',
      whereArgs: [integrationId],
    );
  }

  // ฟังก์ชัน: ลบอุปกรณ์เชื่อมต่อออกจากตาราง TbHealthIntegrations
  Future<void> deleteConnectedDevice(int integrationId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete(
      AppDatabase.tableHealthIntegrations,
      where: 'nIntegrationId = ?',
      whereArgs: [integrationId],
    );
  }
}
