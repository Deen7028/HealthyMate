import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';

class RegisterSubmitButton extends StatelessWidget {
  final bool canSubmit;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onDisabledTap;

  const RegisterSubmitButton({
    super.key,
    required this.canSubmit,
    required this.isLoading,
    required this.onSubmit,
    required this.onDisabledTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: canSubmit ? onSubmit : onDisabledTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canSubmit ? AppTheme.primaryGreen : Colors.grey.shade400,
          foregroundColor: Colors.white,
          elevation: canSubmit ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'สมัครสมาชิก',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }
}
