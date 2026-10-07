import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/device/biometric_apple_auth_service.dart';
import 'package:healthymate/core/services/supabase_service.dart';
import 'package:healthymate/core/services/sync/sync_service.dart';

class LoginController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  int failedAttempts = 0;
  DateTime? lockoutUntil;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    return emailRegex.hasMatch(email);
  }

  void registerFailedAttempt() {
    failedAttempts++;
    if (failedAttempts >= 5) {
      lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
    }
  }

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

    if (rawEmail.isEmpty) {
      errorMessage = 'กรุณากรอกอีเมลของคุณ';
      notifyListeners();
      return false;
    }

    if (!isValidEmail(rawEmail)) {
      errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง (เช่น example@domain.com)';
      notifyListeners();
      return false;
    }

    if (rawPassword.isEmpty) {
      errorMessage = 'กรุณากรอกรหัสผ่าน';
      notifyListeners();
      return false;
    }

    if (rawPassword.length < 6) {
      errorMessage = 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final loginResult = await AuthService.instance.login(rawEmail, rawPassword);
      final isSuccess = loginResult['success'] == true;

      if (!isSuccess) {
        registerFailedAttempt();
        isLoading = false;
        errorMessage = loginResult['message']?.toString() ?? 'เข้าสู่ระบบไม่สำเร็จ';
        notifyListeners();
        return false;
      }

      await BiometricAuthService.instance.saveCredentials(rawEmail, rawPassword);
      clearFailedAttempts();

      final currentUser = await AppDatabase.instance.getUserByEmail(rawEmail);
      if (currentUser != null && currentUser.nUserId > 0) {
        SyncService.instance.syncPendingData();
      }

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'เกิดข้อผิดพลาด: $e';
      notifyListeners();
      return false;
    }
  }

  /// เข้าสู่ระบบด้วย Google
  Future<Map<String, dynamic>> loginWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.healthymate://login-callback/',
        );
        isLoading = false;
        notifyListeners();
        return {'status': 'success', 'message': 'เข้าสู่ระบบด้วย Google สำเร็จ'};
      }

      final GoogleSignInAccount user = await _googleSignIn.authenticate();
      final names = user.displayName?.split(' ') ?? ['Google', 'User'];
      final firstName = names.isNotEmpty ? names.first : 'Google';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      final googleData = {
        'sEmail': user.email,
        'sFirstName': firstName,
        'sLastName': lastName,
        'sGoogleId': user.id,
      };

      final result = await AuthApiService.loginWithGoogle(googleData);

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
        await _googleSignIn.signOut();
        isLoading = false;
        errorMessage = result['message'] ?? 'เข้าสู่ระบบด้วย Google ไม่สำเร็จ';
        notifyListeners();
        return {'status': 'error', 'message': errorMessage};
      }
    } catch (error) {
      isLoading = false;
      errorMessage = 'เกิดข้อผิดพลาด: $error';
      notifyListeners();
      return {'status': 'error', 'message': errorMessage};
    }
  }

  /// เข้าสู่ระบบด้วย Biometric
  Future<Map<String, dynamic>> loginWithBiometric() async {
    final available = await BiometricAuthService.instance.isBiometricAvailable();
    if (!available) {
      return {'status': 'unavailable', 'message': 'อุปกรณ์นี้ไม่รองรับการสแกนลายนิ้วมือหรือใบหน้า'};
    }

    final credentials = await BiometricAuthService.instance.getCredentials();
    if (credentials == null) {
      return {'status': 'no_credentials', 'message': 'กรุณาเข้าสู่ระบบด้วยอีเมลและรหัสผ่านในครั้งแรกเพื่อเปิดใช้งานสแกนนิ้ว'};
    }

    final email = credentials['email'] ?? '';
    final password = credentials['password'] ?? '';

    if (email.isEmpty || password.isEmpty) {
      return {'status': 'no_credentials', 'message': 'ไม่พบข้อมูลยืนยันตัวตน'};
    }

    final authenticated = await BiometricAuthService.instance.authenticate(
      reason: 'ยืนยันตัวตนด้วย FaceID / TouchID เพื่อเข้าสู่ระบบ HealthyMate',
    );

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
