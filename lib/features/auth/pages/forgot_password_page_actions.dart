// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์การยืนยันตัวตนและกู้รหัสผ่าน (forgot password page actions)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'forgot_password_page.dart';

/// Extension จัดการ Action / Events ต่างๆ ของหน้าลืมรหัสผ่าน (ส่ง OTP และบันทึกรหัสผ่านใหม่)
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

  /// จัดการ Action สำหรับรีเซ็ตรหัสผ่าน
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
    /// ถ้า state ไม่ mount แล้วไม่ต้องทำอะไรต่อ
    if (!mounted) return;
    /// ถ้าสำเร็จ
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

  /// ฟังก์ชันแสดงข้อความผิดพลาด
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
