// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์การเข้าสู่ระบบ (login page google)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'login_page.dart';

extension LoginPageGoogle on _LoginPageState {
  Future<void> _handleGoogleSignIn() async {
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

      // 2. Fallback เป็น GoogleSignIn SDK Native
      final GoogleSignInAccount user = await _googleSignIn.authenticate();

      final names = user.displayName?.split(' ') ?? ['Google', 'User'];
      final firstName = names.isNotEmpty ? names.first : 'Google';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      final googleData = {
        'sEmail': user.email,
        'sFirstName': firstName,
        'sLastName': lastName,
        'sProfileImagePath': user.photoUrl ?? '',
        'sGoogleId': user.id,
      };

      final result = await AuthApiService.loginWithGoogle(googleData);

      if (result['status'] == 'success') {
        final userData = result['user'];
        final String? token = result['token']?.toString();
        final tbUser = await AppDatabase.instance.upsertUserFromServer(
          userData,
        );
        await AuthService.instance.setLoginSession(tbUser.sEmail, token: token);

        if (!mounted) return;
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เข้าสู่ระบบสำเร็จ!'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError(result['message'] ?? 'เข้าสู่ระบบด้วย Google ไม่สำเร็จ');
        await _googleSignIn.signOut();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('เกิดข้อผิดพลาด: $error');
    }
  }
}
