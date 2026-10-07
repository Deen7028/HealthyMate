part of 'profile_controller.dart';

// ส่วนการตั้งค่าและความพึงพอใจของผู้ใช้ (ProfileControllerPreferences)
// ทำหน้าที่จัดการสิทธิ์การเข้าถึงตำแหน่ง GPS, การบันทึกหน่วยวัด และการอัปเดตข้อมูลส่วนตัว
extension ProfileControllerPreferences on ProfileController {
  // ฟังก์ชัน: จัดการการแตะปุ่มตั้งค่า Location Services / สิทธิ์ GPS
  Future<void> handleLocationTap() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    } else {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      } else {
        await Geolocator.openLocationSettings();
      }
    }
    await checkLocationService();
  }

  // ฟังก์ชัน: บันทึกหน่วยวัดที่ผู้ใช้เลือก (Unit Preference) เช่น กม., กก.
  Future<void> saveUserUnitPreference(String unit) async {
    selectedUnit = unit;
    this._notifyProfileListeners();
    final uId = currentUser?.nUserId;
    if (uId == null) return;

    // 1. บันทึกลง SQLite
    await AppDatabase.instance.saveUserUnitPreference(uId, unit);

    // 2. ซิงค์ขึ้น Remote Server
    final isSynced = await GoalApiService.saveUserPreferencesRemote(
      userId: uId,
      unitLabel: unit,
    );
    if (!isSynced) {
      await SyncService.instance.updatePendingCount();
    }
  }

  // ฟังก์ชัน: บันทึกและแก้ไขข้อมูลส่วนตัว (ชื่อ, นามสกุล, เพศ, อายุ, ส่วนสูง, น้ำหนัก)
  Future<bool> updateProfileInfo({
    required String firstName,
    required String lastName,
    required String gender,
    required int age,
    required double height,
    required double weight,
  }) async {
    if (firstName.isEmpty || currentUser == null) return false;

    final updated = currentUser!.copyWith(
      sFirstName: firstName,
      sLastName: lastName,
      nAge: age,
      nHeight: height,
      nWeight: weight,
      sGender: gender,
    );

    // 1. บันทึกลง SQLite ภายในเครื่อง
    await AppDatabase.instance.updateUser(updated);
    currentUser = updated;
    this._notifyProfileListeners();

    // 2. ซิงค์ข้อมูลขึ้น Remote Server
    final isSynced = await ProfileApiService.updateUserProfile(updated);
    if (!isSynced) {
      await SyncService.instance.updatePendingCount();
    }
    return isSynced;
  }
}
