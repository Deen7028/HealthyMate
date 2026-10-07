part of 'forgot_password_page.dart';

/// Extension สำหรับสร้าง UI ของฟอร์มกรอกอีเมล
extension _ForgotPasswordEmailForm on _ForgotPasswordPageState {
  /// Build UI ฟอร์มกรอกอีเมล
  Widget _buildEmailForm() {
    return Column(
      key: const ValueKey('email_form'),
      children: [
        /// อีเมล
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'อีเมล',
            hintText: 'example@email.com',
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: AppTheme.primaryGreen,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        /// ปุ่มส่ง OTP
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _controller.isLoading ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: _controller.isLoading
                  ? const SizedBox(
                      key: ValueKey('loading_otp'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'ส่งรหัส OTP',
                      key: ValueKey('text_otp'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
