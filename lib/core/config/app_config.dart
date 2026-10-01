import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ตัวจัดการ Environment Variables (.env) ของแอปพลิเคชัน
class AppConfig {
  /// Loads only the client configuration from the root `.env` asset.
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      debugPrint('AppConfig: .env not found; using safe defaults.');
    }
  }

  /// Base URL ของ PHP Remote Server API (Fallback)
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'https://healthymate-api.onrender.com/api';

  /// Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Host Header สำหรับ Virtual Host (ถ้ามี)
  static String get hostHeader => dotenv.env['HOST_HEADER'] ?? '';

  /// Secure App Key สำหรับยืนยันการเข้าถึง API
  static String get appKey => dotenv.env['APP_KEY'] ?? '';
}
