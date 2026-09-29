import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service_config.dart';

class ActivityApiService {
  static Future<List<Map<String, dynamic>>> fetchWorkouts({
    required int userId,
    String? since,
  }) async {
    try {
      var urlStr = '${ApiServiceConfig.baseUrl}/workouts.php?nUserId=$userId';
      if (since != null && since.isNotEmpty) {
        urlStr += '&since=${Uri.encodeComponent(since)}';
      }
      final uri = Uri.parse(urlStr);
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] is List) {
          return List<Map<String, dynamic>>.from(
            (body['data'] as List).map(
              (item) => Map<String, dynamic>.from(item as Map),
            ),
          );
        }
      } else {
        debugPrint('[API ERROR] fetchWorkouts HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] fetchWorkouts failed: $e');
    }
    return [];
  }

  /// 5. บันทึกข้อมูลการออกกำลังกายขึ้น PHP API (`workouts.php`)

  static Future<bool> saveWorkout(Map<String, dynamic> workout) async {
    try {
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/workouts.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(workout))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint(
            '☁️ [API SUCCESS] [TbWorkouts] ➜ บันทึกการออกกำลังกายขึ้น Server สำเร็จ (${workout['sType']}, ${workout['nDistance']} กม.)',
          );
          return true;
        }
      } else {
        debugPrint('[API ERROR] saveWorkout HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveWorkout failed: $e');
    }
    return false;
  }

  /// 5. บันทึกประวัติมื้ออาหารขึ้น PHP API (`nutrition_logs.php`)

  static Future<bool> saveNutritionLog(Map<String, dynamic> log) async {
    try {
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/nutrition_logs.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(log))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint(
            '☁️ [API SUCCESS] [TbNutritionLogs] ➜ บันทึกมื้ออาหาร "${log['sFoodName']}" (${log['nCalories']} kcal) ขึ้น Server สำเร็จ',
          );
          return true;
        }
      } else {
        debugPrint('[API ERROR] saveNutritionLog HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveNutritionLog failed: $e');
    }
    return false;
  }

  /// 5.1 ลบประวัติสุขภาพจาก Server (`health_records.php`)

  static Future<bool> deleteNutritionLogRemote(int nutritionId) async {
    try {
      final uri = Uri.parse(
        '${ApiServiceConfig.baseUrl}/nutrition_logs.php?nNutritionId=$nutritionId',
      );
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .delete(
            uri,
            headers: headers,
            body: jsonEncode({'nNutritionId': nutritionId}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint(
            '☁️ [API SUCCESS] [TbNutritionLogs] ➜ ลบรายการมื้ออาหาร ID: $nutritionId บน Server สำเร็จ',
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] deleteNutritionLogRemote failed: $e');
    }
    return false;
  }

  /// 6. อัปโหลดรูปภาพขึ้น Server (/uploads) และรับ path กลับมาบันทึกลง Database

  static Future<String?> uploadImage(
    String localFilePath, {
    String type = 'general',
  }) async {
    try {
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/upload_image.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..fields['type'] = type
        ..files.add(await http.MultipartFile.fromPath('image', localFilePath));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          return body['filePath']
              as String?; // ส่งกลับ "uploads/profile/xxx.jpg"
        }
      }
    } catch (e) {
      debugPrint('Error uploading image to server: $e');
    }
    return null;
  }

  // ==========================================
  // Dashboard API (Aggregated Endpoint)
  // ==========================================

  /// 7. ดึงข้อมูล Dashboard รวม (user, healthRecord, workoutStats, nutrition, goal, routines)
  /// ใน HTTP request เดียวเพื่อลด latency
}
