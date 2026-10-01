import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service_config.dart';

class DashboardApiService {
  static Future<Map<String, dynamic>?> fetchDashboardData({
    required int userId,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiServiceConfig.baseUrl}/dashboard.php?nUserId=$userId',
      );
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      debugPrint('[API] fetchDashboardData HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        } else {
          debugPrint(
            '[API ERROR] fetchDashboardData HTTP ${response.statusCode}',
          );
        }
      } else {
        debugPrint(
          '[API ERROR] fetchDashboardData HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] fetchDashboardData failed: $e');
    }
    return null;
  }

  // ==========================================
  // Routines API
  // ==========================================

  /// 8. ดึงกิจวัตรทั้งหมดจาก Server พร้อมสถานะวันนี้
}
