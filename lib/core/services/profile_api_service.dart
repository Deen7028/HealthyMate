import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service_config.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

import 'package:healthymate/core/services/supabase_service.dart';

class ProfileApiService {
  static Future<bool> updateUserProfile(dynamic userOrMap) async {
    try {
      final Map<String, dynamic> payload;
      if (userOrMap is Map<String, dynamic>) {
        payload = Map<String, dynamic>.from(userOrMap)
          ..removeWhere(
            (key, _) => const {
              'sPassword',
              'sPasswordHash',
              'sGeminiApiKey',
              'sAuthToken',
            }.contains(key),
          );
      } else if (userOrMap is TbUser) {
        payload = userOrMap.toPublicProfileMap();
      } else {
        payload = {};
      }

      // 1. ลองอัปเดตผ่าน Supabase ก่อน
      if (SupabaseService.instance.isInitialized) {
        final success = await SupabaseService.instance.upsertUser(payload);
        if (success) {
          debugPrint('☁️ [Supabase SUCCESS] [TbUsers] ➜ อัปเดตข้อมูลผู้ใช้สำเร็จ');
          return true;
        }
      }

      // 2. Fallback ไป PHP API
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/user_profile.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint('☁️ [API SUCCESS] [TbUsers] ➜ อัปเดตข้อมูลผู้ใช้สำเร็จ');
          return true;
        }
      } else {
        debugPrint('[API ERROR] updateUserProfile HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] updateUserProfile failed: $e');
    }
    return false;
  }

  /// 4. ดึงประวัติการออกกำลังกายจาก PHP API (`workouts.php`)
  /// รองรับทั้ง Initial Data Hydration (ดึงทั้งหมด) และ Delta Sync (เฉพาะรายการใหม่ตั้งแต่ since)

  static Future<Map<String, dynamic>> deleteAccount({
    required int userId,
    required String email,
  }) async {
    try {
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/delete_account.php'),
            headers: headers,
            body: jsonEncode({'nUserId': userId, 'sEmail': email}),
          )
          .timeout(const Duration(seconds: 10));

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
