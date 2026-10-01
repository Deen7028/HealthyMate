import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:healthymate/core/config/app_config.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/location_background_service.dart';
import 'package:healthymate/core/services/notification_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/shared/theme/theme_service.dart';
import 'package:healthymate/core/services/tts_service.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:healthymate/features/login/pages/login_page.dart';
import 'package:healthymate/core/services/supabase_service.dart';
import 'package:healthymate/main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  await SupabaseService.instance.init();
  AppDatabase.ensureInitialized();
  await AuthService.instance.init();
  await ThemeService.instance.init();
  await SyncService.instance.init();
  await NotificationService.instance.init();
  await LocationBackgroundService.instance.initialize();
  await TtsService.instance.init();
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '653331824744-u7shnuntsincr6j4e91p7urbqie9kqu0.apps.googleusercontent.com',
  );

  // ดักฟัง Supabase Auth State Change (สำหรับ Google OAuth Deep Link)
  if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
    SupabaseService.instance.client!.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null && session.user.email != null) {
        final email = session.user.email!.trim().toLowerCase();
        final meta = session.user.userMetadata ?? {};
        final givenName = meta['given_name']?.toString() ?? meta['first_name']?.toString();
        final familyName = meta['family_name']?.toString() ?? meta['last_name']?.toString();
        final fullName = meta['full_name']?.toString() ?? meta['name']?.toString() ?? '';

        String firstName = 'Google';
        String lastName = 'User';

        if (givenName != null && givenName.isNotEmpty) {
          firstName = givenName;
          lastName = familyName ?? '';
        } else if (fullName.isNotEmpty) {
          final names = fullName.trim().split(' ');
          firstName = names.isNotEmpty ? names.first : 'Google';
          lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
        }

        final avatarUrl = meta['avatar_url']?.toString() ?? meta['picture']?.toString() ?? '';

        // 1. ตรวจสอบหรือสร้าง/อัปเดตผู้ใช้ใน TbUsers บน Supabase
        var existing = await SupabaseService.instance.getUserByEmail(email);
        final currentFirstName = (firstName != 'Google' && firstName.isNotEmpty)
            ? firstName
            : (existing?['sFirstName'] ?? firstName);
        final currentLastName = (lastName != 'User' && lastName.isNotEmpty)
            ? lastName
            : (existing?['sLastName'] ?? lastName);
        final currentAvatar = avatarUrl.isNotEmpty
            ? avatarUrl
            : (existing?['sProfileImagePath'] ?? '');

        final userSyncPayload = {
          'sEmail': email,
          'sFirstName': currentFirstName,
          'sLastName': currentLastName,
          'sProfileImagePath': currentAvatar,
          'sPasswordHash': 'GOOGLE_AUTH_USER',
          'isSynced': true,
        };

        if (existing != null) {
          userSyncPayload['nUserId'] = existing['nUserId'];
        }

        await SupabaseService.instance.upsertUser(userSyncPayload);
        existing = await SupabaseService.instance.getUserByEmail(email);

        final int userId = (existing?['nUserId'] as num?)?.toInt() ?? 1;

        final userPayload = {
          'nUserId': userId,
          'sEmail': email,
          'sFirstName': currentFirstName,
          'sLastName': currentLastName,
          'sProfileImagePath': currentAvatar,
          'sPasswordHash': 'GOOGLE_AUTH_USER',
          'isSynced': true,
        };

        // 2. บันทึกลง SQLite และเริ่ม Session
        final tbUser = await AppDatabase.instance.upsertUserFromServer(userPayload);
        await AuthService.instance.setLoginSession(tbUser.sEmail, token: session.accessToken);
        debugPrint('🎉 [Google Auth Success] เข้าสู่ระบบสำเร็จ: ${tbUser.sEmail} (ID: ${tbUser.nUserId})');
      }
    });
  }

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
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('th', 'TH'),
            Locale('en', 'US'),
          ],
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => ListenableBuilder(
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
