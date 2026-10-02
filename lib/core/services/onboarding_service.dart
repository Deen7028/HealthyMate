import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService extends ChangeNotifier {
  static final OnboardingService instance = OnboardingService._internal();
  OnboardingService._internal();

  static const String _keyIsFirstRun = 'is_first_run';
  bool _isFirstRun = true;
  bool _isInitialized = false;

  bool get isFirstRun => _isFirstRun;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isFirstRun = prefs.getBool(_keyIsFirstRun) ?? true;
    } catch (e) {
      debugPrint('OnboardingService init error: $e');
      _isFirstRun = true;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsFirstRun, false);
      _isFirstRun = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }
  }

  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsFirstRun, true);
      _isFirstRun = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting onboarding: $e');
    }
  }
}
