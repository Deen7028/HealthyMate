import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/auth/widgets/otp_verification_dialog.dart';
import '../widgets/index.dart';
import '../controllers/register_controller.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback? onRegisterSuccess;
  final VoidCallback? onLoginTap;

  const RegisterPage({
    super.key,
    this.onRegisterSuccess,
    this.onLoginTap,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  late final RegisterController _controller;

  // Form Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Focus Nodes
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // State Variables
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;

  @override
  void initState() {
    super.initState();
    _controller = RegisterController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasDigits => RegExp(r'[0-9]').hasMatch(_passwordController.text);

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
              _showSnackBar('สมัครสมาชิกและยืนยันตัวตนสำเร็จแล้ว!', AppTheme.primaryGreen, Icons.check_circle_rounded);
              if (widget.onRegisterSuccess != null) {
                widget.onRegisterSuccess!();
              } else {
                Navigator.of(context).pop();
              }
            } else {
              _showSnackBar('เกิดข้อผิดพลาดในการบันทึกข้อมูลผู้ใช้', Colors.red.shade700, Icons.error_outline_rounded);
            }
          },
        ),
      );
    } else if (_controller.errorMessage != null) {
      final color = status == RegisterStatus.termsNotAccepted ? Colors.orange.shade800 : Colors.red.shade700;
      final icon = status == RegisterStatus.termsNotAccepted ? Icons.info_outline_rounded : Icons.warning_amber_rounded;
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
      _showSnackBar('กรุณาติ๊กยอมรับเงื่อนไขและนโยบายความเป็นส่วนตัวก่อนสมัครสมาชิก', Colors.orange.shade800, Icons.info_outline_rounded);
    } else {
      _handleRegister();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
              onPressed: () {
                if (widget.onLoginTap != null) {
                  widget.onLoginTap!();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FadeSlideEntrance(
                      delayIndex: 1,
                      child: RegisterHeader(),
                    ),
                    const SizedBox(height: 28),

                    FadeSlideEntrance(
                      delayIndex: 2,
                      child: RegisterFormFields(
                        firstNameController: _firstNameController,
                        lastNameController: _lastNameController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        lastNameFocusNode: _lastNameFocusNode,
                        emailFocusNode: _emailFocusNode,
                        passwordFocusNode: _passwordFocusNode,
                        confirmPasswordFocusNode: _confirmPasswordFocusNode,
                        obscurePassword: _obscurePassword,
                        obscureConfirmPassword: _obscureConfirmPassword,
                        onToggleObscurePassword: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        onToggleObscureConfirmPassword: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        onPasswordChanged: (_) => setState(() {}),
                        hasMinLength: _hasMinLength,
                        hasUppercase: _hasUppercase,
                        hasLowercase: _hasLowercase,
                        hasDigits: _hasDigits,
                        onSubmit: _handleRegister,
                      ),
                    ),

                    const SizedBox(height: 20),

                    FadeSlideEntrance(
                      delayIndex: 3,
                      child: RegisterConsentSection(
                        acceptTerms: _acceptTerms,
                        acceptPrivacy: _acceptPrivacy,
                        onTermsChanged: (val) => setState(() => _acceptTerms = val),
                        onPrivacyChanged: (val) => setState(() => _acceptPrivacy = val),
                        onShowTerms: _showTermsBottomSheet,
                        onShowPrivacy: _showPrivacyBottomSheet,
                      ),
                    ),

                    const SizedBox(height: 28),

                    FadeSlideEntrance(
                      delayIndex: 4,
                      child: RegisterSubmitButton(
                        canSubmit: _acceptTerms && _acceptPrivacy && !_controller.isLoading,
                        isLoading: _controller.isLoading,
                        onSubmit: _handleRegister,
                        onDisabledTap: _handleDisabledTap,
                      ),
                    ),

                    const SizedBox(height: 24),

                    FadeSlideEntrance(
                      delayIndex: 5,
                      child: RegisterFooterLink(
                        onLoginTap: () {
                          if (widget.onLoginTap != null) {
                            widget.onLoginTap!();
                          } else {
                            Navigator.of(context).maybePop();
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget สำหรับทำแอนิเมชัน Fade & Slide ขึ้นแบบ Staggered เมื่อเปิดหน้าจอ
class FadeSlideEntrance extends StatelessWidget {
  final Widget child;
  final int delayIndex;

  const FadeSlideEntrance({
    super.key,
    required this.child,
    required this.delayIndex,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (delayIndex * 120)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
