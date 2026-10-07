import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthymate/core/services/api_service_config.dart';
import 'package:healthymate/core/services/supabase_service.dart';
import 'package:healthymate/core/database/app_database.dart';

/// เซอร์วิสสำหรับจัดการการส่งอีเมล, เช็คอีเมลซ้ำ และระบบรหัส OTP (Email API Service)
class EmailApiService {
  /// ตรวจสอบว่ามีอีเมลนี้ลงทะเบียนไว้ในระบบแล้วหรือไม่
  static Future<Map<String, dynamic>> checkEmailRemote(String email) async {
    try {
      // 1. ตรวจสอบผ่าน Supabase ก่อน
      if (SupabaseService.instance.isInitialized) {
        final existing = await SupabaseService.instance.getUserByEmail(email);
        if (existing != null) {
          return {'status': 'exists', 'exists': true, 'message': 'อีเมลนี้ถูกใช้งานแล้ว'};
        } else {
          return {'status': 'available', 'exists': false, 'message': 'อีเมลนี้สามารถใช้งานได้'};
        }
      }

      // 2. ระบบสำรอง: ยิงไปยัง Remote PHP API Backend
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/auth/check_email.php');
      final response = await http
          .post(
            uri,
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': email}),
          )
          .timeout(const Duration(seconds: 8));

      // 3. ตรวจสอบผลลัพธ์
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('EmailApiService: Check email error: $e');
    }
    return {'status': 'offline_or_error', 'exists': false};
  }

  /// ส่งคำขอรหัส OTP สำหรับการสมัครสมาชิกใหม่
  static Future<Map<String, dynamic>> sendEmailOtp(String sEmail) async {
    try {
      final cleanEmail = sEmail.trim().toLowerCase();

      // 1. ส่งผ่านระบบ Supabase Auth OTP
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        try {
          await SupabaseService.instance.client!.auth.signInWithOtp(
            email: cleanEmail,
            shouldCreateUser: true,
          );
          return {
            'status': 'success',
            'message': 'ส่งรหัส OTP ไปยังอีเมลเรียบร้อยแล้ว',
          };
        } catch (supaErr) {
          debugPrint('⚠️ Supabase signInWithOtp: $supaErr - พยายามใช้ระบบสำรอง');
        }
      }

      // 2. ระบบสำรอง: ยิงไปยัง PHP API Backend
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/auth/send_email_otp.php'),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': cleanEmail}),
          )
          .timeout(const Duration(seconds: 12));

      // 3. แปลงผลลัพธ์ JSON
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('EmailApiService: Send OTP error: $e');
    }
    return {
      'status': 'error',
      'message': 'ไม่สามารถส่งรหัส OTP ได้ กรุณาตรวจสอบอินเทอร์เน็ต',
    };
  }

  /// ยืนยันรหัส OTP ที่ผู้ใช้กรอก
  static Future<Map<String, dynamic>> verifyEmailOtp(
    String sEmail,
    String sOtp,
  ) async {
    try {
      final cleanEmail = sEmail.trim().toLowerCase();
      final cleanOtp = sOtp.trim();

      // 1. ยืนยันผ่าน Supabase Auth OTP
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        try {
          final res = await SupabaseService.instance.client!.auth.verifyOTP(
            email: cleanEmail,
            token: cleanOtp,
            type: OtpType.magiclink,
          );
          if (res.user != null) {
            return {
              'status': 'success',
              'message': 'ยืนยันรหัส OTP สำเร็จ',
            };
          }
        } catch (_) {}
      }

      // 2. ระบบสำรอง: ตรวจสอบผ่าน PHP API Backend
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/auth/verify_email_otp.php'),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': cleanEmail, 'sOtp': cleanOtp}),
          )
          .timeout(const Duration(seconds: 8));

      // 3. ตรวจสอบสถานะการยืนยัน
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('EmailApiService: Verify OTP error: $e');
    }
    return {
      'status': 'error',
      'message': 'รหัส OTP ไม่ถูกต้องหรือหมดอายุ',
    };
  }

  /// ส่งรหัส OTP สำหรับการลืมรหัสผ่าน
  static Future<Map<String, dynamic>> sendForgotPasswordOtp(
    String sEmail,
  ) async {
    try {
      final cleanEmail = sEmail.trim().toLowerCase();

      // 1. ส่งผ่าน Supabase Password Reset OTP
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        try {
          await SupabaseService.instance.client!.auth.resetPasswordForEmail(
            cleanEmail,
          );
          return {
            'status': 'success',
            'message': 'ส่งรหัส OTP กู้รหัสผ่านไปยังอีเมลแล้ว',
          };
        } catch (_) {}
      }

      // 2. ระบบสำรอง: ส่งผ่าน PHP API Backend
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/auth/send_forgot_password_otp.php'),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': cleanEmail}),
          )
          .timeout(const Duration(seconds: 12));

      // 3. แปลงผลลัพธ์
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('EmailApiService: Send forgot password OTP error: $e');
    }
    return {
      'status': 'error',
      'message': 'ไม่สามารถส่งรหัส OTP ได้ กรุณาลองใหม่อีกครั้ง',
    };
  }

  /// ตั้งค่ารหัสผ่านใหม่ (Reset Password)
  static Future<Map<String, dynamic>> resetPassword(
    String sEmail,
    String sNewPassword,
  ) async {
    try {
      final cleanEmail = sEmail.trim().toLowerCase();

      // 1. อัปเดตรหัสผ่านใหม่บน Supabase
      if (SupabaseService.instance.isInitialized) {
        final user = await SupabaseService.instance.getUserByEmail(cleanEmail);
        if (user != null) {
          final newHash = AppDatabase.hashPassword(sNewPassword);
          user['sPasswordHash'] = newHash;
          user['dtUpdatedAt'] = DateTime.now().toIso8601String();
          await SupabaseService.instance.upsertUser(user);
          return {
            'status': 'success',
            'message': 'เปลี่ยนรหัสผ่านสำเร็จ',
          };
        }
      }

      // 2. ระบบสำรอง: อัปเดตผ่าน PHP API Backend
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/auth/reset_password.php'),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({
              'sEmail': cleanEmail,
              'sNewPassword': sNewPassword,
            }),
          )
          .timeout(const Duration(seconds: 8));

      // 3. ตรวจสอบผลลัพธ์
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('EmailApiService: Reset password error: $e');
    }
    return {
      'status': 'error',
      'message': 'เกิดข้อผิดพลาดในการเปลี่ยนรหัสผ่าน',
    };
  }
}
