import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/auth/widgets/otp_verification_dialog.dart';
import '../widgets/index.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
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

  // Password validation checks
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasDigits => RegExp(r'[0-9]').hasMatch(_passwordController.text);

  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasLowercase && _hasDigits;

  void _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('รหัสผ่านไม่ผ่านเงื่อนไขความปลอดภัย กรุณาตรวจสอบอีกครั้ง'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!_acceptTerms || !_acceptPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('กรุณายินยอมรับเงื่อนไขการให้บริการและนโยบายความเป็นส่วนตัวก่อนสมัครสมาชิก'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final sEmail = _emailController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. ตรวจสอบว่ามีอีเมลนี้ในฐานข้อมูล TbUsers ในเครื่องหรือบน Server หรือยัง
      final isLocalExist = await AppDatabase.instance.isEmailExists(sEmail);
      if (isLocalExist) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('อีเมลนี้ถูกใช้งานแล้ว กรุณาใช้อีเมลอื่นหรือเข้าสู่ระบบ'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      // ตรวจสอบกับ Remote Server เผื่อกรณีลบแอปแล้วติดตั้งใหม่ (Server Duplication Check)
      final remoteCheck = await HealthApiService.checkEmailRemote(sEmail);
      if (remoteCheck['exists'] == true || remoteCheck['status'] == 'exists') {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('อีเมลนี้ถูกลงทะเบียนไว้บนระบบเซิร์ฟเวอร์แล้ว กรุณาเข้าสู่ระบบ'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      // 2. ส่งรหัส OTP ไปยังอีเมลผ่าน Backend API
      final objOtpResult = await HealthApiService.sendEmailOtp(sEmail);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (objOtpResult['status'] != 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(objOtpResult['message'] ?? 'ไม่สามารถส่งรหัส OTP ได้'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => OtpVerificationDialog(
          sEmail: sEmail,
          onVerificationSuccess: () async {
            // ดำเนินการบันทึกบัญชีลง SQLite และ Sync ขึ้น MySQL เมื่อยืนยันสำเร็จ
            await _executeUserCreation();
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text('เกิดข้อผิดพลาด: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// เมธอดสร้างผู้ใช้จริงหลังผ่านการยืนยัน OTP เรียบร้อยแล้ว
  Future<void> _executeUserCreation() async {
    setState(() => _isLoading = true);
    try {
      final String sFirstName = _firstNameController.text.trim();
      final String sLastName = _lastNameController.text.trim();
      final String sEmail = _emailController.text.trim();
      final String sPassword = _passwordController.text;

      // 1. บันทึกข้อมูลสมาชิกลงในตาราง TbUsers (SQLite)
      final newUser = await AppDatabase.instance.registerUser(
        firstName: sFirstName,
        lastName: sLastName,
        email: sEmail,
        password: sPassword,
      );

      // 2. ส่งข้อมูลไปอัปเดต/สร้างบัญชีบนเซิร์ฟเวอร์ MySQL ผ่าน PHP API
      try {
        final serverSuccess = await HealthApiService.updateUserProfile(newUser.toMap());
        if (serverSuccess) {
          await AppDatabase.instance.markUserAsSynced(newUser.nUserId);
        }
      } catch (e) {
        debugPrint('Sync new user error: $e');
      }

      // 3. กระตุ้น SyncService ในเบื้องหลัง
      SyncService.instance.updatePendingCount();
      SyncService.instance.syncPendingData();

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text('สร้างบัญชีสำเร็จ! ยินดีต้อนรับคุณ ${newUser.sFullName}'),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      if (widget.onRegisterSuccess != null) {
        widget.onRegisterSuccess!();
      } else {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text('เกิดข้อผิดพลาดในการลงทะเบียน: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('กรุณาติ๊กยอมรับเงื่อนไขและนโยบายความเป็นส่วนตัวก่อนสมัครสมาชิก'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      _handleRegister();
    }
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
                // 1. ส่วนหัวของหน้าจอ (Header)
                const RegisterHeader(),

                const SizedBox(height: 28),

                // 2. แบบฟอร์มข้อมูลสมาชิก (Registration Form)
                RegisterFormFields(
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

                const SizedBox(height: 20),

                // 3. การยอมรับเงื่อนไขและนโยบาย (Terms & Privacy Consent)
                RegisterConsentSection(
                  acceptTerms: _acceptTerms,
                  acceptPrivacy: _acceptPrivacy,
                  onTermsChanged: (val) => setState(() => _acceptTerms = val),
                  onPrivacyChanged: (val) => setState(() => _acceptPrivacy = val),
                  onShowTerms: _showTermsBottomSheet,
                  onShowPrivacy: _showPrivacyBottomSheet,
                ),

                const SizedBox(height: 28),

                // 4. ปุ่มดำเนินการหลัก (Call to Action)
                RegisterSubmitButton(
                  canSubmit: _acceptTerms && _acceptPrivacy && !_isLoading,
                  isLoading: _isLoading,
                  onSubmit: _handleRegister,
                  onDisabledTap: _handleDisabledTap,
                ),

                const SizedBox(height: 24),

                // 5. ลิงก์สลับหน้าจอ (Footer Link)
                RegisterFooterLink(
                  onLoginTap: () {
                    if (widget.onLoginTap != null) {
                      widget.onLoginTap!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
