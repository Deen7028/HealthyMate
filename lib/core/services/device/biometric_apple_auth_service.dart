import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

// บริการตรวจสอบตัวตนด้วยระบบไบโอเมตริกซ์ (สแกนลายนิ้วมือ / Face ID) และจัดเก็บข้อมูลอย่างปลอดภัย
class BiometricAuthService {
  BiometricAuthService._();
  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ตรวจสอบว่าอุปกรณ์รองรับและมีการตั้งค่าไบโอเมตริกซ์ไว้หรือไม่
  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  // เรียกเปิดหน้าต่างยืนยันตัวตนด้วยไบโอเมตริกซ์ (Face ID / ลายนิ้วมือ)
  Future<bool> authenticate({String reason = 'กรุณายืนยันตัวตนเพื่อเข้าสู่ระบบ'}) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  // ---- ส่วนจัดการ Secure Storage สำหรับเก็บ Credentials นิรภัย ---- //

  // บันทึกอีเมลและรหัสผ่านลงใน Secure Storage นิรภัย
  Future<void> saveCredentials(String email, String password) async {
    try {
      await _secureStorage.write(key: 'secure_email', value: email);
      await _secureStorage.write(key: 'secure_password', value: password);
    } catch (e) {
      debugPrint('Error saving credentials to secure storage: $e');
    }
  }

  // ดึงข้อมูลอีเมลและรหัสผ่านที่บันทึกไว้ออกมาใช้
  Future<Map<String, String>?> getCredentials() async {
    try {
      final email = await _secureStorage.read(key: 'secure_email');
      final password = await _secureStorage.read(key: 'secure_password');
      if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
        return {'email': email, 'password': password};
      }
    } catch (e) {
      debugPrint('Error reading credentials from secure storage: $e');
    }
    return null;
  }

  // ลบข้อมูล Credentials ทั้งหมดออกจาก Secure Storage
  Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: 'secure_email');
      await _secureStorage.delete(key: 'secure_password');
    } catch (e) {
      debugPrint('Error clearing credentials from secure storage: $e');
    }
  }
}
