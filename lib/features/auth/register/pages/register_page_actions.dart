// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์การสมัครสมาชิก (register page actions)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'register_page.dart';

extension _RegisterPageActions on _RegisterPageState {
  void _showSnackBar(String message, Color bgColor, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sEmail = _emailController.text.trim();
    final sPassword = _passwordController.text;

    final status = await _controller.processRegister(
      email: sEmail,
      password: sPassword,
      acceptTerms: _acceptTerms,
      acceptPrivacy: _acceptPrivacy,
    );

    if (!mounted) return;

    if (status == RegisterStatus.otpSentSuccess) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => OtpVerificationDialog(
          sEmail: sEmail,
          onVerificationSuccess: () async {
            final success = await _controller.saveUserAfterOtpVerified(
              email: sEmail,
              password: sPassword,
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
            );

            if (!mounted) return;
            if (success) {
              _showSnackBar(
                'สมัครสมาชิกและยืนยันตัวตนสำเร็จแล้ว!',
                AppTheme.primaryGreen,
                Icons.check_circle_rounded,
              );
              if (widget.onRegisterSuccess != null) {
                widget.onRegisterSuccess!();
              } else {
                Navigator.of(context).pop();
              }
            } else {
              _showSnackBar(
                'เกิดข้อผิดพลาดในการบันทึกข้อมูลผู้ใช้',
                Colors.red.shade700,
                Icons.error_outline_rounded,
              );
            }
          },
        ),
      );
    } else if (_controller.errorMessage != null) {
      final color = status == RegisterStatus.termsNotAccepted
          ? Colors.orange.shade800
          : Colors.red.shade700;
      final icon = status == RegisterStatus.termsNotAccepted
          ? Icons.info_outline_rounded
          : Icons.warning_amber_rounded;
      _showSnackBar(_controller.errorMessage!, color, icon);
    }
  }

  void _showTermsBottomSheet() {
    TermsPrivacySheets.showTermsBottomSheet(
      context: context,
      onAccept: () => setState(() => _acceptTerms = true),
    );
  }

  void _showPrivacyBottomSheet() {
    TermsPrivacySheets.showPrivacyBottomSheet(
      context: context,
      onAccept: () => setState(() => _acceptPrivacy = true),
    );
  }

  void _handleDisabledTap() {
    if (!_acceptTerms || !_acceptPrivacy) {
      ScaffoldMessenger.of(context).clearSnackBars();
      _showSnackBar(
        'กรุณาติ๊กยอมรับเงื่อนไขและนโยบายความเป็นส่วนตัวก่อนสมัครสมาชิก',
        Colors.orange.shade800,
        Icons.info_outline_rounded,
      );
    } else {
      _handleRegister();
    }
  }
}
