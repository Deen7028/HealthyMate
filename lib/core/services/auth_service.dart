import 'package:flutter/foundation.dart';
import 'package:healthymate/core/database/app_database.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String _currentUserEmail = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String get currentUserEmail => _currentUserEmail;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _isLoggedIn = await AppDatabase.instance.getLoginStatus();
    } catch (e) {
      debugPrint('Error initializing auth state: $e');
      _isLoggedIn = false;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    final success = await AppDatabase.instance.authenticateUser(email, password);
    if (success) {
      _isLoggedIn = true;
      _currentUserEmail = email;
      await AppDatabase.instance.setLoginStatus(true, email: email);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUserEmail = '';
    await AppDatabase.instance.setLoginStatus(false);
    notifyListeners();
  }
}
