import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

class HealthApiService {
  // กำหนด Base URL ของเซิร์ฟเวอร์ PHP (เช่น http://172.18.111.42/api หรือ http://localhost/api)
  static String baseUrl = "https://std.mcs.psu.ac.th/6620310001/html/HealthyMate/api/";

  /// 1. ดึงข้อมูลประวัติสุขภาพจาก PHP API (`health_records.php`)
  static Future<List<TbHealthRecord>> fetchHealthRecords({int userId = 1}) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl/health_records.php?nUserId=$userId');
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final body = jsonDecode(responseBody);
        if (body['status'] == 'success' && body['data'] is List) {
          return (body['data'] as List)
              .map((item) => TbHealthRecord.fromMap(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching records from PHP API: $e');
    }
    return [];
  }

  /// 2. บันทึกข้อมูลสุขภาพใหม่ผ่าน PHP API (`health_records.php`)
  static Future<bool> saveHealthRecord(TbHealthRecord record) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl/health_records.php');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(jsonEncode(record.toMap()));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final body = jsonDecode(responseBody);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('Error saving record to PHP API: $e');
    }
    return false;
  }

  /// 3. อัปเดตข้อมูลผู้ใช้ผ่าน PHP API (`user_profile.php`)
  static Future<bool> updateUserProfile(TbUser user) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl/user_profile.php');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(jsonEncode(user.toMap()));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final body = jsonDecode(responseBody);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('Error updating user on PHP API: $e');
    }
    return false;
  }
}

