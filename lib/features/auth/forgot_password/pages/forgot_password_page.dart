import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/auth/widgets/otp_verification_dialog.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/index.dart';

// ส่วนหน้าจอลืมรหัสผ่าน (ForgotPasswordPage)
// ทำหน้าที่ประกอบ Widget หน้าจอสำหรับกรอกอีเมลรับ OTP และตั้งรหัสผ่านใหม่
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // 1. ประกาศ Controller และ State สำหรับฟอร์ม
  late final ForgotPasswordController _controller;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 2. กำหนดค่าเริ่มต้น Controller
    _controller = ForgotPasswordController();
  }

  @override
  void dispose() {
    // 3. คืนทรัพยากร Controller และ FocusNode ทั้งหมดเมื่อออกจากหน้า
    _controller.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  // ฟังก์ชัน: จัดการการส่งรหัส OTP ไปยังอีเมล
  Future<void> _handleSendOtp() async {
    // 1. ซ่อนคีย์บอร์ด
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();

    // 2. เรียก Controller ส่ง OTP
    final success = await _controller.sendOtp(email);
    if (!mounted) return;

    // 3. หากส่งสำเร็จ เปิด Dialog ให้ผู้ใช้กรอกรหัส OTP ยืนยัน
    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => OtpVerificationDialog(
          sEmail: email,
          onVerificationSuccess: () {
            _controller.markOtpVerified();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ยืนยันรหัส OTP สำเร็จ กรุณากำหนดรหัสผ่านใหม่'),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          },
        ),
      );
    } else {
      _showError(_controller.errorMessage ?? 'ส่งรหัส OTP ไม่สำเร็จ');
    }
  }

  // ฟังก์ชัน: จัดการการรีเซ็ตรหัสผ่านใหม่
  Future<void> _handleResetPassword() async {
    // 1. ซ่อนคีย์บอร์ดและตรวจสอบความถูกต้องของฟอร์ม
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 2. เรียก Controller เปลี่ยนรหัสผ่านใหม่
    final success = await _controller.resetPassword(
      email,
      newPassword,
      confirmPassword,
    );

    if (!mounted) return;

    // 3. หากเปลี่ยนสำเร็จ แสดง SnackBar แจ้งเตือนและพากลับหน้าเข้าสู่ระบบ
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('เปลี่ยนรหัสผ่านสำเร็จ! กรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่'),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    } else {
      _showError(_controller.errorMessage ?? 'เกิดข้อผิดพลาดในการเปลี่ยนรหัสผ่าน');
    }
  }

  // ฟังก์ชัน: แสดงข้อความแจ้งเตือนข้อผิดพลาด
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 4. ผูกการแสดงผลเข้ากับ Controller ด้วย ListenableBuilder
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // หัวข้อและคำอธิบายเปลี่ยนตามสถานะ OTP
                  Text(
                    _controller.isOtpVerified ? 'ตั้งรหัสผ่านใหม่' : 'ลืมรหัสผ่าน?',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _controller.isOtpVerified
                        ? 'กรุณากำหนดรหัสผ่านใหม่สำหรับเข้าสู่ระบบ'
                        : 'กรอกอีเมลที่คุณใช้ลงทะเบียนเพื่อรับรหัส OTP สำหรับยืนยันตัวตน',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  // สลับแบบฟอร์มด้วย Animation (กรอกอีเมล ➔ ตั้งรหัสผ่านใหม่)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _controller.isOtpVerified
                        ? ForgotPasswordNewPasswordForm(
                            formKey: _formKey,
                            newPasswordController: _newPasswordController,
                            confirmPasswordController: _confirmPasswordController,
                            passwordFocusNode: _passwordFocusNode,
                            confirmPasswordFocusNode: _confirmPasswordFocusNode,
                            isLoading: _controller.isLoading,
                            onResetPassword: _handleResetPassword,
                          )
                        : ForgotPasswordEmailForm(
                            emailController: _emailController,
                            isLoading: _controller.isLoading,
                            onSendOtp: _handleSendOtp,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}