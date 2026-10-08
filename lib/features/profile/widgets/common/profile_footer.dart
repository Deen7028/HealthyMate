import 'package:flutter/material.dart';
// ส่วนท้ายของหน้าโปรไฟล์
class ProfileFooter extends StatelessWidget {
  final VoidCallback onPrivacyPolicyTap;
  final VoidCallback onTermsTap;

  const ProfileFooter({
    super.key,
    required this.onPrivacyPolicyTap,
    required this.onTermsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE2E7DF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Color(0xFF659B70),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'HEALTHYMATE APP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: Color(0xFF8C968E),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Version 3.4.1 (Build 892)',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF8C968E),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onPrivacyPolicyTap,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6F7A72)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('•', style: TextStyle(color: Color(0xFF8C968E))),
              ),
              TextButton(
                onPressed: onTermsTap,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Terms of Service',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6F7A72)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
