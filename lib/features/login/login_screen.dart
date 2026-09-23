import 'package:flutter/material.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/register/register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.onClose,
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

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
      debugPrint('LoginScreen: Exception during _handleLogin: $e\n$stack');
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

  void _handleSocialLogin(String provider) {
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
                                const Center(
                                  child: Text(
                                    'ยินดีต้อนรับกลับ',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Subtitle
                                const Center(
                                  child: Text(
                                    'กรุณาเข้าสู่ระบบเพื่อดำเนินการต่อ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Error Message Banner if any
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDE8E8),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFF8B4B4)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded, color: Color(0xFFE02424), size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(color: Color(0xFF9B1C1C), fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Field 1 Label
                                const Text(
                                  'อีเมลหรือชื่อผู้ใช้',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Field 1 Input: Email/Username
                                TextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) {
                                    if (_errorMessage != null) {
                                      setState(() => _errorMessage = null);
                                    }
                                  },
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'กรอกอีเมลของคุณ',
                                    hintStyle: const TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      color: AppTheme.textSecondary,
                                      size: 22,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    filled: true,
                                    fillColor: AppTheme.subtleSurface,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppTheme.borderLight, width: 1.2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.8),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Field 2 Label & Forgot Password Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'รหัสผ่าน',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('ระบบจะส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลของคุณ'),
                                            backgroundColor: AppTheme.primaryGreen,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'ลืมรหัสผ่าน?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Field 2 Input: Password
                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: !_isPasswordVisible,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  onChanged: (_) {
                                    if (_errorMessage != null) {
                                      setState(() => _errorMessage = null);
                                    }
                                  },
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    hintStyle: const TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 14,
                                      letterSpacing: 2,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: AppTheme.textSecondary,
                                      size: 22,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    filled: true,
                                    fillColor: AppTheme.subtleSurface,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppTheme.borderLight, width: 1.2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.8),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Primary Login Button
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shadowColor: const Color(0x662E6339),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Text(
                                                'เข้าสู่ระบบ',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Divider with Text
                                Row(
                                  children: const [
                                    Expanded(child: Divider(color: AppTheme.borderLight, thickness: 1)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'หรือเข้าสู่ระบบด้วย',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: AppTheme.borderLight, thickness: 1)),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Social Login Buttons Row
                                Row(
                                  children: [
                                    // Google Button
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _handleSocialLogin('Google'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          backgroundColor: AppTheme.subtleSurface,
                                          side: const BorderSide(color: AppTheme.borderLight, width: 1.2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.account_circle_outlined,
                                              color: AppTheme.textPrimary,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Google',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Apple Button
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _handleSocialLogin('Apple'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          backgroundColor: AppTheme.subtleSurface,
                                          side: const BorderSide(color: AppTheme.borderLight, width: 1.2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.file_download_outlined,
                                              color: AppTheme.textPrimary,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Apple',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 28),

                                // Register Navigation Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'ยังไม่มีบัญชีสมาชิก? ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => RegisterScreen(
                                              onLoginTap: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'สมัครสมาชิกที่นี่',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ],
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
