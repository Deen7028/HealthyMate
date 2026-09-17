import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

class HealthApiService {
  // Base URL ของเซิร์ฟเวอร์ PHP API
  static String baseUrl = "https://std.mcs.psu.ac.th/6620310001/html/HealthyMate/api";

  /// 1. ดึงข้อมูลประวัติสุขภาพจาก PHP API (`health_records.php`)
  static Future<List<TbHealthRecord>> fetchHealthRecords({int userId = 1}) async {
    try {
      final uri = Uri.parse('$baseUrl/health_records.php?nUserId=$userId');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] is List) {
          return (body['data'] as List)
              .map((item) => TbHealthRecord.fromMap(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('PHP API offline or fallback: $e');
    }
    return [];
  }

  /// 2. บันทึกข้อมูลสุขภาพใหม่ผ่าน PHP API (`health_records.php`)
  static Future<bool> saveHealthRecord(TbHealthRecord record) async {
    try {
      final uri = Uri.parse('$baseUrl/health_records.php');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(record.toMap()),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('PHP API offline or fallback: $e');
    }
    return false;
  }

  /// 3. อัปเดตข้อมูลผู้ใช้ผ่าน PHP API (`user_profile.php`)
  /// รองรับการส่ง `Map<String, dynamic>` จาก `toPublicProfileMap()` หรือ `TbUser`
  static Future<bool> updateUserProfile(dynamic userOrMap) async {
    try {
      final uri = Uri.parse('$baseUrl/user_profile.php');
      final Map<String, dynamic> payload;
      if (userOrMap is Map<String, dynamic>) {
        payload = userOrMap;
      } else if (userOrMap is TbUser) {
        payload = userOrMap.toPublicProfileMap();
      } else {
        payload = {};
      }

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('PHP API offline or fallback: $e');
    }
    return false;
  }
}
