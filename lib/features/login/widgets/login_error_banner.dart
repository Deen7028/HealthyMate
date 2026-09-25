import 'package:flutter/material.dart';

class LoginErrorBanner extends StatelessWidget {
  final String errorMessage;

  const LoginErrorBanner({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF8B4B4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE02424),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(
                color: Color(0xFF9B1C1C),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
