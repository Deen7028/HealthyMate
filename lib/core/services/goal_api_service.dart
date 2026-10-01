import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service_config.dart';

class GoalApiService {
  static Future<bool> updateRoutineProgressRemote({
    required int routineId,
    required String date,
    required num progressValue,
    required bool isCompleted,
  }) async {
    try {
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/routines.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'action': 'update_progress',
              'nRoutineId': routineId,
              'dtLogDate': date,
              'nProgressValue': progressValue,
              'isCompleted': isCompleted ? 1 : 0,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] updateRoutineProgressRemote failed: $e');
    }
    return false;
  }

  /// 14. บันทึกหรืออัปเดตเป้าหมายหลักของผู้ใช้บน Server

  static Future<bool> saveMainGoalRemote({
    required int userId,
    int routineId = 0,
    required String title,
    required double progress,
    required String remainingText,
  }) async {
    try {
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/goals.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'nUserId': userId,
              'nRoutineId': routineId,
              'sTitle': title,
              'nProgress': progress,
              'sRemainingText': remainingText,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint(
            '☁️ [API SUCCESS] [TbGoals] ➜ บันทึกเป้าหมายหลัก "$title" ขึ้น Server สำเร็จ (ความคืบหน้า: ${(progress * 100).toInt()}%)',
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveMainGoalRemote failed: $e');
    }
    return false;
  }

  /// 15. ลบ/ปลดเป้าหมายหลักของผู้ใช้บน Server

  static Future<bool> clearMainGoalRemote(int userId) async {
    try {
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/goals.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .delete(
            uri,
            headers: headers,
            body: jsonEncode({'action': 'clear_goal', 'nUserId': userId}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint(
            '☁️ [API SUCCESS] [TbGoals] ➜ ลบ/ปลดเป้าหมายหลักบน Server สำเร็จ',
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] clearMainGoalRemote failed: $e');
    }
    return false;
  }

  /// 16. ซิงค์ค่าการตั้งค่าผู้ใช้ขึ้น Server (TbUserPreferences)

  static Future<bool> saveUserPreferencesRemote({
    required int userId,
    required String unitLabel,
  }) async {
    try {
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/user_preferences.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'nUserId': userId,
              'sUnitSystem': unitLabel.startsWith('Kilo')
                  ? 'metric'
                  : 'imperial',
              'sUnitLabel': unitLabel,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint(
            '☁️ [API SUCCESS] [TbUserPreferences] ➜ บันทึกการตั้งค่าหน่วยวัด ($unitLabel) ขึ้น Server สำเร็จ',
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveUserPreferencesRemote failed: $e');
    }
    return false;
  }

  /// 17. ซิงค์หรือปลดล็อกเหรียญรางวัล (TbUserBadges)

  static Future<bool> unlockBadgeRemote({
    required int userId,
    int? badgeId,
    String? badgeName,
  }) async {
    try {
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/badges.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'nUserId': userId,
              if (badgeId != null && badgeId > 0) 'nBadgeId': badgeId,
              'sBadgeName': ?badgeName,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' || body['status'] == 'already_earned') {
          debugPrint(
            '🏆 [API SUCCESS] [TbUserBadges] ➜ ปลดล็อก/ซิงค์เหรียญรางวัล "${badgeName ?? 'Badge #$badgeId'}" ขึ้น Server สำเร็จ',
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] unlockBadgeRemote failed: $e');
    }
    return false;
  }

  /// Helper: วันที่วันนี้ในรูปแบบ yyyy-MM-dd
}
