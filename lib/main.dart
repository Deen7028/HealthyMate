import 'package:flutter/material.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/login/login_screen.dart';
import 'package:healthymate/main_app.dart';
import 'package:healthymate/features/register/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();
  runApp(const HealthyMateApp());
}

class HealthyMateApp extends StatelessWidget {
  const HealthyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthyMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
  }
}
