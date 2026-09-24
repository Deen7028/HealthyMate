import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService._();
  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'กรุณายืนยันตัวตนเพื่อเข้าสู่ระบบ'}) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }
}
