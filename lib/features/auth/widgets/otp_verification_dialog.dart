import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/theme/app_theme.dart';

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

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  int _nCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _nCountdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_nCountdown > 0) {
        setState(() => _nCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    final sCode = _otpController.text.trim();
    if (sCode.length != 6) return;

    setState(() => _isLoading = true);
    final objRes = await HealthApiService.verifyEmailOtp(widget.sEmail, sCode);
    setState(() => _isLoading = false);

    if (objRes['status'] == 'success') {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onVerificationSuccess();
      }
    } else {
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

  Future<void> _handleResend() async {
    if (_nCountdown > 0) return;
    setState(() => _isLoading = true);
    final objRes = await HealthApiService.sendEmailOtp(widget.sEmail);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_outlined, color: AppTheme.primaryGreen, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'ยืนยันรหัส OTP',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'กรอกรหัส 6 หลักที่เราส่งไปยัง\n${widget.sEmail}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                filled: true,
                fillColor: AppTheme.subtleSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ยืนยันรหัส', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _nCountdown > 0 ? null : _handleResend,
              child: Text(
                _nCountdown > 0 ? 'ขอรหัสใหม่ได้ใน ($_nCountdown วิ)' : 'ส่งรหัส OTP ใหม่อีกครั้ง',
                style: TextStyle(
                  color: _nCountdown > 0 ? AppTheme.textTertiary : AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}