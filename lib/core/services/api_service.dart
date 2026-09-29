import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/config/app_config.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

class HealthApiService {
  // Base URL ของเซิร์ฟเวอร์ PHP API ดึงจาก .env (AppConfig)
  static String get baseUrl => AppConfig.baseUrl;

  /// Headers พื้นฐานสำหรับระบบความปลอดภัยและการเรียก API
  static Map<String, String> get defaultHeaders {
    final headers = <String, String>{'Content-Type': 'application/json; charset=utf-8'};
    if (AppConfig.appKey.isNotEmpty) {
      headers['X-App-Key'] = AppConfig.appKey;
    }
    if (AppConfig.hostHeader.isNotEmpty) {
      headers['Host'] = AppConfig.hostHeader;
    }
    return headers;
  }

  /// ดึง Headers พร้อม Authorization Bearer Token
  static Future<Map<String, String>> getAuthHeaders() async {
    final headers = Map<String, String>.from(defaultHeaders);
    final token = await AppDatabase.instance.getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// 0. ยืนยันตัวตนกับ Remote Server (`login.php`) เมื่อติดตั้งใหม่หรือไม่มีข้อมูลในเครื่อง
  /// คืนค่าเป็น Map พร้อม status ('success', 'not_found', 'invalid_password', 'offline_or_error') และข้อมูล user
  static Future<Map<String, dynamic>> loginRemote({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/login.php');
      final Map<String, dynamic> payload = {
        'sEmail': email,
        'sPassword': password,
      };

      final response = await http
          .post(
            uri,
            headers: defaultHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      debugPrint('HealthApiService: Remote login HTTP ${response.statusCode}');

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

  /// ตรวจสอบการซ้ำของอีเมลกับ Remote Server (`check_email.php`)
  static Future<Map<String, dynamic>> checkEmailRemote(String email) async {
    try {
      final uri = Uri.parse('$baseUrl/check_email.php');
      final response = await http
          .post(
            uri,
            headers: defaultHeaders,
            body: jsonEncode({'sEmail': email}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('HealthApiService: Check email error: $e');
    }
    return {'status': 'offline_or_error', 'exists': false};
  }
  
  /// ส่งคำขอ OTP ไปยังอีเมล
  static Future<Map<String, dynamic>> sendEmailOtp(String sEmail) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/send_email_otp.php'),
            headers: defaultHeaders,
            body: jsonEncode({'sEmail': sEmail}),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
      return {
        'status': 'error',
        'message': 'ตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง (HTTP ${response.statusCode})',
      };
    } catch (e) {
      return {'status': 'error', 'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e'};
    }
  }

  /// ยืนยันรหัส OTP
  static Future<Map<String, dynamic>> verifyEmailOtp(String sEmail, String sOtpCode) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/verify_email_otp.php'),
            headers: defaultHeaders,
            body: jsonEncode({'sEmail': sEmail, 'sOtpCode': sOtpCode}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
      return {
        'status': 'error',
        'message': 'ตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง (HTTP ${response.statusCode})',
      };
    } catch (e) {
      return {'status': 'error', 'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e'};
    }
  }

  /// 1. ดึงข้อมูลประวัติสุขภาพจาก PHP API (`health_records.php`)
  static Future<List<TbHealthRecord>> fetchHealthRecords({
    required int userId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/health_records.php?nUserId=$userId');
      final headers = await getAuthHeaders();
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
        debugPrint('[API ERROR] fetchHealthRecords HTTP ${response.statusCode}');
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
      final headers = await getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(record.toMap()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint('☁️ [API SUCCESS] [TbHealthRecords] ➜ บันทึกประวัติสุขภาพสำเร็จ (BMI: ${record.nBmi.toStringAsFixed(1)}, TDEE: ${record.nTdee.round()} kcal)');
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
  static Future<bool> updateUserProfile(dynamic userOrMap) async {
    try {
      final uri = Uri.parse('$baseUrl/user_profile.php');
      final Map<String, dynamic> payload;
      if (userOrMap is Map<String, dynamic>) {
        payload = Map<String, dynamic>.from(userOrMap)
          ..removeWhere((key, _) => const {
            'sPassword',
            'sPasswordHash',
            'sGeminiApiKey',
            'sAuthToken',
          }.contains(key));
      } else if (userOrMap is TbUser) {
        payload = userOrMap.toPublicProfileMap();
      } else {
        payload = {};
      }

      final headers = await getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint('☁️ [API SUCCESS] [TbUsers] ➜ อัปเดตข้อมูลผู้ใช้สำเร็จ');
          return true;
        }
      } else {
        debugPrint('[API ERROR] updateUserProfile HTTP ${response.statusCode}');
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
      final headers = await getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] is List) {
          return List<Map<String, dynamic>>.from(
            (body['data'] as List).map((item) => Map<String, dynamic>.from(item as Map)),
          );
        }
      } else {
        debugPrint('[API ERROR] fetchWorkouts HTTP ${response.statusCode}');
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
      final headers = await getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(workout),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint('☁️ [API SUCCESS] [TbWorkouts] ➜ บันทึกการออกกำลังกายขึ้น Server สำเร็จ (${workout['sType']}, ${workout['nDistance']} กม.)');
          return true;
        }
      } else {
        debugPrint('[API ERROR] saveWorkout HTTP ${response.statusCode}');
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
      final headers = await getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(log),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint('☁️ [API SUCCESS] [TbNutritionLogs] ➜ บันทึกมื้ออาหาร "${log['sFoodName']}" (${log['nCalories']} kcal) ขึ้น Server สำเร็จ');
          return true;
        }
      } else {
        debugPrint('[API ERROR] saveNutritionLog HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] saveNutritionLog failed: $e');
    }
    return false;
  }

  /// 5.1 ลบประวัติสุขภาพจาก Server (`health_records.php`)
  static Future<bool> deleteHealthRecordRemote(int recordId) async {
    try {
      final uri = Uri.parse('$baseUrl/health_records.php?nRecordId=$recordId');
      final headers = await getAuthHeaders();
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
          debugPrint('☁️ [API SUCCESS] [TbHealthRecords] ➜ ลบประวัติสุขภาพ ID: $recordId บน Server สำเร็จ');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] deleteHealthRecordRemote failed: $e');
    }
    return false;
  }

  /// 5.2 ลบรายการมื้ออาหารจาก Server (`nutrition_logs.php`)
  static Future<bool> deleteNutritionLogRemote(int nutritionId) async {
    try {
      final uri = Uri.parse('$baseUrl/nutrition_logs.php?nNutritionId=$nutritionId');
      final headers = await getAuthHeaders();
      final response = await http
          .delete(
            uri,
            headers: headers,
            body: jsonEncode({'nNutritionId': nutritionId}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint('☁️ [API SUCCESS] [TbNutritionLogs] ➜ ลบรายการมื้ออาหาร ID: $nutritionId บน Server สำเร็จ');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] deleteNutritionLogRemote failed: $e');
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
      final headers = await getAuthHeaders();
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
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
      final headers = await getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      debugPrint('[API] fetchDashboardData HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        } else {
          debugPrint('[API ERROR] fetchDashboardData HTTP ${response.statusCode}');
        }
      } else {
        debugPrint('[API ERROR] fetchDashboardData HTTP ${response.statusCode}');
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
      final headers = await getAuthHeaders();
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
      final uri = Uri.parse('$baseUrl/routines.php');
      final headers = await getAuthHeaders();
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
          debugPrint('[API] ✅ insertRoutineRemote: $title (ID=${body['nRoutineId']})');
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
      final uri = Uri.parse('$baseUrl/routines.php');
      final headers = await getAuthHeaders();
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
      final uri = Uri.parse('$baseUrl/routines.php');
      final headers = await getAuthHeaders();
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
      final dateStr = date ?? _todayDateStr();
      final uri = Uri.parse('$baseUrl/routines.php');
      final headers = await getAuthHeaders();
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
  static Future<bool> updateRoutineProgressRemote({
    required int routineId,
    required String date,
    required num progressValue,
    required bool isCompleted,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/routines.php');
      final headers = await getAuthHeaders();
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
      final uri = Uri.parse('$baseUrl/goals.php');
      final headers = await getAuthHeaders();
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
          debugPrint('☁️ [API SUCCESS] [TbGoals] ➜ บันทึกเป้าหมายหลัก "$title" ขึ้น Server สำเร็จ (ความคืบหน้า: ${(progress * 100).toInt()}%)');
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
      final uri = Uri.parse('$baseUrl/goals.php');
      final headers = await getAuthHeaders();
      final response = await http
          .delete(
            uri,
            headers: headers,
            body: jsonEncode({
              'action': 'clear_goal',
              'nUserId': userId,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint('☁️ [API SUCCESS] [TbGoals] ➜ ลบ/ปลดเป้าหมายหลักบน Server สำเร็จ');
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
      final uri = Uri.parse('$baseUrl/user_preferences.php');
      final headers = await getAuthHeaders();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'nUserId': userId,
              'sUnitSystem': unitLabel.startsWith('Kilo') ? 'metric' : 'imperial',
              'sUnitLabel': unitLabel,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          debugPrint('☁️ [API SUCCESS] [TbUserPreferences] ➜ บันทึกการตั้งค่าหน่วยวัด ($unitLabel) ขึ้น Server สำเร็จ');
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
      final uri = Uri.parse('$baseUrl/badges.php');
      final headers = await getAuthHeaders();
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
          debugPrint('🏆 [API SUCCESS] [TbUserBadges] ➜ ปลดล็อก/ซิงค์เหรียญรางวัล "${badgeName ?? 'Badge #$badgeId'}" ขึ้น Server สำเร็จ');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[API EXCEPTION] unlockBadgeRemote failed: $e');
    }
    return false;
  }

  /// Helper: วันที่วันนี้ในรูปแบบ yyyy-MM-dd
  static String _todayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// ส่งคำขอ OTP สำหรับลืมรหัสผ่าน
  static Future<Map<String, dynamic>> sendForgotPasswordOtp(String sEmail) async {
    try {
      debugPrint('[API] sendForgotPasswordOtp: $baseUrl/send_forgot_password_otp.php');
      final response = await http
          .post(
            Uri.parse('$baseUrl/send_forgot_password_otp.php'),
            headers: defaultHeaders,
            body: jsonEncode({'sEmail': sEmail}),
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('[API] sendForgotPasswordOtp HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
      return {
        'status': 'error',
        'message': 'ตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง (HTTP ${response.statusCode})',
      };
    } catch (e) {
      debugPrint('[API ERROR] sendForgotPasswordOtp: $e');
      return {'status': 'error', 'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e'};
    }
  }

  /// รีเซ็ตรหัสผ่านใหม่
  static Future<Map<String, dynamic>> resetPassword(String sEmail, String sNewPassword) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/reset_password.php'),
            headers: defaultHeaders,
            body: jsonEncode({'sEmail': sEmail, 'sNewPassword': sNewPassword}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
      return {
        'status': 'error',
        'message': 'ตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง (HTTP ${response.statusCode})',
      };
    } catch (e) {
      return {'status': 'error', 'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginWithGoogle(Map<String, dynamic> googleUserData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/google_login.php'),
            headers: defaultHeaders,
            body: jsonEncode(googleUserData),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
      return {
        'status': 'error',
        'message': 'ตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง (HTTP ${response.statusCode})',
      };
    } catch (e) {
      return {'status': 'error', 'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e'};
    }
  }

  /// ลบบัญชีผู้ใช้และข้อมูลทั้งหมดจากระบบเซิร์ฟเวอร์ (PDPA/GDPR Account Deletion)
  static Future<Map<String, dynamic>> deleteAccount({required int userId, required String email}) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/delete_account.php'),
            headers: headers,
            body: jsonEncode({'nUserId': userId, 'sEmail': email}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
      return {
        'status': 'error',
        'message': 'ตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง (HTTP ${response.statusCode})',
      };
    } catch (e) {
      return {'status': 'error', 'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e'};
    }
  }
}
