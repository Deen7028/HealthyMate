import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/services/supabase_service.dart';
import 'package:healthymate/core/services/api_service_config.dart';

/// เซอร์วิสสำหรับจัดการกิจวัตรประจำวัน (Routine API Service)
class RoutineApiService {
  /// ดึงรายการกิจวัตรทั้งหมดของผู้ใช้ตามวันที่ระบุ
  static Future<Map<String, dynamic>?> fetchRoutines({
    required int userId,
    String? date,
  }) async {
    try {
      // 1. ดึงจาก Supabase Database
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        final routines = await SupabaseService.instance.client!
            .from('TbRoutines')
            .select()
            .eq('nUserId', userId);
        return {
          'status': 'success',
          'data': List<Map<String, dynamic>>.from(routines as List),
        };
      }

      // 2. ระบบสำรอง: ดึงผ่าน PHP API
      final dateStr = date ?? ApiServiceConfig.todayDateStr();
      final uri = Uri.parse(
        '${ApiServiceConfig.baseUrl}/routines.php?nUserId=$userId&date=$dateStr',
      );
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      // 3. แปลงผลลัพธ์
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          return Map<String, dynamic>.from(body as Map);
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] fetchRoutines failed: $e');
    }
    return null;
  }

  /// เพิ่มกิจวัตรใหม่ (Insert Routine)
  static Future<int> insertRoutineRemote({
    required int userId,
    required String title,
    String time = '',
    double targetValue = 1.0,
    String unit = 'ครั้ง',
    String linkedWorkout = '',
    int? color,
    int? iconData,
    bool isNotificationActive = true,
  }) async {
    try {
      // 1. บันทึกลง Supabase
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        final res = await SupabaseService.instance.client!.from('TbRoutines').insert({
          'nUserId': userId,
          'sTitle': title,
          'sTime': time,
          'nTargetValue': targetValue,
          'sUnit': unit,
          'sLinkedWorkout': linkedWorkout,
          'nColor': color,
          'nIconData': iconData,
          'isNotificationActive': isNotificationActive ? 1 : 0,
        }).select('nRoutineId').single();

        return (res['nRoutineId'] as num?)?.toInt() ?? 0;
      }

      // 2. ระบบสำรอง: บันทึกผ่าน PHP API
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/routines.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'sTitle': title,
              'sTime': time,
              'nTargetValue': targetValue,
              'sUnit': unit,
              'sLinkedWorkout': linkedWorkout,
              'nColor': color,
              'nIconData': iconData,
              'isNotificationActive': isNotificationActive ? 1 : 0,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['nRoutineId'] != null) {
          return (body['nRoutineId'] as num).toInt();
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] insertRoutineRemote failed: $e');
    }
    return 0;
  }

  /// แก้ไขกิจวัตรเดิม (Update Routine)
  static Future<bool> updateRoutineRemote({
    required int routineId,
    required String title,
    String time = '',
    double targetValue = 1.0,
    String unit = 'ครั้ง',
    String linkedWorkout = '',
    int? color,
    int? iconData,
    bool isNotificationActive = true,
  }) async {
    try {
      // 1. อัปเดตบน Supabase
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!.from('TbRoutines').update({
          'sTitle': title,
          'sTime': time,
          'nTargetValue': targetValue,
          'sUnit': unit,
          'sLinkedWorkout': linkedWorkout,
          'nColor': color,
          'nIconData': iconData,
          'isNotificationActive': isNotificationActive ? 1 : 0,
          'dtUpdatedAt': DateTime.now().toIso8601String(),
        }).eq('nRoutineId', routineId);
        return true;
      }

      // 2. ระบบสำรอง: อัปเดตผ่าน PHP API
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/routines.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .put(
            uri,
            headers: headers,
            body: jsonEncode({
              'nRoutineId': routineId,
              'sTitle': title,
              'sTime': time,
              'nTargetValue': targetValue,
              'sUnit': unit,
              'sLinkedWorkout': linkedWorkout,
              'nColor': color,
              'nIconData': iconData,
              'isNotificationActive': isNotificationActive ? 1 : 0,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] updateRoutineRemote failed: $e');
    }
    return false;
  }

  /// ลบกิจวัตรตาม routineId
  static Future<bool> deleteRoutineRemote(int routineId) async {
    try {
      // 1. ลบจาก Supabase
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!
            .from('TbRoutines')
            .delete()
            .eq('nRoutineId', routineId);
        return true;
      }

      // 2. ระบบสำรอง: ลบผ่าน PHP API
      final uri = Uri.parse(
        '${ApiServiceConfig.baseUrl}/routines.php?nRoutineId=$routineId',
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
      debugPrint('[API EXCEPTION] deleteRoutineRemote failed: $e');
    }
    return false;
  }
}
