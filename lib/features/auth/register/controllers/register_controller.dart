import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';

/// สถานะการทำงานของการสมัครสมาชิก
enum RegisterStatus {
  idle,
  loading,
  passwordInvalid,
  termsNotAccepted,
  emailExistsLocal,
  emailExistsRemote,
  otpSentSuccess,
  error,
}

/// คอนโทรลเลอร์จัดการระบบสมัครสมาชิก (Register Controller)
/// รับผิดชอบการตรวจสอบความปลอดภัยของรหัสผ่าน, เงื่อนไขการใช้งาน, เช็คอีเมลซ้ำ และส่ง OTP
class RegisterController extends ChangeNotifier {
  // สถานะปัจจุบันของการสมัครสมาชิก
  RegisterStatus status = RegisterStatus.idle;
  // ข้อความแสดงความผิดพลาด
  String? errorMessage;
  // ตัวแปรบอกสถานะการโหลด
  bool isLoading = false;

  /// ตรวจสอบความเหมาะสมของรหัสผ่าน (อย่างน้อย 8 ตัวอักษร, พิมพ์ใหญ่, พิมพ์เล็ก, ตัวเลข)
  bool checkPasswordValid(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    return hasMinLength && hasUppercase && hasLowercase && hasDigits;
  }

  /// ดำเนินการสมัครสมาชิกและส่ง OTP
  Future<RegisterStatus> processRegister({
    required String email,
    required String password,
    required bool acceptTerms,
    required bool acceptPrivacy,
  }) async {
    // 1. ตรวจสอบเงื่อนไขความปลอดภัยของรหัสผ่าน
    if (!checkPasswordValid(password)) {
      status = RegisterStatus.passwordInvalid;
      errorMessage = 'รหัสผ่านไม่ผ่านเงื่อนไขความปลอดภัย กรุณาตรวจสอบอีกครั้ง';
      notifyListeners();
      return status;
    }

    // 2. ตรวจสอบการยอมรับเงื่อนไขและนโยบายความเป็นส่วนตัว
    if (!acceptTerms || !acceptPrivacy) {
      status = RegisterStatus.termsNotAccepted;
      errorMessage = 'กรุณายินยอมรับเงื่อนไขการให้บริการและนโยบายความเป็นส่วนตัวก่อนสมัครสมาชิก';
      notifyListeners();
      return status;
    }

    // กำหนดสถานะกำลังโหลด
    isLoading = true;
    status = RegisterStatus.loading;
    notifyListeners();

    try {
      // 3. ตรวจสอบอีเมลซ้ำในฐานข้อมูล Local SQLite ก่อน
      final isLocalExist = await AppDatabase.instance.isEmailExists(email);
      if (isLocalExist) {
        isLoading = false;
        status = RegisterStatus.emailExistsLocal;
        errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว กรุณาใช้อีเมลอื่นหรือเข้าสู่ระบบ';
        notifyListeners();
        return status;
      }

      // 4. ตรวจสอบอีเมลซ้ำบน Remote Server / Supabase
      final remoteCheck = await EmailApiService.checkEmailRemote(email);
      if (remoteCheck['exists'] == true || remoteCheck['status'] == 'exists') {
        isLoading = false;
        status = RegisterStatus.emailExistsRemote;
        errorMessage = 'อีเมลนี้ถูกลงทะเบียนไว้บนระบบเซิร์ฟเวอร์แล้ว กรุณาเข้าสู่ระบบ';
        notifyListeners();
        return status;
      }

      // 5. ส่งรหัส OTP ยืนยันไปยังอีเมล
      final otpResult = await EmailApiService.sendEmailOtp(email);
      isLoading = false;

      // ถ้าส่ง OTP สำเร็จ
      if (otpResult['status'] == 'success') {
        status = RegisterStatus.otpSentSuccess;
        notifyListeners();
        return status;
      } else {
        // ถ้าส่งไม่สำเร็จ
        status = RegisterStatus.error;
        errorMessage = otpResult['message'] ?? 'ไม่สามารถส่งรหัส OTP ได้';
        notifyListeners();
        return status;
      }
    } catch (e) {
      // จัดการเมื่อเกิดข้อผิดพลาด
      isLoading = false;
      status = RegisterStatus.error;
      errorMessage = 'เกิดข้อผิดพลาดในการลงทะเบียน: $e';
      notifyListeners();
      return status;
    }
  }

  /// บันทึกข้อมูลผู้ใช้ใหม่ลงฐานข้อมูลหลังจากยืนยัน OTP สำเร็จแล้ว
  Future<bool> saveUserAfterOtpVerified({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // 1. บันทึกข้อมูลผู้ใช้ลง Local SQLite
      final newUser = await AppDatabase.instance.registerUser(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      // 2. ตั้งค่าสถานะการเข้าสู่ระบบ
      await AppDatabase.instance.setLoginStatus(true, email: email);

      // 3. ซิงค์ข้อมูลผู้ใช้ขึ้น Server (ถ้าเชื่อมต่ออินเทอร์เน็ตอยู่)
      try {
        final serverSuccess = await ProfileApiService.updateUserProfile(newUser.toMap());
        if (serverSuccess) {
          await AppDatabase.instance.markUserAsSynced(newUser.nUserId);
        }
      } catch (e) {
        debugPrint('Sync new user error: $e');
      }

      return true;
    } catch (e) {
      debugPrint('[RegisterController] Save user error: $e');
      return false;
    }
  }
}
