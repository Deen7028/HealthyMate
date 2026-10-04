// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์โปรไฟล์ การตั้งค่า และบัญชีผู้ใช้ (profile controller loading)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'profile_controller.dart';

extension ProfileControllerLoading on ProfileController {
  Future<void> checkLocationService() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      isLocationEnabled = enabled;
      this._notifyProfileListeners();
    } catch (e) {
      debugPrint('Error checking location service: $e');
    }
  }

  /// คำนวณวัน Active โดยตั้งเวลาเป็น 00:00:00 ของทั้งสองวันก่อนนำมาลบกัน
  /// เพื่อป้องกันปัญหาการลบเวลาดิบแล้ววันขาดไป 1 วันเมื่อสมัครดึก
  int calculateActiveDays(DateTime createdAt, DateTime now) {
    final createdDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );
    final nowDate = DateTime(now.year, now.month, now.day);
    final diffInDays = nowDate.difference(createdDate).inDays;
    return diffInDays >= 0 ? diffInDays + 1 : 1;
  }

  /// โหลดข้อมูลผู้ใช้ สถิติ และการตั้งค่าทั้งหมด
  /// คืนค่า true หากพบผู้ใช้งาน และคืนค่า false หากไม่พบบัญชีผู้ใช้ (ต้องบังคับ Logout)
  Future<bool> loadUserData() async {
    try {
      isLoading = true;
      this._notifyProfileListeners();

      final email = AuthService.instance.currentUserEmail;
      TbUser? user;
      if (email.isNotEmpty) {
        user = await AppDatabase.instance.getUserByEmail(email);
      }

      // ป้องกันช่องโหว่ Data Leak: หาก Authentication ผิดพลาดหรือไม่พบบัญชี ให้ logout ทันที
      if (user == null) {
        debugPrint('ProfileController: No valid authenticated user found.');
        isLoading = false;
        this._notifyProfileListeners();
        return false;
      }

      final currentUserId = user.nUserId;

      final results = await Future.wait([
        AppDatabase.instance.getWorkoutCount(userId: currentUserId),
        AppDatabase.instance.getUserGoal(currentUserId),
        AppDatabase.instance.getConnectedDevices(currentUserId),
        AppDatabase.instance.getUserUnitPreference(currentUserId),
        Geolocator.isLocationServiceEnabled(),
        AppDatabase.instance.getGeminiApiKey(currentUserId),
      ]);

      workoutCount = results[0] as int;
      final goalData = results[1] as Map<String, dynamic>?;
      connectedDevices = results[2] as List<Map<String, dynamic>>;
      selectedUnit = results[3] as String;
      isLocationEnabled = results[4] as bool;
      geminiApiKey = results[5] as String;

      // คำนวณวัน Active ด้วยตรรกะที่ถูกต้อง (00:00:00)
      activeDays = calculateActiveDays(user.dtCreatedAt, DateTime.now());

      if (goalData != null) {
        mainGoalTitle = goalData['sTitle']?.toString() ?? '';
        goalProgress = (goalData['nProgress'] as num?)?.toDouble() ?? 0.0;
        goalRemainingText = goalData['sRemainingText']?.toString() ?? '';
      } else {
        mainGoalTitle = '';
        goalProgress = 0.0;
        goalRemainingText = '';
      }

      currentUser = user;
      isLoading = false;
      this._notifyProfileListeners();
      return true;
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      isLoading = false;
      this._notifyProfileListeners();
      return true;
    }
  }

  /// คืนค่า ImageProvider สำหรับแสดงรูปโปรไฟล์
  ImageProvider? getAvatarImageProvider() {
    final path = currentUser?.sProfileImagePath ?? '';
    if (path.isNotEmpty) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return NetworkImage(path);
      }
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
  }

  /// เลือกรูปภาพจาก Camera/Gallery
}
