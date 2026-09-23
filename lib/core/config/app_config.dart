import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ตัวจัดการ Environment Variables (.env) ของแอปพลิเคชัน
class AppConfig {
  /// เริ่มต้นโหลดไฟล์ `.env` พร้อมระบบ Fallback
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('AppConfig: Failed to load .env file, using fallback values: $e');
    }
  }

  /// Base URL ของ PHP Remote Server API
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'https://172.18.111.30/6620310001/html/HealthyMate/api';

  /// Host Header สำหรับ Virtual Host Apache ม.อ.
  static String get hostHeader =>
      dotenv.env['HOST_HEADER'] ?? 'std.mcs.psu.ac.th';

  /// Secure App Key สำหรับยืนยันการเข้าถึง API
  static String get appKey =>
      dotenv.env['APP_KEY'] ?? 'HealthyMate_Secure_App_2026';
}
