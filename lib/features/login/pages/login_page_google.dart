part of 'login_page.dart';

extension LoginPageGoogle on _LoginPageState {
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      if (!_googleSignIn.supportsAuthenticate()) {
        setState(() => _isLoading = false);
        _showError('แพลตฟอร์มนี้ยังไม่รองรับ Google Sign-In');
        return;
      }

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
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        _showError(
          'กรุณาตั้งค่า OAuth Web Client ID หรือ google-services.json บน Android ให้เรียบร้อยก่อนใช้งาน Google Sign-In',
        );
      } else if (e.code == GoogleSignInExceptionCode.canceled) {
        // ผู้ใช้กดยกเลิกการล็อกอิน ไม่ต้องแสดง error แดง
        return;
      } else {
        _showError(
          'เกิดข้อผิดพลาดในการเข้าสู่ระบบ Google: ${e.description ?? e.code.name}',
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('เกิดข้อผิดพลาด: $error');
    }
  }
}
