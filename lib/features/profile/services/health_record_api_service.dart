import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/services/api_service_config.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';

import 'package:healthymate/core/services/supabase_service.dart';

class HealthRecordApiService {
  static Future<List<TbHealthRecord>> fetchHealthRecords({
    required int userId,
  }) async {
    try {
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        final res = await SupabaseService.instance.client!
            .from('TbHealthRecords')
            .select()
            .eq('nUserId', userId)
            .order('dtRecordedAt', ascending: false);
        return (res as List)
            .map((item) => TbHealthRecord.fromMap(item as Map<String, dynamic>))
            .toList();
      }

      final uri = Uri.parse(
        '${ApiServiceConfig.baseUrl}/profile/health_records.php?nUserId=$userId',
      );
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] is List) {
          return (body['data'] as List)
              .map(
                (item) => TbHealthRecord.fromMap(item as Map<String, dynamic>),
              )
              .toList();
        }
      } else {
        debugPrint(
          '[API ERROR] fetchHealthRecords HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] fetchHealthRecords failed: $e');
    }
    return [];
  }

  /// 2. บันทึกข้อมูลสุขภาพใหม่ผ่าน Supabase / PHP API (`health_records.php`)

  static Future<bool> saveHealthRecord(TbHealthRecord record) async {
    try {
      if (SupabaseService.instance.isInitialized) {
        final mapData = record.toMap();
        mapData.remove('nRecordId'); // ให้ Postgres generate ID อัตโนมัติถ้าเป็นแถวใหม่
        final success = await SupabaseService.instance.upsertHealthRecord(mapData);
        if (success) return true;
      }

      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/profile/health_records.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(record.toMap()))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint(
            '☁️ [API SUCCESS] [TbHealthRecords] ➜ บันทึกประวัติสุขภาพสำเร็จ (BMI: ${record.nBmi.toStringAsFixed(1)}, TDEE: ${record.nTdee.round()} kcal)',
          );
          return true;
        }
      } else {
        debugPrint('[API ERROR] saveHealthRecord HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveHealthRecord failed: $e');
    }
    return false;
  }

  /// 3. อัปเดตข้อมูลผู้ใช้ผ่าน PHP API (`user_profile.php`)
  /// รองรับการส่ง `Map<String, dynamic>` จาก `toPublicProfileMap()` หรือ `TbUser`

  static Future<bool> deleteHealthRecordRemote(int recordId) async {
    try {
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!
            .from('TbHealthRecords')
            .delete()
            .eq('nRecordId', recordId);
        return true;
      }

      final uri = Uri.parse(
        '${ApiServiceConfig.baseUrl}/profile/health_records.php?nRecordId=$recordId',
      );
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .delete(
            uri,
            headers: headers,
            body: jsonEncode({'nRecordId': recordId}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint(
            '☁️ [API SUCCESS] [TbHealthRecords] ➜ ลบประวัติสุขภาพ ID: $recordId บน Server สำเร็จ',
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] deleteHealthRecordRemote failed: $e');
    }
    return false;
  }

  /// 5.2 ลบรายการมื้ออาหารจาก Server (`nutrition_logs.php`)
}
