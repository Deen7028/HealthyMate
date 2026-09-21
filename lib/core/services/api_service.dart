import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

class HealthApiService {
  // Base URL ของเซิร์ฟเวอร์ PHP API
  static String baseUrl = "https://172.18.111.30/6620310001/html/HealthyMate/api";

  /// Headers พื้นฐานสำหรับ Virtual Host Apache ของ ม.อ. และระบบความปลอดภัยป้องกันการเข้าถึงตรง
  static Map<String, String> get defaultHeaders => {
    'Host': 'std.mcs.psu.ac.th',
    'Content-Type': 'application/json; charset=utf-8',
    'X-App-Key': 'HealthyMate_Secure_App_2026',
  };

  /// 0. ยืนยันตัวตนกับ Remote Server (`login.php`) เมื่อติดตั้งใหม่หรือไม่มีข้อมูลในเครื่อง
  /// คืนค่าเป็น Map พร้อม status ('success', 'not_found', 'invalid_password', 'offline_or_error') และข้อมูล user
  static Future<Map<String, dynamic>> loginRemote({
    required String email,
    required String password,
    String? passwordHash,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/login.php');
      final Map<String, dynamic> payload = {
        'sEmail': email,
        'sPassword': password,
      };
      if (passwordHash != null) {
        payload['sPasswordHash'] = passwordHash;
      }

      final response = await http
          .post(
            uri,
            headers: defaultHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      debugPrint('HealthApiService: Remote login status code: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('HealthApiService: Remote login error or offline: $e');
    }
    return {'status': 'offline_or_error', 'message': 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้'};
  }
  
  /// ส่งคำขอ OTP ไปยังอีเมล
  static Future<Map<String, dynamic>> sendEmailOtp(String sEmail) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send_email_otp.php'),
        headers: {'Content-Type': 'application/json', 'X-App-Key': 'HealthyMate_Secure_App_2026'},
        body: jsonEncode({'sEmail': sEmail}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e'};
    }
  }

  /// ยืนยันรหัส OTP
  static Future<Map<String, dynamic>> verifyEmailOtp(String sEmail, String sOtpCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify_email_otp.php'),
        headers: {'Content-Type': 'application/json', 'X-App-Key': 'HealthyMate_Secure_App_2026'},
        body: jsonEncode({'sEmail': sEmail, 'sOtpCode': sOtpCode}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e'};
    }
  }

  /// 1. ดึงข้อมูลประวัติสุขภาพจาก PHP API (`health_records.php`)
  static Future<List<TbHealthRecord>> fetchHealthRecords({
    int userId = 1,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/health_records.php?nUserId=$userId');
      final response = await http
          .get(uri, headers: defaultHeaders)
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
        debugPrint('[API ERROR] fetchHealthRecords HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] fetchHealthRecords failed: $e');
    }
    return [];
  }

  /// 2. บันทึกข้อมูลสุขภาพใหม่ผ่าน PHP API (`health_records.php`)
  static Future<bool> saveHealthRecord(TbHealthRecord record) async {
    try {
      final uri = Uri.parse('$baseUrl/health_records.php');
      final response = await http
          .post(
            uri,
            headers: defaultHeaders,
            body: jsonEncode(record.toMap()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      } else {
        debugPrint('[API ERROR] saveHealthRecord HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveHealthRecord failed: $e');
    }
    return false;
  }

  /// 3. อัปเดตข้อมูลผู้ใช้ผ่าน PHP API (`user_profile.php`)
  /// รองรับการส่ง `Map<String, dynamic>` จาก `toPublicProfileMap()` หรือ `TbUser`
  static Future<bool> updateUserProfile(dynamic userOrMap) async {
    try {
      final uri = Uri.parse('$baseUrl/user_profile.php');
      final Map<String, dynamic> payload;
      if (userOrMap is Map<String, dynamic>) {
        payload = userOrMap;
      } else if (userOrMap is TbUser) {
        payload = userOrMap.toPublicProfileMap();
      } else {
        payload = {};
      }

      final response = await http
          .post(
            uri,
            headers: defaultHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      } else {
        debugPrint('[API ERROR] updateUserProfile HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] updateUserProfile failed: $e');
    }
    return false;
  }

  /// 4. ดึงประวัติการออกกำลังกายจาก PHP API (`workouts.php`)
  /// รองรับทั้ง Initial Data Hydration (ดึงทั้งหมด) และ Delta Sync (เฉพาะรายการใหม่ตั้งแต่ since)
  static Future<List<Map<String, dynamic>>> fetchWorkouts({
    required int userId,
    String? since,
  }) async {
    try {
      var urlStr = '$baseUrl/workouts.php?nUserId=$userId';
      if (since != null && since.isNotEmpty) {
        urlStr += '&since=${Uri.encodeComponent(since)}';
      }
      final uri = Uri.parse(urlStr);
      final response = await http
          .get(uri, headers: defaultHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] is List) {
          return List<Map<String, dynamic>>.from(
            (body['data'] as List).map((item) => Map<String, dynamic>.from(item as Map)),
          );
        }
      } else {
        debugPrint('[API ERROR] fetchWorkouts HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] fetchWorkouts failed: $e');
    }
    return [];
  }

  /// 5. บันทึกข้อมูลการออกกำลังกายขึ้น PHP API (`workouts.php`)
  static Future<bool> saveWorkout(Map<String, dynamic> workout) async {
    try {
      final uri = Uri.parse('$baseUrl/workouts.php');
      final response = await http
          .post(
            uri,
            headers: defaultHeaders,
            body: jsonEncode(workout),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      } else {
        debugPrint('[API ERROR] saveWorkout HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveWorkout failed: $e');
    }
    return false;
  }

  /// 5. บันทึกประวัติมื้ออาหารขึ้น PHP API (`nutrition_logs.php`)
  static Future<bool> saveNutritionLog(Map<String, dynamic> log) async {
    try {
      final uri = Uri.parse('$baseUrl/nutrition_logs.php');
      final response = await http
          .post(
            uri,
            headers: defaultHeaders,
            body: jsonEncode(log),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      } else {
        debugPrint('[API ERROR] saveNutritionLog HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveNutritionLog failed: $e');
    }
    return false;
  }

  /// 6. อัปโหลดรูปภาพขึ้น Server (/uploads) และรับ path กลับมาบันทึกลง Database
  static Future<String?> uploadImage(
    String localFilePath, {
    String type = 'general',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/upload_image.php');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Host': 'std.mcs.psu.ac.th',
          'X-App-Key': 'HealthyMate_Secure_App_2026',
        })
        ..fields['type'] = type
        ..files.add(await http.MultipartFile.fromPath('image', localFilePath));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          return body['filePath']
              as String?; // ส่งกลับ "uploads/profile/xxx.jpg"
        }
      }
    } catch (e) {
      debugPrint('Error uploading image to server: $e');
    }
    return null;
  }

  // ==========================================
  // Dashboard API (Aggregated Endpoint)
  // ==========================================

  /// 7. ดึงข้อมูล Dashboard รวม (user, healthRecord, workoutStats, nutrition, goal, routines)
  /// ใน HTTP request เดียวเพื่อลด latency
  static Future<Map<String, dynamic>?> fetchDashboardData({
    required int userId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/dashboard.php?nUserId=$userId');
      final response = await http
          .get(uri, headers: defaultHeaders)
          .timeout(const Duration(seconds: 8));

      debugPrint('[API] fetchDashboardData HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        } else {
          debugPrint('[API ERROR] fetchDashboardData: ${response.body}');
        }
      } else {
        debugPrint('[API ERROR] fetchDashboardData HTTP ${response.statusCode}: ${response.body}');
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
  static Future<Map<String, dynamic>?> fetchRoutines({
    required int userId,
    String? date,
  }) async {
    try {
      final dateStr = date ?? _todayDateStr();
      final uri = Uri.parse('$baseUrl/routines.php?nUserId=$userId&date=$dateStr');
      final response = await http
          .get(uri, headers: defaultHeaders)
          .timeout(const Duration(seconds: 8));

      debugPrint('[API] fetchRoutines HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          return Map<String, dynamic>.from(body as Map);
        }
      } else {
        debugPrint('[API ERROR] fetchRoutines HTTP ${response.statusCode}: ${response.body}');
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
    bool isNotificationActive = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/routines.php');
      final response = await http
          .post(
            uri,
            headers: defaultHeaders,
            body: jsonEncode({
              'action': 'insert',
              'nUserId': userId,
              'sTitle': title,
              'sTime': time,
              'isNotificationActive': isNotificationActive ? 1 : 0,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint('[API] ✅ insertRoutineRemote: $title (ID=${body['nRoutineId']})');
          return (body['nRoutineId'] as num?)?.toInt() ?? 0;
        }
      }
      debugPrint('[API ERROR] insertRoutineRemote HTTP ${response.statusCode}: ${response.body}');
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
    bool isNotificationActive = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/routines.php');
      final response = await http
          .put(
            uri,
            headers: defaultHeaders,
            body: jsonEncode({
              'nRoutineId': routineId,
              'sTitle': title,
              'sTime': time,
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
      final uri = Uri.parse('$baseUrl/routines.php');
      final response = await http
          .delete(
            uri,
            headers: defaultHeaders,
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
      final dateStr = date ?? _todayDateStr();
      final uri = Uri.parse('$baseUrl/routines.php');
      final response = await http
          .post(
            uri,
            headers: defaultHeaders,
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

  /// Helper: วันที่วันนี้ในรูปแบบ yyyy-MM-dd
  static String _todayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
