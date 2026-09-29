import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service_config.dart';

class EmailApiService {
  static Future<Map<String, dynamic>> checkEmailRemote(String email) async {
    try {
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/check_email.php');
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
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/send_email_otp.php'),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': sEmail}),
          )
          .timeout(const Duration(seconds: 25));

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
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/verify_email_otp.php'),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': sEmail, 'sOtpCode': sOtpCode}),
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

  static Future<Map<String, dynamic>> sendForgotPasswordOtp(
    String sEmail,
  ) async {
    try {
      debugPrint(
        '[API] sendForgotPasswordOtp: ${ApiServiceConfig.baseUrl}/send_forgot_password_otp.php',
      );
      final response = await http
          .post(
            Uri.parse(
              '${ApiServiceConfig.baseUrl}/send_forgot_password_otp.php',
            ),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': sEmail}),
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('[API] sendForgotPasswordOtp HTTP ${response.statusCode}');

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
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/reset_password.php'),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode({'sEmail': sEmail, 'sNewPassword': sNewPassword}),
          )
          .timeout(const Duration(seconds: 60));

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
