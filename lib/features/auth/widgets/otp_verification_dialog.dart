import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

part 'otp_verification_dialog_actions.dart';
part 'otp_verification_dialog_content.dart';

class OtpVerificationDialog extends StatefulWidget {
  final String sEmail;
  final VoidCallback onVerificationSuccess;

  const OtpVerificationDialog({
    super.key,
    required this.sEmail,
    required this.onVerificationSuccess,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  int _nCountdown = 60;
  Timer? _timer;
  late final AnimationController _shakeController;
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

  DateTime? _endTime;

  @override
  Widget build(BuildContext context) => _buildDialog(context);
}
