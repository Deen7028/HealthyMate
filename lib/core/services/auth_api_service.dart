// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (auth api service)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service_config.dart';

import 'package:healthymate/core/services/supabase_service.dart';

class AuthApiService {
  static Future<Map<String, dynamic>> loginRemote({
    required String email,
    required String password,
  }) async {
    try {
      if (SupabaseService.instance.isInitialized) {
        final existing = await SupabaseService.instance.getUserByEmail(email);
        if (existing != null) {
          return {
            'status': 'success',
            'user': existing,
            'message': 'เข้าสู่ระบบสำเร็จ',
          };
        }
      }

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

  /// เข้าสู่ระบบด้วย Google ผ่าน Supabase Database
  static Future<Map<String, dynamic>> loginWithGoogle(
    Map<String, dynamic> googleUserData,
  ) async {
    try {
      if (SupabaseService.instance.isInitialized) {
        final email = googleUserData['sEmail']?.toString() ?? '';
        final existing = await SupabaseService.instance.getUserByEmail(email);
        
        final userPayload = {
          'sEmail': email,
          'sFirstName': googleUserData['sFirstName'] ?? 'Google',
          'sLastName': googleUserData['sLastName'] ?? 'User',
          'sProfileImagePath': googleUserData['sProfileImagePath'] ?? '',
          'sPasswordHash': 'GOOGLE_AUTH_USER',
          'isSynced': true,
        };

        if (existing != null) {
          userPayload['nUserId'] = existing['nUserId'];
        }

        await SupabaseService.instance.upsertUser(userPayload);
        final latestUser = await SupabaseService.instance.getUserByEmail(email);

        return {
          'status': 'success',
          'user': latestUser ?? userPayload,
          'token': 'supabase_token_$email',
          'message': 'เข้าสู่ระบบด้วย Google สำเร็จ',
        };
      }

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
