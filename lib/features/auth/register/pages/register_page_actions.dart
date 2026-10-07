part of 'register_page.dart';

// ส่วนการทำงานและเหตุการณ์ของหน้าลงทะเบียน (_RegisterPageActions)
// ทำหน้าที่จัดการการกดปุ่มสมัครสมาชิก, แสดง OTP Dialog, เปิด Bottom Sheet เงื่อนไข และแจ้งเตือน SnackBar
extension _RegisterPageActions on _RegisterPageState {
  // ฟังก์ชัน: แสดงข้อความแจ้งเตือน SnackBar
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

  // ฟังก์ชัน: จัดการการส่งข้อมูลสมัครสมาชิก
  void _handleRegister() async {
    // 1. ซ่อนคีย์บอร์ดและตรวจสอบความถูกต้องของฟอร์ม
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sEmail = _emailController.text.trim();
    final sPassword = _passwordController.text;

    // 2. เรียก Controller ประมวลผลและส่ง OTP ไปยังอีเมล
    final status = await _controller.processRegister(
      email: sEmail,
      password: sPassword,
      acceptTerms: _acceptTerms,
      acceptPrivacy: _acceptPrivacy,
    );

    if (!mounted) return;

    // 3. หากส่ง OTP สำเร็จ ให้เปิด Dialog เพื่อยืนยันรหัส 6 หลัก
    if (status == RegisterStatus.otpSentSuccess) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => OtpVerificationDialog(
          sEmail: sEmail,
          onVerificationSuccess: () async {
            // เมื่อยืนยัน OTP ถูกต้อง บันทึกข้อมูลผู้ใช้ลงระบบ
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
      // 4. กรณีเกิดข้อผิดพลาดหรือยังไม่ยอมรับเงื่อนไข
      final color = status == RegisterStatus.termsNotAccepted
          ? Colors.orange.shade800
          : Colors.red.shade700;
      final icon = status == RegisterStatus.termsNotAccepted
          ? Icons.info_outline_rounded
          : Icons.warning_amber_rounded;
      _showSnackBar(_controller.errorMessage!, color, icon);
    }
  }

  // ฟังก์ชัน: เปิดแผ่นหน้าต่างเงื่อนไขการใช้งาน (Terms of Service)
  void _showTermsBottomSheet() {
    TermsPrivacySheets.showTermsBottomSheet(
      context: context,
      onAccept: () => setState(() => _acceptTerms = true),
    );
  }

  // ฟังก์ชัน: เปิดแผ่นหน้าต่างนโยบายความเป็นส่วนตัว (Privacy Policy)
  void _showPrivacyBottomSheet() {
    TermsPrivacySheets.showPrivacyBottomSheet(
      context: context,
      onAccept: () => setState(() => _acceptPrivacy = true),
    );
  }

  // ฟังก์ชัน: ตรวจสอบเมื่อผู้ใช้กดปุ่มสมัครในขณะที่ยังไม่ได้ยอมรับข้อตกลง
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
