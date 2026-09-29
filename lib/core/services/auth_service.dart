import 'package:flutter/foundation.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String _currentUserEmail = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String get currentUserEmail => _currentUserEmail;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _isLoggedIn = await AppDatabase.instance.getLoginStatus();
      if (_isLoggedIn) {
        _currentUserEmail = await AppDatabase.instance.getLoggedInUserEmail() ?? '';
      }
    } catch (e) {
      debugPrint('Error initializing auth state: $e');
      _isLoggedIn = false;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// เข้าสู่ระบบ (รองรับทั้ง Offline Local SQLite และ Online Remote Server Fallback)
  /// คืนค่าเป็น Map:
  /// - `success`: true/false
  /// - `user`: TbUser ที่ล็อกอินสำเร็จ (ถ้ามี)
  /// - `status`: 'success' | 'not_found' | 'invalid_password' | 'offline_or_error'
  /// - `message`: ข้อความอธิบาย
  Future<Map<String, dynamic>> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. ตรวจสอบใน SQLite เครื่องก่อน (กรณีมีข้อมูลอยู่แล้ว หรือใช้งานแบบออฟไลน์)
    final isLocalUserExists = await AppDatabase.instance.isEmailExists(cleanEmail);
    if (isLocalUserExists) {
      final isPasswordCorrect = await AppDatabase.instance.authenticateUser(cleanEmail, password);
      if (isPasswordCorrect) {
        // ยิง loginRemote ใน Background เพื่อรับ Token ล่าสุดจาก Server (ถ้ามีเน็ต)
        String? token;
        try {
          final remoteRes = await HealthApiService.loginRemote(
            email: cleanEmail,
            password: password,
          );
          if (remoteRes['status'] == 'success') {
            token = remoteRes['token']?.toString();
          }
        } catch (_) {}

        _isLoggedIn = true;
        _currentUserEmail = cleanEmail;
        await AppDatabase.instance.setLoginStatus(true, email: cleanEmail, token: token);
        final localUser = await AppDatabase.instance.getUserByEmail(cleanEmail);
        notifyListeners();
        return {
          'success': true,
          'status': 'success',
          'user': localUser,
          'message': 'เข้าสู่ระบบสำเร็จ',
        };
      } else {
        // มีผู้ใช้ในเครื่องแต่รหัสผ่านผิด
        return {
          'success': false,
          'status': 'invalid_password',
          'message': 'รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง',
        };
      }
    }

    // 2. ถ้าใน SQLite ไม่มีผู้ใช้นี้ (เช่น ลงแอปใหม่ ย้ายเครื่อง หรือล้างข้อมูลแอป)
    // ให้ยิงไปตรวจสอบกับ MySQL Server ผ่าน login.php
    final remoteRes = await HealthApiService.loginRemote(
      email: cleanEmail,
      password: password,
    );

    final status = remoteRes['status']?.toString() ?? 'offline_or_error';
    if (status == 'success' && remoteRes['user'] != null) {
      // 3. เซิร์ฟเวอร์ยืนยันว่าถูกต้อง -> ทำการ Hydrate บันทึก User ลง SQLite ในเครื่องทันที
      final hydratedUser = await AppDatabase.instance.upsertUserFromServer(
        Map<String, dynamic>.from(remoteRes['user'] as Map),
        authenticatedPassword: password,
      );

      _isLoggedIn = true;
      _currentUserEmail = cleanEmail;
      final String? token = remoteRes['token']?.toString();
      await AppDatabase.instance.setLoginStatus(true, email: cleanEmail, token: token);
      notifyListeners();

      return {
        'success': true,
        'status': 'success',
        'user': hydratedUser,
        'message': 'เข้าสู่ระบบสำเร็จ',
      };
    } else if (status == 'not_found') {
      return {
        'success': false,
        'status': 'not_found',
        'message': remoteRes['message']?.toString() ?? 'ไม่พบบัญชีผู้ใช้นี้ในระบบ กรุณาตรวจสอบอีเมลหรือสมัครสมาชิก',
      };
    } else if (status == 'invalid_password') {
      return {
        'success': false,
        'status': 'invalid_password',
        'message': remoteRes['message']?.toString() ?? 'รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง',
      };
    } else {
      return {
        'success': false,
        'status': 'offline_or_error',
        'message': 'ไม่พบบัญชีในเครื่อง และไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
      };
    }
  }

  Future<void> setLoginSession(String email, {String? token}) async {
    final cleanEmail = email.trim().toLowerCase();
    _isLoggedIn = true;
    _currentUserEmail = cleanEmail;
    await AppDatabase.instance.setLoginStatus(true, email: cleanEmail, token: token);
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUserEmail = '';
    await AppDatabase.instance.setLoginStatus(false);
    notifyListeners();
  }
}
