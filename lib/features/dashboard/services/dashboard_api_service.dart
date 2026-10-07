// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (dashboard api service)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/services/supabase_service.dart';
import 'package:healthymate/core/services/api_service_config.dart';

class DashboardApiService {
  static Future<Map<String, dynamic>?> fetchDashboardData({
    required int userId,
  }) async {
    try {
      // 1. ดึงข้อมูลผ่าน Supabase โดยตรง
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        final client = SupabaseService.instance.client!;

        // ดึงประวัติสุขภาพล่าสุด
        final healthRecords = await client
            .from('TbHealthRecords')
            .select()
            .eq('nUserId', userId)
            .order('dtRecordedAt', ascending: false)
            .limit(1);

        // ดึงการออกกำลังกายล่าสุด
        final workouts = await client
            .from('TbWorkouts')
            .select()
            .eq('nUserId', userId)
            .order('dtWorkoutDate', ascending: false)
            .limit(10);

        // ดึงกิจวัตรทั้งหมด
        final routines = await client
            .from('TbRoutines')
            .select()
            .eq('nUserId', userId);

        // ดึงโภชนาการวันนี้
        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final nutrition = await client
            .from('TbNutritionLogs')
            .select()
            .eq('nUserId', userId)
            .gte('dtLoggedAt', '$todayStr 00:00:00');

        return {
          'status': 'success',
          'data': {
            'latestHealthRecord': healthRecords.isNotEmpty ? healthRecords.first : null,
            'workouts': workouts,
            'routines': routines,
            'todayNutrition': nutrition,
          }
        };
      }

      // 2. Fallback PHP API
      final uri = Uri.parse(
        '${ApiServiceConfig.baseUrl}/dashboard.php?nUserId=$userId',
      );
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] fetchDashboardData failed: $e');
    }
    return null;
  }
}
