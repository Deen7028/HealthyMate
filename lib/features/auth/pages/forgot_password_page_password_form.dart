// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์การยืนยันตัวตนและกู้รหัสผ่าน (forgot password page password form)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'forgot_password_page.dart';

extension _ForgotPasswordPasswordForm on _ForgotPasswordPageState {
  /// ฟังก์ชันสร้าง UI ของฟอร์มกรอกรหัสผ่าน
  Widget _buildPasswordForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        key: const ValueKey('password_form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ช่องรหัสผ่านใหม่
          TextFormField(
            controller: _newPasswordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_confirmPasswordFocusNode),
            decoration: InputDecoration(
              labelText: 'รหัสผ่านใหม่ (Password)',
              hintText: '••••••••',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.primaryGreen,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textTertiary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.primaryGreen,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกรหัสผ่านใหม่';
              }
              if (value.length < 8) {
                return 'รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษร';
              }
              return null;
            },
          ),

          const SizedBox(height: 8),

          // กล่องเงื่อนไขความปลอดภัยเหมือนหน้า Register
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: _newPasswordController.text.isEmpty
                ? const SizedBox.shrink()
                : PasswordRequirementsCard(
                    hasMinLength: _hasMinLength,
                    hasUppercase: _hasUppercase,
                    hasLowercase: _hasLowercase,
                    hasDigits: _hasDigits,
                  ),
          ),

          const SizedBox(height: 18),

          // ช่องยืนยันรหัสผ่านใหม่
          TextFormField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
            decoration: InputDecoration(
              labelText: 'ยืนยันรหัสผ่านใหม่ (Confirm Password)',
              hintText: '••••••••',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.primaryGreen,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textTertiary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.primaryGreen,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณายืนยันรหัสผ่านใหม่';
              }
              if (value != _newPasswordController.text) {
                return 'รหัสผ่านทั้งสองช่องไม่ตรงกัน';
              }
              return null;
            },
          ),

          const SizedBox(height: 28),
          /// ปุ่มยืนยันการรีเซ็ตรหัสผ่าน
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _controller.isLoading ? null : _handleResetPassword,
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
                        key: ValueKey('loading_pass'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'บันทึกรหัสผ่านใหม่',
                        key: ValueKey('text_pass'),
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
      ),
    );
  }
}
