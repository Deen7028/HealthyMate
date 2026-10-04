// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์การสมัครสมาชิก (register controller)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';

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

class RegisterController extends ChangeNotifier {
  RegisterStatus status = RegisterStatus.idle;
  String? errorMessage;
  bool isLoading = false;

  bool checkPasswordValid(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    return hasMinLength && hasUppercase && hasLowercase && hasDigits;
  }

  Future<RegisterStatus> processRegister({
    required String email,
    required String password,
    required bool acceptTerms,
    required bool acceptPrivacy,
  }) async {
    if (!checkPasswordValid(password)) {
      status = RegisterStatus.passwordInvalid;
      errorMessage = 'รหัสผ่านไม่ผ่านเงื่อนไขความปลอดภัย กรุณาตรวจสอบอีกครั้ง';
      notifyListeners();
      return status;
    }

    if (!acceptTerms || !acceptPrivacy) {
      status = RegisterStatus.termsNotAccepted;
      errorMessage = 'กรุณายินยอมรับเงื่อนไขการให้บริการและนโยบายความเป็นส่วนตัวก่อนสมัครสมาชิก';
      notifyListeners();
      return status;
    }

    isLoading = true;
    status = RegisterStatus.loading;
    notifyListeners();

    try {
      final isLocalExist = await AppDatabase.instance.isEmailExists(email);
      if (isLocalExist) {
        isLoading = false;
        status = RegisterStatus.emailExistsLocal;
        errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว กรุณาใช้อีเมลอื่นหรือเข้าสู่ระบบ';
        notifyListeners();
        return status;
      }

      final remoteCheck = await EmailApiService.checkEmailRemote(email);
      if (remoteCheck['exists'] == true || remoteCheck['status'] == 'exists') {
        isLoading = false;
        status = RegisterStatus.emailExistsRemote;
        errorMessage = 'อีเมลนี้ถูกลงทะเบียนไว้บนระบบเซิร์ฟเวอร์แล้ว กรุณาเข้าสู่ระบบ';
        notifyListeners();
        return status;
      }

      final otpResult = await EmailApiService.sendEmailOtp(email);
      isLoading = false;

      if (otpResult['status'] == 'success') {
        status = RegisterStatus.otpSentSuccess;
        notifyListeners();
        return status;
      } else {
        status = RegisterStatus.error;
        errorMessage = otpResult['message'] ?? 'ไม่สามารถส่งรหัส OTP ได้';
        notifyListeners();
        return status;
      }
    } catch (e) {
      isLoading = false;
      status = RegisterStatus.error;
      errorMessage = 'เกิดข้อผิดพลาดในการลงทะเบียน: $e';
      notifyListeners();
      return status;
    }
  }

  Future<bool> saveUserAfterOtpVerified({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final newUser = await AppDatabase.instance.registerUser(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      await AppDatabase.instance.setLoginStatus(true, email: email);

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
