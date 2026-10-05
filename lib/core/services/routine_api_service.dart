// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (routine api service)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/services/supabase_service.dart';
import 'api_service_config.dart';

class RoutineApiService {
  static Future<Map<String, dynamic>?> fetchRoutines({
    required int userId,
    String? date,
  }) async {
    try {
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

      final dateStr = date ?? ApiServiceConfig.todayDateStr();
      final uri = Uri.parse(
        '${ApiServiceConfig.baseUrl}/routines.php?nUserId=$userId&date=$dateStr',
      );
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

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

  /// 9. เพิ่มกิจวัตรใหม่
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
          'isNotificationActive': isNotificationActive,
        }).select('nRoutineId').maybeSingle();

        if (res != null && res['nRoutineId'] != null) {
          return (res['nRoutineId'] as num).toInt();
        }
      }

      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/routines.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'action': 'insert',
              'nUserId': userId,
              'sTitle': title,
              'sTime': time,
              'targetValue': targetValue,
              'unit': unit,
              'sLinkedWorkout': linkedWorkout,
              'color': color,
              'iconData': iconData,
              'isNotificationActive': isNotificationActive ? 1 : 0,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          return (body['nRoutineId'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] insertRoutineRemote failed: $e');
    }
    return 0;
  }

  /// 10. แก้ไขกิจวัตร
  static Future<bool> updateRoutineRemote({
    required int routineId,
    required String title,
    String time = '',
    double? targetValue,
    String? unit,
    String? linkedWorkout,
    int? color,
    int? iconData,
    bool isNotificationActive = true,
  }) async {
    try {
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!.from('TbRoutines').update({
          'sTitle': title,
          'sTime': time,
          'nTargetValue': targetValue,
          'sUnit': unit,
          'sLinkedWorkout': linkedWorkout,
          'nColor': color,
          'nIconData': iconData,
          'isNotificationActive': isNotificationActive,
        }).eq('nRoutineId', routineId);
        return true;
      }

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
              'targetValue': targetValue,
              'nTargetValue': targetValue,
              'unit': unit,
              'sUnit': unit,
              'sLinkedWorkout': linkedWorkout,
              'color': color,
              'nColor': color,
              'iconData': iconData,
              'nIconData': iconData,
              'isNotificationActive': isNotificationActive ? 1 : 0,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] updateRoutineRemote failed: $e');
    }
    return false;
  }

  /// 11. ลบกิจวัตร
  static Future<bool> deleteRoutineRemote(int routineId) async {
    try {
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!
            .from('TbRoutines')
            .delete()
            .eq('nRoutineId', routineId);
        return true;
      }

      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/routines.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .delete(
            uri,
            headers: headers,
            body: jsonEncode({'nRoutineId': routineId}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] deleteRoutineRemote failed: $e');
    }
    return false;
  }

  /// 12. สลับสถานะเช็ค/ยกเลิกเช็คกิจวัตร
  static Future<bool?> toggleRoutineLogRemote({
    required int routineId,
    String? date,
  }) async {
    try {
      final dateStr = date ?? ApiServiceConfig.todayDateStr();

      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        final client = SupabaseService.instance.client!;
        final existing = await client
            .from('TbRoutineLogs')
            .select()
            .eq('nRoutineId', routineId)
            .eq('dtLogDate', dateStr)
            .maybeSingle();

        if (existing != null) {
          final current = existing['isCompleted'] == true;
          final updated = !current;
          await client
              .from('TbRoutineLogs')
              .update({'isCompleted': updated, 'dtUpdatedAt': DateTime.now().toIso8601String()})
              .eq('nRoutineId', routineId)
              .eq('dtLogDate', dateStr);
          return updated;
        } else {
          await client.from('TbRoutineLogs').insert({
            'nRoutineId': routineId,
            'dtLogDate': dateStr,
            'isCompleted': true,
            'nProgressValue': 1.0,
          });
          return true;
        }
      }

      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/routines.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'action': 'toggle_log',
              'nRoutineId': routineId,
              'dtLogDate': dateStr,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          return (body['isCompleted'] as num?)?.toInt() == 1;
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] toggleRoutineLogRemote failed: $e');
    }
    return null;
  }
}
