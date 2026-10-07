part of 'forgot_password_page.dart';

/// Extension สำหรับสร้าง UI Structure ของหน้าลืมรหัสผ่าน (สลับระหว่างฟอร์มกรอกอีเมลกับฟอร์มรหัสผ่านใหม่)
extension _ForgotPasswordPageContent on _ForgotPasswordPageState {
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
                  Text(
                    _controller.isOtpVerified
                        ? 'กำหนดรหัสผ่านใหม่'
                        : 'ลืมรหัสผ่าน?',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _controller.isOtpVerified
                        ? 'กรุณากรอกรหัสผ่านใหม่ที่มีความยาวอย่างน้อย 8 ตัวอักษรและตรงตามเงื่อนไข'
                        : 'กรอกอีเมลของคุณเพื่อรับรหัส OTP สำหรับยืนยันการตั้งรหัสผ่านใหม่',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _controller.isOtpVerified
                        ? _buildPasswordForm()
                        : _buildEmailForm(),
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
