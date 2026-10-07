// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (goal api service)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/services/supabase_service.dart';
import 'package:healthymate/core/services/api_service_config.dart';

class GoalApiService {
  static Future<bool> updateRoutineProgressRemote({
    required int routineId,
    required String date,
    required num progressValue,
    required bool isCompleted,
  }) async {
    try {
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        final client = SupabaseService.instance.client!;
        final existing = await client
            .from('TbRoutineLogs')
            .select()
            .eq('nRoutineId', routineId)
            .eq('dtLogDate', date)
            .maybeSingle();

        if (existing != null) {
          await client.from('TbRoutineLogs').update({
            'nProgressValue': progressValue.toDouble(),
            'isCompleted': isCompleted,
            'dtUpdatedAt': DateTime.now().toIso8601String(),
          }).eq('nRoutineId', routineId).eq('dtLogDate', date);
        } else {
          await client.from('TbRoutineLogs').insert({
            'nRoutineId': routineId,
            'dtLogDate': date,
            'nProgressValue': progressValue.toDouble(),
            'isCompleted': isCompleted,
          });
        }
        return true;
      }

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
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        final payload = {
          'nUserId': userId,
          if (routineId > 0) 'nRoutineId': routineId,
          'sTitle': title,
          'nProgress': progress,
          'sRemainingText': remainingText,
          'dtUpdatedAt': DateTime.now().toIso8601String(),
        };
        final success = await SupabaseService.instance.upsertGoal(payload);
        if (success) return true;
      }

      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/routines/goals.php');
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
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!
            .from('TbGoals')
            .delete()
            .eq('nUserId', userId);
        return true;
      }

      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/routines/goals.php');
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
        return body['status'] == 'success';
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
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!.from('TbUserPreferences').upsert({
          'nUserId': userId,
          'sUnitSystem': unitLabel.startsWith('Kilo') ? 'metric' : 'imperial',
          'sUnitLabel': unitLabel,
        });
        return true;
      }

      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/profile/user_preferences.php');
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
        return body['status'] == 'success';
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
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        if (badgeId != null && badgeId > 0) {
          await SupabaseService.instance.client!.from('TbUserBadges').upsert({
            'nUserId': userId,
            'nBadgeId': badgeId,
          });
          return true;
        }
      }

      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/routines/badges.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'nUserId': userId,
              if (badgeId != null && badgeId > 0) 'nBadgeId': badgeId,
              if (badgeName != null) 'sBadgeName': badgeName,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success' || body['status'] == 'already_earned';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] unlockBadgeRemote failed: $e');
    }
    return false;
  }
}
