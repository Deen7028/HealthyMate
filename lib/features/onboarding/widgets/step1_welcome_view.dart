import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class Step1WelcomeView extends StatelessWidget {
  final VoidCallback onGetStarted;

  const Step1WelcomeView({
    super.key,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Logo & Branding
          Center(
            child: Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withAlpha(50),
                    AppTheme.primaryLightGreen.withAlpha(25),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withAlpha(35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.favorite_rounded,
                  size: 52,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ยินดีต้อนรับสู่ HealthyMate',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เพื่อนคู่คิดด้านสุขภาพและการออกกำลังกายอัจฉริยะ\nพร้อมดูแลคุณในทุกย่างก้าว',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Feature 1: AI Food Recognition
          _buildFeatureCard(
            context: context,
            icon: Icons.camera_alt_rounded,
            badgeEmoji: '📸',
            title: 'AI Food Recognition',
            description: 'ถ่ายรูปอาหารเพื่อคำนวณพลังงานและสารอาหารแคลอรีอัตโนมัติด้วย AI',
            accentColor: const Color(0xFFE65100),
            bgAccent: const Color(0xFFFFF3E0),
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // Feature 2: GPS Workout Tracking
          _buildFeatureCard(
            context: context,
            icon: Icons.directions_run_rounded,
            badgeEmoji: '🛰️',
            title: 'GPS Workout Tracking',
            description: 'ติดตามการวิ่ง เดิน ปั่นจักรยาน พร้อมคำนวณแคลอรีและ Pace บนแผนที่เรียลไทม์',
            accentColor: AppTheme.primaryGreen,
            bgAccent: AppTheme.primaryGreenLight,
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // Feature 3: Daily Routines & Goals
          _buildFeatureCard(
            context: context,
            icon: Icons.track_changes_rounded,
            badgeEmoji: '🎯',
            title: 'Daily Routines & Goals',
            description: 'จัดการกิจวัตรประจำวัน ตั้งเป้าหมายสุขภาพ และพิชิตเหรียญรางวัลความสำเร็จ',
            accentColor: const Color(0xFF1976D2),
            bgAccent: const Color(0xFFE3F2FD),
            isDark: isDark,
          ),
          const SizedBox(height: 36),

          // Get Started Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppTheme.primaryGreen.withAlpha(100),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'เริ่มต้นใช้งาน (Get Started)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String badgeEmoji,
    required String title,
    required String description,
    required Color accentColor,
    required Color bgAccent,
    required bool isDark,
  }) {
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? accentColor.withAlpha(40) : bgAccent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                badgeEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
