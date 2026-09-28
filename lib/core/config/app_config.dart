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
      dotenv.env['BASE_URL'] ?? 'https://healthymate-api.onrender.com/api';

  /// Host Header สำหรับ Virtual Host (ถ้ามี)
  static String get hostHeader =>
      dotenv.env['HOST_HEADER'] ?? '';

  /// Secure App Key สำหรับยืนยันการเข้าถึง API
  static String get appKey =>
      dotenv.env['APP_KEY'] ?? 'HealthyMate_Secure_App_2026';
}
