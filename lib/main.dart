import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:healthymate/core/config/app_config.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/location_background_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/core/services/theme_service.dart';
import 'package:healthymate/core/services/tts_service.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/login/pages/login_page.dart';
import 'package:healthymate/main_app.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // ยินยอมให้ข้ามการตรวจ SSL สำหรับ IP เซิร์ฟเวอร์ ม.อ. (172.18.x.x) หรือในโหมด kDebugMode
        if (kDebugMode ||
            host == '172.18.111.30' ||
            host.startsWith('172.18.')) {
          return true;
        }
        return false;
      };
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  AppDatabase.ensureInitialized();
  await AuthService.instance.init();
  await ThemeService.instance.init();
  await SyncService.instance.init();
  await LocationBackgroundService.instance.initialize();
  await TtsService.instance.init();
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '653331824744-1gcsv7spstab9sf5tlrs3e3qf21364su.apps.googleusercontent.com',
  );
  runApp(const HealthyMateApp());
}

class HealthyMateApp extends StatelessWidget {
  const HealthyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'HealthyMate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          home: ListenableBuilder(
            listenable: AuthService.instance,
            builder: (context, _) {
              if (!AuthService.instance.isLoggedIn) {
                return const LoginPage();
              }
              return const MainAppShell();
            },
          ),
        );
      },
    );
  }
}
