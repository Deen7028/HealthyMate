import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service_config.dart';

class AuthApiService {
  static Future<Map<String, dynamic>> loginRemote({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/login.php');
      final Map<String, dynamic> payload = {
        'sEmail': email,
        'sPassword': password,
      };

      final response = await http
          .post(
            uri,
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      debugPrint('HealthApiService: Remote login HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('HealthApiService: Remote login error or offline: $e');
    }
    return {
      'status': 'offline_or_error',
      'message': 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้',
    };
  }

  /// ตรวจสอบการซ้ำของอีเมลกับ Remote Server (`check_email.php`)

  static Future<Map<String, dynamic>> loginWithGoogle(
    Map<String, dynamic> googleUserData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/google_login.php'),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode(googleUserData),
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

  /// ลบบัญชีผู้ใช้และข้อมูลทั้งหมดจากระบบเซิร์ฟเวอร์ (PDPA/GDPR Account Deletion)
}
