// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์การยืนยันตัวตนและกู้รหัสผ่าน (forgot password controller)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';

/// คอนโทรลเลอร์จัดการสถานะและลอจิกการลืมรหัสผ่าน (Forgot Password Controller)
/// ทำหน้าที่ส่ง OTP ยืนยันรหัส OTP และตั้งรหัสผ่านใหม่
class ForgotPasswordController extends ChangeNotifier {
  bool isLoading = false;
  bool isOtpVerified = false;
  String? errorMessage;

  /// ส่งรหัส OTP ไปยังอีเมลที่ระบุ
  Future<bool> sendOtp(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      errorMessage = 'กรุณากรอกอีเมลที่ถูกต้อง';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await EmailApiService.sendForgotPasswordOtp(email);
      isLoading = false;

      if (result['status'] == 'success') {
        notifyListeners();
        return true;
      } else {
        errorMessage = result['message'] ?? 'ไม่สามารถส่งรหัส OTP ได้';
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์';
      notifyListeners();
      return false;
    }
  }

  /// ทำเครื่องหมายว่า OTP ถูกยืนยันแล้ว
  void markOtpVerified() {
    isOtpVerified = true;
    notifyListeners();
  }

  /// รีเซ็ตรหัสผ่านใหม่
  Future<bool> resetPassword(
      String email, String newPassword, String confirmPassword) async {
    if (newPassword.isEmpty) {
      errorMessage = 'กรุณากรอกรหัสผ่านใหม่';
      notifyListeners();
      return false;
    }

    if (newPassword.length < 8) {
      errorMessage = 'รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษร';
      notifyListeners();
      return false;
    }

    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      errorMessage = 'รหัสผ่านต้องมีตัวพิมพ์ใหญ่ (A-Z) อย่างน้อย 1 ตัว';
      notifyListeners();
      return false;
    }

    if (!RegExp(r'[a-z]').hasMatch(newPassword)) {
      errorMessage = 'รหัสผ่านต้องมีตัวพิมพ์เล็ก (a-z) อย่างน้อย 1 ตัว';
      notifyListeners();
      return false;
    }

    if (!RegExp(r'[0-9]').hasMatch(newPassword)) {
      errorMessage = 'รหัสผ่านต้องมีตัวเลข (0-9) อย่างน้อย 1 ตัว';
      notifyListeners();
      return false;
    }

    if (newPassword != confirmPassword) {
      errorMessage = 'รหัสผ่านทั้งสองช่องไม่ตรงกัน';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await EmailApiService.resetPassword(email, newPassword);
      if (result['status'] == 'success') {
        await AppDatabase.instance.updateLocalPassword(email, newPassword);
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        isLoading = false;
        errorMessage = result['message'] ?? 'เกิดข้อผิดพลาดในการเปลี่ยนรหัสผ่าน';
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์';
      notifyListeners();
      return false;
    }
  }
}
