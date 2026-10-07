import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthymate/core/services/api_service_config.dart';

import 'package:healthymate/core/services/supabase_service.dart';

class EmailApiService {
  static Future<Map<String, dynamic>> checkEmailRemote(String email) async {
    try {
      if (SupabaseService.instance.isInitialized) {
        final existing = await SupabaseService.instance.getUserByEmail(email);
        if (existing != null) {
          return {'status': 'exists', 'exists': true, 'message': 'อีเมลนี้ถูกใช้งานแล้ว'};
        } else {
          return {'status': 'available', 'exists': false, 'message': 'อีเมลนี้สามารถใช้งานได้'};
        }
      }

      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/auth/check_email.php');
      final response = await http
          .post(
            uri,
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': email}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('HealthApiService: Check email error: $e');
    }
    return {'status': 'offline_or_error', 'exists': false};
  }

  /// ส่งคำขอ OTP ไปยังอีเมล
  static Future<Map<String, dynamic>> sendEmailOtp(String sEmail) async {
    try {
      final cleanEmail = sEmail.trim().toLowerCase();

      // 1. ลองใช้ Supabase Auth OTP ก่อน
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        try {
          await SupabaseService.instance.client!.auth.signInWithOtp(
            email: cleanEmail,
            shouldCreateUser: true,
          );
          debugPrint('🚀 [Supabase Auth OTP] ส่งรหัส OTP ไปยัง $cleanEmail สำเร็จ');
          return {
            'status': 'success',
            'message': 'ส่งรหัส OTP ไปยังอีเมลเรียบร้อยแล้ว',
          };
        } catch (supaErr) {
          debugPrint('⚠️ Supabase signInWithOtp: $supaErr - พยายามใช้ระบบสำรอง');
        }
      }

      // 2. Fallback ไปยัง PHP API บน Server (ถ้ายังมีอยู่)
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/auth/send_email_otp.php'),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': cleanEmail}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
      return {
        'status': 'error',
        'message':
            'ตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง (HTTP ${response.statusCode})',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e',
      };
    }
  }

  /// ยืนยันรหัส OTP
  static Future<Map<String, dynamic>> verifyEmailOtp(
    String sEmail,
    String sOtpCode,
  ) async {
    try {
      final cleanEmail = sEmail.trim().toLowerCase();

      // 1. ลองตรวจสอบผ่าน Supabase Auth OTP
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        try {
          final res = await SupabaseService.instance.client!.auth.verifyOTP(
            email: cleanEmail,
            token: sOtpCode.trim(),
            type: OtpType.email,
          );
          if (res.session != null || res.user != null) {
            debugPrint('🚀 [Supabase OTP Verified] ยืนยัน OTP สำเร็จ: $cleanEmail');
            return {'status': 'success', 'message': 'ยืนยันรหัส OTP สำเร็จ'};
          }
        } catch (supaErr) {
          debugPrint('Supabase verifyOTP attempt: $supaErr');
        }

        // ตรวจสอบผ่านตาราง TbEmailOtps (ถ้าบันทึกไว้ในตาราง)
        final isCustomOtpValid = await SupabaseService.instance.verifyEmailOtp(
          email: cleanEmail,
          otpCode: sOtpCode.trim(),
        );
        if (isCustomOtpValid) {
          return {'status': 'success', 'message': 'ยืนยันรหัส OTP สำเร็จ'};
        }
      }

      // 2. Fallback ไปยัง PHP API บน Server
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/auth/verify_email_otp.php'),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': cleanEmail, 'sOtpCode': sOtpCode}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
      return {
        'status': 'error',
        'message':
            'ตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง (HTTP ${response.statusCode})',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e',
      };
    }
  }

  /// 1. ดึงข้อมูลประวัติสุขภาพจาก PHP API (`health_records.php`)

  /// ส่งรหัส OTP สำหรับรีเซ็ตรหัสผ่าน (ลืมรหัสผ่าน)
  static Future<Map<String, dynamic>> sendForgotPasswordOtp(
    String sEmail,
  ) async {
    try {
      final cleanEmail = sEmail.trim().toLowerCase();

      // 1. ส่ง OTP ผ่าน Supabase Auth
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        try {
          await SupabaseService.instance.client!.auth.resetPasswordForEmail(
            cleanEmail,
            redirectTo: 'com.example.healthymate://login-callback',
          );
          debugPrint('🚀 [Supabase Password Reset OTP] ส่งรหัสรีเซ็ตไปที่ $cleanEmail สำเร็จ');
          return {
            'status': 'success',
            'message': 'ส่งรหัส OTP สำหรับรีเซ็ตรหัสผ่านเรียบร้อยแล้ว',
          };
        } catch (supaErr) {
          debugPrint('⚠️ Supabase resetPasswordForEmail: $supaErr - พยายามใช้ระบบสำรอง');
        }
      }

      // 2. Fallback ไปยัง PHP API
      debugPrint(
        '[API] sendForgotPasswordOtp: ${ApiServiceConfig.baseUrl}/auth/send_forgot_password_otp.php',
      );
      final response = await http
          .post(
            Uri.parse(
              '${ApiServiceConfig.baseUrl}/auth/send_forgot_password_otp.php',
            ),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': cleanEmail}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
      return {
        'status': 'error',
        'message':
            'ตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง (HTTP ${response.statusCode})',
      };
    } catch (e) {
      debugPrint('[API ERROR] sendForgotPasswordOtp: $e');
      return {
        'status': 'error',
        'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e',
      };
    }
  }

  /// รีเซ็ตรหัสผ่านใหม่
  static Future<Map<String, dynamic>> resetPassword(
    String sEmail,
    String sNewPassword,
  ) async {
    try {
      final cleanEmail = sEmail.trim().toLowerCase();

      // 1. อัปเดตรหัสผ่านผ่าน Supabase Database
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        try {
          await SupabaseService.instance.client!
              .from('TbUsers')
              .update({'sPasswordHash': sNewPassword, 'dtUpdatedAt': DateTime.now().toIso8601String()})
              .eq('sEmail', cleanEmail);

          debugPrint('🚀 [Supabase Password Updated] อัปเดตรหัสผ่านใหม่สำเร็จ: $cleanEmail');
          return {
            'status': 'success',
            'message': 'เปลี่ยนรหัสผ่านสำเร็จเรียบร้อยแล้ว',
          };
        } catch (supaErr) {
          debugPrint('Supabase resetPassword database update error: $supaErr');
        }
      }

      // 2. Fallback ไปยัง PHP API
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/auth/reset_password.php'),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': cleanEmail, 'sNewPassword': sNewPassword}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
      return {
        'status': 'error',
        'message':
            'ตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง (HTTP ${response.statusCode})',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e',
      };
    }
  }
}
