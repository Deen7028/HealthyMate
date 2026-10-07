// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์การสมัครสมาชิก (register page content)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'register_page.dart';

extension _RegisterPageContent on _RegisterPageState {
  Widget _buildPage(BuildContext context) {
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
                        onTermsChanged: (val) =>
                            setState(() => _acceptTerms = val),
                        onPrivacyChanged: (val) =>
                            setState(() => _acceptPrivacy = val),
                        onShowTerms: _showTermsBottomSheet,
                        onShowPrivacy: _showPrivacyBottomSheet,
                      ),
                    ),

                    const SizedBox(height: 28),

                    FadeSlideEntrance(
                      delayIndex: 4,
                      child: RegisterSubmitButton(
                        canSubmit:
                            _acceptTerms &&
                            _acceptPrivacy &&
                            !_controller.isLoading,
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
