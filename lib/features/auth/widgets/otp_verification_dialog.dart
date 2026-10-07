import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

part 'otp_verification_dialog_actions.dart';
part 'otp_verification_dialog_content.dart';

/// ป๊อบอัพไดอะล็อกป้อนและยืนยันรหัส OTP 6 หลัก (OTP Verification Dialog Component)
class OtpVerificationDialog extends StatefulWidget {
  /// อีเมลที่ลงทะเบียน
  final String sEmail;
  /// callback เมื่อยืนยัน OTP สำเร็จ
  final VoidCallback onVerificationSuccess;
  const OtpVerificationDialog({
    super.key,
    required this.sEmail,
    required this.onVerificationSuccess,
  });
  /// สร้าง State ของ OtpVerificationDialog
  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}
/// State ของ OtpVerificationDialog
class _OtpVerificationDialogState extends State<OtpVerificationDialog>
    with SingleTickerProviderStateMixin {
  /// controller สำหรับกรอกรหัส OTP
  final TextEditingController _otpController = TextEditingController();
  /// ตัวแปรสำหรับตรวจสอบว่ากำลังโหลดหรือไม่
  bool _isLoading = false;
  /// ตัวแปรสำหรับนับเวลาถอยหลัง
  int _nCountdown = 60;
  Timer? _timer;
  /// controller สำหรับ shake
  late final AnimationController _shakeController;
  /// animation สำหรับ shake
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 12.0, end: -10.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 10.0, end: -5.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
  /// ตัวแปรสำหรับเก็บเวลาสิ้นสุดการนับถอยหลัง
  DateTime? _endTime;
  /// build widget
  @override
  Widget build(BuildContext context) => _buildDialog(context);
}
