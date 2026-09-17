import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/theme_service.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/login/login_screen.dart';
import 'package:healthymate/main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase.ensureInitialized();
  await AuthService.instance.init();
  await ThemeService.instance.init();
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
                return const LoginScreen();
              }
              return const MainAppShell();
            },
          ),
        );
      },
    );
  }
}
