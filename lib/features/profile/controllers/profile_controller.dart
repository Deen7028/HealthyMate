import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/data_export_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

class ProfileController extends ChangeNotifier {
  bool isLoading = true;
  bool isUploadingImage = false;
  bool isLocationEnabled = true;
  TbUser? currentUser;

  int workoutCount = 0;
  int activeDays = 0;
  String mainGoalTitle = '';
  double goalProgress = 0.0;
  String goalRemainingText = '';
  List<Map<String, dynamic>> connectedDevices = [];
  String selectedUnit = 'Kilometers, Kilograms';
  String geminiApiKey = '';

  final ImagePicker _picker = ImagePicker();

  /// ตรวจสอบสถานะ GPS Location Service
  Future<void> checkLocationService() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      isLocationEnabled = enabled;
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking location service: $e');
    }
  }

  /// คำนวณวัน Active โดยตั้งเวลาเป็น 00:00:00 ของทั้งสองวันก่อนนำมาลบกัน
  /// เพื่อป้องกันปัญหาการลบเวลาดิบแล้ววันขาดไป 1 วันเมื่อสมัครดึก
  int calculateActiveDays(DateTime createdAt, DateTime now) {
    final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final nowDate = DateTime(now.year, now.month, now.day);
    final diffInDays = nowDate.difference(createdDate).inDays;
    return diffInDays >= 0 ? diffInDays + 1 : 1;
  }

  /// โหลดข้อมูลผู้ใช้ สถิติ และการตั้งค่าทั้งหมด
  /// คืนค่า true หากพบผู้ใช้งาน และคืนค่า false หากไม่พบบัญชีผู้ใช้ (ต้องบังคับ Logout)
  Future<bool> loadUserData() async {
    try {
      isLoading = true;
      notifyListeners();

      final email = AuthService.instance.currentUserEmail;
      TbUser? user;
      if (email.isNotEmpty) {
        user = await AppDatabase.instance.getUserByEmail(email);
      }

      // ป้องกันช่องโหว่ Data Leak: หาก Authentication ผิดพลาดหรือไม่พบบัญชี ให้ logout ทันที
      if (user == null) {
        debugPrint('ProfileController: No valid authenticated user found.');
        isLoading = false;
        notifyListeners();
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
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      isLoading = false;
      notifyListeners();
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
  Future<bool> handleImagePick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked != null) {
      await saveImageLocally(picked.path);
      return true;
    }
    return false;
  }

  /// บันทึกรูปลง Documents Directory ถาวร พร้อมลบรูปเดิมป้องกัน Storage Leak
  Future<void> saveImageLocally(String tempPath) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final userId = currentUser?.nUserId ?? 1;
      final rawExt = tempPath.contains('.') ? tempPath.split('.').last.toLowerCase() : 'jpg';
      final fileExtension = (rawExt.length <= 4 && !rawExt.contains('/')) ? rawExt : 'jpg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final permanentPath = '${docDir.path}/profile_avatar_${userId}_$timestamp.$fileExtension';

      // 1. ลบรูปโปรไฟล์เดิมทิ้งก่อนเพื่อป้องกัน Storage Leak
      final oldPath = currentUser?.sProfileImagePath ?? '';
      if (oldPath.isNotEmpty && !oldPath.startsWith('http')) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      // 2. คัดลอกไฟล์จาก temp ไปยัง Documents ถาวร
      final tempFile = File(tempPath);
      await tempFile.copy(permanentPath);

      // 3. ลบ temp file ชั่วคราว
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await updateProfileImagePath(permanentPath);
    } catch (e) {
      debugPrint('Error saving image permanently: $e');
      await updateProfileImagePath(tempPath);
    }
  }

  /// อัปเดตรูปโปรไฟล์ทั้ง SQLite และ Remote Server พร้อมระบบ State Management ระหว่างอัปโหลด (isUploadingImage)
  Future<void> updateProfileImagePath(String path) async {
    if (currentUser == null) return;

    isUploadingImage = true;
    notifyListeners();

    try {
      final updated = currentUser!.copyWith(sProfileImagePath: path);

      // 1. อัปเดต SQLite ภายในเครื่องทันที
      await AppDatabase.instance.updateUser(updated);
      currentUser = updated;
      notifyListeners();

      // 2. ซิงค์ขึ้น Remote Server
      String finalPathForRemote = path;
      if (path.isNotEmpty && !path.startsWith('http')) {
        final remoteUrl = await HealthApiService.uploadImage(path, type: 'profile');
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          finalPathForRemote = remoteUrl;
        }
      }

      final remotePayload = updated.copyWith(sProfileImagePath: finalPathForRemote);
      final isSynced = await HealthApiService.updateUserProfile(remotePayload);

      if (!isSynced) {
        await SyncService.instance.updatePendingCount();
      }
    } catch (e) {
      debugPrint('Error updating profile image path: $e');
    } finally {
      isUploadingImage = false;
      notifyListeners();
    }
  }

  /// จัดการเมื่อผู้ใช้กดเปลี่ยนสถานะ Location Services
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

  /// บันทึกหน่วยวัดที่เลือก
  Future<void> saveUserUnitPreference(String unit) async {
    selectedUnit = unit;
    notifyListeners();
    final uId = currentUser?.nUserId ?? 1;
    await AppDatabase.instance.saveUserUnitPreference(
      uId,
      unit,
    );
    final isSynced = await HealthApiService.saveUserPreferencesRemote(
      userId: uId,
      unitLabel: unit,
      geminiApiKey: geminiApiKey,
    );
    if (!isSynced) {
      await SyncService.instance.updatePendingCount();
    }
  }

  /// บันทึกข้อมูลส่วนตัว (ชื่อ, นามสกุล, เพศ, อายุ, ส่วนสูง, น้ำหนัก)
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

    // 1. บันทึกลง SQLite
    await AppDatabase.instance.updateUser(updated);
    currentUser = updated;
    notifyListeners();

    // 2. ซิงค์ขึ้น Remote Server
    final isSynced = await HealthApiService.updateUserProfile(updated);
    if (!isSynced) {
      await SyncService.instance.updatePendingCount();
    }
    return isSynced;
  }

  /// เพิ่มอุปกรณ์ที่เชื่อมต่อ
  Future<void> addConnectedDevice(String providerName) async {
    final userId = currentUser?.nUserId ?? 1;
    await AppDatabase.instance.insertConnectedDevice(
      userId: userId,
      providerName: providerName,
      isSynced: true,
    );
    connectedDevices = await AppDatabase.instance.getConnectedDevices(userId);
    notifyListeners();
  }

  /// สลับสถานะเปิด/ปิดอุปกรณ์ที่เชื่อมต่อ
  Future<void> toggleConnectedDeviceStatus(int integrationId, bool isActive) async {
    final userId = currentUser?.nUserId ?? 1;
    await AppDatabase.instance.updateConnectedDeviceStatus(
      integrationId: integrationId,
      isSynced: isActive,
    );
    connectedDevices = await AppDatabase.instance.getConnectedDevices(userId);
    notifyListeners();
  }

  /// ลบอุปกรณ์ที่เชื่อมต่อ
  Future<void> deleteConnectedDevice(int integrationId) async {
    final userId = currentUser?.nUserId ?? 1;
    await AppDatabase.instance.deleteConnectedDevice(integrationId);
    connectedDevices = await AppDatabase.instance.getConnectedDevices(userId);
    notifyListeners();
  }

  /// ส่งออก PDF
  Future<String?> exportPdf() async {
    final userId = currentUser?.nUserId ?? 1;
    return await DataExportService.instance.exportDataToPdf(userId);
  }

  /// ลบบัญชีผู้ใช้
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    // 0. ลบไฟล์รูปภาพโปรไฟล์จริงในเครื่อง (ถ้ามี)
    final profilePath = user.sProfileImagePath;
    if (profilePath.isNotEmpty && !profilePath.startsWith('http')) {
      try {
        final file = File(profilePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting local profile picture file: $e');
      }
    }

    // 1. เรียก API ทำลายข้อมูลบน Server
    await HealthApiService.deleteAccount(userId: user.nUserId, email: user.sEmail);

    // 2. ทำลายข้อมูล SQLite ในเครื่อง
    await AppDatabase.instance.deleteUserAccount(user.nUserId);

    // 3. เคลียร์ Google Session & App Session
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    await AuthService.instance.logout();
  }

  /// ออกจากระบบ
  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('GoogleSignIn signOut error during logout: $e');
    }
    await AuthService.instance.logout();
  }

  /// อัปเดต Gemini API Key พร้อมบันทึกลง SQLite และซิงค์ขึ้น Server
  Future<void> updateGeminiApiKey(String key) async {
    geminiApiKey = key;
    notifyListeners();

    final uId = currentUser?.nUserId ?? 1;

    // 1. บันทึกลง SQLite
    await AppDatabase.instance.saveGeminiApiKey(uId, key);

    // 2. ซิงค์ขึ้น Remote Server
    final isSynced = await HealthApiService.saveUserPreferencesRemote(
      userId: uId,
      unitLabel: selectedUnit,
      geminiApiKey: key,
    );
    if (!isSynced) {
      await SyncService.instance.updatePendingCount();
    }
  }
}
