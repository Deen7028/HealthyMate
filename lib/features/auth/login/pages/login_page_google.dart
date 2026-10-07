part of 'login_page.dart';

extension LoginPageGoogle on _LoginPageState {
  Future<void> _handleGoogleSignIn() async {
    // กำหนดสถานะ _isLoading เป็น true และเคลียร์ข้อความผิดพลาด
    setState(() => _isLoading = true);
    try {
      // 1. ตรวจสอบว่ามี Supabase พร้อมใช้งานหรือไม่
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        await SupabaseService.instance.client!.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'com.example.healthymate://login-callback',
        );
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. ใช้ GoogleSignIn SDK Native
      final GoogleSignInAccount user = await _googleSignIn.authenticate();

      // แยกชื่อและนามสกุล
      final names = user.displayName?.split(' ') ?? ['Google', 'User'];
      final firstName = names.isNotEmpty ? names.first : 'Google';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      // สร้างข้อมูลสำหรับส่งไปยัง API
      final googleData = {
        'sEmail': user.email,
        'sFirstName': firstName,
        'sLastName': lastName,
        'sProfileImagePath': user.photoUrl ?? '',
        'sGoogleId': user.id,
      };

      // ส่งข้อมูลไปยัง API และตรวจสอบผลลัพธ์
      final result = await AuthApiService.loginWithGoogle(googleData);

      // ตรวจสอบว่า login สำเร็จหรือไม่
      if (result['status'] == 'success') {
        final userData = result['user'];
        final String? token = result['token']?.toString();
        final tbUser = await AppDatabase.instance.upsertUserFromServer(userData);
        await AuthService.instance.setLoginSession(tbUser.sEmail, token: token);

        // เช็คว่า widget ยัง mounted อยู่หรือไม่
        if (!mounted) return;
        setState(() => _isLoading = false);

        // แสดงข้อความสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เข้าสู่ระบบสำเร็จ!'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // เรียกใช้ callback เมื่อ login สำเร็จ
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
      } else {
        // เช็คว่า widget ยัง mounted อยู่หรือไม่
        if (!mounted) return;
        setState(() => _isLoading = false);
        // แสดงข้อความผิดพลาด
        _showError(result['message'] ?? 'เข้าสู่ระบบด้วย Google ไม่สำเร็จ');
        // ล็อกเอาท์ออกจาก Google
        await _googleSignIn.signOut();
      }
    } catch (error) {
      // เช็คว่า widget ยัง mounted อยู่หรือไม่
      if (!mounted) return;
      setState(() => _isLoading = false);
      // แสดงข้อความผิดพลาด
      _showError('เกิดข้อผิดพลาด: $error');
    }
  }
}
