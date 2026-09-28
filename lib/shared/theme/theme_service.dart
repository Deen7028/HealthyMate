import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/auth_service.dart';

/// Centralized Theme Service for Light/Dark mode management in HealthyMate
class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    try {
      final email = AuthService.instance.currentUserEmail;
      if (email.isNotEmpty) {
        final user = await AppDatabase.instance.getUserByEmail(email);
        if (user != null) {
          _isDarkMode = user.isDarkMode;
          notifyListeners();
          return;
        }
      }
      final defaultUser = await AppDatabase.instance.getUser(userId: 1);
      if (defaultUser != null) {
        _isDarkMode = defaultUser.isDarkMode;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error init ThemeService: $e');
    }
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();

    try {
      final email = AuthService.instance.currentUserEmail;
      var user = email.isNotEmpty ? await AppDatabase.instance.getUserByEmail(email) : null;
      user ??= await AppDatabase.instance.getUser(userId: 1);

      if (user != null) {
        final updated = user.copyWith(isDarkMode: value);
        await AppDatabase.instance.updateUser(updated);
      }
    } catch (e) {
      debugPrint('Error updating darkMode in DB: $e');
    }
  }
}
