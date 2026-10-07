import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/device/biometric_apple_auth_service.dart';
import 'package:healthymate/core/services/supabase_service.dart';
import 'package:healthymate/core/services/sync/sync_service.dart';

/// คอนโทรลเลอร์จัดการการเข้าสู่ระบบ (Login Controller)
/// รองรับ Login ด้วย Email/Password, Google OAuth และ Biometric (FaceID/Fingerprint)
class LoginController extends ChangeNotifier {
  // สถานะการโหลด
  bool isLoading = false;
  // ข้อความแสดงความผิดพลาด
  String? errorMessage;
  // จำนวนครั้งที่เข้าสู่ระบบผิด
  int failedAttempts = 0;
  // เวลาที่ระงับการเข้าสู่ระบบชั่วคราว
  DateTime? lockoutUntil;

  // อินสแตนซ์สำหรับ Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// ตรวจสอบความถูกต้องของรูปแบบอีเมล
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    return emailRegex.hasMatch(email);
  }

  /// บันทึกจำนวนครั้งที่เข้าสู่ระบบผิดพลาด และล็อค 30 วินาทีเมื่อผิดครบ 5 ครั้ง
  void registerFailedAttempt() {
    failedAttempts++;
    if (failedAttempts >= 5) {
      lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
    }
  }

  /// ล้างประวัติการเข้าสู่ระบบผิดพลาดเมื่อสำเร็จ
  void clearFailedAttempts() {
    failedAttempts = 0;
    lockoutUntil = null;
  }

  /// เข้าสู่ระบบด้วย Email & Password
  Future<bool> login({
    required String rawEmail,
    required String rawPassword,
  }) async {
    // 1. ตรวจสอบการถูกระงับชั่วคราว (Lockout Security)
    if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!)) {
      final waitSeconds = lockoutUntil!.difference(DateTime.now()).inSeconds;
      errorMessage = 'คุณพยายามเข้าสู่ระบบผิดบ่อยเกินไป กรุณารอ $waitSeconds วินาที';
      notifyListeners();
      return false;
    }

    // 2. เช็คว่าอีเมลไม่ว่างเปล่า
    if (rawEmail.isEmpty) {
      errorMessage = 'กรุณากรอกอีเมลของคุณ';
      notifyListeners();
      return false;
    }

    // 3. ตรวจสอบรูปแบบอีเมล
    if (!isValidEmail(rawEmail)) {
      errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง (เช่น example@domain.com)';
      notifyListeners();
      return false;
    }

    // 4. เช็คว่ารหัสผ่านไม่ว่างเปล่า
    if (rawPassword.isEmpty) {
      errorMessage = 'กรุณากรอกรหัสผ่าน';
      notifyListeners();
      return false;
    }

    // 5. เช็คความยาวรหัสผ่านอย่างน้อย 6 ตัวอักษร
    if (rawPassword.length < 6) {
      errorMessage = 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      notifyListeners();
      return false;
    }

    // กำหนดสถานะกำลังโหลด
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 6. ดำเนินการเข้าสู่ระบบผ่าน AuthService
      final loginResult = await AuthService.instance.login(rawEmail, rawPassword);
      final isSuccess = loginResult['success'] == true;

      // ถ้าเข้าสู่ระบบไม่สำเร็จ
      if (!isSuccess) {
        registerFailedAttempt();
        isLoading = false;
        errorMessage = loginResult['message']?.toString() ?? 'เข้าสู่ระบบไม่สำเร็จ';
        notifyListeners();
        return false;
      }

      // 7. บันทึกข้อมูลสำหรับใช้งาน Biometric ในครั้งต่อไป
      await BiometricAuthService.instance.saveCredentials(rawEmail, rawPassword);
      clearFailedAttempts();

      // 8. เริ่มซิงค์ข้อมูลกับเซิร์ฟเวอร์
      final currentUser = await AppDatabase.instance.getUserByEmail(rawEmail);
      if (currentUser != null && currentUser.nUserId > 0) {
        SyncService.instance.syncPendingData();
      }

      // เข้าสู่ระบบสำเร็จ
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // จัดการเมื่อเกิดข้อผิดพลาด
      isLoading = false;
      errorMessage = 'เกิดข้อผิดพลาด: $e';
      notifyListeners();
      return false;
    }
  }

  /// เข้าสู่ระบบด้วย Google Account
  Future<Map<String, dynamic>> loginWithGoogle() async {
    // กำหนดสถานะกำลังโหลด
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 1. ถ้าใช้ Supabase ให้ล็อกอินผ่าน OAuth Supabase
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.healthymate://login-callback/',
        );
        isLoading = false;
        notifyListeners();
        return {'status': 'success', 'message': 'เข้าสู่ระบบด้วย Google สำเร็จ'};
      }

      // 2. เรียก Native Google Sign-In SDK
      final GoogleSignInAccount user = await _googleSignIn.authenticate();
      final names = user.displayName?.split(' ') ?? ['Google', 'User'];
      final firstName = names.isNotEmpty ? names.first : 'Google';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      // 3. เตรียมข้อมูลผู้ใช้
      final googleData = {
        'sEmail': user.email,
        'sFirstName': firstName,
        'sLastName': lastName,
        'sGoogleId': user.id,
      };

      // 4. ส่งข้อมูลไปยัง Backend API
      final result = await AuthApiService.loginWithGoogle(googleData);

      // ถ้าล็อกอินสำเร็จ
      if (result['status'] == 'success') {
        final userData = result['user'];
        final String? token = result['token']?.toString();
        final tbUser = await AppDatabase.instance.upsertUserFromServer(userData);
        await AuthService.instance.setLoginSession(tbUser.sEmail, token: token);
        clearFailedAttempts();

        isLoading = false;
        notifyListeners();
        return {'status': 'success', 'message': 'เข้าสู่ระบบสำเร็จ!'};
      } else {
        // ถ้าล็อกอินไม่สำเร็จให้ Sign Out ออก
        await _googleSignIn.signOut();
        isLoading = false;
        errorMessage = result['message'] ?? 'เข้าสู่ระบบด้วย Google ไม่สำเร็จ';
        notifyListeners();
        return {'status': 'error', 'message': errorMessage};
      }
    } catch (error) {
      // จัดการเมื่อเกิดข้อผิดพลาด
      isLoading = false;
      errorMessage = 'เกิดข้อผิดพลาด: $error';
      notifyListeners();
      return {'status': 'error', 'message': errorMessage};
    }
  }

  /// เข้าสู่ระบบด้วย Biometric (สแกนลายนิ้วมือ / Face ID)
  Future<Map<String, dynamic>> loginWithBiometric() async {
    // 1. ตรวจสอบว่าเครื่องรองรับ Biometric หรือไม่
    final available = await BiometricAuthService.instance.isBiometricAvailable();
    if (!available) {
      return {'status': 'unavailable', 'message': 'อุปกรณ์นี้ไม่รองรับการสแกนลายนิ้วมือหรือใบหน้า'};
    }

    // 2. ดึง Credential ที่เคยบันทึกไว้ใน Secure Storage
    final credentials = await BiometricAuthService.instance.getCredentials();
    if (credentials == null) {
      return {'status': 'no_credentials', 'message': 'กรุณาเข้าสู่ระบบด้วยอีเมลและรหัสผ่านในครั้งแรกเพื่อเปิดใช้งานสแกนนิ้ว'};
    }

    final email = credentials['email'] ?? '';
    final password = credentials['password'] ?? '';

    if (email.isEmpty || password.isEmpty) {
      return {'status': 'no_credentials', 'message': 'ไม่พบข้อมูลยืนยันตัวตน'};
    }

    // 3. เริ่มขั้นตอนสแกนใบหน้า/ลายนิ้วมือ
    final authenticated = await BiometricAuthService.instance.authenticate(
      reason: 'ยืนยันตัวตนด้วย FaceID / TouchID เพื่อเข้าสู่ระบบ HealthyMate',
    );

    // 4. ถ้าสแกนผ่าน ให้ทำการเข้าสู่ระบบ
    if (authenticated) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final loginResult = await AuthService.instance.login(
        email,
        password,
      );

      final isSuccess = loginResult['success'] == true;
      if (isSuccess) {
        clearFailedAttempts();
        final currentUser = await AppDatabase.instance.getUserByEmail(email);
        if (currentUser != null && currentUser.nUserId > 0) {
          SyncService.instance.syncPendingData();
        }
        isLoading = false;
        notifyListeners();
        return {'status': 'success', 'message': 'ยืนยันตัวตนสำเร็จ!'};
      } else {
        isLoading = false;
        errorMessage = loginResult['message']?.toString() ?? 'ข้อมูลความปลอดภัยไม่ถูกต้อง กรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่';
        notifyListeners();
        return {'status': 'error', 'message': errorMessage};
      }
    }

    return {'status': 'cancelled', 'message': 'ยกเลิกการยืนยันตัวตน'};
  }
}
