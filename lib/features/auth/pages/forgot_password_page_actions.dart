part of 'forgot_password_page.dart';

extension _ForgotPasswordPageActions on _ForgotPasswordPageState {
  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    final success = await _controller.sendOtp(email);
    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => OtpVerificationDialog(
          sEmail: email,
          onVerificationSuccess: () {
            _controller.markOtpVerified();
          },
        ),
      );
    } else if (_controller.errorMessage != null) {
      _showError(_controller.errorMessage!);
    }
  }

  Future<void> _handleResetPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isPasswordValid) {
      _showError('กรุณากรอกรหัสผ่านใหม่ให้ครบตามเงื่อนไขความปลอดภัย');
      return;
    }

    final email = _emailController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final success = await _controller.resetPassword(
      email,
      newPassword,
      confirmPassword,
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'เปลี่ยนรหัสผ่านสำเร็จ กรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else if (_controller.errorMessage != null) {
      _showError(_controller.errorMessage!);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
