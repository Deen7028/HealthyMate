// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์การยืนยันตัวตนและกู้รหัสผ่าน (otp verification dialog actions)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'otp_verification_dialog.dart';

/// Extension สำหรับจัดการนับเวลาถอยหลัง 60 วินาทีและยืนยัน/ส่งรหัส OTP ซ้ำ
extension _OtpVerificationDialogActions on _OtpVerificationDialogState {
  void _startCountdown() {
    _endTime = DateTime.now().add(const Duration(seconds: 60));
    setState(() => _nCountdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_endTime == null) return;
      final remaining = _endTime!.difference(DateTime.now()).inSeconds;
      if (remaining > 0) {
        if (mounted) setState(() => _nCountdown = remaining);
      } else {
        if (mounted) setState(() => _nCountdown = 0);
        timer.cancel();
      }
    });
  }

  /// ฟังก์ชันยืนยันรหัส OTP
  Future<void> _handleVerify() async {
    final sCode = _otpController.text.trim();
    if (sCode.length != 6) {
      _shakeController.forward(from: 0.0);
      return;
    }

    setState(() => _isLoading = true);
    final objRes = await EmailApiService.verifyEmailOtp(widget.sEmail, sCode);
    setState(() => _isLoading = false);

    if (objRes['status'] == 'success') {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onVerificationSuccess();
      }
    } else {
      _shakeController.forward(from: 0.0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(objRes['message'] ?? 'รหัสยืนยันไม่ถูกต้อง'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// ฟังก์ชันส่งรหัส OTP ใหม่
  Future<void> _handleResend() async {
    if (_nCountdown > 0) return;
    setState(() => _isLoading = true);
    final objRes = await EmailApiService.sendEmailOtp(widget.sEmail);
    setState(() => _isLoading = false);

    if (objRes['status'] == 'success') {
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งรหัส OTP ใหม่ไปยังอีเมลแล้ว'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
