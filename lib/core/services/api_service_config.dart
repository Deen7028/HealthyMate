// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (api service config)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:io';
import 'package:healthymate/core/config/app_config.dart';
import 'package:healthymate/core/database/app_database.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class ApiServiceConfig {
  static String get baseUrl => AppConfig.baseUrl;

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

  static Future<Map<String, String>> getAuthHeaders() async {
    final headers = Map<String, String>.from(defaultHeaders);
    final token = await AppDatabase.instance.getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String todayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
