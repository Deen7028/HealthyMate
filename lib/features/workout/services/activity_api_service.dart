import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/services/supabase_service.dart';
import 'package:healthymate/core/services/api_service_config.dart';

/// เซอร์วิสสำหรับจัดการบันทึกกิจกรรมการออกกำลังกาย และประวัติโภชนาการ (Activity API Service)
class ActivityApiService {
  /// ดึงประวัติการออกกำลังกายของผู้ใช้
  static Future<List<Map<String, dynamic>>> fetchWorkouts({
    required int userId,
    String? since,
  }) async {
    try {
      // 1. ดึงข้อมูลจาก Supabase Database
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

      // 2. ระบบสำรอง: ดึงผ่าน PHP API
      var urlStr = '${ApiServiceConfig.baseUrl}/workouts/workouts.php?nUserId=$userId';
      if (since != null && since.isNotEmpty) {
        urlStr += '&since=${Uri.encodeComponent(since)}';
      }
      final uri = Uri.parse(urlStr);
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      // 3. แปลงผลลัพธ์
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

  /// บันทึกข้อมูลกิจกรรมการออกกำลังกาย
  static Future<bool> saveWorkout(Map<String, dynamic> workout) async {
    try {
      // 1. บันทึกลง Supabase
      if (SupabaseService.instance.isInitialized) {
        final payload = Map<String, dynamic>.from(workout);
        payload.remove('nWorkoutId');
        final success = await SupabaseService.instance.upsertWorkout(payload);
        if (success) return true;
      }

      // 2. ระบบสำรอง: บันทึกผ่าน PHP API
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/workouts/workouts.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(workout))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveWorkout failed: $e');
    }
    return false;
  }

  /// บันทึกประวัติมื้ออาหารและโภชนาการ (AI Nutrition Log)
  static Future<bool> saveNutritionLogRemote(Map<String, dynamic> log) async {
    try {
      // 1. บันทึกลง Supabase
      if (SupabaseService.instance.isInitialized) {
        final payload = Map<String, dynamic>.from(log);
        payload.remove('nNutritionId');
        final success = await SupabaseService.instance.upsertNutritionLog(payload);
        if (success) return true;
      }

      // 2. ระบบสำรอง: บันทึกผ่าน PHP API
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/nutrition/nutrition_logs.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(log))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveNutritionLogRemote failed: $e');
    }
    return false;
  }

  /// ลบประวัติมื้ออาหารตาม nutritionId
  static Future<bool> deleteNutritionLogRemote(int nutritionId) async {
    try {
      // 1. ลบจาก Supabase
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!
            .from('TbNutritionLogs')
            .delete()
            .eq('nNutritionId', nutritionId);
        return true;
      }

      // 2. ระบบสำรอง: ลบผ่าน PHP API
      final uri = Uri.parse(
        '${ApiServiceConfig.baseUrl}/nutrition/nutrition_logs.php?nNutritionId=$nutritionId',
      );
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] deleteNutritionLogRemote failed: $e');
    }
    return false;
  }

  /// บันทึกประวัติมื้ออาหาร (Alias สำหรับ SyncService)
  static Future<bool> saveNutritionLog(Map<String, dynamic> log) => saveNutritionLogRemote(log);

  /// อัปโหลดรูปภาพไปยัง Supabase Storage หรือ PHP Backend
  static Future<String?> uploadImage(
    String localFilePath, {
    String type = 'general',
  }) async {
    try {
      final file = File(localFilePath);
      if (!await file.exists()) return null;

      // 1. อัปโหลดผ่าน Supabase Storage (ถ้าเปิดใช้งาน)
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        final bytes = await file.readAsBytes();
        final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await SupabaseService.instance.client!.storage
            .from('uploads')
            .uploadBinary('$type/$fileName', bytes);
        final publicUrl = SupabaseService.instance.client!.storage
            .from('uploads')
            .getPublicUrl('$type/$fileName');
        return publicUrl;
      }

      // 2. ระบบสำรอง: อัปโหลดผ่าน PHP API
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/media/upload_image.php');
      final request = http.MultipartRequest('POST', uri);
      final headers = await ApiServiceConfig.getAuthHeaders();
      request.headers.addAll(headers);
      request.fields['type'] = type;
      request.files.add(
        await http.MultipartFile.fromPath('image', localFilePath),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['url'] != null) {
          return body['url'].toString();
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] uploadImage failed: $e');
    }
    return null;
  }
}
