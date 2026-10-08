import 'dart:io';
import 'package:healthymate/core/config/app_config.dart';
import 'package:healthymate/core/database/app_database.dart';

// อนุญาตให้เรียก API ผ่าน HTTPS ได้แม้ใบรับรองความปลอดภัยจะไม่ตรง (สำหรับ Local Development/Self-signed SSL)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

// การตั้งค่าส่วนกลางสำหรับการเรียก Backend API (Base URL, Headers และ Auth Token)
class ApiServiceConfig {
  // ดึง Base URL ของ API จาก AppConfig
  static String get baseUrl => AppConfig.baseUrl;

  // Header มาตรฐานสำหรับการเรียก API ทั่วไป (Content-Type, X-App-Key, Host)
  static Map<String, String> get defaultHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (AppConfig.appKey.isNotEmpty) {
      headers['X-App-Key'] = AppConfig.appKey;
    }
    if (AppConfig.hostHeader.isNotEmpty) {
      headers['Host'] = AppConfig.hostHeader;
    }
    return headers;
  }

  // Header ที่แนบ Bearer Token สำหรับ Endpoint ที่ต้องการยืนยันตัวตน (Authenticated Requests)
  static Future<Map<String, String>> getAuthHeaders() async {
    final headers = Map<String, String>.from(defaultHeaders);
    final token = await AppDatabase.instance.getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // คืนค่าสตริงวันที่ปัจจุบันในรูปแบบ YYYY-MM-DD
  static String todayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
