import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/services/api_service_config.dart';
import 'package:healthymate/core/services/supabase_service.dart';
import 'package:healthymate/core/database/app_database.dart';

/// เซอร์วิสสำหรับจัดการการยืนยันตัวตนกับ Remote Server และ Supabase (Auth API Service)
class AuthApiService {
  /// เข้าสู่ระบบผ่าน Supabase หรือ Remote PHP Server
  static Future<Map<String, dynamic>> loginRemote({
    required String email,
    required String password,
  }) async {
    try {
      // 1. ตรวจสอบว่าเปิดใช้งาน Supabase หรือไม่
      if (SupabaseService.instance.isInitialized) {
        // 1.1 ค้นหาข้อมูลผู้ใช้จากตารางผ่าน Supabase
        final existing = await SupabaseService.instance.getUserByEmail(email);
        if (existing != null) {
          final storedHash = existing['sPasswordHash']?.toString() ?? '';
          
          bool isValid = false;
          // 1.2 ถ้าเป็นผู้ใช้จาก Google Login ให้ Bypass การเช็ครหัสผ่าน
          if (storedHash == 'GOOGLE_AUTH_USER') {
            isValid = true;
          } else {
            // 1.3 ตรวจสอบความถูกต้องของ Password Hash หรือ Plaintext เดิม
            isValid = storedHash.isNotEmpty &&
                (AppDatabase.verifyPassword(password, storedHash) ||
                    storedHash == password);
          }

          // 1.4 ถ้ารหัสผ่านถูกต้อง
          if (isValid) {
            // อัปเกรดรหัสผ่านเดิมที่เป็น Plaintext ให้เป็น Secure Hash แบบอัตโนมัติ
            if (storedHash == password && password != 'GOOGLE_AUTH_USER') {
              final newHash = AppDatabase.hashPassword(password);
              existing['sPasswordHash'] = newHash;
              await SupabaseService.instance.upsertUser(existing);
            }
            return {
              'status': 'success',
              'user': existing,
              'message': 'เข้าสู่ระบบสำเร็จ',
            };
          } else {
            // ถ้ารหัสผ่านไม่ถูกต้อง
            return {
              'status': 'error',
              'message': 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
            };
          }
        }
      }

      // 2. ระบบสำรอง: ยิงไปยัง Remote PHP API Backend
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/auth/login.php');
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

      // 3. ตรวจสอบผลลัพธ์จากเซิร์ฟเวอร์
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      } else {
        try {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic>) {
            return body;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('AuthApiService: Remote login error: $e');
    }
    // 4. กรณีเกิดข้อผิดพลาดในการเชื่อมต่อ
    return {
      'status': 'offline_or_error',
      'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กำลังทำงานในโหมดออฟไลน์',
    };
  }

  /// เข้าสู่ระบบด้วยข้อมูล Google OAuth
  static Future<Map<String, dynamic>> loginWithGoogle(
    Map<String, dynamic> googleData,
  ) async {
    try {
      final email = googleData['sEmail']?.toString() ?? '';
      
      // 1. ตรวจสอบและบันทึกลง Supabase
      if (SupabaseService.instance.isInitialized && email.isNotEmpty) {
        final existing = await SupabaseService.instance.getUserByEmail(email);
        
        if (existing != null) {
          // ถ้ามีบัญชีอยู่แล้ว ให้ส่งข้อมูลกลับทันที
          return {
            'status': 'success',
            'user': existing,
            'token': 'supabase_token_$email',
            'message': 'เข้าสู่ระบบสำเร็จ',
          };
        } else {
          // ถ้าเป็นผู้ใช้ใหม่ ให้สร้าง Record ผู้ใช้บน Supabase
          final newUser = {
            'sEmail': email,
            'sFirstName': googleData['sFirstName'] ?? 'Google',
            'sLastName': googleData['sLastName'] ?? 'User',
            'sPasswordHash': 'GOOGLE_AUTH_USER',
            'dtCreatedAt': DateTime.now().toIso8601String(),
            'dtUpdatedAt': DateTime.now().toIso8601String(),
          };
          
          final inserted = await SupabaseService.instance.upsertUser(newUser);
          return {
            'status': 'success',
            'user': inserted,
            'token': 'supabase_token_$email',
            'message': 'สร้างบัญชีและเข้าสู่ระบบสำเร็จ',
          };
        }
      }

      // 2. ระบบสำรอง: ยิงไปยัง Remote PHP API Backend
      final response = await http
          .post(
            Uri.parse('${ApiServiceConfig.baseUrl}/auth/google_login.php'),
            headers: ApiServiceConfig.defaultHeaders,
            body: jsonEncode(googleData),
          )
          .timeout(const Duration(seconds: 8));

      // 3. แปลงผลลัพธ์ JSON
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('AuthApiService: Google login error: $e');
    }
    // 4. กรณีเกิดข้อผิดพลาด
    return {
      'status': 'error',
      'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง',
    };
  }
}
