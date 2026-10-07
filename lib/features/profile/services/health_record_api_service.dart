import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/services/api_service_config.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/core/services/supabase_service.dart';

/// เซอร์วิสสำหรับจัดการประวัติบันทึกข้อมูลสุขภาพ (Health Record API Service)
class HealthRecordApiService {
  /// ดึงประวัติข้อมูลสุขภาพของผู้ใช้จากเซิร์ฟเวอร์
  static Future<List<TbHealthRecord>> fetchHealthRecords({
    required int userId,
  }) async {
    try {
      // 1. ดึงผ่าน Supabase Database
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

      // 2. ระบบสำรอง: ดึงผ่าน PHP API
      final uri = Uri.parse(
        '${ApiServiceConfig.baseUrl}/profile/health_records.php?nUserId=$userId',
      );
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 5));

      // 3. แปลงผลลัพธ์
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

  /// บันทึกข้อมูลสุขภาพใหม่ขึ้น Supabase หรือ PHP API
  static Future<bool> saveHealthRecord(TbHealthRecord record) async {
    try {
      // 1. บันทึกลง Supabase
      if (SupabaseService.instance.isInitialized) {
        final mapData = record.toMap();
        mapData.remove('nRecordId'); // ให้ Postgres generate ID อัตโนมัติถ้าเป็นแถวใหม่
        final success = await SupabaseService.instance.upsertHealthRecord(mapData);
        if (success) return true;
      }

      // 2. ระบบสำรอง: บันทึกผ่าน PHP API
      final uri = Uri.parse('${ApiServiceConfig.baseUrl}/profile/health_records.php');
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(record.toMap()))
          .timeout(const Duration(seconds: 5));

      // 3. ตรวจสอบสถานะผลลัพธ์
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveHealthRecord failed: $e');
    }
    return false;
  }

  /// ลบประวัติข้อมูลสุขภาพตาม recordId
  static Future<bool> deleteHealthRecordRemote(int recordId) async {
    try {
      // 1. ลบจาก Supabase
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!
            .from('TbHealthRecords')
            .delete()
            .eq('nRecordId', recordId);
        return true;
      }

      // 2. ระบบสำรอง: ลบผ่าน PHP API
      final uri = Uri.parse(
        '${ApiServiceConfig.baseUrl}/profile/health_records.php?nRecordId=$recordId',
      );
      final headers = await ApiServiceConfig.getAuthHeaders();
      final response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] deleteHealthRecordRemote failed: $e');
    }
    return false;
  }
}
