part of 'register_form_fields.dart';

extension _RegisterFormFieldsContent on RegisterFormFields {
  Widget _buildFormFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First Name & Last Name Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First Name Field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextFieldLabel('ชื่อ (First Name)'),
                  TextFormField(
                    controller: firstNameController,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(lastNameFocusNode),
                    decoration: _buildInputDecoration(
                      hintText: 'สมชาย',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกชื่อ';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Last Name Field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextFieldLabel('นามสกุล (Last Name)'),
                  TextFormField(
                    controller: lastNameController,
                    focusNode: lastNameFocusNode,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(emailFocusNode),
                    decoration: _buildInputDecoration(
                      hintText: 'ใจดี',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกนามสกุล';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Email Field
        _buildTextFieldLabel('อีเมล (Email Address)'),
        TextFormField(
          controller: emailController,
          focusNode: emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) =>
              FocusScope.of(context).requestFocus(passwordFocusNode),
          decoration: _buildInputDecoration(
            hintText: 'example@email.com',
            prefixIcon: Icons.email_outlined,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'กรุณากรอกอีเมล';
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value.trim())) {
              return 'รูปแบบอีเมลไม่ถูกต้อง';
            }
            return null;
          },
        ),

        const SizedBox(height: 18),

        // Password Field
        _buildTextFieldLabel('รหัสผ่าน (Password)'),
        TextFormField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
          onChanged: onPasswordChanged,
          onFieldSubmitted: (_) =>
              FocusScope.of(context).requestFocus(confirmPasswordFocusNode),
          decoration: _buildInputDecoration(
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.textTertiary,
              ),
              onPressed: onToggleObscurePassword,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอกรหัสผ่าน';
            }
            if (value.length < 8) {
              return 'รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษร';
            }
            return null;
          },
        ),

        const SizedBox(height: 8),

        // ใช้ AnimatedSize ครอบไว้ให้กล่องความปลอดภัยยืดหดได้อย่างสมูท
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: passwordController.text.isEmpty
              ? const SizedBox.shrink()
              : PasswordRequirementsCard(
                  hasMinLength: hasMinLength,
                  hasUppercase: hasUppercase,
                  hasLowercase: hasLowercase,
                  hasDigits: hasDigits,
                ),
        ),

        const SizedBox(height: 18),

        // Confirm Password Field
        _buildTextFieldLabel('ยืนยันรหัสผ่าน (Confirm Password)'),
        TextFormField(
          controller: confirmPasswordController,
          focusNode: confirmPasswordFocusNode,
          obscureText: obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit(),
          decoration: _buildInputDecoration(
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.textTertiary,
              ),
              onPressed: onToggleObscureConfirmPassword,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณายืนยันรหัสผ่าน';
            }
            if (value != passwordController.text) {
              return 'รหัสผ่านไม่ตรงกัน';
            }
            return null;
          },
        ),
      ],
    );
  }
}
