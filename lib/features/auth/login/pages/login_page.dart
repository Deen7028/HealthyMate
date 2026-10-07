import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/auth/register/pages/register_page.dart';
import '../controllers/login_controller.dart';
import '../widgets/index.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, this.onClose, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final LoginController _controller;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isPasswordVisible = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    final success = await _controller.login(
      rawEmail: _emailController.text.trim(),
      rawPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      _triggerShake();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เข้าสู่ระบบสำเร็จ! ยินดีต้อนรับกลับมา'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );

    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    }
  }

  Future<void> _handleGoogleLogin() async {
    FocusScope.of(context).unfocus();
    final result = await _controller.loginWithGoogle();
    if (!mounted) return;

    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'เข้าสู่ระบบสำเร็จ!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }
    } else {
      _triggerShake();
    }
  }

  Future<void> _handleBiometricLogin() async {
    FocusScope.of(context).unfocus();
    final result = await _controller.loginWithBiometric();
    if (!mounted) return;

    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'เข้าสู่ระบบสำเร็จ!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }
    } else if (result['status'] != 'cancelled') {
      _triggerShake();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'เกิดข้อผิดพลาด'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(height: topPadding + 16),
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
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            width: double.infinity,
                            color: AppTheme.primaryGreen,
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(28.0),
                              child: AnimatedBuilder(
                                animation: _shakeAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(_shakeAnimation.value, 0.0),
                                    child: child,
                                  );
                                },
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 12),
                                      const LoginHeader(),
                                      const SizedBox(height: 32),
                                      AnimatedSize(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeOutCubic,
                                        child: _controller.errorMessage != null
                                            ? Padding(
                                                padding: const EdgeInsets.only(bottom: 24),
                                                child: LoginErrorBanner(
                                                  errorMessage: _controller.errorMessage!,
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
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
                                        onChanged: (_) {},
                                        onSubmit: _handleLogin,
                                      ),
                                      const SizedBox(height: 32),
                                      LoginSubmitButton(
                                        isLoading: _controller.isLoading,
                                        onSubmit: _handleLogin,
                                      ),
                                      const SizedBox(height: 28),
                                      SocialLoginButtons(
                                        onGoogleLogin: _handleGoogleLogin,
                                        onBiometricLogin: _handleBiometricLogin,
                                      ),
                                      const SizedBox(height: 32),
                                      LoginFooterLink(
                                        onRegisterTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => const RegisterPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
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
      },
    );
  }
}
