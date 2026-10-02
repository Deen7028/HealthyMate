import 'package:flutter/material.dart';
import 'package:healthymate/core/services/onboarding_service.dart';
import 'package:healthymate/features/login/pages/login_page.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class OnboardingSlideItem {
  final String title;
  final String description;
  final String emoji;
  final IconData icon;
  final Color accentColor;
  final Color bgLightColor;

  const OnboardingSlideItem({
    required this.title,
    required this.description,
    required this.emoji,
    required this.icon,
    required this.accentColor,
    required this.bgLightColor,
  });
}

class OnboardingSlidesPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingSlidesPage({super.key, this.onCompleted});

  @override
  State<OnboardingSlidesPage> createState() => _OnboardingSlidesPageState();
}

class _OnboardingSlidesPageState extends State<OnboardingSlidesPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<OnboardingSlideItem> _slides = [
    OnboardingSlideItem(
      title: 'AI Food Recognition',
      description:
          'ถ่ายรูปอาหารเพื่อวิเคราะห์โภชนาการ คำนวณแคลอรี และบันทึกสารอาหารอัตโนมัติด้วย AI อัจฉริยะ',
      emoji: '📸',
      icon: Icons.camera_alt_rounded,
      accentColor: Color(0xFFE65100),
      bgLightColor: Color(0xFFFFF3E0),
    ),
    OnboardingSlideItem(
      title: 'GPS Workout Tracking',
      description:
          'ติดตามการวิ่ง เดิน และปั่นจักรยานแบบเรียลไทม์ คำนวณความเร็ว Pace และแคลอรีบนแผนที่สดใหม่',
      emoji: '🛰️',
      icon: Icons.directions_run_rounded,
      accentColor: AppTheme.primaryGreen,
      bgLightColor: AppTheme.primaryGreenLight,
    ),
    OnboardingSlideItem(
      title: 'Daily Routines & Goals',
      description:
          'ตั้งเป้าหมายสุขภาพ บันทึกกิจวัตรประจำวัน พร้อมพิชิตเหรียญรางวัลและความสำเร็จเพื่อสุขภาพที่ดีขึ้นทุกวัน',
      emoji: '🎯',
      icon: Icons.track_changes_rounded,
      accentColor: Color(0xFF1976D2),
      bgLightColor: Color(0xFFE3F2FD),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleFinishSlides() async {
    // บันทึกว่าผ่านหน้าสไลด์แนะนำแอปแล้ว (isFirstRun = false)
    await OnboardingService.instance.completeOnboarding();
    if (!mounted) return;

    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Logo & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withAlpha(35),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.favorite_rounded,
                            size: 20,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HealthyMate',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  if (_currentIndex < _slides.length - 1)
                    TextButton(
                      onPressed: _handleFinishSlides,
                      child: Text(
                        'ข้าม',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Middle Carousel Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Large Graphic / Icon Card
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            color: isDark
                                ? slide.accentColor.withAlpha(45)
                                : slide.bgLightColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: slide.accentColor.withAlpha(50),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              slide.emoji,
                              style: const TextStyle(fontSize: 78),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  // Page Indicators (Dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isSelected = _currentIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Next / Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentIndex < _slides.length - 1) {
                          _pageController.animateToPage(
                            _currentIndex + 1,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOutCubic,
                          );
                        } else {
                          _handleFinishSlides();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppTheme.primaryGreen.withAlpha(100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentIndex == _slides.length - 1
                                ? 'เริ่มต้นใช้งาน (Get Started)'
                                : 'ถัดไป',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
