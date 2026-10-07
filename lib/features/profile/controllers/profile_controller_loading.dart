part of 'profile_controller.dart';

// ส่วนโหลดข้อมูลโปรไฟล์ (ProfileControllerLoading)
// ทำหน้าที่ดึงข้อมูลผู้ใช้, สถิติกิจกรรม, การคำนวณ Active Days และ Avatar Provider
extension ProfileControllerLoading on ProfileController {
  // ฟังก์ชัน: ตรวจสอบสถานะการเปิดใช้งาน GPS Location Service
  Future<void> checkLocationService() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      isLocationEnabled = enabled;
      this._notifyProfileListeners();
    } catch (e) {
      debugPrint('Error checking location service: $e');
    }
  }

  // ฟังก์ชัน: คำนวณจำนวนวันที่ใช้งาน (Active Days) โดยนับจากเวลา 00:00:00
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

  // ฟังก์ชัน: โหลดข้อมูลผู้ใช้ สถิติ และการตั้งค่าทั้งหมด (Load Profile Data)
  Future<bool> loadUserData() async {
    try {
      isLoading = true;
      this._notifyProfileListeners();

      // 1. ตรวจสอบอีเมลผู้ใช้ที่เข้าสู่ระบบ
      final email = AuthService.instance.currentUserEmail;
      TbUser? user;
      if (email.isNotEmpty) {
        user = await AppDatabase.instance.getUserByEmail(email);
      }

      // หากไม่พบบัญชีผู้ใช้ในระบบ ให้ส่งกลับ false
      if (user == null) {
        debugPrint('ProfileController: No valid authenticated user found.');
        isLoading = false;
        this._notifyProfileListeners();
        return false;
      }

      final currentUserId = user.nUserId;

      // 2. ดึงข้อมูลสถิติ, เป้าหมาย, อุปกรณ์ และ API Key แบบขนาน (Future.wait)
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

      // 3. คำนวณ Active Days
      activeDays = calculateActiveDays(user.dtCreatedAt, DateTime.now());

      // 4. แปลงข้อมูลเป้าหมายหลัก
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

  // ฟังก์ชัน: ดึง ImageProvider สำหรับแสดงรูปโปรไฟล์ (Local File หรือ Network URL)
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
}
