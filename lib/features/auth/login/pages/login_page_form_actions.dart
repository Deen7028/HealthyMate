// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์การเข้าสู่ระบบ (login page form actions)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'login_page.dart';

extension LoginPageFormActions on _LoginPageState {
  /// Regex ตรวจสอบรูปแบบ Email ที่ถูกต้อง
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    return emailRegex.hasMatch(email);
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();

    // 1. ตรวจสอบการถูกระงับชั่วคราว (Lockout Security)
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final waitSeconds = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      setState(() { 
        // แสดงข้อความเตือนเมื่อถูกระงับชั่วคราวและ เวลา
        _errorMessage = 'คุณพยายามเข้าสู่ระบบผิดบ่อยเกินไป กรุณารอ $waitSeconds วินาที';
      });
      _triggerShake();
      return;
    }

    final rawEmail = _emailController.text.trim();
    final rawPassword = _passwordController.text;

    // 2. ดักตรวจช่องว่าง (Empty Check)
    if (rawEmail.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกอีเมลของคุณ';
      });
      _triggerShake();
      _emailFocusNode.requestFocus();
      return;
    }

    // 3. ดักตรวจรูปแบบอีเมล (Email Format Validation)
    if (!this._isValidEmail(rawEmail)) {
      setState(() {
        _errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง (เช่น example@domain.com)';
      });
      _triggerShake();
      _emailFocusNode.requestFocus();
      return;
    }

    // 4. ดักตรวจความยาวและเนื้อหารหัสผ่าน (Password Validation)
    if (rawPassword.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกรหัสผ่าน';
      });
      _triggerShake();
      _passwordFocusNode.requestFocus();
      return;
    }

    if (rawPassword.length < 6) {
      setState(() {
        _errorMessage = 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      });
      _triggerShake();
      _passwordFocusNode.requestFocus();
      return;
    }

    setState(() {
      // กำหนดสถานะ _isLoading เป็น true และเคลียร์ข้อความผิดพลาด
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 5. ดำเนินการเข้าสู่ระบบผ่าน AuthService
      // (ปุ่ม Login จะหมุนต่อเนื่อง _isLoading = true ระหว่างเช็คทั้งในเครื่อง SQLite และ Remote MySQL Server)
      final loginResult = await AuthService.instance.login(
        rawEmail,
        rawPassword,
      );

      if (!mounted) return;

      final isSuccess = loginResult['success'] == true;
      if (!isSuccess) {
        this._registerFailedAttempt();
        setState(() {
          _isLoading =
              false; // สิ้นสุดกระบวนการตรวจสอบทั้งหมด ค่อยหยุดหมุนและแจ้ง Error
          _errorMessage =
              loginResult['message']?.toString() ?? 'เข้าสู่ระบบไม่สำเร็จ';
        });
        _triggerShake();
        return;
      }

      // 6. เข้าสู่ระบบสำเร็จ -> บันทึกลงตู้เซฟนิรภัยเพื่อ Biometric & รีเซ็ตจำนวนครั้งที่ผิด
      await BiometricAuthService.instance.saveCredentials(
        rawEmail,
        rawPassword,
      );
      _failedAttempts = 0;
      _lockoutUntil = null;

      // 7. ดึงประวัติการออกกำลังกายจาก Database Server ลง SQLite ทันที (Initial Data Hydration)
      final loggedInUser = loginResult['user'] as TbUser?;
      if (loggedInUser != null) {
        // ดึงข้อมูลใน Background ต่อเนื่อง
        SyncService.instance.pullDownstreamWorkouts(loggedInUser.nUserId);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('เข้าสู่ระบบสำเร็จแล้ว ยินดีต้อนรับ!'),
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
    } catch (e, stack) {
      debugPrint('LoginPage: Exception during _handleLogin: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อระบบ: $e';
      });
    }
  }

  /// ดักจับการล็อกอินผิดซ้ำๆ เพื่อความปลอดภัย
  void _registerFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
    }
  }
}
