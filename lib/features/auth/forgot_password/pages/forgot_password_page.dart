import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/auth/widgets/otp_verification_dialog.dart';
import 'package:healthymate/features/auth/register/widgets/password_requirements_card.dart';
import '../controllers/forgot_password_controller.dart';

part 'forgot_password_page_actions.dart';
part 'forgot_password_page_content.dart';
part 'forgot_password_page_email_form.dart';
part 'forgot_password_page_password_form.dart';

/// หน้าจอสำหรับกู้คืน/รีเซ็ตรหัสผ่าน (Forgot Password Page Widget)
/// รองรับกระบวนการส่ง OTP ยืนยันรหัส และกำหนดรหัสผ่านใหม่
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}
/// State ของ ForgotPasswordPage
class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final ForgotPasswordController _controller;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  @override
  void initState() {
    super.initState();
    _controller = ForgotPasswordController();
  }
  /// dispose controller
  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  /// ตรวจสอบความยาวของรหัสผ่าน
  bool get _hasMinLength => _newPasswordController.text.length >= 8;
  /// ตรวจสอบตัวพิมพ์ใหญ่
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_newPasswordController.text);
  /// ตรวจสอบตัวพิมพ์เล็ก
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_newPasswordController.text);
  /// ตรวจสอบตัวเลข
  bool get _hasDigits => RegExp(r'[0-9]').hasMatch(_newPasswordController.text);
  /// ตรวจสอบรหัสผ่านว่าถูกต้องหรือไม่
  bool get _isPasswordValid =>_hasMinLength && _hasUppercase && _hasLowercase && _hasDigits;

  /// Build UI ของ ForgotPasswordPage
  @override
  Widget build(BuildContext context) => _buildPage(context);
}
