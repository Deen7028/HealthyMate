// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (activity api service)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/services/supabase_service.dart';
import 'api_service_config.dart';

class ActivityApiService {
  static Future<List<Map<String, dynamic>>> fetchWorkouts({
    required int userId,
    String? since,
  }) async {
    try {
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        var query = SupabaseService.instance.client!
            .from('TbWorkouts')
            .select()
            .eq('nUserId', userId);
        if (since != null && since.isNotEmpty) {
          query = query.gte('dtUpdatedAt', since);
        }
        final res = await query.order('dtWorkoutDate', ascending: false);
        return List<Map<String, dynamic>>.from(res as List);
      }

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
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] fetchWorkouts failed: $e');
    }
    return [];
  }

  /// 5. บันทึกข้อมูลการออกกำลังกาย
  static Future<bool> saveWorkout(Map<String, dynamic> workout) async {
    try {
      if (SupabaseService.instance.isInitialized) {
        final payload = Map<String, dynamic>.from(workout);
        payload.remove('nWorkoutId');
        final success = await SupabaseService.instance.upsertWorkout(payload);
        if (success) return true;
      }

      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/workouts.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(workout))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveWorkout failed: $e');
    }
    return false;
  }

  /// 5.1 บันทึกประวัติมื้ออาหาร
  static Future<bool> saveNutritionLog(Map<String, dynamic> log) async {
    try {
      if (SupabaseService.instance.isInitialized) {
        final payload = Map<String, dynamic>.from(log);
        payload.remove('nNutritionId');
        final success = await SupabaseService.instance.upsertNutritionLog(payload);
        if (success) return true;
      }

      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/nutrition_logs.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(log))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveNutritionLog failed: $e');
    }
    return false;
  }

  /// 5.2 ลบประวัติมื้ออาหาร
  static Future<bool> deleteNutritionLogRemote(int nutritionId) async {
    try {
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!
            .from('TbNutritionLogs')
            .delete()
            .eq('nNutritionId', nutritionId);
        return true;
      }

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
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] deleteNutritionLogRemote failed: $e');
    }
    return false;
  }

  /// 6. อัปโหลดรูปภาพขึ้น Supabase Storage Bucket
  static Future<String?> uploadImage(
    String localFilePath, {
    String type = 'general',
  }) async {
    try {
      if (SupabaseService.instance.isInitialized) {
        final folder = type == 'profile'
            ? 'profiles'
            : (type == 'nutrition' ? 'nutrition' : 'workouts');
        final remoteUrl = await SupabaseService.instance.uploadImage(
          localFilePath,
          folder: folder,
        );
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          return remoteUrl;
        }
      }

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
        if (body['status'] == 'success' && body['image_url'] != null) {
          return body['image_url'] as String;
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] uploadImage failed: $e');
    }
    return null;
  }
}
