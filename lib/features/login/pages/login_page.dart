import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/biometric_apple_auth_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/register/pages/register_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../widgets/index.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onLoginSuccess;

  const LoginPage({
    super.key,
    this.onClose,
    this.onLoginSuccess,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      if (!_googleSignIn.supportsAuthenticate()) {
        setState(() => _isLoading = false);
        _showError('แพลตฟอร์มนี้ยังไม่รองรับ Google Sign-In');
        return;
      }

      final GoogleSignInAccount user = await _googleSignIn.authenticate();
      final names = user.displayName?.split(' ') ?? ['Google', 'User'];
      final firstName = names.isNotEmpty ? names.first : 'Google';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      final googleData = {
        'sEmail': user.email,
        'sFirstName': firstName,
        'sLastName': lastName,
        'sProfileImagePath': user.photoUrl ?? '',
        'sGoogleId': user.id,
      };

      final result = await HealthApiService.loginWithGoogle(googleData);

      if (result['status'] == 'success') {
        final userData = result['user'];
        final tbUser = await AppDatabase.instance.upsertUserFromServer(userData);
        await AuthService.instance.setLoginSession(tbUser.sEmail);

        if (!mounted) return;
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เข้าสู่ระบบสำเร็จ!'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError(result['message'] ?? 'เข้าสู่ระบบด้วย Google ไม่สำเร็จ');
        await _googleSignIn.signOut();
      }
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        _showError('กรุณาตั้งค่า OAuth Web Client ID หรือ google-services.json บน Android ให้เรียบร้อยก่อนใช้งาน Google Sign-In');
      } else if (e.code == GoogleSignInExceptionCode.canceled) {
        // ผู้ใช้กดยกเลิกการล็อกอิน ไม่ต้องแสดง error แดง
        return;
      } else {
        _showError('เกิดข้อผิดพลาดในการเข้าสู่ระบบ Google: ${e.description ?? e.code.name}');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('เกิดข้อผิดพลาด: $error');
    }
  }
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Regex ตรวจสอบรูปแบบ Email ที่ถูกต้อง
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    return emailRegex.hasMatch(email);
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();

    // 1. ตรวจสอบการถูกระงับชั่วคราว (Lockout Security)
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final waitSeconds = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      setState(() {
        _errorMessage = 'คุณพยายามเข้าสู่ระบบผิดบ่อยเกินไป กรุณารอ $waitSeconds วินาที';
      });
      return;
    }

    final rawEmail = _emailController.text.trim();
    final rawPassword = _passwordController.text;

    // 2. ดักตรวจช่องว่าง (Empty Check)
    if (rawEmail.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกอีเมลของคุณ';
      });
      _emailFocusNode.requestFocus();
      return;
    }

    // 3. ดักตรวจรูปแบบอีเมล (Email Format Validation)
    if (!_isValidEmail(rawEmail)) {
      setState(() {
        _errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง (เช่น example@domain.com)';
      });
      _emailFocusNode.requestFocus();
      return;
    }

    // 4. ดักตรวจความยาวและเนื้อหารหัสผ่าน (Password Validation)
    if (rawPassword.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกรหัสผ่าน';
      });
      _passwordFocusNode.requestFocus();
      return;
    }

    if (rawPassword.length < 6) {
      setState(() {
        _errorMessage = 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      });
      _passwordFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 5. ดำเนินการเข้าสู่ระบบผ่าน AuthService
      // (ปุ่ม Login จะหมุนต่อเนื่อง _isLoading = true ระหว่างเช็คทั้งในเครื่อง SQLite และ Remote MySQL Server)
      final loginResult = await AuthService.instance.login(rawEmail, rawPassword);

      if (!mounted) return;

      final isSuccess = loginResult['success'] == true;
      if (!isSuccess) {
        _registerFailedAttempt();
        setState(() {
          _isLoading = false; // สิ้นสุดกระบวนการตรวจสอบทั้งหมด ค่อยหยุดหมุนและแจ้ง Error
          _errorMessage = loginResult['message']?.toString() ?? 'เข้าสู่ระบบไม่สำเร็จ';
        });
        return;
      }

      // 6. เข้าสู่ระบบสำเร็จ -> รีเซ็ตจำนวนครั้งที่ผิด
      _failedAttempts = 0;
      _lockoutUntil = null;

      // 7. ดึงประวัติการออกกำลังกายจาก Database Server ลง SQLite ทันที (Initial Data Hydration)
      final loggedInUser = loginResult['user'] as TbUser?;
      if (loggedInUser != null) {
        // ดึงข้อมูลใน Background ต่อเนื่อง
        SyncService.instance.pullDownstreamWorkouts(loggedInUser.nUserId);
      }

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('เข้าสู่ระบบสำเร็จแล้ว ยินดีต้อนรับ!'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );

      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      debugPrint('LoginPage: Exception during _handleLogin: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อระบบ: $e';
      });
    }
  }

  /// ดักจับการล็อกอินผิดซ้ำๆ เพื่อความปลอดภัย
  void _registerFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
    }
  }

  Future<void> _handleBiometricSignIn() async {
    final available = await BiometricAuthService.instance.isBiometricAvailable();
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อุปกรณ์นี้ไม่รองรับหรือยังไม่ได้เปิดใช้งาน Biometric (FaceID/TouchID)'),
          backgroundColor: Color(0xFF4A5568),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final authenticated = await BiometricAuthService.instance.authenticate(
      reason: 'ยืนยันตัวตนด้วย FaceID / TouchID เพื่อเข้าสู่ระบบ HealthyMate',
    );
    if (authenticated) {
      final email = AuthService.instance.currentUserEmail;
      if (email.isNotEmpty) {
        await AuthService.instance.setLoginSession(email);
        if (!mounted) return;
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
      } else {
        _showError('กรุณาล็อกอินด้วยอีเมลครั้งแรกเพื่อเปิดใช้งาน Biometric');
      }
    }
  }

  void _handleSocialLogin(String provider) {
    if (provider == 'Google') {
      _handleGoogleSignIn();
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text('ระบบเข้าสู่ระบบด้วย $provider กำลังอยู่ในช่วงพัฒนา'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4A5568),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: topPadding + 16),

            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.favorite_border_rounded,
                      color: AppTheme.primaryGreen,
                      size: 26,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'HealthyMate',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryGreen,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Main Login Sheet Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: Column(
                    children: [
                      // Top Green Accent Border Line
                      Container(
                        height: 4,
                        width: double.infinity,
                        color: AppTheme.primaryGreen,
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(28.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 12),

                                // Heading Text
                                const LoginHeader(),

                                const SizedBox(height: 32),

                                // Error Message Banner if any
                                if (_errorMessage != null) ...[
                                  LoginErrorBanner(errorMessage: _errorMessage!),
                                  const SizedBox(height: 20),
                                ],

                                // Login Input Fields
                                LoginFormFields(
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  emailFocusNode: _emailFocusNode,
                                  passwordFocusNode: _passwordFocusNode,
                                  isPasswordVisible: _isPasswordVisible,
                                  onTogglePasswordVisibility: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                  onChanged: (_) {
                                    if (_errorMessage != null) {
                                      setState(() => _errorMessage = null);
                                    }
                                  },
                                  onSubmit: _handleLogin,
                                ),

                                const SizedBox(height: 32),

                                // Primary Login Button
                                LoginSubmitButton(
                                  isLoading: _isLoading,
                                  onSubmit: _handleLogin,
                                ),

                                const SizedBox(height: 32),

                                // Social Login Buttons
                                SocialLoginButtons(
                                  onGoogleLogin: () => _handleSocialLogin('Google'),
                                  onBiometricLogin: _handleBiometricSignIn,
                                ),

                                const SizedBox(height: 28),

                                // Register Navigation Link
                                LoginFooterLink(
                                  onRegisterTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => RegisterPage(
                                          onLoginTap: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 16),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
