// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์การเข้าสู่ระบบ (login page other auth)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'login_page.dart';

extension LoginPageOtherAuth on _LoginPageState {
  Future<void> _handleBiometricSignIn() async {
    final available = await BiometricAuthService.instance
        .isBiometricAvailable();
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'อุปกรณ์นี้ไม่รองรับหรือยังไม่ได้เปิดใช้งาน Biometric (FaceID/TouchID)',
          ),
          backgroundColor: Color(0xFF4A5568),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final credentials = await BiometricAuthService.instance.getCredentials();
    if (credentials == null) {
      _showError(
        'กรุณาเข้าสู่ระบบด้วยอีเมลและรหัสผ่านในครั้งแรกเพื่อเปิดใช้งานสแกนนิ้ว',
      );
      return;
    }

    final authenticated = await BiometricAuthService.instance.authenticate(
      reason: 'ยืนยันตัวตนด้วย FaceID / TouchID เพื่อเข้าสู่ระบบ HealthyMate',
    );

    if (authenticated) {
      setState(() => _isLoading = true);

      final loginResult = await AuthService.instance.login(
        credentials['email']!,
        credentials['password']!,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (loginResult['success'] == true) {
        final loggedInUser = loginResult['user'] as TbUser?;
        if (loggedInUser != null) {
          SyncService.instance.pullDownstreamWorkouts(loggedInUser.nUserId);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('เข้าสู่ระบบด้วย Biometric สำเร็จแล้ว!'),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } else {
        _showError(
          'ข้อมูลยืนยันตัวตนหมดอายุหรือรหัสผ่านถูกเปลี่ยนแปลง กรุณาล็อกอินใหม่ด้วยรหัสผ่าน',
        );
        await BiometricAuthService.instance.clearCredentials();
      }
    }
  }

  void _handleSocialLogin(String provider) {
    if (provider == 'Google') {
      this._handleGoogleSignIn();
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text('ระบบเข้าสู่ระบบด้วย $provider กำลังอยู่ในช่วงพัฒนา'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4A5568),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
