import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/auth/widgets/otp_verification_dialog.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isOtpVerified = false; // ถ้า true จะแสดงช่องกรอกรหัสใหม่
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // 1. ส่งอีเมลเพื่อขอ OTP
  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('กรุณากรอกอีเมลที่ถูกต้อง');
      return;
    }

    setState(() => _isLoading = true);

    // ยิง API ขอ OTP (API จะเช็คว่ามีอีเมลนี้ในระบบไหม)
    final result = await HealthApiService.sendForgotPasswordOtp(email);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      // เปิด Dialog กรอก OTP
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => OtpVerificationDialog(
          sEmail: email,
          onVerificationSuccess: () {
            setState(() {
              _isOtpVerified = true; // เปิดให้กรอกรหัสผ่านใหม่
            });
          },
        ),
      );
    } else {
      _showError(result['message'] ?? 'ไม่สามารถส่งรหัส OTP ได้');
    }
  }

  // 2. บันทึกรหัสผ่านใหม่
  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    final newPassword = _newPasswordController.text;

    if (newPassword.length < 8) {
      _showError('รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษร');
      return;
    }

    setState(() => _isLoading = true);

    // ยิง API อัปเดตรหัสผ่านใหม่
    final result = await HealthApiService.resetPassword(email, newPassword);
    
    if (!mounted) return;

    if (result['status'] == 'success') {
      // อัปเดต SQLite ในเครื่องเผื่อออฟไลน์
      await AppDatabase.instance.updateLocalPassword(email, newPassword);
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('เปลี่ยนรหัสผ่านสำเร็จ กรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่')),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // ปิดหน้าลืมรหัสผ่าน กลับไปหน้า Login
      Navigator.of(context).pop(); 
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(result['message'] ?? 'เกิดข้อผิดพลาดในการเปลี่ยนรหัสผ่าน');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset_rounded, size: 40, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 24),
              const Text(
                'ลืมรหัสผ่าน?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _isOtpVerified 
                    ? 'ยืนยันตัวตนสำเร็จแล้ว กรุณาตั้งรหัสผ่านใหม่เพื่อเข้าใช้งานบัญชีของคุณ'
                    : 'ไม่ต้องกังวล! เพียงกรอกอีเมลที่เชื่อมโยงกับบัญชีของคุณ เราจะส่งรหัส OTP เพื่อตั้งรหัสผ่านใหม่ไปให้',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),

              // ช่องกรอกอีเมล (ซ่อน/Disable เมื่อยืนยัน OTP ผ่านแล้ว)
              TextFormField(
                controller: _emailController,
                enabled: !_isOtpVerified,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'อีเมล',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryGreen),
                  filled: true,
                  fillColor: _isOtpVerified ? Colors.grey.shade100 : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                  ),
                ),
              ),

              if (_isOtpVerified) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่านใหม่ (New Password)',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.textTertiary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ปุ่มดำเนินการหลัก
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_isOtpVerified ? _handleResetPassword : _handleSendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          _isOtpVerified ? 'บันทึกรหัสผ่านใหม่' : 'ส่งรหัส OTP',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}