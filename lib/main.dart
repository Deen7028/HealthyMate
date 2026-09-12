import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/main_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const MainAppShell(),
    );
  }
}
