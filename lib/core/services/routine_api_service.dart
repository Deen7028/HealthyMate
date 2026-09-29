import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service_config.dart';

class RoutineApiService {
  static Future<Map<String, dynamic>?> fetchRoutines({
    required int userId,
    String? date,
  }) async {
    try {
      final dateStr = date ?? ApiServiceConfig.todayDateStr();
      final uri = Uri.parse(
        '${ApiServiceConfig.baseUrl}/routines.php?nUserId=$userId&date=$dateStr',
      );
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      debugPrint('[API] fetchRoutines HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          return Map<String, dynamic>.from(body as Map);
        }
      } else {
        debugPrint('[API ERROR] fetchRoutines HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] fetchRoutines failed: $e');
    }
    return null;
  }

  /// 9. เพิ่มกิจวัตรใหม่ขึ้น Server

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
          debugPrint(
            '[API] ✅ insertRoutineRemote: $title (ID=${body['nRoutineId']})',
          );
          return (body['nRoutineId'] as num?)?.toInt() ?? 0;
        }
      }
      debugPrint('[API ERROR] insertRoutineRemote HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('[API EXCEPTION] insertRoutineRemote failed: $e');
    }
    return 0;
  }

  /// 10. แก้ไขกิจวัตรบน Server

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

  /// 11. ลบกิจวัตรจาก Server

  static Future<bool> deleteRoutineRemote(int routineId) async {
    try {
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

  /// 12. สลับสถานะเช็ค/ยกเลิกเช็คกิจวัตรบน Server

  static Future<bool?> toggleRoutineLogRemote({
    required int routineId,
    String? date,
  }) async {
    try {
      final dateStr = date ?? ApiServiceConfig.todayDateStr();
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

  /// 13. อัปเดตความคืบหน้าย่อยของกิจวัตรบน Server (`update_progress`)
}
