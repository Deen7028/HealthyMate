// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์การเข้าสู่ระบบ (login page content)

part of 'login_page.dart';

extension LoginPageContent on _LoginPageState {
  Widget _buildLoginPage(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: topPadding + 16),

            // ส่วนบนสุด เป็นโลโก้ HealthyMate
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

            // ส่วนล่าง เป็นการ์ดสไลด์ลงมาจากด้านบน
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
                      // เส้นขีดสีเขียวด้านบนสุดของการ์ด
                      Container(
                        height: 4,
                        width: double.infinity,
                        color: AppTheme.primaryGreen,
                      ),

                      // ส่วนเนื้อหา
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

                                  // ส่วนข้อความต้อนรับ
                                  const LoginHeader(),

                                  const SizedBox(height: 32),

                                  // ส่วนแสดงข้อความ error message (ถ้ามี)
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    child: _errorMessage != null
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 20,
                                            ),
                                            child: LoginErrorBanner(
                                              errorMessage: _errorMessage!,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),

                                  // ส่วนกรอกข้อมูล
                                  LoginFormFields(
                                    emailController: _emailController,
                                    passwordController: _passwordController,
                                    emailFocusNode: _emailFocusNode,
                                    passwordFocusNode: _passwordFocusNode,
                                    isPasswordVisible: _isPasswordVisible,
                                    onTogglePasswordVisibility: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                    onChanged: (_) {
                                      if (_errorMessage != null) {
                                        setState(() => _errorMessage = null);
                                      }
                                    },
                                    onSubmit: this._handleLogin,
                                  ),

                                  const SizedBox(height: 32),

                                  // ปุ่ม Login หลัก
                                  LoginSubmitButton(
                                    isLoading: _isLoading,
                                    onSubmit: this._handleLogin,
                                  ),

                                  const SizedBox(height: 32),

                                  // ปุ่ม Social Login และ Biometric Login
                                  SocialLoginButtons(
                                    onGoogleLogin: () =>
                                        this._handleSocialLogin('Google'),
                                    onBiometricLogin:
                                        this._handleBiometricSignIn,
                                  ),

                                  const SizedBox(height: 28),

                                  // ส่วนล่างสุด เป็นลิงก์ไปยังหน้า Register
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
