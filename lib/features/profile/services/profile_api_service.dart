import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/services/api_service_config.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/core/services/supabase_service.dart';

/// เซอร์วิสสำหรับจัดการข้อมูลโปรไฟล์ผู้ใช้ และการลบบัญชี (Profile API Service)
class ProfileApiService {
  /// อัปเดตข้อมูลโปรไฟล์ผู้ใช้ขึ้นไปยัง Supabase หรือ Remote Server
  static Future<bool> updateUserProfile(dynamic userOrMap) async {
    try {
      final Map<String, dynamic> payload;
      // 1. แปลงข้อมูลและลบฟิลด์ที่ไม่จำเป็นต้องส่งออก
      if (userOrMap is Map<String, dynamic>) {
        payload = Map<String, dynamic>.from(userOrMap)
          ..removeWhere(
            (key, _) => const {
              'sPassword',
              'sGeminiApiKey',
              'sAuthToken',
            }.contains(key),
          );
      } else if (userOrMap is TbUser) {
        payload = userOrMap.toMap();
      } else {
        payload = {};
      }

      // 2. อัปเดตผ่านระบบ Supabase ก่อน
      if (SupabaseService.instance.isInitialized) {
        final success = await SupabaseService.instance.upsertUser(payload);
        if (success) {
          debugPrint('☁️ [Supabase SUCCESS] [TbUsers] ➜ อัปเดตข้อมูลผู้ใช้สำเร็จ');
          return true;
        }
      }

      // 3. ระบบสำรอง: ยิงไปยัง Remote PHP API Backend
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/profile/user_profile.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 5));

      // 4. ตรวจสอบผลลัพธ์
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

  /// ลบบัญชีผู้ใช้ถาวร (Delete Account)
  static Future<Map<String, dynamic>> deleteAccount({
    required int userId,
    required String email,
  }) async {
    try {
      // 1. ลบจาก Supabase Database
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!
            .from('TbUsers')
            .delete()
            .eq('nUserId', userId);
        return {'status': 'success', 'message': 'ลบบัญชีผู้ใช้สำเร็จ'};
      }

      // 2. ระบบสำรอง: ลบผ่าน Remote PHP API
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/profile/delete_account.php'),
            headers: headers,
            body: jsonEncode({'nUserId': userId, 'sEmail': email}),
          )
          .timeout(const Duration(seconds: 10));

      // 3. ตรวจสอบผลลัพธ์
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
