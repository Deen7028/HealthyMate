// ส่วนนี้อธิบายบทบาทของไฟล์: จุดเริ่มต้นของแอป ใช้เตรียม service หลักและเปิดหน้าแรก
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:healthymate/core/config/app_config.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service_config.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/location_background_service.dart';
import 'package:healthymate/core/services/notification_service.dart';
import 'package:healthymate/core/services/onboarding_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/shared/theme/theme_service.dart';
import 'package:healthymate/core/services/tts_service.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:healthymate/features/login/pages/login_page.dart';
import 'package:healthymate/features/onboarding/pages/onboarding_slides_page.dart';
import 'package:healthymate/features/onboarding/pages/profile_setup_wizard_page.dart';
import 'package:healthymate/core/services/supabase_service.dart';
import 'package:healthymate/main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await AppConfig.init();
  await SupabaseService.instance.init();
  AppDatabase.ensureInitialized();
  await AuthService.instance.init();
  await OnboardingService.instance.init();
  await ThemeService.instance.init();
  await SyncService.instance.init();
  await NotificationService.instance.init();
  try {
    await LocationBackgroundService.instance.initialize();
  } catch (e) {
    debugPrint('LocationBackgroundService init error: $e');
  }
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
        final localExisting = await AppDatabase.instance.getUserByEmail(email);

        final currentFirstName = (firstName != 'Google' && firstName.isNotEmpty)
            ? firstName
            : (existing?['sFirstName'] ?? localExisting?.sFirstName ?? firstName);
        final currentLastName = (lastName != 'User' && lastName.isNotEmpty)
            ? lastName
            : (existing?['sLastName'] ?? localExisting?.sLastName ?? lastName);
        final currentAvatar = avatarUrl.isNotEmpty
            ? avatarUrl
            : (existing?['sProfileImagePath'] ?? localExisting?.sProfileImagePath ?? '');

        final userSyncPayload = {
          'sEmail': email,
          'sFirstName': currentFirstName,
          'sLastName': currentLastName,
          'sProfileImagePath': currentAvatar,
          'isSynced': true,
        };

        if (existing != null) {
          userSyncPayload['nUserId'] = existing['nUserId'];
        } else {
          userSyncPayload['sPasswordHash'] = 'GOOGLE_AUTH_USER';
        }

        await SupabaseService.instance.upsertUser(userSyncPayload);
        existing = await SupabaseService.instance.getUserByEmail(email);

        final int userId = (existing?['nUserId'] as num?)?.toInt() ?? (localExisting?.nUserId ?? 1);

        // ดึงข้อมูลส่วนสูง น้ำหนัก อายุ เพศ ที่เคยบันทึกไว้ (จาก Server หรือ Local) ไม่ให้ถูก reset เป็น 0
        final finalWeight = (existing?['nWeight'] as num?)?.toDouble() ?? localExisting?.nWeight;
        final finalHeight = (existing?['nHeight'] as num?)?.toDouble() ?? localExisting?.nHeight;
        final finalAge = (existing?['nAge'] as num?)?.toInt() ?? localExisting?.nAge;
        final finalGender = existing?['sGender']?.toString() ?? localExisting?.sGender;
        final finalActivity = existing?['sActivityLevel']?.toString() ?? localExisting?.sActivityLevel;

        final userPayload = {
          'nUserId': userId,
          'sEmail': email,
          'sFirstName': currentFirstName,
          'sLastName': currentLastName,
          'sProfileImagePath': currentAvatar,
          'nWeight': finalWeight,
          'nHeight': finalHeight,
          'nAge': finalAge,
          'sGender': finalGender,
          'sActivityLevel': finalActivity,
          'isSynced': true,
        };
        
        if (existing == null && localExisting == null) {
          userPayload['sPasswordHash'] = 'GOOGLE_AUTH_USER';
        } else {
          userPayload['sPasswordHash'] = existing?['sPasswordHash'] ?? localExisting?.sPasswordHash ?? '';
        }

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
                listenable: Listenable.merge([
                  AuthService.instance,
                  OnboardingService.instance,
                ]),
                builder: (context, _) {
                  if (OnboardingService.instance.isFirstRun) {
                    return const OnboardingSlidesPage();
                  }
                  if (!AuthService.instance.isLoggedIn) {
                    return const LoginPage();
                  }
                  return FutureBuilder(
                    future: AppDatabase.instance.getUserByEmail(AuthService.instance.currentUserEmail),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                          ),
                        );
                      }
                      final user = snapshot.data;
                      final isProfileIncomplete = user == null ||
                          (user.nWeight == null || user.nWeight! <= 0) ||
                          (user.nHeight == null || user.nHeight! <= 0);

                      if (isProfileIncomplete) {
                        return const ProfileSetupWizardPage();
                      }
                      return const MainAppShell();
                    },
                  );
                },
              ),
            );
          },
          home: ListenableBuilder(
            listenable: Listenable.merge([
              AuthService.instance,
              OnboardingService.instance,
            ]),
            builder: (context, _) {
              if (OnboardingService.instance.isFirstRun) {
                return const OnboardingSlidesPage();
              }
              if (!AuthService.instance.isLoggedIn) {
                return const LoginPage();
              }
              return FutureBuilder(
                future: AppDatabase.instance.getUserByEmail(AuthService.instance.currentUserEmail),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                      ),
                    );
                  }
                  final user = snapshot.data;
                  final isProfileIncomplete = user == null ||
                      (user.nWeight == null || user.nWeight! <= 0) ||
                      (user.nHeight == null || user.nHeight! <= 0);

                  if (isProfileIncomplete) {
                    return const ProfileSetupWizardPage();
                  }
                  return const MainAppShell();
                },
              );
            },
          ),
        );
      },
    );
  }
}
