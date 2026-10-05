// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์ขั้นตอนเริ่มต้นใช้งานและตั้งค่าเป้าหมาย (step3 primary goal view)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/features/onboarding/models/onboarding_goal_template.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class Step3PrimaryGoalView extends StatelessWidget {
  final OnboardingGoalTemplate? selectedGoal;
  final ValueChanged<OnboardingGoalTemplate> onSelectGoal;
  final VoidCallback onFinish;
  final VoidCallback onBack;
  final bool isLoading;

  const Step3PrimaryGoalView({
    super.key,
    required this.selectedGoal,
    required this.onSelectGoal,
    required this.onFinish,
    required this.onBack,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกเป้าหมายสุขภาพหลักของคุณ',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'เลือกเป้าหมายเริ่มต้น เพื่อให้ HealthyMate ติดตามความคืบหน้าบน Dashboard และแจ้งเตือนให้คุณทันที',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Template Cards
          ...OnboardingGoalTemplate.templates.map((template) {
            final isSelected = selectedGoal?.id == template.id;
            return GestureDetector(
              onTap: () => onSelectGoal(template),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppTheme.primaryGreen.withAlpha(50) : AppTheme.primaryGreenLight)
                      : cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : borderColor,
                    width: isSelected ? 2.2 : 1.2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppTheme.primaryGreen.withAlpha(40),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen.withAlpha(40)
                            : (isDark ? Colors.white10 : const Color(0xFFF0F4F0)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          template.icon,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppTheme.primaryGreen : textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            template.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? AppTheme.primaryGreen : textSecondary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Navigation Action Buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'ย้อนกลับ',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (selectedGoal == null || isLoading) ? null : onFinish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppTheme.primaryGreen.withAlpha(120),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'เสร็จสิ้น & เข้าสู่แอป',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.check_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
